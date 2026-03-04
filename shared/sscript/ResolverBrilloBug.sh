#!/bin/bash
# ResolverBrilloBug.sh — Paso 1: Añade acpi_backlight=video al bootloader
# Compatible con: GRUB (Arch/Debian), systemd-boot (Pop!_OS)
# EJECUTAR ANTES del reboot. Después corre ResolverBrilloBug2.sh.

echo "🔧 Iniciando fix de brillo (Paso 1)..."
echo ""

if [ "$EUID" -ne 0 ]; then
  echo "❌ Necesita permisos de superusuario"
  echo "💡 Ejecuta: sudo $0"
  exit 1
fi

PARAM="acpi_backlight=video"

# ── Detectar bootloader ────────────────────────────────────────────────────────
if [ -f /etc/default/grub ]; then
  echo "🔍 Detectado: GRUB"

  if grep -q "$PARAM" /etc/default/grub; then
    echo "✅ '$PARAM' ya existe en /etc/default/grub. Sin cambios."
    grep "GRUB_CMDLINE_LINUX" /etc/default/grub
    exit 0
  fi

  BACKUP="/etc/default/grub.bak.$(date +%Y%m%d_%H%M%S)"
  cp /etc/default/grub "$BACKUP" && echo "✅ Backup: $BACKUP"

  # Añadir al final de GRUB_CMDLINE_LINUX_DEFAULT
  sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $PARAM\"/" /etc/default/grub

  echo "📝 Nueva línea:"
  grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub

  # Regenerar GRUB
  if command -v grub-mkconfig &>/dev/null; then
    grub-mkconfig -o /boot/grub/grub.cfg && echo "✅ grub.cfg regenerado"
  elif command -v update-grub &>/dev/null; then
    update-grub && echo "✅ GRUB actualizado"
  fi

elif [ -f /boot/efi/loader/entries/Pop_OS-current.conf ]; then
  echo "🔍 Detectado: systemd-boot (Pop!_OS)"
  ENTRY="/boot/efi/loader/entries/Pop_OS-current.conf"

  if grep -q "$PARAM" "$ENTRY"; then
    echo "✅ '$PARAM' ya existe. Sin cambios."
    grep "^options" "$ENTRY"
    exit 0
  fi

  BACKUP="$ENTRY.bak.$(date +%Y%m%d_%H%M%S)"
  cp "$ENTRY" "$BACKUP" && echo "✅ Backup: $BACKUP"
  sed -i "/^options / s/$/ $PARAM/" "$ENTRY"
  echo "📝 Nueva línea options:"
  grep "^options" "$ENTRY"

elif ls /boot/loader/entries/*.conf &>/dev/null 2>&1; then
  echo "🔍 Detectado: systemd-boot genérico"
  ENTRY=$(ls /boot/loader/entries/*.conf | head -1)
  echo "   Usando entrada: $ENTRY"

  if grep -q "$PARAM" "$ENTRY"; then
    echo "✅ '$PARAM' ya existe. Sin cambios."
    exit 0
  fi

  BACKUP="$ENTRY.bak.$(date +%Y%m%d_%H%M%S)"
  cp "$ENTRY" "$BACKUP" && echo "✅ Backup: $BACKUP"
  sed -i "/^options / s/$/ $PARAM/" "$ENTRY"
  echo "📝 Nueva línea options:"
  grep "^options" "$ENTRY"

else
  echo "❌ No se detectó bootloader compatible (GRUB / systemd-boot)"
  echo "   Añade manualmente 'acpi_backlight=video' a tus parámetros de kernel"
  exit 1
fi

echo ""
echo "🔄 REINICIA el sistema: sudo reboot"
echo "   → Después del reboot corre: sudo bash ResolverBrilloBug2.sh"
echo ""
echo "🔍 Verificar tras reiniciar:"
echo "   cat /proc/cmdline | grep acpi_backlight"