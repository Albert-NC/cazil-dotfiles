#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — toggle-radio.sh
# Control unificado de WiFi (wlan) y Bluetooth (bt)
# Uso: toggle-radio [wifi|bt] [on|off]
# ==============================================================================

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

notify() { command -v notify-send &>/dev/null && notify-send "$1" "$2" -i "$3" 2>/dev/null; }

case "${1,,}" in
    wifi)
        if [ "$2" == "on" ]; then
            echo -e "${YELLOW}[*] Arrancando WiFi (NetworkManager)...${NC}"
            sudo systemctl start NetworkManager 2>/dev/null
            rfkill unblock wlan 2>/dev/null
            notify "Internet Activado" "Daemon de Wi-Fi INICIADO 🚀" network-wireless-signal-excellent
        else
            echo -e "${RED}[*] Deteniendo WiFi (NetworkManager)...${NC}"
            rfkill block wlan 2>/dev/null
            sudo systemctl stop NetworkManager 2>/dev/null
            notify "Modo Ahorro Internet" "Daemon y Antena Wi-Fi APAGADOS 🪫" network-wireless-offline
        fi
        ;;

    bt|bluetooth)
        if [ "$2" == "on" ]; then
            echo -e "${YELLOW}[*] Arrancando Bluetooth...${NC}"
            sudo systemctl start bluetooth 2>/dev/null
            rfkill unblock bluetooth 2>/dev/null
            notify "Bluetooth Activado" "Daemon de Bluetooth INICIADO 🎧" bluetooth-active
        else
            echo -e "${RED}[*] Deteniendo Bluetooth...${NC}"
            rfkill block bluetooth 2>/dev/null
            sudo systemctl stop bluetooth 2>/dev/null
            notify "Modo Ahorro Bluetooth" "Daemon y Antena Bluetooth APAGADOS 🪫" bluetooth-disabled
        fi
        ;;

    *)
        echo -e "Uso: toggle-radio [wifi|bt] [on|off]"
        ;;
esac
