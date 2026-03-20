#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — perfil-energia.sh
# Gestión unificada de energía, rendimiento y límites de batería
# Uso: perfil-energia [eco|gaming|normal|limit <%>]
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
THRESHOLD_FILE="/sys/class/power_supply/BAT0/charge_control_end_threshold"

notify() { command -v notify-send &>/dev/null && notify-send "$1" "$2" -i "$3" 2>/dev/null; }

case "${1,,}" in
    # 🍃 MODO ECO — Ahorro máximo de batería
    eco|powersave)
        echo -e "${GREEN}[+] Activando Modo Eco...${NC}"
        hyprctl keyword monitor eDP-1,1920x1080@60,0x0,1
        brightnessctl set 20%
        if command -v auto-cpufreq &>/dev/null; then
            sudo auto-cpufreq --quiet --force powersave
        fi
        hyprctl keyword animations:enabled 0
        notify "Modo Eco" "Activado: 60Hz + Ahorro de energía" battery-caution
        ;;

    # 🎮 MODO GAMING — Máximo rendimiento
    gaming|performance)
        echo -e "${CYAN}[+] Activando Modo Gaming...${NC}"
        hyprctl keyword monitor eDP-1,1920x1080@144,0x0,1
        brightnessctl set 100%
        if command -v auto-cpufreq &>/dev/null; then
            sudo auto-cpufreq --quiet --force performance
        fi
        if command -v nvidia-settings &>/dev/null; then
            nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" &>/dev/null
        fi
        hyprctl keyword animations:enabled 1
        notify "Modo Gaming" "Rendimiento máximo activado 🚀" preferences-desktop-gaming
        ;;

    # 🔄 MODO NORMAL — Balanceado
    normal|reset)
        echo -e "${YELLOW}[-] Restaurando Perfil Normal...${NC}"
        hyprctl keyword monitor eDP-1,1920x1080@60,0x0,1
        brightnessctl set 80%
        if command -v auto-cpufreq &>/dev/null; then
            sudo auto-cpufreq --quiet --force reset
        fi
        hyprctl keyword animations:enabled 1
        notify "Modo Normal" "Perfil balanceado restaurado" battery
        ;;

    # 🔋 LÍMITE DE BATERÍA
    limit)
        LIMIT=${2:-80}
        if [ ! -f "$THRESHOLD_FILE" ]; then
            echo -e "${RED}[!] Error: Driver 'acer-wmi-battery' o similar no detectado.${NC}"
            exit 1
        fi
        echo "$LIMIT" | sudo tee "$THRESHOLD_FILE" > /dev/null
        echo -e "${GREEN}[✓] Límite de batería establecido al $LIMIT%.${NC}"
        notify "Batería" "Límite de carga: $LIMIT%" battery-full
        ;;

    *)
        echo -e "${CYAN}Uso: perfil-energia <opción>${NC}"
        echo -e "  ${GREEN}eco${NC}      🍃 Ahorro máximo (60Hz, animaciones off)"
        echo -e "  ${GREEN}gaming${NC}   🎮 Máximo rendimiento (144Hz, animaciones on)"
        echo -e "  ${GREEN}normal${NC}   🔄 Balanceado (60Hz)"
        echo -e "  ${GREEN}limit <%> ${NC}🔋 Establecer límite de carga de batería"
        ;;
esac
