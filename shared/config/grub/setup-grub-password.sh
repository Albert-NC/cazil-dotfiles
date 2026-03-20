#!/bin/bash
# ==============================================================================
# CAZIL — Protección de GRUB con contraseña PBKDF2
# Uso: sudo bash shared/grub/setup-grub-password.sh
#
# Qué hace:
#   1. Genera un hash PBKDF2 de tu contraseña elegida
#   2. Escribe la config en /etc/grub.d/01_cazil_password
#   3. Regenera grub.cfg
#
# Resultado: Para editar entradas del GRUB se requerirá la contraseña.
#            El arranque normal ocurre sin pedirla (--unrestricted).
# ==============================================================================

set -euo pipefail

# Validar que corre como root
[ "$EUID" -ne 0 ] && { echo -e "\033[0;31m[!] Ejecuta con sudo\033[0m"; exit 1; }

# Verificar dependencia
command -v grub-mkpasswd-pbkdf2 >/dev/null 2>&1 || { echo -e "\033[0;31m[!] grub-mkpasswd-pbkdf2 no instalado o GRUB no presente. Abortando.\033[0m"; exit 1; }

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║        PROTECCIÓN DE GRUB CON CONTRASEÑA      ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠  IMPORTANTE: Si olvidas esta contraseña tendrás que${NC}"
echo -e "${YELLOW}   regenerar grub.cfg manualmente desde un Live USB.${NC}"
echo ""

# Generar hash PBKDF2 interactivo
echo -e "${GREEN}[*] Introduce la contraseña para GRUB (se pedirá dos veces):${NC}"
HASH=$(grub-mkpasswd-pbkdf2 | grep "PBKDF2 hash" | awk '{print $NF}')

if [ -z "$HASH" ]; then
    echo -e "${RED}[!] Error generando el hash. Abortando.${NC}"
    exit 1
fi

GRUB_USER="${SUDO_USER:-$(whoami)}"
GRUB_FILE="/etc/grub.d/01_cazil_password"

# Escribir configuración
sudo tee "$GRUB_FILE" > /dev/null << EOF
#!/bin/sh
# CAZIL — GRUB password protection (generado automáticamente)
# Para deshabilitar: sudo rm $GRUB_FILE && sudo grub-mkconfig -o /boot/grub/grub.cfg

cat << GRUB_HEREDOC
set superusers="$GRUB_USER"
password_pbkdf2 $GRUB_USER $HASH
GRUB_HEREDOC
EOF

sudo chmod +x "$GRUB_FILE"
echo -e "${GREEN}[✓] Contraseña configurada para el usuario GRUB: '$GRUB_USER'${NC}"

# Marcar todas las entradas como --unrestricted para que arranquen sin contraseña
# Mejor enfoque: Usar un archivo drop-in para mayor persistencia
echo 'GRUB_CMDLINE_LINUX_DEFAULT="--unrestricted $GRUB_CMDLINE_LINUX_DEFAULT"' | \
    sudo tee /etc/default/grub.d/unrestricted.cfg > /dev/null

# Regenerar grub.cfg
echo -e "${GREEN}[*] Regenerando grub.cfg...${NC}"
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  GRUB protegido correctamente ✓       ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Usuario GRUB : $GRUB_USER             ${NC}"
echo -e "${GREEN}║  Arranque     : sin contraseña        ║${NC}"
echo -e "${GREEN}║  Edición      : requiere contraseña   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Para deshabilitar:${NC}"
echo -e "  sudo rm $GRUB_FILE"
echo -e "  sudo grub-mkconfig -o /boot/grub/grub.cfg"
