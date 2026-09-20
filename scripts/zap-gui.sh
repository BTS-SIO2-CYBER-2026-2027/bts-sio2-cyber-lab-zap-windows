#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib.sh"
load_lab_env

NAME="bts-sio-zap-gui"
VOLUME="bts-sio-zap-gui-data"
case "${1:-start}" in
  start)
    check_docker
    if docker container inspect "$NAME" >/dev/null 2>&1; then
      if [[ "$(docker inspect -f '{{.State.Running}}' "$NAME")" != true ]]; then
        docker start "$NAME" >/dev/null
      fi
    else
      docker volume create "$VOLUME" >/dev/null
      docker run -d --name "$NAME" --init \
        --add-host=host.docker.internal:host-gateway \
        -p 127.0.0.1:8091:8080 \
        -v "$VOLUME:/zap/wrk:rw" \
        ghcr.io/zaproxy/zaproxy:stable zap-webswing.sh >/dev/null
    fi
    echo "ZAP graphique démarre. Ouvrez l'adresse transférée du port 8091, puis /zap."
    echo "Dans ZAP, ciblez uniquement l'application du laboratoire : http://host.docker.internal:$APP_PORT"
    echo "Le premier affichage peut prendre quelques instants."
    ;;
  stop)
    check_docker
    if docker container inspect "$NAME" >/dev/null 2>&1; then
      docker stop "$NAME" >/dev/null
      echo "ZAP graphique arrêté. La session et les réglages sont conservés."
    else
      echo "ZAP graphique n'est pas démarré."
    fi
    ;;
  status)
    check_docker
    if docker container inspect "$NAME" >/dev/null 2>&1; then
      docker inspect -f 'ZAP graphique : {{.State.Status}}' "$NAME"
    else
      echo "ZAP graphique : absent"
    fi
    ;;
  *)
    echo "Utilisation : bash scripts/zap-gui.sh [start|stop|status]" >&2
    exit 2
    ;;
esac
