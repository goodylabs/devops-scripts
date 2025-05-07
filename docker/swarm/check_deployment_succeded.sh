#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Expected format 'script <service_name>'"
    exit 1
fi

$SERVICE_NAME="${1}"

STATUS=$(docker service inspect  | jq ".[0].UpdateStatus.State" -r)

echo "status: ${STATUS}"

if [ $STATUS = "rollback_completed" ]; then
    exit 1
fi
