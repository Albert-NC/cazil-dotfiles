#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — config-dns-seguro.sh
# Configura DNS over TLS (DoT) con Cloudflare usando systemd-resolved
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# 1. Configurar systemd-resolved
RESOLVED_CONF="/etc/systemd/resolved.conf"
NM_CONF="/etc/NetworkManager/conf.d/dns.conf"

echo -e "${GREEN}[*] Configurando systemd-resolved para DNS over TLS...${NC}"

sudo bash -c "cat > $RESOLVED_CONF" <<EOF
[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
FallbackDNS=9.9.9.9 149.112.112.112
Domains=~.
DNSOverTLS=yes
EOF

# 2. Configurar NetworkManager para usar systemd-resolved
echo -e "${GREEN}[*] Integrando con NetworkManager...${NC}"
sudo mkdir -p /etc/NetworkManager/conf.d/
sudo bash -c "cat > $NM_CONF" <<EOF
[main]
dns=systemd-resolved
EOF

# 3. Gestionar /etc/resolv.conf symlink
echo -e "${GREEN}[*] Actualizando enlace simbólico de resolv.conf...${NC}"
sudo rm -f /etc/resolv.conf
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# 4. Habilitar y reiniciar servicios
echo -e "${GREEN}[*] Reiniciando servicios...${NC}"
sudo systemctl enable --now systemd-resolved
sudo systemctl restart NetworkManager

# 5. Verificación rápida
echo -e "${YELLOW}[!] Verificando configuración:${NC}"
resolvectl status | grep -E "Protocols|DNS over TLS|DNS Servers" | head -n 5

notify-send "Seguridad DNS" "DNS over TLS activado con Cloudflare 🔒" -i network-transmit-secure
echo -e "${GREEN}[✓] ¡DNS Seguro configurado correctamente!${NC}"
