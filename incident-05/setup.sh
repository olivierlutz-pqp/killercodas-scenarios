#!/bin/bash
set -e

# NOTE : adapte le nom du DaemonSet/label au CNI réellement installé sur l'image
# Killercoda utilisée (vérifie avec `kubectl -n kube-system get ds` avant de figer ce script).
CNI_DS="kube-flannel"
CNI_LABEL="app=flannel"

kubectl -n kube-system patch daemonset "$CNI_DS" \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"20Mi"}]'

# Pod témoin qui logue ses échecs de connexion à l'API
kubectl create deployment probe --image=busybox -- \
  sh -c "while true; do wget -qO- --timeout=2 https://kubernetes.default >> /tmp/log 2>&1 || echo FAIL >> /tmp/log; sleep 5; done"
