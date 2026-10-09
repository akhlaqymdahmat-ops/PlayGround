#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [ -z "${CAPTURE_URL:-}" ]; then echo "CAPTURE_URL must be set" >&2; exit 1; fi
if [ -z "${CAPTURE_DIR:-}" ]; then echo "CAPTURE_DIR must be set" >&2; exit 1; fi
if [ -z "${RUNTIME_DIR:-}" ]; then echo "RUNTIME_DIR must be set" >&2; exit 1; fi
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p bash -n capture.sh
set +e
/usr/bin/time -p node "${RUNTIME_DIR}/scripts/default-capture.mjs"
status=$?
set -e
if [ "$status" -eq 75 ]; then echo "capture: temporary browser/navigation failure (exit 75)" >&2; exit 75; fi
if [ "$status" -ne 0 ]; then echo "capture: default-capture failed with exit $status" >&2; exit "$status"; fi
/usr/bin/time -p ls -lh "$CAPTURE_DIR/final-desktop.png" "$CAPTURE_DIR/final-mobile.png"
/usr/bin/time -p node -e '
const fs=require("fs"),path=require("path");
const dir=process.env.CAPTURE_DIR;
for(const n of ["final-desktop.png","final-mobile.png"]){
  const p=path.join(dir,n);
  const b=fs.readFileSync(p);
  if(b.length<24) throw new Error(n+" too small");
  if(b.subarray(0,8).toString("hex")!=="89504e470d0a1a0a") throw new Error(n+" is not a PNG");
  console.log(n+": OK "+b.length+" bytes");
}'
check=$?
if [ "$check" -ne 0 ]; then echo "capture: rendering defect, PNG validation failed" >&2; exit 1; fi
echo "capture: desktop and mobile screenshots ready in $CAPTURE_DIR"
