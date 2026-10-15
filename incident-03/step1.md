## Ticket d'incident

> "On n'arrive plus à déployer quoi que ce soit sur `app`. Helm renvoie une erreur
> du genre 'another operation is in progress'. On a rien touché depuis ce matin."

**Ta mission :**

1. Identifie pourquoi la release `app` est bloquée.
2. Trouve la cause racine (ce n'est pas le Deployment applicatif).
3. Remets la release dans un état sain (`deployed`), sans supprimer l'historique
   si tu peux l'éviter.

Quelques commandes qui pourraient t'être utiles : `helm status`, `helm history`,
`kubectl get jobs`, `kubectl logs`.
