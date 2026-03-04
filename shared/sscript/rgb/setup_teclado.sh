#!/bin/bash

# --- CONFIGURACIÓN ---
BASE_DIR="$HOME/sscript"
REPO_NAME="acer-predator-turbo-and-rgb-keyboard-linux-module"
REPO_PATH="$HOME/$REPO_NAME"
MONITOR_SCRIPT="$BASE_DIR/teclado_rgb.sh"
DKMS_PATH="/usr/src/facer-1.0"

echo "🚀 Iniciando instalación INMORTAL y limpieza de sistema..."

# 1. Instalar dependencias necesarias
sudo apt update && sudo apt install -y dkms build-essential python3-pip

# 2. Preparar la carpeta oficial en el sistema (Blindaje)
echo "📂 Registrando código fuente en /usr/src..."
sudo mkdir -p "$DKMS_PATH"
if [ -d "$REPO_PATH" ]; then
    sudo cp -r "$REPO_PATH/"* "$DKMS_PATH/"
else
    echo "❌ Error: No se encontró la carpeta $REPO_PATH en el Home."
    exit 1
fi

# 3. Crear el archivo de configuración DKMS
echo "📝 Creando receta DKMS..."
sudo bash -c "cat > $DKMS_PATH/dkms.conf" <<EOF
PACKAGE_NAME="facer"
PACKAGE_VERSION="1.0"
BUILT_MODULE_NAME[0]="facer"
BUILT_MODULE_LOCATION[0]="src/"
DEST_MODULE_LOCATION[0]="/kernel/drivers/platform/x86/"
AUTOINSTALL="yes"
EOF

# 4. Activar el Blindaje (DKMS)
echo "🛡️  Activando blindaje ante actualizaciones..."
sudo dkms remove facer/1.0 --all 2>/dev/null
sudo dkms add -m facer -v 1.0
sudo dkms build -m facer -v 1.0
sudo dkms install -m facer -v 1.0 --force

# 5. Blacklist y Carga Automática
echo "🚫 Bloqueando drivers antiguos y configurando persistencia..."
echo "blacklist acer_nitro_gaming_driver2" | sudo tee /etc/modprobe.d/blacklist-nitro.conf
echo "install acer_nitro_gaming_driver2 /bin/false" | sudo tee -a /etc/modprobe.d/blacklist-nitro.conf
echo "facer" | sudo tee /etc/modules-load.d/facer.conf

# 6. Configurar el Servicio de Systemd
echo "🤖 Configurando el demonio nitro-rgb.service..."
sudo bash -c "cat > /etc/systemd/system/nitro-rgb.service" <<EOF
[Unit]
Description=Servicio de Control RGB Acer Nitro
After=multi-user.target

[Service]
Type=simple
User=root
ExecStart=/bin/bash $MONITOR_SCRIPT
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 7. Sincronizar y Limpiar
echo "🧠 Actualizando initramfs..."
sudo update-initramfs -u

echo "🧹 Limpiando archivos temporales del Home..."
rm -rf "$REPO_PATH"

# 8. Activar todo
sudo systemctl daemon-reload
sudo systemctl enable nitro-rgb.service
sudo systemctl restart nitro-rgb.service

echo "✅ ¡SISTEMA BLINDADO Y LIMPIO! Tu driver vive en /usr/src/facer-1.0"
echo "💡 Asegúrate de que $MONITOR_SCRIPT apunte a /usr/src/facer-1.0/facer_rgb.py"