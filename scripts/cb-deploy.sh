#!/bin/bash
# Cloud Build step 2: deploy the pushed image to the environment's Cloud Run.
set -euxo pipefail

IMAGE=$(cat /workspace/image.env)

# APP_VERSION is baked into the image at build time (ARG APP_VERSION in the
# Dockerfile) — no service-level env override, so rollbacks report the image's
# own version.
export CLOUDSDK_BILLING_QUOTA_PROJECT="$_PROJECT"

gcloud run deploy "$_SERVICE" \
  --project "$_PROJECT" \
  --image "$IMAGE" \
  --region "$_REGION" \
  --service-account "$_RUNTIME_SA" \
  --allow-unauthenticated \
  --quiet

bash "$(dirname "$0")/cb-smoke.sh" "$_PROJECT" "$_REGION" "$_SERVICE"
