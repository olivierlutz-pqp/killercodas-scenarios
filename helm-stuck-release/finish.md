## Bravo

La release est de nouveau `deployed`.

**Ce que ce scénario évaluait :**
- Lecture d'un état Helm (`status`, `history`) plutôt que de se fier au seul message d'erreur
- Compréhension des hooks Helm (`post-upgrade`) et de leur impact sur le cycle de vie d'une release
- Capacité à distinguer "l'appli ne tourne pas" de "le mécanisme de déploiement est cassé"
- Choix entre corriger le chart et upgrader à nouveau, vs. rollback
