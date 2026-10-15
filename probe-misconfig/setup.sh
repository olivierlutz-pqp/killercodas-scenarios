#!/bin/bash
set -e

cat > /root/webapp.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 1
  selector:
    matchLabels: { app: webapp }
  template:
    metadata:
      labels: { app: webapp }
    spec:
      containers:
      - name: webapp
        image: python:3.12-alpine
        command: ["sh", "-c"]
        # L'appli écoute bien sur 8081 (simulé via un petit serveur python)
        args: ["python3 -m http.server 8081 || sleep infinity"]
        ports:
        - containerPort: 8081
        livenessProbe:
          httpGet:
            path: /
            port: 8080   # <- BUG: ancien port, probe jamais satisfaite
          initialDelaySeconds: 3
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 8080   # <- même bug côté readiness
          initialDelaySeconds: 3
          periodSeconds: 5
EOF

kubectl apply -f /root/webapp.yaml
