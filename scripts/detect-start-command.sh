#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/app"

if [[ -f "$APP/package.json" ]]; then
  # Dépendances Node
  if [[ -f "$APP/package-lock.json" ]]; then
    echo "npm ci || npm install" > /tmp/bts-sio-install-command
  else
    echo "npm install" > /tmp/bts-sio-install-command
  fi

  DEV_SCRIPT="$(node -e "const p=require(process.argv[1]); console.log((p.scripts&&p.scripts.dev)?'yes':'no')" "$APP/package.json" 2>/dev/null || echo no)"
  START_SCRIPT="$(node -e "const p=require(process.argv[1]); console.log((p.scripts&&p.scripts.start)?'yes':'no')" "$APP/package.json" 2>/dev/null || echo no)"
  if [[ "$DEV_SCRIPT" == "yes" ]]; then
    # Vite/Next et beaucoup d'outils acceptent --host ; si ce n'est pas le cas, la variable HOST reste disponible.
    echo "npm run dev -- --host 0.0.0.0" 
    exit 0
  elif [[ "$START_SCRIPT" == "yes" ]]; then
    echo "npm start"
    exit 0
  fi
fi

if [[ -f "$APP/requirements.txt" ]]; then
  echo "python -m pip install -r requirements.txt" > /tmp/bts-sio-install-command
elif [[ -f "$APP/pyproject.toml" ]]; then
  echo "python -m pip install ." > /tmp/bts-sio-install-command
fi

if [[ -f "$APP/app.py" ]]; then
  if grep -qi "flask" "$APP/app.py"; then
    echo "python -m flask --app app run --host 0.0.0.0 --port \${PORT:-3000}"
  else
    echo "python app.py"
  fi
  exit 0
fi

if [[ -f "$APP/main.py" ]]; then
  if grep -qi "fastapi" "$APP/main.py"; then
    echo "python -m uvicorn main:app --host 0.0.0.0 --port \${PORT:-3000}"
  else
    echo "python main.py"
  fi
  exit 0
fi

if [[ -f "$APP/index.php" ]]; then
  echo "php -S 0.0.0.0:\${PORT:-3000}"
  exit 0
fi

exit 1
