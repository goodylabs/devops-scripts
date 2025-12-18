#!/bin/bash

set -e

source ./devops/ci_cd_vars.sh

export TRIVY_CACHE_DIR="/tmp/.trivy-cache-${uuidgen}"

mkdir -p $TRIVY_CACHE_DIR

exec trivy image --platform linux/amd64 --severity CRITICAL --exit-code 1 --quiet "${IMAGE_URL}"

rm -rf $TRIVY_CACHE_DIR
