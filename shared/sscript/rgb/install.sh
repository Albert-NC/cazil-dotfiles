#!/bin/bash
#
# install.sh — Instalador completo del driver Acer Nitro AN515-58 RGB
# Uso: sudo bash install.sh
#
# Instala: driver, carga en arranque, permisos udev, servicio de batería
#

set -e  # Detener ante cualquier error

# === Variables ===
INSTALL_DIR="/usr/local/lib/nitro-rgb"
SERVICE_FILE="/etc/systemd/system/nitro-rgb-battery.service"
MODULES_LOAD_CONF="/etc/modules-load.d/nitro-rgb.conf"
UDEV_RULES="/etc/udev/rules.d/99-nitro-rgb.rules"
MODULE_NAME="facer"

# === Verificación de privilegios ===
if [[ $EUID -ne 0 ]]; then
    echo "[-] Este script debe ejecutarse como root: sudo bash install.sh"
    exit 1
fi

echo "======================================"
echo "  Instalador Nitro RGB Driver v5.0   "
echo "======================================"
echo ""

# === 1. Verificar hardware WMI ===
echo "[1/9] Verificando hardware..."
WMI_GUID="7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56"
if [ ! -d "/sys/bus/wmi/devices/$WMI_GUID" ] && \
   [ ! -d "/sys/bus/wmi/devices/${WMI_GUID}-0" ]; then
    echo "[-] WMI bus no encontrado. Tu hardware puede no ser compatible."
    echo "    GUID esperado: $WMI_GUID"
    exit 1
fi
echo "[+] Hardware compatible detectado."

# === Verificar kernel mínimo (>= 5.4) ===
KERNEL_VER=$(uname -r | cut -d. -f1-2 | tr -d '.')
KERNEL_MAJOR=$(uname -r | cut -d. -f1)
KERNEL_MINOR=$(uname -r | cut -d. -f2 | cut -d- -f1)
if [ "$KERNEL_MAJOR" -lt 5 ] || { [ "$KERNEL_MAJOR" -eq 5 ] && [ "$KERNEL_MINOR" -lt 4 ]; }; then
    echo "[-] Kernel $(uname -r) demasiado antiguo. Se requiere >= 5.4."
    exit 1
fi
echo "[+] Kernel $(uname -r) OK."

# === Verificar arquitectura x86_64 ===
if [ "$(uname -m)" != "x86_64" ]; then
    echo "[-] Arquitectura $(uname -m) no soportada. Se requiere x86_64."
    exit 1
fi
echo "[+] Arquitectura x86_64 OK."

# === 2. Verificar archivos fuente necesarios ===
echo "[2/9] Verificando archivos fuente..."
SCRIPT_SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_SRC_DIR/src"
SCRIPTS_DIR="$SCRIPT_SRC_DIR/scripts"
REQUIRED_FILES=("$SRC_DIR/facer.c" "$SRC_DIR/Makefile" "$SRC_DIR/dkms.conf" "$SCRIPTS_DIR/nitro-rgb.py" "$SCRIPTS_DIR/facer-rgb.py")
MISSING=0
for f in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_SRC_DIR/$f" ]; then
        echo "    [-] Falta el archivo: $f"
        MISSING=1
    fi
done
[ $MISSING -eq 1 ] && echo "[-] Archivos faltantes. Descarga el paquete completo." && exit 1
echo "[+] Todos los archivos fuente presentes."

# === 3. Verificar Python 3 ===
echo "[3/9] Verificando Python 3..."
if ! command -v python3 &>/dev/null; then
    echo "[-] Python 3 no encontrado. El monitor de batería no funcionará."
    if [ -f /etc/arch-release ]; then
        echo "    Instala: pacman -S python"
    elif [ -f /etc/debian_version ]; then
        echo "    Instala: apt install python3"
    fi
    exit 1
fi
echo "[+] Python $(python3 --version) encontrado."

# === 4. Verificar dependencias de compilación ===
echo "[4/9] Verificando dependencias de compilación..."
if ! command -v make &>/dev/null || [ ! -d "/lib/modules/$(uname -r)/build" ]; then
    echo "[!] Faltan dependencias. Instálalas según tu distro:"
    if [ -f /etc/arch-release ]; then
        echo "    pacman -S base-devel linux-headers"
    elif [ -f /etc/debian_version ]; then
        echo "    apt install build-essential linux-headers-$(uname -r)"
    fi
    exit 1
fi
echo "[+] Dependencias OK."

# === 5. Descargar módulos conflictivos ===
echo "[5/9] Liberando módulos previos..."
lsmod | grep -q "^facer"    && rmmod facer    && echo "    [+] facer descargado."    || true
lsmod | grep -q "^acer_wmi" && rmmod acer_wmi && echo "    [+] acer_wmi descargado." || true

# Bloquear acer_wmi permanentemente para que no compita al reiniciar
ACER_BLACKLIST="/etc/modprobe.d/blacklist-acer-wmi.conf"
if [ ! -f "$ACER_BLACKLIST" ]; then
    echo "blacklist acer_wmi" > "$ACER_BLACKLIST"
    echo "install acer_wmi /bin/false" >> "$ACER_BLACKLIST"
    echo "    [+] acer_wmi bloqueado permanentemente."
fi

# === 6. Compilar el módulo ===
echo "[6/9] Compilando módulo..."
cd "$SRC_DIR"
if [[ "$(cat /proc/version 2>/dev/null)" == *"clang"* ]]; then
    make CC=clang LD=ld.lld
else
    make
fi
echo "[+] Compilación exitosa."

# === 7. Cargar el módulo y verificar con lsmod ===
echo "[7/9] Cargando módulo en el kernel..."
insmod ./facer.ko 2>/dev/null || insmod facer.ko 2>/dev/null
# Confirmar que realmente quedó cargado
sleep 1
if ! lsmod | grep -q "^facer"; then
    echo "[-] El módulo no aparece en lsmod. Revisa dmesg."
    dmesg | tail -5
    exit 1
fi
echo "[+] Módulo cargado y confirmado con lsmod."

# Esperar a que aparezcan los dispositivos /dev (hasta 10 segundos)
echo "    Esperando dispositivos /dev..."
for i in $(seq 1 10); do
    if [ -e /dev/acer-gkbbl ] && [ -e /dev/acer-gkbbl-static ]; then
        echo "[+] Dispositivos /dev listos."
        break
    fi
    sleep 1
    [ $i -eq 10 ] && echo "[!] Los dispositivos /dev no aparecieron. Revisa dmesg." && dmesg | tail -5
done

# === 8. Configurar DKMS ===
echo "[8/9] Configurando DKMS..."
DKMS_SRC="/usr/src/nitro-rgb-5.0"
if ! command -v dkms &>/dev/null; then
    echo "[!] DKMS no instalado. Instalando..."
    if [ -f /etc/arch-release ]; then
        pacman -S --needed --noconfirm dkms
    elif [ -f /etc/debian_version ]; then
        apt-get install -y dkms
    fi
fi

# Copiar fuentes al directorio de DKMS
mkdir -p "$DKMS_SRC"
cp "$SRC_DIR/facer.c"   "$DKMS_SRC/"
cp "$SRC_DIR/Makefile"  "$DKMS_SRC/"
cp "$SRC_DIR/dkms.conf" "$DKMS_SRC/"

# Registrar, compilar e instalar con DKMS
dkms remove  nitro-rgb/5.0 --all 2>/dev/null || true
dkms add     "$DKMS_SRC"
dkms build   nitro-rgb/5.0
dkms install nitro-rgb/5.0

# Verificar que DKMS installó correctamente
if ! dkms status nitro-rgb/5.0 2>/dev/null | grep -q "installed"; then
    echo "[-] DKMS no pudo instalar el módulo. Revisa: dkms status"
    dkms status
    exit 1
fi
echo "[+] DKMS verificado: el módulo se recompilará automáticamente al actualizar el kernel."

# === 7. Reglas udev (acceso sin sudo) ===
echo "[7/8] Configurando permisos de dispositivos..."
cat > "$UDEV_RULES" << 'EOF'
KERNEL=="acer-gkbbl",        SUBSYSTEM=="mem", MODE="0666"
KERNEL=="acer-gkbbl-static", SUBSYSTEM=="mem", MODE="0666"
EOF
udevadm control --reload-rules && udevadm trigger
# Configurar carga automática en arranque vía modules-load.d
echo "$MODULE_NAME" > "$MODULES_LOAD_CONF"
echo "[+] Módulo registrado para carga automática en arranque."

# === 8. Instalar scripts y autostart del monitor de batería ===
echo "[8/8] Instalando monitor de batería..."
mkdir -p "$INSTALL_DIR"
cp "$SCRIPTS_DIR/nitro-rgb.py"  "$INSTALL_DIR/"
cp "$SCRIPTS_DIR/facer-rgb.py"  "$INSTALL_DIR/battery_monitor.sh"
chmod +x "$INSTALL_DIR/battery_monitor.sh" "$INSTALL_DIR/nitro-rgb.py"

CURRENT_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
MONITOR_CMD="/bin/bash $INSTALL_DIR/battery_monitor.sh"

# --- Detectar init system ---
if pidof systemd &>/dev/null || [ "$(cat /proc/1/comm 2>/dev/null)" = "systemd" ]; then
    # ── systemd ─────────────────────────────────────────────────────
    echo "    [i] Init: systemd"
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Nitro RGB Battery Monitor
After=multi-user.target

[Service]
Type=simple
User=$CURRENT_USER
ExecStart=$MONITOR_CMD
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable nitro-rgb-battery.service
    systemctl start  nitro-rgb-battery.service
    echo "    [+] Servicio systemd habilitado."

elif command -v rc-service &>/dev/null; then
    # ── OpenRC ──────────────────────────────────────────────────
    echo "    [i] Init: OpenRC"
    OPENRC_SCRIPT="/etc/init.d/nitro-rgb-battery"
    cat > "$OPENRC_SCRIPT" << EOF
#!/sbin/openrc-run
description="Nitro RGB Battery Monitor"
command="$MONITOR_CMD"
command_background=true
pidfile="/run/nitro-rgb-battery.pid"
EOF
    chmod +x "$OPENRC_SCRIPT"
    rc-update add nitro-rgb-battery default
    rc-service nitro-rgb-battery start
    echo "    [+] Servicio OpenRC habilitado."

elif command -v sv &>/dev/null && [ -d /etc/runit/runsvdir ]; then
    # ── runit ────────────────────────────────────────────────────
    echo "    [i] Init: runit"
    RUNIT_DIR="/etc/runit/runsvdir/default/nitro-rgb-battery"
    mkdir -p "$RUNIT_DIR"
    printf '#!/bin/sh\nexec %s\n' "$MONITOR_CMD" > "$RUNIT_DIR/run"
    chmod +x "$RUNIT_DIR/run"
    echo "    [+] Servicio runit habilitado."

else
    # ── Fallback: cron @reboot ────────────────────────────────────────
    echo "    [i] Init: desconocido. Usando cron @reboot."
    CRON_ENTRY="@reboot $MONITOR_CMD >> /var/log/nitro-rgb-battery.log 2>&1 &"
    ( crontab -l 2>/dev/null | grep -v "nitro-rgb"; echo "$CRON_ENTRY" ) | crontab -
    echo "    [+] Entrada cron @reboot configurada."
fi

# === Resultado final ===
echo ""
echo "======================================"
echo "  ¡Instalación completada!"
echo "======================================"
echo ""
echo "  Dispositivos:"
ls -l /dev/acer-gkbbl* 2>/dev/null || echo "  [!] Los dispositivos aún no aparecen, espera un momento."
echo ""
echo "  Probar luces:"
echo "    python3 $INSTALL_DIR/nitro-rgb.py --all -cR 0 -cG 255 -cB 0"
echo ""
echo "  Para desinstalar: sudo bash uninstall.sh"
dmesg | grep nitro | tail -3