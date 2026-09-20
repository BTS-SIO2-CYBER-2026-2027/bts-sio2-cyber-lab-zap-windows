#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$ROOT/.lab-state"
mkdir -p "$STATE_DIR" "$ROOT/reports"
PID_FILE="$STATE_DIR/reports-server.pid"
LOG_FILE="$STATE_DIR/reports-server.log"
PORT="${REPORTS_PORT:-8080}"

is_reports_server() {
  local pid="${1:-}"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  local cmd
  cmd="$(ps -p "$pid" -o args= 2>/dev/null || true)"
  [[ "$cmd" == *"http.server $PORT"* ]]
}

if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if is_reports_server "$PID"; then
    echo "Serveur de rapports déjà actif (PID $PID, port $PORT)."
    exit 0
  fi
  rm -f "$PID_FILE"
fi

nohup python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$ROOT/reports" >"$LOG_FILE" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"
sleep 1
if ! is_reports_server "$PID"; then
  echo "ERREUR : serveur de rapports non démarré." >&2
  rm -f "$PID_FILE"
  tail -n 30 "$LOG_FILE" >&2 || true
  exit 1
fi

echo "Serveur de rapports démarré sur le port $PORT (PID $PID)."
