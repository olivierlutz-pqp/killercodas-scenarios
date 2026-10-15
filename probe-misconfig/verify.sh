#!/bin/bash

READY=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
RESTARTS=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null)

if [ "$READY" == "true" ] && [ "$RESTARTS" -lt 3 ]; then
  echo "OK: pod ready, redémarrages maîtrisés ($RESTARTS)"
  exit 0
else
  echo "KO: ready=$READY, restarts=$RESTARTS"
  exit 1
fi
