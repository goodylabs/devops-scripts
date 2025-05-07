#!/bin/bash

set -ex

if [ "$#" -ne 1 ]; then
  echo "Expected format 'script <image_url>'"
  exit 1
fi

IMAGE_URL="${1}"

branch="${CI_COMMIT_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}"
branch="$(git rev-parse --abbrev-ref HEAD | sed 's/\//_/g')"
commit_hash="${CI_COMMIT_SHA:-$(git rev-parse HEAD)}"

IMAGE_TAG_HASH="${IMAGE_URL}:${commit_hash}"
IMAGE_TAG_BRANCH="${IMAGE_URL}:${branch}"

docker buildx build --platform linux/amd64 -t $IMAGE_TAG_HASH -t $IMAGE_TAG_BRANCH .

docker push "${IMAGE_TAG_HASH}"
docker push "${IMAGE_TAG_BRANCH}"
