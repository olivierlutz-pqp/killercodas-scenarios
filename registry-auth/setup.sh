#!/bin/bash
set -euo pipefail

# ======================================================================
# NOTE IMPORTANTE : ce script suppose containerd + systemd + ctr
# disponibles (standard sur l'image kubeadm de Killercoda).
# ======================================================================

# Nom résolvable depuis le noeud : containerd/kubelet utilisent le resolver
# de l'hôte, pas CoreDNS, donc un nom en *.svc.cluster.local ne marche pas.
REGISTRY_HOST="registry.internal:5000"
grep -q "registry.internal" /etc/hosts || echo "127.0.0.1 registry.internal" >> /etc/hosts

# 1. Génère un htpasswd (bcrypt, requis par le registry Docker)
kubectl run htpasswd-gen --image=httpd:2.4-alpine --restart=Never --command -- \
  sh -c "htpasswd -Bbn registryuser registrypass > /tmp/htpasswd && sleep 3600"
kubectl wait --for=condition=Ready pod/htpasswd-gen --timeout=120s
until kubectl exec htpasswd-gen -- test -s /tmp/htpasswd; do sleep 1; done
kubectl exec htpasswd-gen -- cat /tmp/htpasswd > /root/htpasswd
kubectl delete pod htpasswd-gen --wait=false

# Le secret doit vivre dans le même namespace que le registry qui le monte
kubectl -n kube-system create secret generic registry-htpasswd --from-file=htpasswd=/root/htpasswd
rm -f /root/htpasswd

# 2. Déploie un petit registry privé protégé par basic auth dans kube-system.
#    hostNetwork : le registry écoute directement sur le port 5000 du noeud.
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
      hostNetwork: true
      tolerations:
      - operator: Exists
      containers:
      - name: registry
        image: registry:2
        env:
        - name: REGISTRY_HTTP_ADDR
          value: ":5000"
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
EOF
kubectl apply -f /root/registry.yaml
kubectl -n kube-system rollout status deployment/private-registry --timeout=120s
rm -f /root/registry.yaml

# Attend que le registry réponde (401 attendu sans credentials)
until curl -s -o /dev/null "http://${REGISTRY_HOST}/v2/"; do sleep 1; done

# 3. Autorise containerd (CRI) à parler en clair (http) à ce registry.
#    hosts.toml n'est lu que si config_path pointe vers certs.d.
mkdir -p "/etc/containerd/certs.d/${REGISTRY_HOST}"
cat > "/etc/containerd/certs.d/${REGISTRY_HOST}/hosts.toml" <<EOF
server = "http://${REGISTRY_HOST}"
[host."http://${REGISTRY_HOST}"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF

if grep -q 'config_path *= *"/etc/containerd/certs.d"' /etc/containerd/config.toml; then
  : # déjà configuré
elif grep -q 'config_path *=' /etc/containerd/config.toml; then
  sed -i 's#config_path *= *".*"#config_path = "/etc/containerd/certs.d"#' /etc/containerd/config.toml
  systemctl restart containerd
  sleep 5
  until kubectl get nodes >/dev/null 2>&1; do sleep 2; done
else
  echo "ERREUR : aucune clé config_path dans /etc/containerd/config.toml, adapter le script" >&2
  exit 1
fi

# 4. Pousse une image vers le registry privé. On travaille dans un namespace
#    containerd dédié ("setup") : si l'image était présente dans "k8s.io",
#    kubelet la trouverait en cache et le pod démarrerait sans pull, donc sans
#    jamais reproduire le bug du secret.
ctr -n setup images pull --all-platforms docker.io/library/busybox:1.36
ctr -n setup images tag docker.io/library/busybox:1.36 "${REGISTRY_HOST}/billing-api:1.0"
ctr -n setup images push --plain-http --user registryuser:registrypass "${REGISTRY_HOST}/billing-api:1.0"
ctr -n setup images rm docker.io/library/busybox:1.36 "${REGISTRY_HOST}/billing-api:1.0"

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
        imagePullPolicy: Always
        # busybox sort immédiatement sans commande longue : on le garde en vie
        command: ["sh", "-c", "while true; do sleep 3600; done"]
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
