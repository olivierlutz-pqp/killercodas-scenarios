#!/bin/bash

EXPECTED_IMAGE="registry.internal:5000/billing-api:1.0"

fail() { echo "KO: $1"; exit 1; }

# 1. L'image doit toujours venir du registry privé (pas de contournement
#    en remplaçant l'image par une image publique)
IMAGE=$(kubectl -n payments get deploy billing-api \
  -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$IMAGE" == "$EXPECTED_IMAGE" ] || fail "l'image doit rester $EXPECTED_IMAGE (actuelle : $IMAGE)"

# 2. Le registry doit toujours exiger une authentification
AUTH=$(kubectl -n kube-system get deploy private-registry \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REGISTRY_AUTH")].value}' 2>/dev/null)
[ "$AUTH" == "htpasswd" ] || fail "l'authentification du registry ne doit pas être désactivée"
CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://registry.internal:5000/v2/")
[ "$CODE" == "401" ] || fail "le registry doit refuser les accès anonymes (HTTP $CODE)"

# 3. Le pull doit passer par un imagePullSecret présent dans payments
#    (au niveau du Deployment ou du ServiceAccount utilisé)
SECRETS=$(kubectl -n payments get deploy billing-api \
  -o jsonpath='{.spec.template.spec.imagePullSecrets[*].name}' 2>/dev/null)
SA=$(kubectl -n payments get deploy billing-api \
  -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null)
SECRETS="$SECRETS $(kubectl -n payments get sa "${SA:-default}" \
  -o jsonpath='{.imagePullSecrets[*].name}' 2>/dev/null)"

VALID=""
for S in $SECRETS; do
  TYPE=$(kubectl -n payments get secret "$S" -o jsonpath='{.type}' 2>/dev/null)
  [ "$TYPE" == "kubernetes.io/dockerconfigjson" ] && VALID="$S"
done
[ -n "$VALID" ] || fail "aucun imagePullSecret de type docker-registry valide dans le namespace payments"

# 4. Le pod doit tourner
READY=$(kubectl -n payments get pods -l app=billing-api \
  -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null)
[[ "$READY" == *true* ]] || fail "billing-api n'est toujours pas ready"

echo "OK: billing-api tire son image du registry privé via le secret '$VALID'"
exit 0
