#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — apagar-redes-grub.sh
# Configura el Kernel desde GRUB para que inicie con Wi-Fi y Bluetooth apagados
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}[*] Configurando el Kernel (GRUB) para iniciar en Modo Avión...${NC}"

# Comprobar si ya está aplicado
if grep -q "rfkill.default_state=0" /etc/default/grub; then
    echo -e "${GREEN}[✓] La configuración ya está aplicada en GRUB.${NC}"
else
    # Añadir el parámetro al kernel
    sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^\"]*\)"/\1 rfkill.default_state=0"/' /etc/default/grub
    
    echo -e "${GREEN}[*] Parámetro 'rfkill.default_state=0' añadido a /etc/default/grub.${NC}"
    echo -e "${YELLOW}[*] Actualizando configuración de GRUB...${NC}"
    
    # Dependiendo de si está en Arch o Debian/Ubuntu, el comando cambia
    if command -v grub-mkconfig &>/dev/null; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    elif command -v update-grub &>/dev/null; then
        sudo update-grub
    else
        echo -e "${RED}[!] No se pudo encontrar un comando para actualizar GRUB.${NC}"
    fi
    
    notify-send "GRUB" "Configurado el arranque sin Redes. Reinicia para aplicar." -i system-reboot
    echo -e "${GREEN}[✓] ¡Listo! La próxima vez que enciendas tu laptop, Wi-Fi y Bluetooth estarán totalmente apagados desde el nivel del hardware virtual (kernel).${NC}"
fi
