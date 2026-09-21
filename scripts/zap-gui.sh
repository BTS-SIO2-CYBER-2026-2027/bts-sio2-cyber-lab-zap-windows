#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib.sh"
load_lab_env

NAME="bts-sio-zap-gui"
VOLUME="bts-sio-zap-gui-data"
STATE="$ROOT/.lab-state"
PIDFILE="$STATE/zap-gui-proxy.pid"
create_container() {
  docker volume create "$VOLUME" >/dev/null
  docker run -d -i --name "$NAME" --init --user zap \
    --add-host=host.docker.internal:host-gateway \
    -p 127.0.0.1:8093:8080 \
    -v "$VOLUME:/zap/wrk:rw" \
    ghcr.io/zaproxy/zaproxy:stable zap-webswing.sh >/dev/null
}
recreate_container() {
  if docker container inspect "$NAME" >/dev/null 2>&1; then
    docker rm -f "$NAME" >/dev/null
  fi
  create_container
}
wait_for_zap() {
  local attempt
  for attempt in $(seq 1 60); do
    if curl -sS -o /dev/null --max-time 2 http://127.0.0.1:8093/zap/ 2>/dev/null; then
      return 0
    fi
    if [[ "$(docker inspect -f '{{.State.Running}}' "$NAME" 2>/dev/null || true)" != true ]]; then
      echo "Le conteneur ZAP s'est arrêté pendant son démarrage." >&2
      docker logs --tail 40 "$NAME" >&2 || true
      return 1
    fi
    sleep 1
  done
  echo "ERREUR : ZAP n'a pas répondu après 60 secondes." >&2
  docker logs --tail 40 "$NAME" >&2 || true
  return 1
}
start_proxy() {
  mkdir -p "$STATE"
  if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    return
  fi
  nohup node "$ROOT/scripts/zap-gui-proxy.js" >"$STATE/zap-gui-proxy.log" 2>&1 </dev/null &
  echo $! > "$PIDFILE"
  sleep 1
  if ! kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    cat "$STATE/zap-gui-proxy.log" >&2
    echo "ERREUR : relais ZAP indisponible sur le port 8091" >&2
    exit 1
  fi
}
ACTION="${1:-start}"
case "$ACTION" in
  start)
    check_docker
    # Une ancienne installation v5/v6 occupait 8091 directement. Le volume
    # /zap/wrk persiste indépendamment du conteneur recréé.
    if docker container inspect "$NAME" >/dev/null 2>&1; then
      if [[ "$(docker inspect -f '{{json .HostConfig.PortBindings}}' "$NAME")" == *'"HostPort":"8091"'* ]]; then
        docker rm -f "$NAME" >/dev/null
      fi
    fi
    if docker container inspect "$NAME" >/dev/null 2>&1 && \
       [[ "$(docker inspect -f '{{.State.Running}}' "$NAME")" != true ]]; then
      # Un redémarrage du même conteneur peut laisser Xvfb inutilisable.
      # Le volume de données est séparé : recréer le conteneur est sans perte.
      recreate_container
    elif ! docker container inspect "$NAME" >/dev/null 2>&1; then
      create_container
    fi
    start_proxy
    wait_for_zap
    echo "ZAP graphique est prêt. Ouvrez uniquement l'adresse privée du port 8091, puis /zap/."
    echo "Ignorez le port technique 8093 s'il apparaît dans Codespaces."
    echo "Dans ZAP, ciblez uniquement l'application du laboratoire : http://host.docker.internal:$APP_PORT"
    echo "Le premier affichage peut prendre quelques instants."
    ;;
  restart)
    check_docker
    echo "Réinitialisation de la connexion graphique ZAP..."
    recreate_container
    start_proxy
    wait_for_zap
    echo "ZAP graphique est prêt. Fermez les anciens onglets et ouvrez uniquement le port privé 8091, puis /zap/."
    ;;
  stop)
    check_docker
    if [[ -f "$PIDFILE" ]]; then
      kill "$(cat "$PIDFILE")" 2>/dev/null || true
      rm -f "$PIDFILE"
    fi
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
      if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "Relais du port 8091 : running"
      else
        echo "Relais du port 8091 : arrêté"
      fi
    else
      echo "ZAP graphique : absent"
    fi
    ;;
  *)
    echo "Utilisation : bash scripts/zap-gui.sh [start|restart|stop|status]" >&2
    exit 2
    ;;
esac
