#!/bin/bash

set -e

if [ "$#" -ne 3 ]; then
  echo "Expected format 'script <ENV_FILE> <SERVICE_NAME> <IMAGE_URL>'"
  exit 1
fi

ENV_FILE="${1}"
SERVICE_NAME="${2}"
IMAGE_URL="${3}"

if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file not found: $ENV_FILE"
    exit 1
fi

docker pull ${IMAGE_URL}

docker_update_cmd="docker service update --image ${IMAGE_URL}"

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
