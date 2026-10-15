#!/bin/bash
set -e

# ======================================================================
# NOTE IMPORTANTE : ce script suppose containerd + systemd + crictl/ctr
# disponibles (standard sur l'image kubeadm de Killercoda). Si l'image
# utilisée diffère, adapte les commandes "ctr" / "systemctl" en conséquence.
# ======================================================================

# 1. Génère un htpasswd (bcrypt, requis par le registry Docker)
kubectl run htpasswd-gen --image=httpd:2.4-alpine --restart=Never --command -- \
  sh -c "htpasswd -Bbn registryuser registrypass > /tmp/htpasswd && sleep 3600"
kubectl wait --for=condition=Ready pod/htpasswd-gen --timeout=60s
kubectl cp htpasswd-gen:/tmp/htpasswd /root/htpasswd
kubectl delete pod htpasswd-gen --wait=false
kubectl create secret generic registry-htpasswd --from-file=htpasswd=/root/htpasswd

# 2. Déploie un petit registry privé protégé par basic auth dans kube-system
cat > /root/registry.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: private-registry
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels: { app: private-registry }
  template:
    metadata:
      labels: { app: private-registry }
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        env:
        - name: REGISTRY_AUTH
          value: htpasswd
        - name: REGISTRY_AUTH_HTPASSWD_REALM
          value: Registry
        - name: REGISTRY_AUTH_HTPASSWD_PATH
          value: /auth/htpasswd
        volumeMounts:
        - name: auth
          mountPath: /auth
      volumes:
      - name: auth
        secret:
          secretName: registry-htpasswd
---
apiVersion: v1
kind: Service
metadata:
  name: private-registry
  namespace: kube-system
spec:
  selector: { app: private-registry }
  ports:
  - port: 5000
    targetPort: 5000
EOF
kubectl apply -f /root/registry.yaml
kubectl -n kube-system rollout status deployment/private-registry --timeout=60s

REGISTRY_HOST="private-registry.kube-system.svc.cluster.local:5000"

# 3. Autorise containerd à parler en clair (http) à ce registry interne
mkdir -p "/etc/containerd/certs.d/${REGISTRY_HOST}"
cat > "/etc/containerd/certs.d/${REGISTRY_HOST}/hosts.toml" <<EOF
server = "http://${REGISTRY_HOST}"
[host."http://${REGISTRY_HOST}"]
  capabilities = ["pull", "resolve"]
EOF
systemctl restart containerd
sleep 5

# 4. Pousse une image existante vers ce registry privé
ctr -n k8s.io images pull docker.io/library/busybox:1.36
ctr -n k8s.io images tag docker.io/library/busybox:1.36 "${REGISTRY_HOST}/billing-api:1.0"
ctr -n k8s.io images push --user registryuser:registrypass "${REGISTRY_HOST}/billing-api:1.0"

# 5. Namespace applicatif + déploiement qui référence un imagePullSecret
kubectl create namespace payments

cat > /root/billing-api.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-api
  namespace: payments
spec:
  replicas: 1
  selector:
    matchLabels: { app: billing-api }
  template:
    metadata:
      labels: { app: billing-api }
    spec:
      imagePullSecrets:
      - name: regcred
      containers:
      - name: billing-api
        image: ${REGISTRY_HOST}/billing-api:1.0
EOF
kubectl apply -f /root/billing-api.yaml

# 6. BUG : le secret 'regcred' est créé... mais dans le namespace 'default',
#    pas dans 'payments' où vit le Deployment. Les secrets ne sont pas
#    partagés entre namespaces : le pull échoue malgré un secret "qui existe".
kubectl create secret docker-registry regcred \
  --docker-server="${REGISTRY_HOST}" \
  --docker-username=registryuser \
  --docker-password=registrypass \
  -n default
