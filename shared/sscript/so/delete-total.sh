#!/bin/bash
# ==============================================================================
# DELETE TOTAL - Docker Cleanup
# ==============================================================================

if [ -z "$1" ]; then
    echo "Uso: delete_total <nombre_del_contenedor>"
    exit 1
fi

NAME=$1

if ! docker ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
    echo "❌ Error: El contenedor '$NAME' no existe."
    exit 1
fi

echo "🗑️ Eliminando por completo el contenedor: $NAME..."
docker stop "$NAME" 2>/dev/null
docker rm -v "$NAME"
echo "✅ $NAME eliminado."
