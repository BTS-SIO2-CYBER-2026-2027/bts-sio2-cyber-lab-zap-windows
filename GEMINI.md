# Consignes Gemini — bts-sio-cyber-lab

- Génère et modifie l'application directement dans `app/`.
- L'application doit écouter sur le port 3000 et utiliser une commande de démarrage standard détectable.
- **Ne démarre jamais toi-même un serveur persistant sur le port 3000.** Le superviseur du laboratoire le fait automatiquement.
- Si le port 3000 est occupé, ne tue pas le processus et ne lance pas de seconde instance : valide l'application existante avec `curl`.
- Utilise les tests statiques, unitaires et HTTP pour vérifier ton travail. Vérifie aussi le `Content-Type` des pages HTML.
- Ne modifie pas `.lab.env`, `scripts/`, `.devcontainer/` ni les protections ZAP.
- Ne dégrade jamais volontairement la sécurité du code.
