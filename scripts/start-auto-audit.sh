#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$ROOT/.lab-state"
mkdir -p "$STATE_DIR" "$ROOT/reports"
PID_FILE="$STATE_DIR/auto-audit.pid"
OUT="$STATE_DIR/auto-audit.log"

is_supervisor_pid() {
  local pid="${1:-}"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  local cmd
  cmd="$(ps -p "$pid" -o args= 2>/dev/null || true)"
  [[ "$cmd" == *"$ROOT/scripts/auto-audit.sh"* ]]
}

if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if is_supervisor_pid "$PID"; then
    echo "Superviseur automatique déjà actif (PID $PID)."
    exit 0
  fi
  echo "PID de superviseur obsolète détecté : ${PID:-inconnu}. Nettoyage."
  rm -f "$PID_FILE"
fi

# Le résumé doit être visible dès l'ouverture du Codespace, avant tout scan.
python3 "$ROOT/scripts/generate-security-summary.py" >/dev/null 2>&1 || true

# exec garantit que le PID enregistré est bien celui du superviseur lui-même.
nohup bash -c "exec bash '$ROOT/scripts/auto-audit.sh'" >>"$OUT" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

# Vérifie que le processus ne s'est pas arrêté immédiatement.
sleep 1
if ! is_supervisor_pid "$PID"; then
  echo "ERREUR : le superviseur n'a pas réussi à rester actif." >&2
  rm -f "$PID_FILE"
  echo "Dernières lignes du journal :" >&2
  tail -n 40 "$OUT" >&2 || true
  exit 1
fi

echo "Superviseur automatique démarré (PID $PID)."
echo "Journal : .lab-state/auto-audit.log"
