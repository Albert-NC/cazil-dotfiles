#!/bin/bash
# bajar-brillo.sh — Disminuir brillo del monitor
# Usa brightnessctl (Asegurado por el instalador)

if command -v brightnessctl &>/dev/null; then
    brightnessctl set 5%-
    BRIGHTNESS=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
    notify-send -e -t 1000 -h string:x-canonical-private-synchronous:brightness -h int:value:"$BRIGHTNESS" "Brillo: $BRIGHTNESS%" -i display-brightness
else
    echo "[!] brightnessctl no encontrado"
fi
