#!/bin/bash
# power-save.sh — Script para activar/desactivar modo Eco

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

toggle_eco() {
    if [ "$1" == "on" ]; then
        echo -e "${GREEN}[+] Activando Modo Eco...${NC}"
        # Brillo al 20%
        brightnessctl set 20%
        # CPU a modo powersave (requiere auto-cpufreq o cpupower)
        if command -v auto-cpufreq &> /dev/null; then
            sudo auto-cpufreq --quiet --force powersave
        fi
        # Desactivar animaciones de Hyprland para ahorrar GPU
        hyprctl keyword animations:enabled 0
        # Notificar
        notify-send "Modo Eco" "Activado: Ahorro de energía máximo" -i battery-caution
    else
        echo -e "${YELLOW}[-] Desactivando Modo Eco...${NC}"
        # Brillo al 80%
        brightnessctl set 80%
        # Retornar control a auto-cpufreq (default)
        if command -v auto-cpufreq &> /dev/null; then
            sudo auto-cpufreq --quiet --force reset
        fi
        # Activar animaciones de Hyprland
        hyprctl keyword animations:enabled 1
        # Notificar
        notify-send "Modo Eco" "Desactivado: Rendimiento normal" -i battery
    fi
}

case "$1" in
    on) toggle_eco "on" ;;
    off) toggle_eco "off" ;;
    *) echo "Uso: eco [on|off]" ;;
esac
