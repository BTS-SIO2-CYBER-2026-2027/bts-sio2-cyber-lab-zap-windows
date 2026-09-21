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

Tout se fait dans le navigateur du Codespace : aucun logiciel à installer sur votre PC. Après avoir consulté les rapports, ouvrez le terminal du Codespace et lancez :

```bash
bash scripts/zap-gui.sh start
```

Attendez que le terminal affiche **« ZAP graphique est prêt »**. Dans l'onglet **Ports**, repérez le **port 8091**, vérifiez que sa visibilité est **Privée**, puis cliquez sur **Ouvrir dans le navigateur**. Si nécessaire, ajoutez `/zap/` à la fin de l'adresse transférée. **N'ouvrez jamais le port 8093** : il s'agit du port technique interne. La configuration demande à Codespaces de l'ignorer ; s'il ouvre malgré tout un onglet 8093, fermez cet onglet et revenez au port 8091.

N'ouvrez qu'**un seul onglet ZAP** à la fois. Plusieurs onglets peuvent consommer toutes les connexions graphiques autorisées par Webswing.

À la première ouverture, ZAP peut afficher **« Do you want to persist the ZAP Session? »** : sélectionnez **« No, I do not want to persist this session at this moment in time »**, puis cliquez sur **Start**. Cette réponse concerne l'enregistrement de la session graphique, pas les rapports automatiques enregistrés dans `reports/`. Si la fenêtre **Manage Add-ons** s'ouvre, fermez-la avec le **X** en haut à droite de cette fenêtre pour revenir à la fenêtre principale de ZAP. Ne fermez pas tout l'onglet du navigateur à cette étape.

### Explorer uniquement votre application

Dans ZAP, ouvrez **Quick Start / Démarrage rapide**, puis **Automated Scan / Scan automatisé**. Dans le champ **URL to attack / URL à attaquer**, saisissez **exactement** :

```text
http://host.docker.internal:3000
```

Cette adresse permet au conteneur ZAP de joindre **votre application de laboratoire sur le port 3000**. Dans les options du scan, cochez **Use traditional spider**. Si le message **« The options chosen mean that you need to select the traditional spider »** apparaît, cliquez sur **OK**, cochez **Use traditional spider**, puis relancez **Attack / Attaquer**. Vérifiez l'adresse avant de cliquer sur **Attack** : ce bouton lance l'exploration et des tests actifs, qui peuvent modifier les données de l'application. Utilisez-le uniquement pour cette application et dans le cadre de l'exercice autorisé par votre enseignant. Consultez ensuite les panneaux **Sites**, **History / Historique** et **Alerts / Alertes** pour examiner les requêtes et les résultats. La fenêtre **Manage Add-ons** peut rester fermée pendant l'exercice.

**Périmètre autorisé :** n'entrez aucune URL `github.dev` ou `app.github.dev`, aucune adresse d'un autre Codespace, aucun site public et aucune application d'un tiers. Si votre application renvoie vers un autre site, ne suivez pas ce lien avec ZAP et ne lancez aucun scan sur ce site. L'interface graphique de ZAP accepte techniquement d'autres adresses : **c'est à vous de respecter la cible autorisée**. En cas de doute sur une adresse ou une action, arrêtez-vous et demandez à l'enseignant avant de lancer le scan. Le respect de ce périmètre et de l'autorisation est indispensable ; la seule utilisation de ZAP ne garantit pas à elle seule la conformité légale. Voir l'[article 323-1 du Code pénal](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000047052655).

Le ZAP graphique est une instance différente de celles lancées pour les rapports automatisés : les anciens scans ne figurent pas dans son historique. Explorez la cible dans l'interface pour générer votre propre historique ; comparez ensuite ses alertes aux rapports du dossier `reports/`. La session du ZAP graphique est conservée dans un volume Docker propre au Codespace.

### Fermer ZAP après l'exercice

Pour masquer simplement la fenêtre, fermez **l'onglet ZAP du navigateur** ; l'instance continue alors de tourner dans le Codespace. Pour **arrêter réellement ZAP et libérer des ressources**, revenez au terminal du Codespace et lancez :

```bash
bash scripts/zap-gui.sh stop
```

Vous pouvez ensuite fermer l'onglet ZAP. Pour le rouvrir plus tard, relancez `bash scripts/zap-gui.sh start`, puis rouvrez le port 8091. Gardez ce port **privé** et ne partagez pas son URL : elle donne accès à l'interface de ZAP. Le conteneur exécute la version Linux de ZAP Desktop, affichée dans votre navigateur. [Documentation ZAP Webswing](https://www.zaproxy.org/docs/docker/webswing/).

### Si la connexion à ZAP est perdue

Si la page affiche **« Your connection to the server is lost »**, cliquez d'abord sur **Reconnect** et attendez quelques instants. Si ZAP s'affiche de nouveau, reprenez votre travail. Évitez **Sign out**, qui ferme votre session dans cette interface.

Si **Reconnect** ne suffit pas, revenez à l'onglet de l'éditeur Codespaces et vérifiez l'état de ZAP dans son terminal :

```bash
bash scripts/zap-gui.sh status
```

Si ZAP ou le relais du port 8091 est arrêté, relancez-les avec `bash scripts/zap-gui.sh start`. Le script recrée automatiquement un conteneur ZAP arrêté afin d'éviter l'erreur **« Xvfb failed to start »**, tout en conservant le volume de données.

Si la page affiche **« There are too many active connections »**, fermez tous les onglets ZAP/Webswing, gardez seulement l'éditeur Codespaces, puis lancez :

```bash
bash scripts/zap-gui.sh restart
```

Attendez le message **« ZAP graphique est prêt »**, puis ouvrez une seule fois le **port privé 8091**, avec `/zap/` à la fin. N'utilisez jamais 8093. La commande `restart` recrée uniquement le conteneur graphique et conserve son volume de données.

Après un redémarrage du Codespace, repartez de l'éditeur et relancez `bash scripts/zap-gui.sh start` : une ancienne adresse transférée peut ne plus fonctionner.

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
