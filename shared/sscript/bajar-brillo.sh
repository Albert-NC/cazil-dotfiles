#!/bin/bash
# bajar-brillo.sh
# Script para decrementar el brillo de la pantalla

BACKLIGHT="/sys/class/backlight/acpi_video1/brightness"
MAX_BRIGHTNESS="/sys/class/backlight/acpi_video1/max_brightness"

# Verificar que los archivos existen
if [ ! -f "$BACKLIGHT" ] || [ ! -f "$MAX_BRIGHTNESS" ]; then
    echo "❌ No se pueden leer los archivos de brillo"
    exit 1
fi

# Leer valores
ACTUAL=$(cat "$BACKLIGHT")
MAX=$(cat "$MAX_BRIGHTNESS")

# Calcular decremento (5 puntos)
NUEVO=$((ACTUAL - 5))

# Limitar al mínimo (10% del máximo para no dejarlo muy oscuro)
MINIMO=$((MAX / 10))
if [ $NUEVO -lt $MINIMO ]; then
  NUEVO=$MINIMO
fi

# Aplicar nuevo brillo
echo $NUEVO | sudo tee "$BACKLIGHT" > /dev/null

echo "🌙 Brillo: $NUEVO"
