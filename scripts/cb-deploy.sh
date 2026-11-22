#!/bin/bash
# Cloud Build step 2: deploy the pushed image to the environment's Cloud Run.
set -euxo pipefail

IMAGE=$(cat /workspace/image.env)

# APP_VERSION is baked into the image at build time (ARG APP_VERSION in the
# Dockerfile) — no service-level env override, so rollbacks report the image's
# own version.
gcloud run deploy "$_SERVICE" \
  --project "$PROJECT_ID" \
  --image "$IMAGE" \
  --region "$_REGION" \
  --service-account "$_RUNTIME_SA" \
  --allow-unauthenticated \
  --quiet
