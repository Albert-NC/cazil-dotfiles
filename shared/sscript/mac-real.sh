#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — mac-real.sh
# Fuerza el uso de la MAC real de fábrica en la red WiFi actual
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# 1. Obtener el nombre (SSID) de la red activa
CON_NAME=$(nmcli -t -f NAME,TYPE connection show --active | grep wireless | cut -d: -f1)

if [ -z "$CON_NAME" ]; then
    echo -e "${RED}[!] No estás conectado a ninguna red WiFi.${NC}"
    exit 1
fi

echo -e "${YELLOW}[*] Red detectada: $CON_NAME${NC}"
echo -ne "¿Deseas marcar esta red como de CONFIANZA y usar tu MAC real? (s/n): "
read -r CONFIRMAR

if [[ "$CONFIRMAR" =~ ^(s|si)$ ]]; then
    # Establecer la MAC como 'permanent' (la de fábrica) para esta conexión específica
    nmcli connection modify "$CON_NAME" 802-11-wireless.cloned-mac-address permanent
    echo -e "${GREEN}[*] Configuración aplicada. Reconectando...${NC}"
    nmcli connection up "$CON_NAME"
    notify-send "Seguridad" "Red '$CON_NAME' marcada como de CONFIANZA (MAC Real)" -i security-low
else
    echo -e "${NC}Operación cancelada.${NC}"
fi
