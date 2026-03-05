#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — limpiar-sistema.sh
# Mantenimiento y limpieza profunda para Arch Linux
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}[*] Iniciando limpieza del sistema...${NC}"

# 1. Limpiar cache de pacman (mantener solo los últimos 2)
if command -v paccache &>/dev/null; then
    echo -e "${GREEN}[1/4] Limpiando cache de paquetes (paccache)...${NC}"
    sudo paccache -r
else
    echo -e "${GREEN}[1/4] Limpiando cache de paquetes (pacman -Sc)...${NC}"
    sudo pacman -Sc --noconfirm
fi

# 2. Eliminar paquetes huérfanos
if [ -n "$(pacman -Qtdq)" ]; then
    echo -e "${GREEN}[2/4] Eliminando paquetes huérfanos...${NC}"
    sudo pacman -Rs $(pacman -Qtdq) --noconfirm
else
    echo -e "${GREEN}[2/4] No hay paquetes huérfanos que eliminar.${NC}"
fi

# 3. Limpiar cache de usuario (~/.cache)
echo -e "${GREEN}[3/4] Limpiando cache de usuario (~/.cache)...${NC}"
rm -rf ~/.cache/*
echo -e "${GREEN}    [✓] Cache de usuario liberada.${NC}"

# 4. Limpiar logs antiguos de Journald (mantener solo 2 días)
echo -e "${GREEN}[4/4] Limpiando logs de systemd (journalctl)...${NC}"
sudo journalctl --vacuum-time=2d

echo -e "${YELLOW}╔══════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║         LIMPIEZA COMPLETADA CON ÉXITO        ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}"
