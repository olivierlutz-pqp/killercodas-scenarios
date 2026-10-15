#!/bin/bash
set -e

mkdir -p /root/app-chart/templates

cat > /root/app-chart/Chart.yaml <<'EOF'
apiVersion: v2
name: app-chart
version: 0.1.0
EOF

cat > /root/app-chart/values.yaml <<'EOF'
image: nginx:1.25
migrationImage: busybox:1.36
EOF

cat > /root/app-chart/templates/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 2
  selector:
    matchLabels: { app: webapp }
  template:
    metadata:
      labels: { app: webapp }
    spec:
      containers:
      - name: webapp
        image: {{ .Values.image }}
EOF

cat > /root/app-chart/templates/migration-job.yaml <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  annotations:
    "helm.sh/hook": post-upgrade
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: {{ .Values.migrationImage }}
        command: ["sh", "-c", "exit 1"]
      restartPolicy: Never
  backoffLimit: 1
EOF

# Install initial propre
helm install app /root/app-chart --wait --timeout 60s

# Upgrade dont le hook post-upgrade échoue -> release reste pending-upgrade
helm upgrade app /root/app-chart --set image=nginx:1.26 --timeout 20s || true
