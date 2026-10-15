## Bravo

Le pod CNI est stable, les coupures réseau ont disparu.

**Ce que ce scénario évaluait :**
- Réflexe de vérifier les composants système (`kube-system`) face à un symptôme applicatif flou
- Lecture des événements (`kubectl describe pod`) pour repérer un `OOMKilled`
- Compréhension du lien entre un DaemonSet CNI et la connectivité de tout le nœud
- Capacité à corriger sans sur-corriger (éviter de retirer complètement les limites)
