#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

ok=(
  "http://127.0.0.1:3000"
  "http://localhost:3000"
  "http://127.0.0.1:8080/login"
)
bad=(
  "https://example.com"
  "https://foo.github.dev"
  "http://192.168.1.1"
  "http://10.0.0.2:3000"
)

for u in "${ok[@]}"; do
  assert_local_target "$u" || { echo "Échec garde-fou (devait accepter): $u"; exit 1; }
done

for u in "${bad[@]}"; do
  if (assert_local_target "$u" >/dev/null 2>&1); then
    echo "Échec garde-fou (devait refuser): $u"
    exit 1
  fi
done

echo "Garde-fou ZAP : OK"
