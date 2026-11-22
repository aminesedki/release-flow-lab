#!/bin/bash
# Wait for the Cloud Build triggered by a push to finish and report
# status, duration and log URL.
#
# Usage: cb-wait.sh <project> <region> <commit-sha> <timeout-seconds>
# Prints:
#   STATUS=<SUCCESS|FAILURE|...>
#   DURATION=<e.g. 2m35s>
#   LOG_URL=<console url>
set -euo pipefail

project=$1
region=$2
sha=$3
timeout=${4:-1500}
deadline=$(( $(date +%s) + timeout ))

# 1. wait for the build to appear (trigger fires asynchronously)
build=""
while (( $(date +%s) < deadline )); do
  build=$(gcloud builds list --project "$project" --region "$region" \
    --filter="sourceProvenance.resolvedRepoSource.commitSha=$sha" \
    --limit 1 --format='value(id)' 2>/dev/null || true)
  [[ -n $build ]] && break
  sleep 10
done
[[ -n $build ]] || { echo "STATUS=NOT_FOUND"; echo "DURATION=0s"; echo "LOG_URL="; exit 0; }

# 2. wait for the build to finish
status=WORKING
while (( $(date +%s) < deadline )); do
  status=$(gcloud builds describe "$build" --project "$project" --region "$region" \
    --format='value(status)' 2>/dev/null || echo WORKING)
  case $status in
    SUCCESS|FAILURE|INTERNAL_ERROR|TIMEOUT|CANCELLED|EXPIRED) break ;;
    *) sleep 15 ;;
  esac
done

meta=$(gcloud builds describe "$build" --project "$project" --region "$region" \
  --format='json(logUrl,timing.build.startTime,timing.build.endTime)' 2>/dev/null || echo '{}')
log_url=$(echo "$meta" | python3 -c "import json,sys; b=json.load(sys.stdin); print(b.get('logUrl',''))")
start=$(echo "$meta" | python3 -c "import json,sys; b=json.load(sys.stdin); t=b.get('timing',{}).get('build',{}); print(t.get('startTime',''))")
end=$(echo "$meta" | python3 -c "import json,sys; b=json.load(sys.stdin); t=b.get('timing',{}).get('build',{}); print(t.get('endTime',''))")
duration=$(python3 - "$start" "$end" <<'PY'
import sys, datetime
try:
    s = datetime.datetime.fromisoformat(sys.argv[1].replace('Z', '+00:00'))
    e = datetime.datetime.fromisoformat(sys.argv[2].replace('Z', '+00:00'))
    d = int((e - s).total_seconds())
    print(f"{d // 60}m{d % 60:02d}s" if d >= 60 else f"{d}s")
except Exception:
    print("n/a")
PY
)

echo "STATUS=$status"
echo "DURATION=$duration"
echo "LOG_URL=$log_url"
