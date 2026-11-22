#!/usr/bin/env bash
# Roll an environment back (or forward) to a released image app:X.Y.Z.
# Usage: scripts/rollback.sh <dv|qa|np|pd> <version>   e.g. pd 1.2.0
set -euo pipefail

env=${1:-}
version=${2:-}
[[ $env =~ ^(dv|qa|np|pd)$ ]] || { echo "error: env must be dv, qa, np or pd"; exit 1; }
version=${version#v}
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "error: version must be MAJOR.MINOR.PATCH"; exit 1; }

project="aminesedki-rf-$env"
region="europe-west9"
repo="$region-docker.pkg.dev/$project/release-flow-lab-images/app"
url=$(gcloud run services describe release-flow-lab --project "$project" --region "$region" --format 'value(status.url)')

current=$(curl -sS --max-time 10 "$url/version" || true)
echo "Rolling $env from ${current#\"version\":\"} to app:$version"

gcloud run deploy release-flow-lab \
  --image "$repo:$version" \
  --project "$project" \
  --region "$region" \
  --quiet

new=$(curl -sS --max-time 10 "$url/version" || true)
[[ $new == *"$version"* ]] || {
  echo "warning: /version reports $new (expected $version)"; exit 1
}
echo "OK: $env now serves $version ($url)"
