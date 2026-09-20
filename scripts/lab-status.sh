#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib.sh"
load_lab_env
STATE="$ROOT/.lab-state"

echo "=== bts-sio-cyber-lab : état ==="
PID="$(cat "$STATE/auto-audit.pid" 2>/dev/null || true)"
if [[ "$PID" =~ ^[0-9]+$ ]] && kill -0 "$PID" 2>/dev/null; then
  echo "Superviseur : ACTIF (PID $PID)"
else
  echo "Superviseur : INACTIF"
fi

if curl -sSf --max-time 2 "$APP_URL" >/dev/null 2>&1; then
  CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "$APP_URL" || true)"
  echo "Application : HTTP $CODE sur $APP_URL"
else
  echo "Application : INDISPONIBLE sur $APP_URL"
fi

RPID="$(cat "$STATE/reports-server.pid" 2>/dev/null || true)"
if [[ "$RPID" =~ ^[0-9]+$ ]] && kill -0 "$RPID" 2>/dev/null; then
  echo "Rapports Web : ACTIF (port 8080, PID $RPID)"
else
  echo "Rapports Web : INACTIF"
fi

if docker info >/dev/null 2>&1 && docker container inspect bts-sio-zap-gui >/dev/null 2>&1; then
  docker inspect -f 'ZAP graphique : {{.State.Status}} (port 8091)' bts-sio-zap-gui
else
  echo "ZAP graphique : INACTIF (démarrage : bash scripts/zap-gui.sh start)"
fi

echo "Rapports :"
find "$ROOT/reports" -maxdepth 1 -type f ! -name '.gitkeep' -printf '  - %f\n' 2>/dev/null | sort
