#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"
load_lab_env
assert_local_target "$APP_URL"
check_app "$APP_URL"
check_docker

cat <<MSG
============================================================
 ZAP FULL SCAN - ANALYSE ACTIVE
============================================================
ATTENTION : cette étape envoie de vraies requêtes d'attaque.
Elle est autorisée ici UNIQUEMENT parce que la cible est l'application
locale de votre laboratoire : $APP_URL

Le script refuse les domaines et adresses IP externes.
============================================================
MSG

if [[ "${1:-}" != "--yes" ]]; then
  read -r -p "Tapez OUI pour lancer le scan actif : " ANSWER
  if [[ "$ANSWER" != "OUI" ]]; then
    echo "Scan annulé."
    exit 0
  fi
fi

mkdir -p "$ROOT/reports"
STAMP="$(date +%Y%m%d-%H%M%S)"
HTML="zap-full-$STAMP.html"
JSON="zap-full-$STAMP.json"

set +e
docker run --rm --network host \
  -v "$ROOT/reports:/zap/wrk/:rw" \
  -t ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py \
  -t "$APP_URL" \
  -m 3 \
  -r "$HTML" \
  -J "$JSON" \
  -I
STATUS=$?
set -e

echo ""
echo "Rapport généré : reports/$HTML"
python3 "$ROOT/scripts/generate-security-summary.py" || true
exit "$STATUS"
