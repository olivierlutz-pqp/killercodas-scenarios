## Bravo

La résolution DNS est redevenue fiable.

**Ce que ce scénario évaluait :**
- Capacité à repérer qu'un symptôme "aléatoire et partout" pointe vers un composant
  partagé (CoreDNS) plutôt qu'un pod applicatif précis
- Lecture des logs CoreDNS (`kubectl -n kube-system logs deploy/coredns`)
- Compréhension du plugin `loop` et de pourquoi CoreDNS s'auto-tue quand il détecte
  une boucle de résolution vers lui-même
- Lien entre le `resolv.conf` du nœud et la configuration `forward` de CoreDNS
