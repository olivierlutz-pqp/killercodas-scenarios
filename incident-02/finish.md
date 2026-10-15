## Bravo

Le pod démarre correctement.

**Ce que ce scénario évaluait :**
- Lecture précise du message d'erreur (`kubectl describe pod`) plutôt qu'une supposition rapide
- Compréhension de `imagePullSecrets` : un secret peut exister sans être réellement utilisable
  (mauvais namespace, mauvais nom référencé, ou absent du Deployment)
- Vérification du contenu d'un secret `docker-registry` (`kubectl get secret -o yaml` + decode)
