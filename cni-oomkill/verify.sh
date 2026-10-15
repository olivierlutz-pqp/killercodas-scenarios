#!/bin/bash

CNI_DS="kube-flannel"
CNI_LABEL="app=flannel"

LIMIT=$(kubectl -n kube-system get daemonset "$CNI_DS" \
  -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)

RESTARTS=$(kubectl -n kube-system get pods -l "$CNI_LABEL" \
  -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null)

if [[ "$RESTARTS" -eq 0 && "$LIMIT" != "20Mi" ]]; then
  echo "OK: incident résolu"
  exit 0
else
  echo "KO: le problème n'est pas résolu durablement"
  exit 1
fi
