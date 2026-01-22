#!/bin/bash

set -euo pipefail

STACK_NAME="${1:-}"

if [ -z "$STACK_NAME" ]; then
    echo "Usage: $0 <STACK_NAME>"
    exit 1
fi

if [ -z "${DOCKER_HOST:-}" ]; then
    echo "DOCKER_HOST environment variable is not set."
    exit 1
fi

echo "Connecting to DOCKER_HOST: $DOCKER_HOST"

services=$(docker stack services "${STACK_NAME}" --format "{{.Name}}")

for service in $services; do
    echo "Watching service: $service"

    while true; do
        update_status=$(docker service inspect "$service" --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{else}}---{{end}}')

        if [ "$update_status" = "updating" ]; then
            services_running=$(docker service ps "$service" --filter "desired-state=running" --format '{{ .Image }}' | sort | uniq -c)
            echo "Deployment in progress for $service"
            echo "$services_running"
            echo ""
            sleep 5
            continue
        fi

        if [ "$update_status" = "completed" ]; then
            echo "Deployment completed successfully for $service"
            break
        fi

        if [ "$update_status" = "---" ]; then
            echo "No rolling update for $service (config-only change)"
            break
        fi

        failed_task_id=$(docker service ps "$service" --filter "desired-state=shutdown" --format "{{.ID}}" | head -n 1 || true)

        if [ -n "$failed_task_id" ]; then
            echo "Logs for failed task $failed_task_id"
            docker logs "$failed_task_id" || echo "No logs available for task"

            container_id=$(docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' "$failed_task_id" 2>/dev/null || true)

            if [ -n "$container_id" ]; then
                docker inspect --format='{{range .State.Health.Log}}ExitCode: {{.ExitCode}}, Output: {{.Output}}{{"\n"}}{{end}}' "$container_id" \
                || docker inspect --format='{{json .State.Health}}' "$container_id" | jq
            else
                echo "No container ID found for task"
            fi
        else
            echo "No failed task detected"
        fi

        if [ "$update_status" = "rollback_started" ] || [ "$update_status" = "rollback_completed" ]; then
            echo "Rollback detected for $service"
            exit 1
        fi

        docker service ps "$service" || true

        echo "Unexpected deployment status for $service: $update_status"
        exit 1
    done
done
