#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — modo.sh
# Perfiles de seguridad y energía combinados
# Uso: modo uni | modo casa | modo avion | modo cafe | modo normal | modo estado
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'
BIN="$HOME/.local/bin"

notify() { command -v notify-send &>/dev/null && notify-send "$1" "$2" -i "$3" 2>/dev/null; }

case "${1,,}" in

    # ══════════════════════════════════════════════════════════════════════════
    # MODO UNI — Protección máxima para redes universitarias inseguras
    # ══════════════════════════════════════════════════════════════════════════
    uni|universidad)
        echo -e "${MAGENTA}╔════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║       🎓 MODO UNIVERSIDAD — ACTIVO        ║${NC}"
        echo -e "${MAGENTA}╚════════════════════════════════════════════╝${NC}"

        # 1. MAC aleatoria (no te rastrean en la red)
        echo -e "${CYAN}[1/6] MAC Aleatoria...${NC}"
        [ -f "$BIN/mac-random" ] && bash "$BIN/mac-random" 2>/dev/null || \
            sudo macchanger -r wlan0 2>/dev/null && \
            echo -e "${GREEN}  [✓] MAC randomizada${NC}"

        # 2. DNS seguro (cifrado, no ven tus consultas)
        echo -e "${CYAN}[2/6] DNS over TLS (Cloudflare)...${NC}"
        [ -f "$BIN/dns-seguro" ] && bash "$BIN/dns-seguro" 2>/dev/null || \
            echo -e "${YELLOW}  [!] dns-seguro no disponible, ejecuta install.sh${NC}"

        # 3. Firewall estricto
        echo -e "${CYAN}[3/6] Firewall → solo salida...${NC}"
        sudo ufw default deny incoming 2>/dev/null
        sudo ufw default allow outgoing 2>/dev/null
        sudo ufw enable 2>/dev/null
        echo -e "${GREEN}  [✓] UFW: deny incoming / allow outgoing${NC}"

        # 4. Bloquear Bluetooth (vector de ataque en redes públicas)
        echo -e "${CYAN}[4/6] Bluetooth OFF...${NC}"
        rfkill block bluetooth 2>/dev/null
        echo -e "${GREEN}  [✓] Bluetooth bloqueado${NC}"

        # 5. USBGuard activo (protección contra BadUSB / Rubber Ducky)
        echo -e "${CYAN}[5/6] USBGuard...${NC}"
        sudo systemctl start usbguard 2>/dev/null && \
            echo -e "${GREEN}  [✓] USBGuard activo${NC}" || \
            echo -e "${YELLOW}  [!] USBGuard no instalado${NC}"

        # 6. Eco-mode (ahorro de batería para clases largas)
        echo -e "${CYAN}[6/6] Modo eco (batería)...${NC}"
        [ -f "$BIN/perfil-energia" ] && bash "$BIN/perfil-energia" eco 2>/dev/null
        [ -f "$BIN/toggle-animations" ] && bash "$BIN/toggle-animations" 2>/dev/null

        echo ""
        echo -e "${GREEN}  ✓ MODO UNIVERSIDAD ACTIVO${NC}"
        echo -e "${CYAN}  MAC oculta · DNS cifrado · Firewall · BT off · USB seguro · Eco${NC}"
        notify "🎓 Modo Universidad" "Protección máxima activada" security-high
        ;;

    # ══════════════════════════════════════════════════════════════════════════
    # MODO CAFÉ — Protección para WiFi público (cafetería, aeropuerto, etc.)
    # ══════════════════════════════════════════════════════════════════════════
    cafe|publico|wifi)
        echo -e "${MAGENTA}╔════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║       ☕ MODO CAFÉ — WiFi Público          ║${NC}"
        echo -e "${MAGENTA}╚════════════════════════════════════════════╝${NC}"

        # MAC aleatoria
        sudo macchanger -r wlan0 2>/dev/null || \
            [ -f "$BIN/mac-random" ] && bash "$BIN/mac-random" 2>/dev/null
        echo -e "${GREEN}  [✓] MAC randomizada${NC}"

        # DNS seguro
        [ -f "$BIN/dns-seguro" ] && bash "$BIN/dns-seguro" 2>/dev/null

        # Firewall estricto
        sudo ufw default deny incoming 2>/dev/null
        sudo ufw enable 2>/dev/null

        # BT off
        rfkill block bluetooth 2>/dev/null

        echo -e "${GREEN}  ✓ MODO CAFÉ ACTIVO (MAC + DNS + Firewall + BT off)${NC}"
        notify "☕ Modo Café" "WiFi público protegido" security-high
        ;;

    # ══════════════════════════════════════════════════════════════════════════
    # MODO CASA — Relajar protecciones para red confiable
    # ══════════════════════════════════════════════════════════════════════════
    casa|home)
        echo -e "${MAGENTA}╔════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║       🏠 MODO CASA — Red Confiable        ║${NC}"
        echo -e "${MAGENTA}╚════════════════════════════════════════════╝${NC}"

        # Restaurar MAC original
        sudo macchanger -p wlan0 2>/dev/null && \
            echo -e "${GREEN}  [✓] MAC restaurada a original${NC}"

        # Bluetooth disponible
        rfkill unblock bluetooth 2>/dev/null
        echo -e "${GREEN}  [✓] Bluetooth disponible${NC}"

        # Firewall más permisivo (sigue activo)
        sudo ufw default deny incoming 2>/dev/null
        sudo ufw default allow outgoing 2>/dev/null
        echo -e "${GREEN}  [✓] Firewall: deny in / allow out${NC}"

        # Restaurar animaciones
        [ -f "$BIN/toggle-animations" ] && bash "$BIN/toggle-animations" 2>/dev/null
        [ -f "$BIN/perfil-energia" ] && bash "$BIN/perfil-energia" normal 2>/dev/null

        echo -e "${GREEN}  ✓ MODO CASA ACTIVO (MAC original · BT on · Eco off)${NC}"
        notify "🏠 Modo Casa" "Red confiable" security-medium
        ;;

    # ══════════════════════════════════════════════════════════════════════════
    # MODO AVIÓN — Todo apagado (máxima privacidad / batería)
    # ══════════════════════════════════════════════════════════════════════════
    avion|vuelo|offline)
        echo -e "${MAGENTA}╔════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║       ✈️  MODO AVIÓN — Sin radio           ║${NC}"
        echo -e "${MAGENTA}╚════════════════════════════════════════════╝${NC}"

        nmcli radio wifi off 2>/dev/null
        rfkill block bluetooth 2>/dev/null
        rfkill block wlan 2>/dev/null
        [ -f "$BIN/perfil-energia" ] && bash "$BIN/perfil-energia" eco 2>/dev/null
        [ -f "$BIN/toggle-animations" ] && bash "$BIN/toggle-animations" 2>/dev/null

        echo -e "${GREEN}  ✓ MODO AVIÓN: WiFi off · BT off · Eco on${NC}"
        notify "✈️ Modo Avión" "Radios apagadas" network-offline
        ;;

    # ══════════════════════════════════════════════════════════════════════════
    # MODO NORMAL — Restaurar todo a valores por defecto
    # ══════════════════════════════════════════════════════════════════════════
    normal|reset|off)
        echo -e "${MAGENTA}╔════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║       🔄 MODO NORMAL — Restaurado          ║${NC}"
        echo -e "${MAGENTA}╚════════════════════════════════════════════╝${NC}"

        sudo macchanger -p wlan0 2>/dev/null || true
        rfkill unblock bluetooth 2>/dev/null
        rfkill unblock wlan 2>/dev/null
        nmcli radio wifi on 2>/dev/null
        [ -f "$BIN/perfil-energia" ] && bash "$BIN/perfil-energia" normal 2>/dev/null
        sudo systemctl stop usbguard 2>/dev/null || true

        echo -e "${GREEN}  ✓ TODO RESTAURADO (MAC · WiFi · BT · Eco off · USBGuard off)${NC}"
        notify "🔄 Modo Normal" "Protecciones relajadas" security-low
        ;;

    # ══════════════════════════════════════════════════════════════════════════
    # ESTADO — Resumen rápido de qué está activo
    # ══════════════════════════════════════════════════════════════════════════
    estado|status)
        echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║         ESTADO DE PROTECCIÓN               ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  🛡️  UFW:        $(systemctl is-active ufw 2>/dev/null || echo 'N/A')"
        echo -e "  🔌 USBGuard:   $(systemctl is-active usbguard 2>/dev/null || echo 'N/A')"
        echo -e "  🔐 DoT DNS:    $(resolvectl status 2>/dev/null | grep -q 'DNSOverTLS' && echo 'activo' || echo 'inactivo')"
        MAC=$(ip link show wlan0 2>/dev/null | awk '/ether/ {print $2}')
        echo -e "  📡 MAC WiFi:   ${MAC:-N/A}"
        echo -e "  📶 WiFi:       $(nmcli radio wifi 2>/dev/null || echo 'N/A')"
        BT=$(rfkill list bluetooth 2>/dev/null | grep -c "Soft blocked: yes")
        [ "$BT" -gt 0 ] && echo -e "  🔵 Bluetooth:  bloqueado" || echo -e "  🔵 Bluetooth:  activo"
        echo ""
        ;;

    # ══════════════════════════════════════════════════════════════════════════
    # MODO EXPONER — Fondo estático (Blanco/Negro - Opacidad 100%)
    # ══════════════════════════════════════════════════════════════════════════
    exponer|exhibicion)
        echo -e "${MAGENTA}╔════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║       📸 MODO EXPOSICIÓN — ACTIVO        ║${NC}"
        echo -e "${MAGENTA}╚════════════════════════════════════════════╝${NC}"
        
        # 1. Aplicar tema estático (Blanco/Negro)
        [ -f "$BIN/tema" ] && bash "$BIN/tema" EX
        
        # 2. Notificar
        notify "Exposición" "Modo Exponer Activado" image-x-generic
        echo -e "${GREEN}  ✓ Fondo estático aplicado.${NC}"
        ;;

    *)
        echo -e "${CYAN}Uso: modo <perfil>${NC}"
        echo ""
        echo -e "  ${GREEN}uni${NC}      🎓 Universidad (protección máxima)"
        echo -e "  ${GREEN}cafe${NC}     ☕ WiFi público (MAC + DNS + Firewall)"
        echo -e "  ${GREEN}casa${NC}     🏠 Red confiable (relajado)"
        echo -e "  ${GREEN}avion${NC}    ✈️  Sin radio (offline total)"
        echo -e "  ${GREEN}exponer${NC}  📸 Modo Exponer (estático)"
        echo -e "  ${GREEN}normal${NC}   🔄 Restaurar todo"
        echo -e "  ${GREEN}estado${NC}   📊 Ver qué está activo"
        ;;
esac
