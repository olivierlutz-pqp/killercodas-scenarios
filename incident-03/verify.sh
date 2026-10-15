#!/bin/bash

STATUS=$(helm status app -o json 2>/dev/null | jq -r .info.status)

if [ "$STATUS" == "deployed" ]; then
  echo "OK: release 'app' est en état deployed"
  exit 0
else
  echo "KO: release 'app' est en état '$STATUS' (attendu: deployed)"
  exit 1
fi
