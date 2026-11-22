#!/bin/bash
# Cloud Build step 2: deploy the pushed image to the environment's Cloud Run.
set -euxo pipefail

IMAGE=$(cat /workspace/image.env)
VERSION=$(cat /workspace/build.env)

gcloud run deploy "$_SERVICE" \
  --project "$PROJECT_ID" \
  --image "$IMAGE" \
  --region "$_REGION" \
  --service-account "$_RUNTIME_SA" \
  --update-env-vars "APP_VERSION=$VERSION" \
  --allow-unauthenticated \
  --quiet

# success marker consumed by scripts/github_status.py finish
touch /workspace/deploy.ok
