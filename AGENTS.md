# Instructions de travail — bts-sio-cyber-lab

Ce dépôt est un laboratoire pédagogique BTS SIO. Lorsqu'un élève demande à une IA de créer ou modifier son application Web :

1. **Travaillez directement dans `app/`**. Ne créez pas l'application ailleurs et ne demandez jamais à l'élève de copier/déplacer les fichiers.
2. L'application doit être exécutable dans le Codespace et écouter sur le **port 3000** (`PORT=3000`).
3. Utilisez une commande de démarrage standard détectable par le laboratoire : Node.js (`npm run dev` ou `npm start`), Flask (`app.py`), FastAPI (`main.py`) ou PHP (`index.php`).
4. **Ne démarrez pas vous-même un serveur persistant sur le port 3000.** Le superviseur du laboratoire est le seul composant autorisé à démarrer/redémarrer l'application.
5. **Si le port 3000 est déjà occupé, considérez cela comme normal.** Ne tuez pas le processus et ne lancez pas une seconde instance. Testez l'instance existante avec `curl` et laissez le superviseur la redémarrer après vos modifications.
6. Pour valider le code, utilisez `curl`, les tests, les linters et les vérifications statiques. Contrôlez notamment que les pages HTML sont servies avec `Content-Type: text/html; charset=utf-8`.
7. Vous pouvez vérifier le laboratoire avec `./scripts/lab-status.sh`.
8. Vous pouvez installer les dépendances nécessaires dans `app/`, mais **ne modifiez pas** `.lab.env`, `scripts/`, `.devcontainer/`, ni les garde-fous ZAP.
9. Ne dégradez jamais volontairement la sécurité. Si l'élève demande des bonnes pratiques, appliquez-les sérieusement.
10. Ne prétendez jamais qu'une application est « sécurisée » uniquement parce qu'elle fonctionne ou parce que le prompt demande de la sécurité.
11. Après chaque correction importante, conservez une application exécutable afin que le superviseur puisse la relancer et déclencher automatiquement un nouvel audit ZAP.

Le superviseur du dépôt détecte automatiquement les changements dans `app/`, démarre l'application puis lance les scans ZAP locaux. L'élève n'a aucune opération de copie ou de lancement manuel à effectuer dans le flux normal.
