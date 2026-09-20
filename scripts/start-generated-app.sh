#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib.sh"
load_lab_env
cd "$ROOT/app"
export PORT="$APP_PORT"
export HOST="0.0.0.0"

rm -f /tmp/bts-sio-install-command
if ! CMD="$($ROOT/scripts/detect-start-command.sh)"; then
  echo "Aucune application exécutable détectée dans app/."
  exit 20
fi

if [[ -f /tmp/bts-sio-install-command ]]; then
  INSTALL_CMD="$(cat /tmp/bts-sio-install-command)"
  echo "Installation automatique des dépendances : $INSTALL_CMD"
  bash -lc "$INSTALL_CMD"
fi

echo "Démarrage automatique : $CMD"
exec bash -lc "$CMD"
