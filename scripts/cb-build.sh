#!/bin/bash
# Cloud Build step 1: resolve the version, build and push the image.
# Built-ins (PROJECT_ID, SHORT_SHA, TAG_NAME) are env vars in the step.
set -euxo pipefail
export NO_COLOR=1

if [ -n "${TAG_NAME:-}" ]; then
  VERSION="${TAG_NAME#v}"
else
  VERSION="0.0.0-dev.${SHORT_SHA}"
fi

IMAGE="$_REGION-docker.pkg.dev/$PROJECT_ID/$_REPO/app:$SHORT_SHA"

echo "$VERSION" > /workspace/build.env
echo "$IMAGE" > /workspace/image.env
echo "Building $VERSION for env $_ENV"

docker build --build-arg APP_VERSION="$VERSION" -t "$IMAGE" . 2>&1 |
  sed -r 's/\x1B\[[0-9;]*[mK]//g'
docker push "$IMAGE"

# release builds also push the image under its version tag (rollback friendly)
if [ -n "${TAG_NAME:-}" ]; then
  VERSION_IMAGE="${IMAGE%:*}:$VERSION"
  docker tag "$IMAGE" "$VERSION_IMAGE"
  docker push "$VERSION_IMAGE"
fi
