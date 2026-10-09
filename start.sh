#!/usr/bin/env bash
set -euo pipefail
time -p cd "$(dirname "$0")"
PROJECT_ROOT="$(/usr/bin/time -p pwd)"
/usr/bin/time -p mkdir -p "$PROJECT_ROOT/dist"
# Build when needed: prefer npm build if package.json exists, else ensure static dist output.
/usr/bin/time -p bash -c '
  set -euo pipefail
  cd "$0"
  if [ -f package.json ]; then
    if [ -f package-lock.json ]; then npm ci --no-audit --no-fund; else npm install --no-audit --no-fund; fi
    if node -e "const p=require(\"./package.json\"); process.exit(p.scripts&&p.scripts.build?0:1)"; then npm run build; fi
  fi
  if [ ! -f dist/index.html ] && [ -f index.html ]; then cp index.html dist/index.html; fi
' "$PROJECT_ROOT"
PORT="${PORT:-3000}"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$WEB_DIR"
/usr/bin/time -p bash -c '
  set -euo pipefail
  root="$0"; web="$1"
  if [ ! -f "$root/dist/index.html" ]; then echo "Static deployment output must contain dist/index.html." >&2; exit 1; fi
  printf "%s" "{\"project\":\"$root\",\"directory\":\"$root/dist\"}" > "$web/deployment-output.json"
' "$PROJECT_ROOT" "$WEB_DIR"
/usr/bin/time -p cat "$WEB_DIR/deployment-output.json"
/usr/bin/time -p echo "Serving $PROJECT_ROOT/dist on PORT $PORT"
exec /usr/bin/time -p python3 -m http.server "$PORT" --directory "$PROJECT_ROOT/dist" --bind 0.0.0.0
