## Ticket d'incident

> "C'est aléatoire, ça touche des pods qui n'ont pourtant pas changé. Parfois ça marche,
> parfois non. On soupçonne le réseau mais personne n'a touché aux NetworkPolicy."

Un pod `probe` tourne dans le namespace `default` : il tente de joindre l'API Kubernetes
toutes les 5 secondes et consigne le résultat dans `/tmp/log`.

**Ta mission :** trouve la cause de ces coupures et corrige-la durablement.
