#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$LAB_ROOT/.lab.env"

load_lab_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERREUR : fichier $ENV_FILE introuvable." >&2
    exit 1
  fi

  # Fichier contrôlé par le dépôt pédagogique.
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a

  APP_URL="${APP_URL:-http://127.0.0.1:3000}"
  APP_PORT="${APP_PORT:-3000}"
}

assert_local_target() {
  local target="$1"

  # Garde-fou : le laboratoire refuse explicitement les domaines et IP externes.
  if [[ ! "$target" =~ ^https?://(127\.0\.0\.1|localhost)(:[0-9]{1,5})?(/.*)?$ ]]; then
    echo "REFUS : la cible ZAP doit rester locale au laboratoire." >&2
    echo "Cible reçue : $target" >&2
    echo "Cibles autorisées : http://127.0.0.1:PORT ou http://localhost:PORT" >&2
    exit 2
  fi
}

check_app() {
  local target="$1"
  if ! curl --silent --show-error --fail --max-time 5 "$target" >/dev/null; then
    echo "ERREUR : l'application ne répond pas sur $target" >&2
    echo "Lancez d'abord : ./scripts/start-app.sh" >&2
    exit 3
  fi
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "ERREUR : Docker n'est pas disponible dans ce Codespace." >&2
    exit 4
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "ERREUR : le moteur Docker n'est pas démarré." >&2
    exit 5
  fi
}
