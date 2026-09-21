# bts-sio-cyber-lab

> **Template GitHub Codespaces pour BTS SIO : génération d'une application Web avec une IA, puis audit automatique avec OWASP ZAP.**

## Objectif pédagogique

Vous devez produire **le meilleur prompt possible**. Vous pouvez demander à l'IA une application robuste, des bonnes pratiques de développement et des mesures de sécurité.

Le but du laboratoire n'est pas de vous piéger avec un mauvais prompt. Il est de vérifier une idée essentielle : **même avec un prompt sérieux et une application qui semble fonctionner, le code généré par une IA doit être compris, testé et audité.**

Vous ne devez donc pas seulement constater que l'application fonctionne. Vous devez être capable d'expliquer le code produit, d'identifier les faiblesses détectées et de les corriger.

## Comment fonctionne le laboratoire ?

```text
Navigateur de l'élève
        │
        │ URL Codespaces : *.app.github.dev
        ▼
┌────────────────────────── GitHub Codespace ──────────────────────────┐
│                                                                      │
│     Assistant IA (Copilot / autre)                                  │
│                 │                                                    │
│                 │ génère le code directement                        │
│                 ▼                                                    │
│              app/                                                    │
│                 │                                                    │
│                 ▼                                                    │
│        Application Web générée                                       │
│          127.0.0.1:3000                                              │
│                 ▲                                                    │
│                 │ cible locale uniquement                            │
│                 │                                                    │
│         OWASP ZAP automatique                                        │
│                 │                                                    │
│        ┌────────┴─────────┐                                          │
│        ▼                  ▼                                          │
│  Baseline Scan        Full Scan                                      │
│  (passif)             (actif)                                        │
│        └────────┬─────────┘                                          │
│                 ▼                                                    │
│             reports/                                                 │
│        rapports HTML + JSON                                          │
│        RESUME_SECURITE.md                                             │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Explication du schéma

L'adresse en `*.app.github.dev` sert uniquement à **afficher votre application dans votre navigateur**. Elle est créée par GitHub Codespaces pour vous permettre d'accéder au port 3000 du Codespace.

À l'intérieur du Codespace, l'application fonctionne sur :

```text
http://127.0.0.1:3000
```

OWASP ZAP analyse **cette adresse locale**. Les scripts du laboratoire refusent volontairement les domaines Internet et les autres adresses IP. Vous ne devez donc pas choisir manuellement une cible de scan.

Le **Baseline Scan** réalise principalement une exploration et une analyse passive. Le **Full Scan** réalise ensuite des tests actifs contre votre propre application de laboratoire.

Les résultats sont enregistrés automatiquement dans `reports/`. Le fichier `RESUME_SECURITE.md` est également généré automatiquement pour vous donner une première synthèse des alertes par niveau de risque. Vous devez cependant consulter les rapports HTML et le code source : le résumé ne remplace pas votre analyse.

## Déroulement pour l'élève

```text
Votre prompt
    ↓
IA dans VS Code
    ↓
Création automatique de l'application dans app/
    ↓
Détection du code par le laboratoire
    ↓
Démarrage automatique sur le port 3000
    ↓
ZAP Baseline Scan
    ↓
ZAP Full Scan
    ↓
Rapports + RESUME_SECURITE.md
    ↓
Analyse du code
    ↓
Correction
    ↓
Nouveau scan automatique
```

Aucune copie manuelle de l'application n'est nécessaire. L'assistant IA écrit directement dans `app/` et le superviseur du laboratoire surveille ce dossier.

## Que devez-vous analyser ?

Dans `reports/`, vous trouverez notamment :

```text
zap-baseline-AAAAmmjj-HHMMSS.html
zap-baseline-AAAAmmjj-HHMMSS.json
zap-full-AAAAmmjj-HHMMSS.html
zap-full-AAAAmmjj-HHMMSS.json
RESUME_SECURITE.md
```

Commencez par `RESUME_SECURITE.md`, puis ouvrez les rapports HTML complets. Pour chaque alerte importante, recherchez ensuite la partie du code qui peut l'expliquer.

Une alerte ZAP n'est pas une preuve suffisante à elle seule : il peut exister des faux positifs, et certaines failles ne sont pas détectables automatiquement. **Votre compréhension du code reste indispensable.**

## Explorer ZAP avec son interface graphique

Après avoir consulté les rapports, ouvrez un terminal dans votre Codespace et lancez :

```bash
bash scripts/zap-gui.sh start
```

Dans l'onglet **Ports**, ouvrez l'adresse du **port 8091** et ajoutez `/zap/` à la fin de l'adresse si nécessaire. Patientez pendant le premier chargement. Le conteneur exécute ZAP sous Linux ; l'interface et les fonctions d'analyse sont celles de ZAP Desktop. Le script publie Webswing sur le port local 8093 et lance un relais local sur 8091 : Codespaces conserve son URL privée, tandis que Webswing reçoit l'origine locale qu'il exige pour sa connexion WebSocket.

Si vous utilisiez une version antérieure du template, la première commande `start` recrée uniquement le conteneur graphique pour déplacer son port interne vers 8093. Le volume Docker `bts-sio-zap-gui-data` reste en place. Les rapports automatiques ne sont pas modifiés. Vérifiez `bash scripts/zap-gui.sh status` : ZAP et le relais doivent fonctionner. Le test final est l'ouverture effective de la fenêtre ZAP dans le navigateur Codespaces ; un simple code HTTP 101 ne suffit pas à valider l'interface.

Dans le champ « URL à attaquer » de l'onglet « Démarrage rapide », utilisez **uniquement** :

```text
http://host.docker.internal:3000
```

Cette adresse permet au conteneur ZAP de joindre votre application du laboratoire. **Ne saisissez pas** l'adresse de github.dev, de Codespaces, ni un site extérieur. Commencez par explorer manuellement l'arborescence, les requêtes et les alertes ; un scan actif modifie le comportement de l'application et doit rester limité à votre laboratoire.

Le ZAP graphique est une instance différente de celles lancées pour les rapports automatisés : les anciens scans ne figurent pas dans son historique. Explorez la cible dans l'interface pour générer votre propre historique ; comparez ensuite ses alertes aux rapports du dossier `reports/`. La session du ZAP graphique est conservée dans un volume Docker propre au Codespace.

Pour arrêter l'interface et libérer des ressources :

```bash
bash scripts/zap-gui.sh stop
```

Réexécutez `start` pour la rouvrir. Gardez la visibilité du port **8091 privée** dans Codespaces et ne partagez pas son URL : l'interface permet de piloter ZAP. [Documentation ZAP Webswing](https://www.zaproxy.org/docs/docker/webswing/).

## Stacks détectées automatiquement

Le template sait démarrer automatiquement les cas courants suivants :

- Node.js (`package.json`, script `dev` ou `start`) ;
- Python/Flask (`app.py`) ;
- Python/FastAPI (`main.py`) ;
- PHP (`index.php`).

Pour un autre framework, l'enseignant peut enrichir `scripts/detect-start-command.sh`.

## État du laboratoire

Vous pouvez vérifier à tout moment que le superviseur, l’application et les rapports sont bien actifs avec :

```bash
./scripts/lab-status.sh
```

Le fichier `reports/RESUME_SECURITE.md` est créé dès l’ouverture du Codespace. Avant le premier audit, il indique simplement que les rapports ZAP ne sont pas encore disponibles ; il est ensuite réécrit automatiquement après les scans.

## Diagnostic

Le journal du superviseur se trouve dans :

```text
.lab-state/auto-audit.log
```

Le journal de l'application se trouve dans :

```text
.lab-state/app.log
```

Pour vérifier l'état de l'application depuis le terminal du Codespace :

```bash
curl -I http://127.0.0.1:3000
```

Pour lister les rapports générés :

```bash
find reports -maxdepth 1 -type f -printf '%f\n' | sort
```

## Trois ports à connaître dans Codespaces

Le laboratoire démarre automatiquement deux services utiles :

```text
Port 3000  → votre application Web
Port 8080  → les rapports OWASP ZAP
Port 8091  → interface graphique de ZAP (démarrage à la demande)
```

Dans VS Code Codespaces, ouvrez l'onglet **Ports** :

- cliquez sur l'adresse transférée du **port 3000** pour utiliser votre application ;
- cliquez sur l'adresse transférée du **port 8080** pour afficher la liste des rapports ZAP, puis ouvrez le fichier `zap-baseline-....html` ou `zap-full-....html`.
- après `bash scripts/zap-gui.sh start`, ouvrez l'adresse privée du **port 8091** suivie de `/zap` pour manipuler ZAP.

L'application et le serveur de rapports démarrent automatiquement. L'interface graphique démarre à la demande.

### Pourquoi le port 3000 peut-il être « déjà utilisé » ?

C'est normalement une bonne nouvelle : le **superviseur du laboratoire a déjà démarré votre application**. L'assistant IA ne doit donc pas exécuter une deuxième fois `npm start`, `node server.js`, Flask, Uvicorn, etc.

```text
Assistant IA
   │ écrit/modifie app/
   ▼
Superviseur du laboratoire
   │ démarre/redémarre l'application
   ▼
127.0.0.1:3000
   │
   ├── affichage navigateur via le port 3000 Codespaces
   └── analyse automatique OWASP ZAP

reports/
   │
   └── serveur de rapports → port 8080 → navigateur
```

Si l'assistant veut vérifier son travail, il doit tester l'instance déjà lancée, par exemple avec :

```bash
curl -i http://127.0.0.1:3000/
```

Il ne doit pas tuer le processus existant ni démarrer une seconde instance.
