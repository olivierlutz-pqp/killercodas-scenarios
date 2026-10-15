#!/bin/bash

R1=$(kubectl -n kube-system get pods -l k8s-app=kube-dns \
  -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null)
sleep 15
R2=$(kubectl -n kube-system get pods -l k8s-app=kube-dns \
  -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null)

if [ "$R1" == "$R2" ]; then
  echo "OK: CoreDNS stable, pas de nouveau redémarrage en 15s"
  exit 0
else
  echo "KO: CoreDNS continue de redémarrer ($R1 -> $R2)"
  exit 1
fi
