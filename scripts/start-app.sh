#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Ce template démarre normalement l'application automatiquement."
echo "Démarrage manuel de secours :"
exec "$ROOT/scripts/start-generated-app.sh"
