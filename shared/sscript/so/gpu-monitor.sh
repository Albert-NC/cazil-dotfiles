#!/bin/bash
# gpu-monitor.sh — Monitor de estado de GPU NVIDIA para Waybar
# Salida en formato JSON

if ! command -v nvidia-smi &> /dev/null; then
    exit 0
fi

# Obtener datos de la GPU
PSTATE=$(nvidia-smi --query-gpu=pstate --format=csv,noheader)
TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
# Intentar obtener consumo o estado de energía
POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader 2>/dev/null || echo "N/A")

ICON="󰢮" # Icono de chip/GPU
CLASS="idle"
TEXT=""

if [[ "$PSTATE" != "P8" ]]; then
    CLASS="active"
    TEXT="$ICON $TEMP°C"
else
    # En reposo, podemos mostrar solo el icono o dejar el texto vacío según preferencia
    # Mostramos icono tenue
    TEXT="$ICON"
fi

TOOLTIP="<b>GPU NVIDIA</b>\nEstado: $PSTATE\nTemp: $TEMP°C\nConsumo: $POWER"

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
