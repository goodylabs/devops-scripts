#!/bin/bash

set -eu

STACK_NAME="$1"

if [ -z "$STACK_NAME" ]; then
    echo "Usage: $0 <STACK_NAME>"
    exit 1
fi

if [ -z "${DOCKER_HOST}" ]; then
    echo "DOCKER_HOST environment variable is not set."
    exit 1
fi

echo "Connecting to DOCKER_HOST: $DOCKER_HOST"

services=$(docker stack services "${STACK_NAME}" --format "{{.Name}}")

for service in $services; do

    while true; do
        # -> updating, completed, paused, rollback_started, rollback_completed
        update_status=$(docker service inspect "${service}" --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{else}}---{{end}}')

        if [ $update_status = "updating" ]; then
            services_running=$(docker service ps $service --filter "desired-state=running"   --format '{{ .Image }}' | sort | uniq -c)
            echo "Deployment is in progress. Running containers of the $service:"
            echo "$services_running"
            echo ""
            sleep 5
            continue
        fi

        if [ $update_status = "completed" ]; then
            echo "Deployment completed successfully."
            exit 0
        fi

        if [ $update_status = "---" ]; then
            echo "There was no deployment - only config change."
            exit 0
        fi

        echo "######################"
        echo "##  CONTAINER LOGS  ##"
        echo "######################"

        failed_task_id=$(docker service ps "${service}" --filter "desired-state=shutdown" --format "{{.ID}}" | head -n 1)

        echo "Looking for logs from task: ${failed_task_id}"

        docker service logs "${service}" --tail 1000 | grep failed_task_id || echo "No failed_task_id found in logs"

        echo "####################"
        echo "##  HEALTHCHECKS  ##"
        echo "####################"

        unhealthy_container=$(docker ps -a --filter "name=$service" --filter "status=exited" --format "{{.ID}}" | head -n1)

        docker inspect --format='{{range .State.Health.Log}}ExitCode: {{.ExitCode}}, Output: {{.Output}}{{"\n"}}{{end}}' "${unhealthy_container}" || docker inspect --format='{{json .State.Health}}' "${unhealthy_container}" | jq || echo "No healthcheck information available."

        if [ $update_status = "rollback_started" ] || [ $update_status = "rollback_completed" ]; then
            exit 1
        fi

        docker service ps "${service}" || echo "Failed to get service tasks"

        echo "Unexpected deployment status: $update_status"
        exit 1
    done

done
