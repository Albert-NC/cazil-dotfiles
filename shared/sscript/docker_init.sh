#!/bin/bash
# ==============================================================================
# DOCKER INIT - Disposable Workspace
# ==============================================================================

IMAGE="ubuntu:latest"
PREFIX="docker"
i=1

while docker ps -a --format '{{.Names}}' | grep -q "^${PREFIX}${i}$"; do
    i=$((i+1))
done

NAME="${PREFIX}${i}"

echo "🚀 Creando espacio de trabajo desechable: $NAME ($IMAGE)"
docker run -it --name "$NAME" "$IMAGE" /bin/bash
