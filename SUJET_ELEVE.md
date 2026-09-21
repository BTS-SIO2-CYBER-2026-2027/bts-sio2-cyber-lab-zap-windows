# TP BTS SIO — Vibe Coding, compréhension du code et cybersécurité

## Objectif

Vous allez créer une application Web avec l'aide d'une IA générative, puis confronter automatiquement le résultat à OWASP ZAP.

**Vous devez produire le meilleur prompt possible.** Vous pouvez demander explicitement à l'IA des bonnes pratiques de cybersécurité. Le but du TP n'est pas de provoquer volontairement du mauvais code, mais de vérifier si une application générée par IA peut être considérée comme fiable sans compréhension ni audit.

## 1 — Créer le Codespace

Créez votre dépôt depuis le template puis ouvrez un Codespace. Le laboratoire démarre son superviseur automatiquement.

## 2 — Écrire votre prompt

Conservez votre prompt et ses principales itérations dans `PROMPT.md`.

Vous pouvez être aussi précis que vous le souhaitez, notamment sur la sécurité.

## 3 — Générer l'application

Demandez à l'assistant IA de créer **directement** l'application dans le dossier `app/`.

Contraintes techniques du laboratoire :

- application Web autonome dans le Codespace ;
- écoute sur le port `3000` ;
- ne pas modifier les scripts du dossier `scripts/` ni `.lab.env` ;
- ne pas utiliser de cible externe pour l'audit.

**Vous n'avez aucun fichier à déplacer et aucun script ZAP à lancer.**

Après la génération, le laboratoire détecte automatiquement le code, démarre l'application et lance les scans.

## 4 — Lire les résultats

Les rapports apparaissent automatiquement dans `reports/` :

- `zap-baseline-....html` / `.json` ;
- `zap-full-....html` / `.json`.

Vous devez ensuite relier les alertes pertinentes au code qui les provoque et expliquer les corrections nécessaires.

Pour manipuler l'interface graphique de ZAP, lancez `bash scripts/zap-gui.sh start`, attendez le message **« ZAP graphique est prêt »**, puis ouvrez une seule fois le port privé **8091** dans l'onglet **Ports** (chemin `/zap/`). **N'ouvrez jamais le port technique 8093.** Analysez uniquement `http://host.docker.internal:3000`. Dans **Quick Start > Automated Scan**, cochez **Use traditional spider** avant de cliquer sur **Attack** ; si ZAP affiche un avertissement demandant cette option, cliquez sur **OK**, cochez-la et relancez **Attack**. Cette nouvelle session n'affiche pas les anciens scans automatisés. Arrêtez-la ensuite avec `bash scripts/zap-gui.sh stop`. En cas de connexions trop nombreuses, fermez tous les onglets ZAP, lancez `bash scripts/zap-gui.sh restart`, puis rouvrez uniquement 8091. La procédure détaillée figure dans le `README.md`.

## 5 — Corriger

Vous pouvez corriger vous-même ou utiliser l'IA, mais vous devez comprendre les modifications. Une nouvelle modification de `app/` déclenche automatiquement un nouvel audit lorsque le code se stabilise.

## 6 — Conclusion

Complétez `ANALYSE.md` en comparant le prompt, le code généré, les vulnérabilités détectées et les corrections apportées.
