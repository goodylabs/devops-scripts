#!/bin/bash

set -e

source ./devops/ci_cd_vars.sh

trivy image --server http://trivy-server:4954 --severity CRITICAL --exit-code 1 --quiet "${IMAGE_URL}"
