#!/bin/bash
# subir-brillo.sh
# Script para incrementar el brillo de la pantalla

BACKLIGHT="/sys/class/backlight/acpi_video1/brightness"
MAX_BRIGHTNESS="/sys/class/backlight/acpi_video1/max_brightness"

# Verificar que los archivos existen
if [ ! -f "$BACKLIGHT" ] || [ ! -f "$MAX_BRIGHTNESS" ]; then
    echo "❌ No se pueden leer los archivos de brillo"
    exit 1
fi

# Leer valores actuales
ACTUAL=$(cat "$BACKLIGHT")
MAX=$(cat "$MAX_BRIGHTNESS")

# Calcular incremento (5 puntos)
NUEVO=$((ACTUAL + 5))

# Limitar al máximo (150% del valor máximo como en tu script original)
LIMITE=$((MAX * 150 / 100))

if [ $NUEVO -gt $LIMITE ]; then
  NUEVO=$LIMITE
fi

# Aplicar nuevo brillo
echo $NUEVO | sudo tee "$BACKLIGHT" > /dev/null

echo "✨ Brillo: $NUEVO / $LIMITE (máx 150%)"
