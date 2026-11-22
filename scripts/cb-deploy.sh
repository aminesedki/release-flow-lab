#!/bin/bash
# Cloud Build step 2: deploy the pushed image to the environment's Cloud Run.
set -euxo pipefail

IMAGE=$(cat /workspace/image.env)

gcloud run deploy "$_SERVICE" \
  --project "$PROJECT_ID" \
  --image "$IMAGE" \
  --region "$_REGION" \
  --service-account "$_RUNTIME_SA" \
  --allow-unauthenticated \
  --quiet
