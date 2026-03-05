#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — security-status.sh
# Monitor de Seguridad para Waybar (Custom JSON)
# ==============================================================================

# Iconos Neón
ICON_SECURE="󰒘"
ICON_WARNING="󰒙"
ICON_DANGER="󰒚"

# 1. Verificar Servicios
UFW=$(systemctl is-active ufw)
DNS=$(resolvectl status | grep -q "DNS over TLS: yes" && echo "active" || echo "inactive")
USB=$(systemctl is-active usbguard)
APPARMOR=$(systemctl is-active apparmor)

# 2. Calcular Estado y Tooltip
COUNT=0
[ "$UFW" == "active" ] && COUNT=$((COUNT + 1))
[ "$DNS" == "active" ] && COUNT=$((COUNT + 1))
[ "$USB" == "active" ] && COUNT=$((COUNT + 1))
[ "$APPARMOR" == "active" ] && COUNT=$((COUNT + 1))

TOOLTIP="<b>🛡️ Estado de Seguridad:</b>\n"
TOOLTIP="$TOOLTIP - Firewall (UFW): $UFW\n"
TOOLTIP="$TOOLTIP - DNS (DoT): $DNS\n"
TOOLTIP="$TOOLTIP - USBGuard: $USB\n"
TOOLTIP="$TOOLTIP - AppArmor: $APPARMOR"

# 3. Formatear Salida JSON para Waybar
if [ "$COUNT" -eq 4 ]; then
    # TODO PROTEGIDO (Neon Cyan/Magenta)
    echo "{\"text\": \"$ICON_SECURE\", \"alt\": \"secure\", \"tooltip\": \"$TOOLTIP\", \"class\": \"secure\"}"
elif [ "$COUNT" -gt 1 ]; then
    # RIESGO MEDIO (Amarillo/Naranja)
    echo "{\"text\": \"$ICON_WARNING\", \"alt\": \"warning\", \"tooltip\": \"$TOOLTIP\", \"class\": \"warning\"}"
else
    # PELIGRO (Rojo)
    echo "{\"text\": \"$ICON_DANGER\", \"alt\": \"danger\", \"tooltip\": \"$TOOLTIP\", \"class\": \"danger\"}"
fi
