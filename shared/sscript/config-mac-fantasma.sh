#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — config-mac-fantasma.sh
# Configura aleatorización de MAC (Modo Fantasma) en NetworkManager
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

CONF_FILE="/etc/NetworkManager/conf.d/00-macrandom.conf"

echo -e "${GREEN}[*] Configurando Modo Fantasma (MAC Aleatoria)...${NC}"

# 1. Crear configuración global para NetworkManager
# wifi.scan-rand-mac-address: MAC aleatoria mientras buscas redes
# wifi.cloned-mac-address=stable: Una MAC aleatoria distinta para cada SSID (pero persistente para esa red)
sudo bash -c "cat > $CONF_FILE" <<EOF
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
ethernet.cloned-mac-address=stable
EOF

# 2. Reiniciar NetworkManager para aplicar cambios globales
echo -e "${GREEN}[*] Reiniciando NetworkManager...${NC}"
sudo systemctl restart NetworkManager

notify-send "Seguridad" "Modo Fantasma (MAC Aleatoria) activado 🎭" -i security-high
echo -e "${GREEN}[✓] ¡Modo Fantasma activado!${NC}"
echo -e "${YELLOW}[!] Usa el comando 'mac-real' cuando estés en una red de confianza (casa) para usar tu identidad real.${NC}"
