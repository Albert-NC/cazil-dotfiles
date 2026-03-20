#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — privacy-action.sh
# Gestión unificada de MAC y DNS
# Uso: privacy-action [mac|dns] [toggle|setup]
# ==============================================================================

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

notify() { command -v notify-send &>/dev/null && notify-send "$1" "$2" -i "$3" 2>/dev/null; }

case "${1,,}" in
    mac)
        CONF_FILE="/etc/NetworkManager/conf.d/00-macrandom.conf"
        if [ -f "$CONF_FILE" ]; then
            echo -e "${YELLOW}[*] Desactivando MAC Aleatoria...${NC}"
            sudo rm "$CONF_FILE"
            sudo systemctl restart NetworkManager
            notify "Privacidad" "Usando MAC Real 🔓" security-low
        else
            echo -e "${GREEN}[*] Activando MAC Aleatoria...${NC}"
            sudo bash -c "cat > $CONF_FILE" <<EOF
[device]
wifi.scan-rand-mac-address=yes
[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF
            sudo systemctl restart NetworkManager
            notify "Privacidad" "MAC Aleatoria Activada 🕵️" security-high
        fi
        ;;

    dns)
        # Reutilizar config-dns-seguro.sh si se desea, o integrar aquí
        # Por simplicidad en la llamada unificada:
        echo -e "${GREEN}[*] Configurando DNS Seguro (DNS Over TLS)...${NC}"
        # ... logic from config-dns-seguro.sh can be moved or called ...
        # [Simplified call to the original renamed script if preferred]
        # For now, I'll integrate the logic for a "complete" script.
        RESOLVED_CONF="/etc/systemd/resolved.conf"
        sudo bash -c "cat > $RESOLVED_CONF" <<EOF
[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
FallbackDNS=9.9.9.9 149.112.112.112
Domains=~.
DNSOverTLS=yes
EOF
        sudo systemctl enable --now systemd-resolved
        sudo systemctl restart NetworkManager
        notify "Seguridad DNS" "DNS over TLS activado 🔒" network-transmit-secure
        ;;

    *)
        echo -e "Uso: privacy-action [mac|dns]"
        ;;
esac
