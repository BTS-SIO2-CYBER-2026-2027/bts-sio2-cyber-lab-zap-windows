#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"
load_lab_env
assert_local_target "$APP_URL"
check_app "$APP_URL"
check_docker

mkdir -p "$ROOT/reports"
STAMP="$(date +%Y%m%d-%H%M%S)"
HTML="zap-baseline-$STAMP.html"
JSON="zap-baseline-$STAMP.json"

cat <<MSG
============================================================
 ZAP BASELINE - ANALYSE PASSIVE
============================================================
Cible locale : $APP_URL
Aucune URL Internet n'est acceptée par ce script.
Rapports : reports/$HTML et reports/$JSON
============================================================
MSG

set +e
docker run --rm --network host \
  -v "$ROOT/reports:/zap/wrk/:rw" \
  -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
  -t "$APP_URL" \
  -r "$HTML" \
  -J "$JSON" \
  -I
STATUS=$?
set -e

echo ""
echo "Rapport généré : reports/$HTML"
python3 "$ROOT/scripts/generate-security-summary.py" || true
exit "$STATUS"
