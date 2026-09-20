#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/reports" "$ROOT/.lab-state"
chmod +x "$ROOT/scripts"/*.sh

# Le résumé existe dès le premier démarrage, même avant la génération de l'application.
python3 "$ROOT/scripts/generate-security-summary.py" >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo " bts-sio-cyber-lab"
echo "============================================================"
echo "Environnement prêt."
echo "- L'IA doit générer directement l'application dans app/."
echo "- Aucun remplacement manuel n'est nécessaire."
echo "- Le superviseur démarrera l'application et lancera ZAP automatiquement."
echo "- Les rapports HTML seront servis automatiquement sur le port 8080."
echo "- reports/RESUME_SECURITE.md est créé dès maintenant puis mis à jour après les scans."
echo "============================================================"
