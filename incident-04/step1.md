## Ticket d'incident

> "C'est aléatoire et ça ne touche jamais les mêmes pods deux fois de suite.
> Parfois un `nslookup` passe, parfois non, sur le même pod, à quelques secondes d'écart."

**Ta mission :**

1. Reproduis le problème (ex : boucle de `nslookup` ou `dig` depuis un pod de test).
2. Regarde du côté du composant responsable de la résolution DNS dans le cluster.
3. Identifie la cause exacte dans sa configuration, puis corrige.

Indice : le symptôme touche *tout* le cluster de façon non reproductible à la demande —
pense à un composant partagé plutôt qu'à un pod applicatif précis.
