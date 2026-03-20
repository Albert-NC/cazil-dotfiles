#!/bin/bash
# Script para configurar permisos y reglas udev del control de brillo
# Ejecutar DESPUÉS de reiniciar con acpi_backlight=video aplicado

echo "⚙️  Configurando permisos de control de brillo..."
echo ""

# Verificar permisos de root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Este script necesita permisos de superusuario"
  echo "💡 Ejecuta: sudo $0"
  exit 1
fi

# Detectar usuario real (no root)
ACTUAL_USER="${SUDO_USER:-$USER}"

if [ "$ACTUAL_USER" = "root" ]; then
  echo "❌ No ejecutes este script como root directamente"
  echo "💡 Ejecuta: sudo $0 desde tu usuario normal"
  exit 1
fi

# Agregar usuario al grupo video
echo "👤 Configurando grupo 'video' para usuario '$ACTUAL_USER'..."
if ! groups "$ACTUAL_USER" | grep -q video; then
  usermod -aG video "$ACTUAL_USER"
  echo "✅ Usuario '$ACTUAL_USER' agregado al grupo 'video'"
else
  echo "✅ Usuario '$ACTUAL_USER' ya está en el grupo 'video'"
fi

echo ""

# Detectar qué interfaces de backlight existen
echo "🔍 Detectando interfaces de brillo disponibles..."
BACKLIGHT_DIR="/sys/class/backlight"

if [ ! -d "$BACKLIGHT_DIR" ]; then
  echo "❌ No se encontró el directorio $BACKLIGHT_DIR"
  exit 1
fi

# Listar interfaces disponibles
INTERFACES=$(ls "$BACKLIGHT_DIR" 2>/dev/null)

if [ -z "$INTERFACES" ]; then
  echo "❌ No se encontraron interfaces de brillo"
  exit 1
fi

echo "📋 Interfaces detectadas:"
echo "$INTERFACES" | sed 's/^/   - /'
echo ""

# Crear regla udev según las interfaces disponibles
UDEV_RULE="/etc/udev/rules.d/99-backlight.rules"

echo "📝 Creando reglas udev en $UDEV_RULE..."

# Verificar si existen acpi_video0, acpi_video1, acpi_video2
if echo "$INTERFACES" | grep -q "acpi_video"; then
  echo "✅ Detectadas interfaces acpi_video"
  
  cat > "$UDEV_RULE" << 'EOF'
# Reglas para control de brillo en modo hybrid/compute
# Solo acpi_video1 es accesible (la pantalla principal)

# Bloquear acpi_video0 (puerto externo)
SUBSYSTEM=="backlight", KERNEL=="acpi_video0", RUN+="/bin/chmod 000 /sys/class/backlight/acpi_video0/brightness"

# Hacer acpi_video1 accesible (pantalla principal)
SUBSYSTEM=="backlight", KERNEL=="acpi_video1", RUN+="/bin/chmod 666 /sys/class/backlight/acpi_video1/brightness"

# Bloquear acpi_video2 (puerto externo)
SUBSYSTEM=="backlight", KERNEL=="acpi_video2", RUN+="/bin/chmod 000 /sys/class/backlight/acpi_video2/brightness"
EOF

elif echo "$INTERFACES" | grep -q "nvidia_wmi_ec_backlight"; then
  echo "✅ Detectada interfaz nvidia_wmi_ec_backlight"
  
  cat > "$UDEV_RULE" << 'EOF'
# Reglas para control de brillo en modo nvidia
# Usar la interfaz nativa de NVIDIA

# Hacer nvidia_wmi_ec_backlight accesible
SUBSYSTEM=="backlight", KERNEL=="nvidia_wmi_ec_backlight", RUN+="/bin/chmod 666 /sys/class/backlight/nvidia_wmi_ec_backlight/brightness"
EOF

else
  echo "⚠️  Interfaz desconocida, creando regla genérica..."
  
  cat > "$UDEV_RULE" << 'EOF'
# Regla genérica para control de brillo
# Dar permisos a todas las interfaces detectadas

SUBSYSTEM=="backlight", RUN+="/bin/chmod 666 /sys/class/backlight/%k/brightness"
EOF
fi

echo "✅ Regla udev creada: $UDEV_RULE"
echo ""

# Recargar reglas udev
echo "🔄 Recargando reglas udev..."
udevadm control --reload-rules
udevadm trigger -c backlight
echo "✅ Reglas udev recargadas"

echo ""
echo "🎉 Configuración completada"
echo ""
echo "ℹ️  Para que los cambios de grupo surtan efecto, necesitas:"
echo "   1. Cerrar sesión y volver a entrar"
echo "   2. O reiniciar el sistema"
echo ""
echo "🔍 Después, verifica con:"
echo "   groups  # Debe incluir 'video'"
echo "   ls -l /sys/class/backlight/*/brightness  # Permisos correctos"