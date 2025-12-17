#!/bin/bash

set -e

source ./devops/ci_cd_vars.sh

rm -rf ~/.cache/trivy || true

exec trivy image --platform linux/amd64 --severity CRITICAL --exit-code 1 --quiet "${IMAGE_URL}"
