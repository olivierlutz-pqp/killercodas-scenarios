#!/bin/bash

READY=$(kubectl -n payments get pods -l app=billing-api \
  -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)

if [ "$READY" == "true" ]; then
  echo "OK: billing-api tourne dans le namespace payments"
  exit 0
else
  echo "KO: billing-api n'est toujours pas ready (ready=$READY)"
  exit 1
fi
