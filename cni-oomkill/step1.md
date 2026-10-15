## Ticket d'incident

> "C'est aléatoire, ça touche des pods qui n'ont pourtant pas changé. Parfois ça marche,
> parfois non. On soupçonne le réseau mais personne n'a touché aux NetworkPolicy."

Un pod témoin (`probe`) tourne dans le cluster et logue en continu ses tentatives
de connexion à l'API Kubernetes dans `/tmp/log`.

**Ta mission :**

1. Observe le pattern des échecs (constant ? périodique ? lié à un composant précis ?).
2. Identifie le composant système en cause — l'indice n'est pas dans les pods applicatifs.
3. Corrige durablement le problème.

Pense à regarder du côté de `kube-system`, pas seulement du namespace applicatif.
