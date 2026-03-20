#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — config-hardening.sh
# Aplica endurecimiento (Hardening) del Kernel mediante sysctl
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
CONF_FILE="/etc/sysctl.d/99-cyberpunk-security.conf"

echo -e "${GREEN}[*] Aplicando Hardening del Kernel (sysctl)...${NC}"

# 1. Crear el archivo de configuración de seguridad
sudo bash -c "cat > $CONF_FILE" <<EOF
# --- SEGURIDAD DE RED (IP/TCP) ---
# Ignorar redirecciones ICMP (Previene ataques MitM)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Ignorar paquetes con "Source Routing" (Vectores de ataque antiguos)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Protección contra ataques de saturación SYN (SYN Cookies)
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Log de paquetes sospechosos (Martians)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# --- SEGURIDAD DEL SISTEMA / MEMORIA ---
# Restringir el uso de dmesg a usuarios root (Info de hardware)
kernel.dmesg_restrict = 1

# Restringir el acceso a punteros del kernel (Dificulta exploits)
kernel.kptr_restrict = 2

# Desactivar 'Magic SysRq' (Solo permitir apagado/reinicio seguro)
kernel.sysrq = 176
EOF

# 2. Aplicar los cambios inmediatamente
echo -e "${GREEN}[*] Cargando nuevas reglas de seguridad...${NC}"
sudo sysctl --system

notify-send "Seguridad Kernel" "Hardening aplicado: Reglas de seguridad activas 🛡️" -i security-high
echo -e "${GREEN}[✓] ¡Kernel blindado con éxito!${NC}"
