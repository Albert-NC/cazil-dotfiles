#!/bin/bash
# ==============================================================================
# SCRIPT DE LÍMITE DE BATERÍA (Acer Nitro / Acer WMI)
# ==============================================================================

THRESHOLD_FILE="/sys/class/power_supply/BAT0/charge_control_end_threshold"
LIMIT=${1:-80}

# Verificar que el driver esté cargado
if [ ! -f "$THRESHOLD_FILE" ]; then
    echo "Error: Driver 'acer-wmi-battery' no detectado o no compatible."
    echo "Asegúrate de haber instalado 'acer-wmi-battery-dkms' de AUR."
    exit 1
fi

# Aplicar el límite
echo "$LIMIT" | sudo tee "$THRESHOLD_FILE" > /dev/null
echo "Límite de batería establecido al $LIMIT%."
