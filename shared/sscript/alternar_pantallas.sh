#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — alternar_pantallas.sh
# Alterna entre monitor único (Laptop) y extendido (Laptop + HDMI)
# ==============================================================================

CONFIG_DIR="$HOME/.config/hypr"
MONITOR_CONF="$CONFIG_DIR/monitors.conf"
INTERNAL_CONF="$CONFIG_DIR/monitores_internos.conf"
EXTENDED_CONF="$CONFIG_DIR/monitores_extendidos.conf"

# Verificar qué configuración está activa actualmente leyendo el archivo monitors.conf
CURRENT=$(grep -o "monitores_.*\.conf" "$MONITOR_CONF")

if [ "$CURRENT" == "monitores_internos.conf" ]; then
    echo "Cambiando a modo EXTENDIDO (Laptop + Externo)..."
    sed -i "s/monitores_internos.conf/monitores_extendidos.conf/g" "$MONITOR_CONF"
    notify-send "Monitores" "Modo Extendido Activado (HDMI)" -i video-display
else
    echo "Cambiando a modo INTERNO (Solo Laptop)..."
    sed -i "s/monitores_extendidos.conf/monitores_internos.conf/g" "$MONITOR_CONF"
    notify-send "Monitores" "Modo Interno Activado (Solo Laptop)" -i computer
fi

# Hyprland recargará automáticamente al detectar el cambio en monitors.conf
hyprctl reload
