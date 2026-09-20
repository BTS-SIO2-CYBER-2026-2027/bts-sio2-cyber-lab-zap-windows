#!/usr/bin/env bash
set -u -o pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib.sh"
load_lab_env

STATE_DIR="$ROOT/.lab-state"
mkdir -p "$STATE_DIR" "$ROOT/reports"
LAST_HASH_FILE="$STATE_DIR/last-audited-hash"
APP_PID_FILE="$STATE_DIR/app.pid"
LOG_FILE="$STATE_DIR/app.log"
SUPERVISOR_PID_FILE="$STATE_DIR/auto-audit.pid"
DEBOUNCE="${AUTO_AUDIT_DEBOUNCE_SECONDS:-12}"

cleanup() {
  local recorded
  recorded="$(cat "$SUPERVISOR_PID_FILE" 2>/dev/null || true)"
  if [[ "$recorded" == "$$" ]]; then
    rm -f "$SUPERVISOR_PID_FILE"
  fi
}
trap cleanup EXIT INT TERM

ts() { date '+%H:%M:%S'; }

hash_app() {
  # On hache les métadonnées (chemin, taille, date) plutôt que le contenu.
  # C'est beaucoup plus robuste pendant qu'un assistant IA est en train
  # d'écrire/renommer plusieurs fichiers simultanément.
  local value
  value="$({ find "$ROOT/app" -type f ! -name '.gitkeep' -printf '%P|%s|%T@\n' 2>/dev/null || true; } \
    | LC_ALL=C sort \
    | sha256sum \
    | awk '{print $1}')" || true
  printf '%s\n' "$value"
}

app_has_files() {
  find "$ROOT/app" -type f ! -name '.gitkeep' -print -quit 2>/dev/null | grep -q .
}

stop_previous_app() {
  if [[ -f "$APP_PID_FILE" ]]; then
    local pid
    pid="$(cat "$APP_PID_FILE" 2>/dev/null || true)"
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      sleep 1
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$APP_PID_FILE"
  fi
}

is_app_healthy() {
  curl --silent --fail --max-time 2 "$APP_URL" >/dev/null 2>&1
}

wait_for_app() {
  local i
  for i in $(seq 1 60); do
    if is_app_healthy; then
      return 0
    fi
    sleep 2
  done
  return 1
}

start_managed_app() {
  stop_previous_app
  : > "$LOG_FILE"
  "$ROOT/scripts/start-generated-app.sh" >"$LOG_FILE" 2>&1 &
  local app_pid=$!
  echo "$app_pid" > "$APP_PID_FILE"
}

run_audit_cycle() {
  local hash="$1"
  echo "[$(ts)] Code généré détecté. Préparation de l'application..."
  start_managed_app

  if ! wait_for_app; then
    echo "[$(ts)] L'application ne répond pas encore sur $APP_URL."
    echo "[$(ts)] Le superviseur réessaiera automatiquement."
    tail -n 20 "$LOG_FILE" || true
    return 0
  fi

  echo "[$(ts)] Application disponible sur $APP_URL. Audit automatique en cours."

  if [[ "${AUTO_BASELINE_SCAN:-1}" == "1" ]]; then
    "$ROOT/scripts/zap-baseline.sh" || true
  fi
  if [[ "${AUTO_ACTIVE_SCAN:-1}" == "1" ]]; then
    "$ROOT/scripts/zap-full-scan.sh" --yes || true
  fi

  echo "$hash" > "$LAST_HASH_FILE"
  python3 "$ROOT/scripts/generate-security-summary.py" >/dev/null 2>&1 || true
  echo "[$(ts)] Audit terminé. Rapports disponibles dans reports/."
}

python3 "$ROOT/scripts/generate-security-summary.py" >/dev/null 2>&1 || true

echo "[$(ts)] Superviseur automatique actif : app/ -> démarrage -> ZAP."
echo "[$(ts)] Cible de sécurité verrouillée : $APP_URL"

LAST_SEEN=""
STABLE_SINCE="$(date +%s)"
while true; do
  if ! app_has_files; then
    sleep 3
    continue
  fi

  CURRENT="$(hash_app)"
  if [[ -z "$CURRENT" ]]; then
    echo "[$(ts)] Lecture de app/ temporairement impossible ; nouvelle tentative."
    sleep 3
    continue
  fi

  NOW="$(date +%s)"
  if [[ "$CURRENT" != "$LAST_SEEN" ]]; then
    LAST_SEEN="$CURRENT"
    STABLE_SINCE="$NOW"
  else
    LAST_AUDITED="$(cat "$LAST_HASH_FILE" 2>/dev/null || true)"
    if [[ "$CURRENT" != "$LAST_AUDITED" ]] && (( NOW - STABLE_SINCE >= DEBOUNCE )); then
      run_audit_cycle "$CURRENT" || true
    elif [[ "$CURRENT" == "$LAST_AUDITED" ]] && ! is_app_healthy; then
      echo "[$(ts)] Application arrêtée après l'audit : redémarrage automatique."
      start_managed_app
      if wait_for_app; then
        echo "[$(ts)] Application relancée sur $APP_URL."
      else
        echo "[$(ts)] Échec du redémarrage. Nouvelle tentative au prochain cycle."
      fi
    fi
  fi
  sleep 3
done
