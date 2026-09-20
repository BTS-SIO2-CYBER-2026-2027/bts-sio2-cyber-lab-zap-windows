# Notes enseignant

## Intention pédagogique

Le dispositif ne repose pas sur un prompt volontairement pauvre. L'élève doit pouvoir enrichir son prompt, y compris en demandant les meilleures pratiques de cybersécurité.

Le constat recherché est expérimental : le niveau de confiance ne doit pas découler du prompt ou de l'apparence fonctionnelle de l'application, mais de la compréhension du code, des tests et de l'audit.

## Garde-fou réseau du TP

Les scripts `zap-baseline.sh` et `zap-full-scan.sh` appellent `assert_local_target` avant le lancement de ZAP. Les seules cibles acceptées sont `localhost` et `127.0.0.1`.

Cela ne constitue pas une sandbox de sécurité absolue contre un élève qui modifierait volontairement les scripts, mais cela évite les scans externes accidentels dans le déroulé normal du TP.

L'interface graphique Webswing donne directement accès aux commandes de ZAP : le garde-fou des scripts automatisés ne s'y applique pas. Demandez aux élèves de saisir exclusivement `http://host.docker.internal:3000` et de laisser le port 8091 privé. La session graphique est indépendante des rapports automatiques.

Pour tester le garde-fou :

```bash
./scripts/check-target-guard.sh
```

## Fonctionnement Codespaces

Le port 3000 est automatiquement transféré pour l'affichage dans le navigateur. GitHub Codespaces rend les ports transférés privés par défaut. ZAP n'utilise pas l'URL `*.app.github.dev` : le conteneur ZAP est lancé avec `--network host` et vise `http://127.0.0.1:3000` à l'intérieur du Codespace Docker-in-Docker.

## Déroulé conseillé

- séance 1 : conception du prompt + génération + lecture du code ;
- séance 2 : tests fonctionnels + Baseline Scan ;
- séance 2 : ouvrir l'interface ZAP avec `bash scripts/zap-gui.sh start`, explorer les requêtes et comparer avec le rapport Baseline ;
- séance 3 : Full Scan encadré + recherche de la cause dans le code ;
- séance 4 : correction + ré-audit + comparaison avant/après.

## Évaluation possible

- qualité et traçabilité du prompt : 15 % ;
- application fonctionnelle : 15 % ;
- capacité à expliquer le code : 25 % ;
- analyse des résultats ZAP : 25 % ;
- correction et ré-audit : 15 % ;
- recul critique sur l'usage de l'IA : 5 %.

Ne pas noter l'élève sur le simple nombre de vulnérabilités trouvées : deux IA, deux prompts ou deux stacks peuvent produire des résultats différents.

## Résumé de sécurité automatique

Après chaque scan ZAP, `scripts/generate-security-summary.py` reconstruit automatiquement `reports/RESUME_SECURITE.md` à partir des derniers rapports JSON Baseline et Full Scan. Le fichier présente les nombres d'alertes par niveau et une liste synthétique des alertes principales.

Ce résumé est volontairement présenté comme une aide de lecture et non comme une validation de sécurité : l'élève doit encore ouvrir les rapports HTML, retrouver la cause dans le code et vérifier la correction après un nouveau scan.

Le superviseur surveille également la disponibilité du port 3000 après l'audit. Si un assistant IA arrête le serveur qu'il avait lancé pour ses propres tests, le laboratoire relance automatiquement l'application générée sans demander d'intervention à l'élève.
