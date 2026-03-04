#!/bin/bash
# Módulo: Verifica si el modo Avión está activo (ambas redes apagadas)

# rfkill lista todos los dispositivos de radio (wifi, bt)
# Buscamos si el estado 'Soft blocked' de Bluetooth es 'yes'
BT_BLOCKED=$(rfkill list bluetooth | grep -c "Soft blocked: yes")
WLAN_DOWN=$(ip link show wlan0 | grep -c "state DOWN")

# Si Bluetooth está bloqueado Y el WiFi está apagado, asumimos modo avión.
if [ "$WLAN_DOWN" -eq 1 ] && [ "$BT_BLOCKED" -ge 1 ]; then
    echo "{\"text\":\"󰁍 MODE\",\"class\":\"active\"}" # Icono de Avión (Nerd Font)
else
    echo "" # No muestra nada si las redes están activas
fi