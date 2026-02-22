#!/bin/bash
set -e

OLD_CONTAINERS=$(docker ps -a --filter "until=1h" --format "{{.ID}}")

if [ -n "$OLD_CONTAINERS" ]; then
    echo "Found old containers. Cleaning up..."
    docker rm -f $OLD_CONTAINERS
else
    echo "No containers older than 1h found. Skipping."
fi

#docker network prune -f --filter "until=1h"