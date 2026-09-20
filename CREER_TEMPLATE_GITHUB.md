# Publier ce laboratoire comme template GitHub

1. Créez un dépôt GitHub vide, par exemple `bts-sio-cyber-lab`, dans votre organisation ou votre compte. N'ajoutez pas de README initial : celui du laboratoire est déjà présent.
2. Depuis le dossier décompressé du laboratoire, exécutez les commandes suivantes en remplaçant `COMPTE` par le propriétaire réel du dépôt :

```bash
git init
git add .
git commit -m "Initialiser le laboratoire ZAP avec interface graphique"
git branch -M main
git remote add origin https://github.com/COMPTE/bts-sio-cyber-lab.git
git push -u origin main
```

3. Sur GitHub, ouvrez **Settings → General → Template repository** et activez l'option. Les élèves pourront ensuite utiliser **Use this template → Create a new repository**, puis **Code → Codespaces → Create codespace on main**.
4. Faites un essai avec un dépôt élève : ouvrez les ports **3000**, **8080** et **8091** dans l'onglet **Ports**. Le port 8091 doit rester **Private**. Exécutez `bash scripts/zap-gui.sh start`, puis visitez l'URL transférée du port 8091 suivie de `/zap`.

L'interface graphique ne démarre qu'à la demande pour préserver les ressources des Codespaces. Les rapports automatiques restent servis sur 8080.
