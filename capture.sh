#!/usr/bin/env bash
set -euo pipefail
time -p cd "$(dirname "$0")"
URL="${CAPTURE_URL:?Set CAPTURE_URL.}"
OUT="${CAPTURE_DIR:?Set CAPTURE_DIR.}"
/usr/bin/time -p mkdir -p "$OUT"
/usr/bin/time -p bash -c '
  set -euo pipefail
  url="$0"; out="$1"
  case "$url" in http://*|https://*|file://*) ;; *) echo "CAPTURE_URL must be an http(s) or file URL: $url" >&2; exit 1;; esac
  if [ -e "$out/final-desktop.png" ] && [ ! -f "$out/final-desktop.png" ]; then echo "Blocked: $out/final-desktop.png" >&2; exit 1; fi
' "$URL" "$OUT"
# Delegate rendering to the tested runtime capture (headed Chromium + Xvfb + SwiftShader).
# It opens the exact URL, waits for content, writes final-desktop.png + final-mobile.png,
# exits 75 on transient navigation/browser infra failures and non-zero otherwise.
/usr/bin/time -p node "${RUNTIME_DIR:?}/scripts/default-capture.mjs"
/usr/bin/time -p bash -c '
  set -euo pipefail
  out="$0"
  for n in final-desktop.png final-mobile.png; do
    p="$out/$n"
    [ -f "$p" ] || { echo "Capture did not produce: $n" >&2; exit 1; }
    [ "$(stat -c%s "$p")" -gt 24 ] || { echo "Capture produced empty file: $n" >&2; exit 1; }
    [ "$(head -c 8 "$p" | od -An -tx1 | tr -d " \\n")" = "89504e470d0a1a0a" ] || { echo "Capture did not produce a PNG: $n" >&2; exit 1; }
  done
  ls -l "$out/final-desktop.png" "$out/final-mobile.png"
' "$OUT"
