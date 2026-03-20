#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — zoom.sh
# Control de zoom global para Hyprland
# ==============================================================================
if ! command -v bc &> /dev/null; then echo "Error: bc no está instalado."; exit 1; fi
if ! command -v hyprctl &> /dev/null; then echo "Error: hyprctl no está instalado."; exit 1; fi

# Obtener zoom actual
CURRENT_ZOOM=$(hyprctl getoption cursor:zoom_factor | grep "float" | awk '{print $2}')
STEP=0.25
MIN=1.0
MAX=5.0

case "$1" in
    "in")
        NEW_ZOOM=$(echo "$CURRENT_ZOOM + $STEP" | bc)
        if (( $(echo "$NEW_ZOOM > $MAX" | bc -l) )); then NEW_ZOOM=$MAX; fi
        ;;
    "out")
        NEW_ZOOM=$(echo "$CURRENT_ZOOM - $STEP" | bc)
        if (( $(echo "$NEW_ZOOM < $MIN" | bc -l) )); then NEW_ZOOM=$MIN; fi
        ;;
    "reset")
        NEW_ZOOM=1.0
        ;;
    *)
        echo "Uso: zoom.sh [in|out|reset]"
        exit 1
        ;;
esac

hyprctl keyword cursor:zoom_factor "$NEW_ZOOM"
notify-send "Zoom" "Nivel: ${NEW_ZOOM}x" -t 800 -h string:x-canonical-private-synchronous:zoom
