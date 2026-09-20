# Instructions du laboratoire BTS SIO

Ce dépôt est un laboratoire pédagogique de génération de code puis d'audit automatique.

- Créez et modifiez l'application **directement dans `app/`**.
- Ne demandez jamais à l'élève de copier ou déplacer manuellement l'application ailleurs.
- L'application doit écouter sur le port `3000` et fonctionner dans le Codespace.
- Préférez une commande standard détectable (`npm run dev`, `npm start`, Flask, FastAPI ou PHP).
- **Ne lancez jamais vous-même un serveur persistant sur le port 3000** (`npm start`, `npm run dev`, `node server.js`, `flask run`, `uvicorn`, `python -m http.server`, etc.). Le superviseur du laboratoire est l'unique propriétaire du démarrage et du redémarrage de l'application.
- **Si le port 3000 est déjà occupé, c'est normal : ne tuez pas le processus et ne tentez pas de démarrer une deuxième instance.** Vérifiez l'application existante avec `curl`.
- Pour valider l'application, utilisez de préférence : `curl -i http://127.0.0.1:3000/`, les endpoints HTTP utiles, `node --check`, les tests unitaires ou les linters. Attendez quelques secondes après une modification pour laisser le superviseur redémarrer l'application.
- Vérifiez que les pages HTML sont servies avec un `Content-Type` correct (par exemple `text/html; charset=utf-8`) et non comme du texte brut.
- Vous pouvez consulter l'état du laboratoire avec `./scripts/lab-status.sh`.
- Ne modifiez jamais `.lab.env`, `scripts/`, `.devcontainer/` ni les garde-fous ZAP.
- L'élève peut demander toutes les bonnes pratiques de sécurité qu'il souhaite : ne dégradez volontairement ni son prompt ni le code.
- Ne prétendez pas que l'application est sécurisée uniquement parce que des bonnes pratiques ont été demandées ou parce qu'elle fonctionne.
- Lorsque vous corrigez une faiblesse, expliquez la cause technique afin que l'élève puisse la comprendre.
