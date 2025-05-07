#!/bin/bash

set -e

if [ "$#" -ne 4 ]; then
  echo "Expected format 'script <IP_ADDRESS> <ENV_FILE> <SERVICE_NAME> <IMAGE_URL>'"
  exit 1
fi

IP_ADDRESS="${1}"
ENV_FILE="${2}"
SERVICE_NAME="${3}"
IMAGE_URL="${4}"

if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file not found: $ENV_FILE"
    exit 1
fi

export DOCKER_HOST="ssh://root@${IP_ADDRESS}"

docker pull ${IMAGE_TAG_BRANCH}

docker_update_cmd="docker service update --image ${IMAGE_TAG_BRANCH}"

while IFS= read -r line; do
    if [[ $line == \#* ]]; then
        continue
    fi

    if [[ -z $line ]]; then
        continue
    fi

    docker_update_cmd+=" --env-add ${line}"
done < "${ENV_FILE}"

docker_update_cmd+=" ${SERVICE_NAME}"

eval "$docker_update_cmd"
