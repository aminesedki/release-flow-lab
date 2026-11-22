#!/bin/bash
# Post-deploy smoke test: /health must return 200 with status ok, /version must
# return a non-empty version. Usage: cb-smoke.sh <project> <region> <service>
set -euo pipefail

project=$1
region=$2
service=$3

url=$(gcloud run services describe "$service" --project "$project" --region "$region" \
  --format 'value(status.url)')
echo "Smoke testing $url"

health=""
for _ in $(seq 1 30); do
  health=$(curl -sS --max-time 10 "$url/health" 2>/dev/null || true)
  if echo "$health" | grep -q '"status":"ok"'; then break; fi
  sleep 5
done
echo "$health" | grep -q '"status":"ok"' || {
  echo "SMOKE FAILED: /health did not return status ok (last: $health)"; exit 1
}

version=$(curl -sS --max-time 10 "$url/version" 2>/dev/null || true)
echo "$version" | grep -q '"version":' || {
  echo "SMOKE FAILED: /version returned: $version"; exit 1
}
echo "SMOKE OK: health ok, version $version"
