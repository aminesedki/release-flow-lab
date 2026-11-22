#!/bin/bash
# Cloud Build promote step: deploy the image currently serving the source
# environment, then smoke test the target.
set -euxo pipefail
export CLOUDSDK_BILLING_QUOTA_PROJECT="$_PROJECT"

SOURCE_IMAGE=$(gcloud run services describe "$_SERVICE" \
  --project "$_SOURCE_PROJECT" --region "$_REGION" \
  --format 'value(spec.template.spec.containers[0].image)')
echo "Promoting image:"
echo "  from $_SOURCE_ENV -> $_ENV"

gcloud run deploy "$_SERVICE" \
  --project "$_PROJECT" \
  --image "$SOURCE_IMAGE" \
  --region "$_REGION" \
  --service-account "$_RUNTIME_SA" \
  --allow-unauthenticated \
  --quiet

bash "$(dirname "$0")/cb-smoke.sh" "$_PROJECT" "$_REGION" "$_SERVICE"
