#!/bin/bash
# ssh-monitor.sh — Detecta conexiones SSH salientes activas
# Salida en formato JSON para Waybar

# 1. Buscar conexiones SSH ESTABLECIDAS (excluyendo el propio sistema)
# Buscamos procesos ssh y extraemos el destino de la línea de comandos
SSH_CONN=$(ps -eo args | grep "^ssh " | grep -v "grep" | head -n 1)

if [ -n "$SSH_CONN" ]; then
    # Extraer el host (asumiendo que es el último argumento o el que no empieza por -)
    # Una forma simple: la última palabra de la cadena ssh
    DEST=$(echo "$SSH_CONN" | awk '{print $NF}')
    
    echo "{\"text\": \"󰖟 $DEST\", \"tooltip\": \"Sesión SSH activa hacia $DEST\", \"class\": \"connected\"}"
else
    # Si no hay conexión, salida vacía (Waybar ocultará el módulo si se configura correctamente)
    echo "{\"text\": \"\", \"tooltip\": \"\", \"class\": \"disconnected\"}"
fi
