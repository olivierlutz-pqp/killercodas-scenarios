## Bravo

Le pod est stable.

**Ce que ce scénario évaluait :**
- Réflexe de lire `kubectl describe pod` (section Events) avant de chercher dans les logs applicatifs
- Distinction entre "l'appli plante" et "Kubernetes pense que l'appli plante"
- Compréhension du rôle des probes dans le cycle de vie d'un pod
