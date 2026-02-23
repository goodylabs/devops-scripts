#!/bin/bash
set -e

THRESHOLD=$(date -d "1 hour ago" +%s)

CONTAINERS=$(docker ps -aq)

if [ -z "$CONTAINERS" ]; then
    echo "No containers to check"
    exit 0
fi

for ID in $CONTAINERS; do
    CREATED=$(docker inspect -f '{{.Created}}' "$ID")
    TS=$(date -d "${CREATED%.*}" +%s)

    if [ "$TS" -lt "$THRESHOLD" ]; then
        NAME=$(docker inspect -f '{{.Name}}' "$ID" | sed 's/\///')
        echo "Deleting old container: $NAME ($ID)..."
        docker rm -f "$ID"
    fi
done

docker network prune -f --filter "until=1h" > /dev/null 2>&1 || true