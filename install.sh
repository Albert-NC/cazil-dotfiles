#!/bin/bash
# ==============================================================================
# CAZIL DOTFILES — Instalador unificado
# Uso: bash install.sh [--auto] [--dotfiles-only] [--arch] [--debian]
#
# Estructura esperada:
#   cazil-dotfiles/
#   ├── install.sh           ← este archivo
#   ├── themes/
#   │   ├── 218/             ← tema cyberpunk (hypr, waybar, kitty, etc.)
#   │   └── ilidary/         ← tema ilidary
#   └── shared/
#       ├── fonts/           ← fuentes Nerd Font
#       ├── grub/            ← tema GRUB cyberpunk
#       ├── plymouth/        ← tema Plymouth
#       └── sscript/         ← scripts rgb, fans, brillo
# ==============================================================================

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$REPO_DIR/themes"
SHARED_DIR="$REPO_DIR/shared"
LOG_FILE="/tmp/cazil_install_$(date +%Y%m%d_%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

# Identificación robusta del usuario (para cuando se corre con sudo)
REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Asegurar que HOME apunte al usuario real, no a root
if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    export HOME="$REAL_HOME"
    log "${CYAN}[*] Instalando como root para el usuario: $REAL_USER ($REAL_HOME)${NC}"
fi

AUTO_INSTALL=false
DOTFILES_ONLY=false
DISTRO=""
THEME_NAME=""
THEME_DIR=""

log() { echo -e "$1" | tee -a "$LOG_FILE"; }

ask() {
    local prompt="$1"
    if [ "$AUTO_INSTALL" = true ]; then
        log "${CYAN}[AUTO] $prompt → SÍ${NC}"; return 0
    fi
    echo -ne "${YELLOW}[?] $prompt (s/n): ${NC}"
    read -r r
    [[ "${r,,}" =~ ^(s|si)$ ]]
}

is_installed_pac() { pacman -Qq "$1" &>/dev/null; }
is_installed_apt() { dpkg -l "$1" 2>/dev/null | grep -q "^ii"; }
command_exists()   { command -v "$1" &>/dev/null; }

# Funciones para instalar binarios desde GitHub releases (Debian)
# Uso: install_from_github <owner/repo> <asset-regex> <dest-name> [<extract-glob>]
install_gh_release() {
    local repo="$1" regex="$2" dest="$3" inner="${4:-}"
    local url
    url=$(curl -sf "https://api.github.com/repos/$repo/releases/latest" \
          | grep -o '"browser_download_url": *"[^"]*"' \
          | grep -oP 'https://[^"]+' \
          | grep -E "$regex" | head -1) || true
    if [ -z "$url" ]; then
        log "${YELLOW}  [!] No se pudo obtener release de $repo — saltando${NC}"
        return 1
    fi
    local tmp; tmp=$(mktemp -d)
    log "${CYAN}  [*] Descargando $(basename "$url")...${NC}"
    curl -L --progress-bar "$url" -o "$tmp/pkg" || { rm -rf "$tmp"; return 1; }
    case "$url" in
        *.tar.gz|*.tgz) tar -xzf "$tmp/pkg" -C "$tmp" ;;
        *.tar.xz)       tar -xJf "$tmp/pkg" -C "$tmp" ;;
        *.zip)          unzip -q "$tmp/pkg" -d "$tmp" ;;
        *.deb)          sudo dpkg -i "$tmp/pkg" && rm -rf "$tmp" && return 0 ;;
        *)              mv "$tmp/pkg" "$tmp/$dest" ;;
    esac
    local bin
    if [ -n "$inner" ]; then
        bin=$(find "$tmp" -name "$inner" -type f | head -1)
    else
        bin=$(find "$tmp" -maxdepth 2 -name "$dest" -type f | head -1)
        [ -z "$bin" ] && bin=$(find "$tmp" -maxdepth 2 -type f -perm /111 | head -1)
    fi
    if [ -z "$bin" ]; then
        log "${RED}  [!] No se encontró el binario '$dest' en el release de $repo${NC}"
        rm -rf "$tmp"; return 1
    fi
    sudo install -m755 "$bin" "/usr/local/bin/$dest"
    rm -rf "$tmp"
    log "${GREEN}  [\u2713] $dest instalado desde $repo${NC}"
}

install_fastfetch_deb() {
    command_exists fastfetch && return 0
    # Intentar .deb oficial primero
    install_gh_release "fastfetch-cli/fastfetch" "linux-amd64\.deb" fastfetch || \
    install_gh_release "fastfetch-cli/fastfetch" "linux_amd64\.deb" fastfetch || \
    { log "${YELLOW}  [!] fastfetch: intentar instalar manualmente desde https://github.com/fastfetch-cli/fastfetch/releases${NC}"; return 1; }
}

install_swww_deb() {
    command_exists swww && return 0
    install_gh_release "LGFae/swww" "x86_64.*linux.*musl.*\.tar" swww "swww" || \
    { log "${YELLOW}  [!] swww: instalar manualmente desde https://github.com/LGFae/swww/releases${NC}"; return 1; }
    # swww-daemon también está en el mismo release
    install_gh_release "LGFae/swww" "x86_64.*linux.*musl.*\.tar" swww-daemon "swww-daemon" || true
}

install_yazi_deb() {
    command_exists yazi && return 0
    install_gh_release "sxyazi/yazi" "x86_64.*linux.*musl.*\.zip" yazi "yazi" || \
    { log "${YELLOW}  [!] yazi: instalar manualmente desde https://github.com/sxyazi/yazi/releases${NC}"; return 1; }
}

# ==============================================================================
# PARSE ARGUMENTOS
# ==============================================================================
MODULE_CHOICE=""
for arg in "$@"; do
    case "$arg" in
        --auto)           AUTO_INSTALL=true ;;
        --dotfiles-only)  DOTFILES_ONLY=true ;;
        --arch)           DISTRO="arch" ;;
        --debian)         DISTRO="debian" ;;
        --module=*)       MODULE_CHOICE="${arg#--module=}" ;;
    esac
done

# ==============================================================================
# SUDO KEEPALIVE: pedir contraseña UNA sola vez y mantenerla
# ==============================================================================
if [ "$DOTFILES_ONLY" = false ]; then
    log "${CYAN}[*] Verificando permisos sudo...${NC}"
    sudo -v
    # Refrescar el ticket de sudo en background cada 4 min mientras el script corra
    while true; do sudo -n true; sleep 240; done &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null; exit' EXIT INT TERM
fi

# ==============================================================================
# BANNER
# ==============================================================================
clear
log "${CYAN}"
log "   ██████╗ █████╗ ███████╗██╗██╗     "
log "  ██╔════╝██╔══██╗╚══███╔╝██║██║     "
log "  ██║     ███████║  ███╔╝ ██║██║     "
log "  ██║     ██╔══██║ ███╔╝  ██║██║     "
log "  ╚██████╗██║  ██║███████╗██║███████╗"
log "   ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝"
log "          INSTALADOR v4.0"
log "${NC}"

# ==============================================================================
# 1. DETECTAR DISTRO
# ==============================================================================
if [ -z "$DISTRO" ]; then
    if [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    else
        log "${RED}[!] No se pudo detectar la distro. Usa --arch o --debian${NC}"
        exit 1
    fi
fi
log "${GREEN}[✓] Distro detectada: $DISTRO${NC}"

# ==============================================================================
# 2. DEFINIR TEMA POR DEFECTO
# ==============================================================================
THEME_NAME="218"
THEME_DIR="$THEMES_DIR/218"

if [ ! -d "$THEME_DIR" ]; then
    log "${RED}[!] No se encontró el tema en $THEME_DIR${NC}"
    exit 1
fi
log "${GREEN}[✓] Tema por defecto: $THEME_NAME → $THEME_DIR${NC}"

# ==============================================================================
# 3. MODO: ¿Solo dotfiles o instalación completa?
# ==============================================================================
if [ "$DOTFILES_ONLY" = false ] && [ "$AUTO_INSTALL" = false ]; then
    echo ""
    log "${MAGENTA}╔══════════════════════════════════════════════╗${NC}"
    log "${MAGENTA}║             MODO DE INSTALACIÓN              ║${NC}"
    log "${MAGENTA}╠══════════════════════════════════════════════╣${NC}"
    log "${MAGENTA}║  ${GREEN}[1]${NC} Instalar Todo Automáticamente           ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[2]${NC} Instalar Interactivo (Módulo a módulo)  ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[3]${NC} Reconfigurar / Modular (Dotfiles & Apps)${MAGENTA}║${NC}"
    log "${MAGENTA}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${YELLOW}  Modo [1/2/3]: ${NC}"
    read -r MODE_CHOICE
    case "$MODE_CHOICE" in
        1) AUTO_INSTALL=true ;;
        2) AUTO_INSTALL=false ;;
        3) DOTFILES_ONLY=true ;;
        *) AUTO_INSTALL=false ;;
    esac
fi

# ==============================================================================
# FUNCIONES DE INSTALACIÓN DE PAQUETES
# ==============================================================================
if [ "$DISTRO" = "arch" ]; then
    # ── Optimizar pacman una sola vez ────────────────────────────────
    _arch_optimize_pacman() {
        if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
            sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
            sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
            # Evitar duplicar ILoveCandy si ya existe
            grep -q "ILoveCandy" /etc/pacman.conf || \
                sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
            log "${GREEN}  [\u2713]   Pacman optimizado (descargas paralelas + ILoveCandy)${NC}"
        fi
        # Habilitar multilib si no está (necesario para lib32, Steam, Wine)
        if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
            echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
            log "${GREEN}  [\u2713]   Repositorio multilib habilitado${NC}"
        fi
        sudo pacman -Sy --noconfirm 2>/dev/null || true
    }

    # ── pac(): instala todos los paquetes en UNA sola llamada a pacman ──────
    pac() {
        local to_install=()
        for pkg in "$@"; do
            is_installed_pac "$pkg" || to_install+=("$pkg")
        done
        [ ${#to_install[@]} -eq 0 ] && return 0
        log "${CYAN}  [pacman] Instalando: ${to_install[*]}${NC}"
        sudo pacman -S --needed --noconfirm "${to_install[@]}" || true
    }

    # ── aur(): instala yay si no existe y usa yay ──────────────────────
    aur() {
        if ! command_exists yay; then
            log "${CYAN}[*] Instalando yay (AUR helper)...${NC}"
            local tmp; tmp=$(mktemp -d)
            # git y base-devel son requisitos para makepkg
            pac git base-devel
            git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
            (cd "$tmp/yay" && makepkg -si --noconfirm)
            rm -rf "$tmp"
        fi
        local to_install=()
        for pkg in "$@"; do
            is_installed_pac "$pkg" || to_install+=("$pkg")
        done
        [ ${#to_install[@]} -eq 0 ] && return 0
        log "${CYAN}  [yay/AUR] Instalando: ${to_install[*]}${NC}"
        yay -S --needed --noconfirm "${to_install[@]}" || true
    }
    install_pkgs() {
        log "${CYAN}[*] Instalando paquetes del sistema (Arch Linux)...${NC}"

        # Optimizar pacman primero
        _arch_optimize_pacman

        # ── BOOTSTRAP: Herramientas esenciales para Arch minimalista ────────────
        # Sin esto, muchas cosas del script fallarán (sin git, curl, sudo, etc.)
        log "${CYAN}[*] Instalando herramientas base del sistema...${NC}"
        pac base-devel git curl wget unzip tar openssh \
            sudo polkit networkmanager network-manager-applet \
            grub efibootmgr os-prober \
            pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
            xdg-user-dirs xdg-utils xdg-desktop-portal \
            mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader \
            noto-fonts noto-fonts-emoji ttf-dejavu
        sudo systemctl enable NetworkManager 2>/dev/null || true

        # ── GRUB Splash ──────────────────────────────────────────────────────────
        ask "¿Configurar GRUB para tapar logo del fabricante?" && {
            if [ -f /etc/default/grub ]; then
                # GFXMODE si no existe
                grep -q "^GRUB_GFXMODE=" /etc/default/grub || \
                    echo 'GRUB_GFXMODE=1920x1080,auto' | sudo tee -a /etc/default/grub

                # GFXPAYLOAD si no existe
                grep -q "^GRUB_GFXPAYLOAD_LINUX=" /etc/default/grub || \
                    echo 'GRUB_GFXPAYLOAD_LINUX=keep' | sudo tee -a /etc/default/grub

                # agregar flags al cmdline si no están
                grep -q "vt.global_cursor_default=0" /etc/default/grub || \
                    sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 loglevel=3 vt.global_cursor_default=0"/' \
                    /etc/default/grub

                sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
                log "${GREEN}[✓] GRUB configurado para splash sin logo fabricante${NC}"
            fi
        }
        # Habilitar Pipewire como servicio de usuario AHORA para todo lo demás
        systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
        log "${GREEN}  [\u2713]   Bootstrap base completado${NC}"

        # ── Microcode ────────────────────────────────────────────────────────────
        ask "¿Instalar parches de Microcode (Intel/AMD)?" && {
            if grep -q "vendor_id.*GenuineIntel" /proc/cpuinfo; then
                pac intel-ucode
            elif grep -q "vendor_id.*AuthenticAMD" /proc/cpuinfo; then
                pac amd-ucode
            fi
            if [ -f /etc/default/grub ]; then sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null; fi
        }

        # ── Hyprland y ecosistema Wayland ────────────────────────────────────────
        ask "¿Instalar Hyprland y ecosistema Wayland?" && {
            pac hyprland hyprpaper hyprlock hypridle hyprpolkitagent \
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
                wl-clipboard grim slurp \
                cliphist swww libnotify
        }

        # ── Waybar ───────────────────────────────────────────────────────────────
        ask "¿Instalar Waybar?" && pac waybar


        # ── Kitty ────────────────────────────────────────────────────────────────
        ask "¿Instalar Kitty Terminal?" && pac kitty

        # ── Lanzadores ───────────────────────────────────────────────────────────
        ask "¿Instalar lanzadores (Rofi + Wofi)?" && pac rofi-wayland wofi

        # ── Fuentes Nerd Font y emojis ───────────────────────────────────────────
        ask "¿Instalar fuentes (Nerd Fonts + CJK + Emojis)?" && {
            pac noto-fonts-cjk
            aur ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-mono
        }

        # ── Audio (Pipewire ya instalado en bootstrap, aquí solo extras) ─────────
        ask "¿Instalar control de audio (pavucontrol + easyeffects)?" && {
            pac pavucontrol easyeffects
            # Fix GRUB para HDA Intel (evita clicks/cortes)
            if [ -f /etc/default/grub ] && ! grep -q "snd_hda_intel.power_save=0" /etc/default/grub; then
                sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 snd_hda_intel.power_save=0"/' /etc/default/grub
                sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
                log "${GREEN}  [\u2713]   GRUB: snd_hda_intel.power_save=0 añadido${NC}"
            fi
        }

        # ── Brillo ───────────────────────────────────────────────────────────────
        ask "¿Instalar control de brillo (brightnessctl)?" && {
            pac brightnessctl
            if [ -f /etc/default/grub ] && ! grep -q "acpi_backlight=video" /etc/default/grub; then
                sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 acpi_backlight=video"/' /etc/default/grub
                sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
                log "${GREEN}  [\u2713]   GRUB: acpi_backlight=video añadido${NC}"
            fi
            sudo tee /etc/udev/rules.d/99-backlight.rules > /dev/null << 'EOF'
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod 666 /sys/class/backlight/%k/brightness"
EOF
            sudo udevadm control --reload-rules && sudo udevadm trigger
        }

        # ── Notificaciones ───────────────────────────────────────────────────────
        ask "¿Instalar notificaciones (Mako)?" && pac mako libnotify

        # ── Bluetooth ────────────────────────────────────────────────────────────
        ask "¿Instalar Bluetooth?" && {
            pac bluez bluez-utils blueman
            sudo systemctl enable bluetooth || true
        }

        # ── Energía / CPU ────────────────────────────────────────────────────────
        ask "¿Instalar gestión de energía (auto-cpufreq + PowerTOP)?" && {
            pac powertop
            aur auto-cpufreq
            sudo systemctl enable --now auto-cpufreq 2>/dev/null || true
            # NOTA: TLP se omite intencionalmente porque conflictúa con auto-cpufreq.
            # Si prefieres TLP: pac tlp tlp-rdw && sudo systemctl enable tlp
            #   pero desactiva auto-cpufreq primero.
            # PowerTOP auto-tune al arrancar
            if [ -f "$SHARED_DIR/sscript/powertop-autotune.service" ]; then
                sudo cp "$SHARED_DIR/sscript/powertop-autotune.service" /etc/systemd/system/
                sudo systemctl daemon-reload
                sudo systemctl enable powertop-autotune.service
                log "${GREEN}  [✓]   PowerTOP auto-tune habilitado al arranque${NC}"
            fi
        }

        # ── Límite de carga de batería ──────────────────────────────────────────
        ask "¿Configurar límite de carga de batería (Acer Nitro)?" && {
            pac linux-headers dkms
            aur acer-wmi-battery-dkms
        }

        # ── Gestos, night-light, auto-mount ──────────────────────────────────────
        ask "¿Instalar utilidades de laptop (gestos + night-light + auto-mount)?" && {
            pac gammastep udiskie libinput-gestures
            sudo usermod -aG input "$REAL_USER" || true
        }

        # ── Control de Ventiladores (Acer Nitro) ──────────────────────────────────
        ask "¿Habilitar control de ventiladores (Acer Nitro)?" && {
            if [ -f /etc/default/grub ] && ! grep -q "ec_sys.write_support=1" /etc/default/grub; then
                sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 ec_sys.write_support=1"/' /etc/default/grub
                sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
                log "${GREEN}  [\u2713]   GRUB: ec_sys.write_support=1 añadido para ventiladores${NC}"
            else
                log "${CYAN}  [~]   GRUB: ec_sys.write_support=1 ya configurado${NC}"
            fi
            # Cargar módulo ec_sys en el arranque
            echo "ec_sys" | sudo tee /etc/modules-load.d/ec_sys.conf > /dev/null
        }

        # ── Nitro RGB ─────────────────────────────────────────────────────────────
        ask "¿Instalar soporte RGB Acer Nitro (facer)?" && {
            local RGB_SRC="$SHARED_DIR/sscript/rgb"
            local DKMS_DEST="/usr/src/facer-1.0"
            if [ -d "$RGB_SRC" ]; then
                pac dkms linux-headers
                sudo mkdir -p "$DKMS_DEST"
                sudo cp "$RGB_SRC/facer.c" "$RGB_SRC/Makefile" "$RGB_SRC/dkms.conf" "$DKMS_DEST/"
                sudo dkms remove facer/1.0 --all 2>/dev/null || true
                sudo dkms add -m facer -v 1.0
                sudo dkms build -m facer -v 1.0
                sudo dkms install -m facer -v 1.0
                echo "facer" | sudo tee /etc/modules-load.d/facer.conf > /dev/null
                sudo tee /etc/udev/rules.d/99-nitro-rgb.rules > /dev/null << 'EOF'
KERNEL=="acer-gkbbl",        SUBSYSTEM=="mem", MODE="0666"
KERNEL=="acer-gkbbl-static", SUBSYSTEM=="mem", MODE="0666"
EOF
                sudo udevadm control --reload-rules && sudo udevadm trigger
                log "${GREEN}  [\u2713]   Nitro RGB (facer) instalado vía DKMS${NC}"
            else
                log "${RED}  [!] Código fuente Nitro RGB no encontrado en $RGB_SRC${NC}"
            fi
        }

        # ── Herramientas esenciales de shell ─────────────────────────────────────
        ask "¿Instalar ZSH + plugins + Starship + Fastfetch?" && {
            pac zsh zsh-autosuggestions zsh-syntax-highlighting starship fastfetch tmux fzf zoxide
            aur zsh-fzf-tab-git
            chsh -s /usr/bin/zsh "$REAL_USER" 2>/dev/null || true
        }

        # ── swww (ya en el bloque Wayland, pero por si se saltó) ─────────────────
        command_exists swww || pac swww 2>/dev/null || aur swww

        # ── Multimedia playerctl ──────────────────────────────────────────────────
        ask "¿Instalar playerctl (control multimedia)?" && pac playerctl imv mpv

        # ── Gestión de archivos ───────────────────────────────────────────────────
        ask "¿Instalar Thunar (archivos GUI)?" && pac thunar gvfs tumbler thunar-volman
        ask "¿Instalar Yazi (archivos terminal)?" && \
            pac yazi imagemagick ffmpegthumbnailer poppler fzf zoxide

        # ── Portapapeles avanzado ────────────────────────────────────────────────
        # cliphist ya incluido en bloque Wayland

        # ── Seguridad ────────────────────────────────────────────────────────────
        ask "¿Instalar herramientas de seguridad (UFW, USBGuard)?" && {
            pac ufw usbguard rkhunter apparmor macchanger
            sudo systemctl enable --now ufw || true
            log "${GREEN}  [\u2713]   Seguridad básica activa (recuerda: usbguard genera reglas con tus USBs al inicio)${NC}"
        }

        # ── OCR ───────────────────────────────────────────────────────────────────
        ask "¿Instalar Tesseract OCR?" && pac tesseract tesseract-data-spa

        # ── PDF ───────────────────────────────────────────────────────────────────
        ask "¿Instalar herramientas PDF (ghostscript, qpdf, imagemagick)?" && \
            pac ghostscript qpdf imagemagick

        # ── Impresoras ────────────────────────────────────────────────────────────
        ask "¿Instalar soporte para impresoras (CUPS)?" && {
            pac cups cups-pdf system-config-printer ghostscript
            sudo systemctl enable --now cups || true
            ask "  ¿Instalar Avahi (mDNS para impresoras WiFi)?" && {
                pac avahi nss-mdns
                sudo systemctl enable --now avahi-daemon || true
                sudo sed -i 's/^hosts: .*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' /etc/nsswitch.conf
            }
            if ask "  ¿Impresora Brother?"; then
                echo -ne "${YELLOW}  Modelo (ej: dcpt520w): ${NC}"
                read -r B_MODEL; B_MODEL=${B_MODEL:-dcpt520w}
                aur "brother-$B_MODEL" brscan4 sane
            fi
        }

        # ── Navegadores ───────────────────────────────────────────────────────────
        ask "¿Instalar Firefox?" && pac firefox
        ask "¿Instalar Flatpak (necesario para VSCode, Brave, VLC)?" && {
            pac flatpak
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
        }
        ask "¿Instalar Visual Studio Code (Flatpak)?" && \
            flatpak install -y flathub com.visualstudio.code || true
        ask "¿Instalar Brave (Flatpak)?" && \
            flatpak install -y flathub com.brave.Browser || true

        # ── Contraseñas / Notas ───────────────────────────────────────────────────
        ask "¿Instalar KeePassXC?" && pac keepassxc
        ask "¿Instalar Joplin Desktop?" && aur joplin-desktop

        # ── Wlogout ───────────────────────────────────────────────────────────────
        ask "¿Instalar wlogout (menú de apagado)?" && pac wlogout

        # ── Visor PDF seguro ─────────────────────────────────────────────────────
        ask "¿Instalar visor PDF seguro (Zathura + Firejail)?" && \
            pac zathura zathura-pdf-mupdf firejail

        # ── Display Manager (Ly) ──────────────────────────────────────────────────
        ask "¿Instalar Ly (display manager con efecto Matrix)?" && {
            pac ly 2>/dev/null || aur ly
            # Deshabilitar otros posibles gestores de sesión para evitar conflictos
            for dm in gdm sddm lightdm lxdm slim; do
                sudo systemctl disable "$dm" 2>/dev/null || true
            done
            sudo systemctl disable display-manager.service 2>/dev/null || true
            
            sudo mkdir -p /etc/ly
            [ -f "$SHARED_DIR/config/ly/config.ini" ] && \
                sudo cp "$SHARED_DIR/config/ly/config.ini" /etc/ly/config.ini
            
            sudo systemctl enable ly.service || true
            log "${GREEN}  [✓]   Ly habilitado como gestor de sesión por defecto.${NC}"
        }

        # ── NVIDIA ────────────────────────────────────────────────────────────────
        ask "¿Instalar drivers NVIDIA (Optimus/híbrido)?" && install_nvidia_arch

        # ── Docker ────────────────────────────────────────────────────────────────
        ask "¿Instalar Docker?" && {
            pac docker docker-compose
            # Deshabilitado por defecto (se activa con: sudo systemctl start docker)
            sudo systemctl disable docker || true
            sudo usermod -aG docker "$REAL_USER" || true
            log "${YELLOW}  [!]   Docker instalado pero DESHABILITADO por defecto (usa: sudo systemctl start docker)${NC}"
        }

        # ── Virtualización ────────────────────────────────────────────────────────
        ask "¿Instalar Virtualización (QEMU/KVM/Virt-Manager)?" && {
            pac qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat edk2-ovmf
            sudo systemctl disable libvirtd || true
            sudo usermod -aG libvirt "$REAL_USER" || true
            sudo usermod -aG kvm "$REAL_USER" 2>/dev/null || true
            log "${GREEN}  [\u2713]   Virtualización instalada (inicia con: sudo systemctl start libvirtd)${NC}"
        }

        # ── WinApps ───────────────────────────────────────────────────────────────
        ask "¿Instalar soporte WinApps (apps Windows en Linux)?" && {
            pac freerdp libvirt virt-manager
            local WA_DIR="$HOME/.local/share/winapps"
            if [ ! -d "$WA_DIR" ]; then
                git clone https://github.com/winapps-org/winapps.git "$WA_DIR"
                (cd "$WA_DIR" && ./setup.sh --user) || true
            fi
        }

        # ── DNS Seguro / MAC aleatoria / Hardening ────────────────────────────────
        ask "¿Configurar DNS Seguro (DoT / Cloudflare)?"     && bash "$SHARED_DIR/sscript/config-dns-seguro.sh"
        ask "¿Activar MAC Aleatoria (modo fantasma)?"         && bash "$SHARED_DIR/sscript/mac-random.sh"
        ask "¿Aplicar Hardening del Kernel (sysctl)?"         && bash "$SHARED_DIR/sscript/config-hardening.sh"

        # ── Timeshift ─────────────────────────────────────────────────────────────
        ask "¿Instalar Timeshift (backups del sistema)?" && pac timeshift

        log "${GREEN}[✓] Paquetes Arch instalados correctamente.${NC}"
    }

    install_nvidia_arch() {
        if ! lspci | grep -qi nvidia; then
            log "${YELLOW}[!] No se detectó GPU NVIDIA. Saltando.${NC}"; return
        fi
        # Usar versión DKMS para que se reconstruya con cada cambio de kernel
        pac nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils

        sudo localectl set-x11-keymap latam
        log "${GREEN}[✓] Teclado configurado en Latinoamericano (sistema).${NC}"

        # ── 1. NVIDIA / Hardware ──────────────────────────────────────────────────
        # Nouveau y nvidia no pueden coexistir. Si nouveau carga primero, el driver
        # NVIDIA falla silenciosamente y la pantalla queda negra.
        log "${CYAN}[*] Blacklisting nouveau...${NC}"
        sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null << 'EOF'
# Blacklist del driver open-source nouveau para usar NVIDIA propietario
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
alias nouveau off
alias lbm-nouveau off
EOF
        log "${GREEN}  [✓]   nouveau blacklisted → /etc/modprobe.d/blacklist-nouveau.conf${NC}"

        # ── 2. GRUB: QUITAR nomodeset, AÑADIR nvidia-drm.modeset=1 ──────────────
        # 'nomodeset' desactiva KMS — con NVIDIA propietario esto rompe Wayland.
        # 'nvidia-drm.modeset=1' es requerido para funcionar en Wayland/Hyprland.
        if [ -f /etc/default/grub ]; then
            # Quitar nomodeset si existe
            sudo sed -i 's/\bnomodeset\b//g' /etc/default/grub
            # Añadir nvidia-drm.modeset=1 si no está ya
            if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
                sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 nvidia-drm.modeset=1"/' \
                    /etc/default/grub
                log "${GREEN}  [✓]   GRUB: nomodeset eliminado + nvidia-drm.modeset=1 añadido${NC}"
            else
                log "${CYAN}  [~]   GRUB: nvidia-drm.modeset ya configurado${NC}"
            fi
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
        fi

        # ── 3. MKINITCPIO: asegurar HOOKS de NVIDIA ──────────────────────────────
        # Sin los hooks correctos, nvidia no se carga en el initramfs
        # y el sistema arranca con pantalla negra.
        if [ -f /etc/mkinitcpio.conf ]; then
            if ! grep -q "nvidia nvidia_modeset nvidia_uvm nvidia_drm" /etc/mkinitcpio.conf; then
                # Añadir módulos NVIDIA al array MODULES
                sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
                    /etc/mkinitcpio.conf
                # Limpiar espacios extra si MODULES estaba vacío
                sudo sed -i 's/MODULES=(  /MODULES=(/' /etc/mkinitcpio.conf
                log "${GREEN}  [✓]   mkinitcpio: módulos NVIDIA añadidos a MODULES${NC}"
            else
                log "${CYAN}  [~]   mkinitcpio: módulos NVIDIA ya presentes${NC}"
            fi
        fi

        # ── 4. envycontrol ───────────────────────────────────────────────────────
        if [ -f "$SHARED_DIR/sscript/gpu/envycontrol.py" ]; then
            sudo cp "$SHARED_DIR/sscript/gpu/envycontrol.py" "/usr/local/bin/envycontrol"
            sudo chmod +x "/usr/local/bin/envycontrol"
            log "${GREEN}[✓] envycontrol instalado desde source local.${NC}"
        else
            log "${YELLOW}[!] Source de envycontrol no encontrado. Saltando.${NC}"
        fi

        echo ""
        log "${CYAN}Modo GPU NVIDIA:${NC}"
        log "  [h] hybrid (NVIDIA bajo demanda)  [i] integrated  [n] nvidia"
        echo -ne "  Modo [h/i/n]: "
        local gmode; [ "$AUTO_INSTALL" = true ] && gmode="i" || read -r gmode
        case "$gmode" in
            i) sudo envycontrol -s integrated ;;
            n) sudo envycontrol -s nvidia ;;
            h) sudo envycontrol -s hybrid --force-comp --rtd3 ;;
            *) sudo envycontrol -s integrated ;;
        esac

        # ── 5. RTD3 Power Management ──────────────────────────────────────────────
        if ! grep -q "NVreg_DynamicPowerManagement=0x02" /etc/modprobe.d/nvidia.conf 2>/dev/null; then
            echo "options nvidia NVreg_DynamicPowerManagement=0x02" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
        fi
        sudo systemctl enable nvidia-persistenced.service 2>/dev/null || true

        # ── 6. REBUILD INITRAMFS con todo configurado ────────────────────────────
        log "${CYAN}[*] Rebuilding initramfs (mkinitcpio -P)...${NC}"
        sudo mkinitcpio -P
        log "${GREEN}[✓] NVIDIA configurado: blacklist nouveau + nomodeset limpio + RTD3 + KMS.${NC}"
        log "${YELLOW}[!] IMPORTANTE: Reinicia el sistema para que los cambios de GRUB surtan efecto.${NC}"
    }

else
    # ── Función pac() para Debian: acumula y hace UNA sola llamada a apt ────────
    # Si se le pasa un solo paquete, instala directo.
    # Si se llama repetidamente desde install_pkgs, se agrupan mediante apt_batch.
    _APT_BATCH=()
    apt_flush() {
        [ ${#_APT_BATCH[@]} -eq 0 ] && return 0
        log "${CYAN}  [apt] Instalando: ${_APT_BATCH[*]}${NC}"
        sudo apt-get install -y "${_APT_BATCH[@]}" 2>&1 | grep -v "^Leyendo\|^Creando\|^Procesando" || true
        _APT_BATCH=()
    }
    pac() {
        for pkg in "$@"; do
            is_installed_apt "$pkg" && continue
            _APT_BATCH+=("$pkg")
        done
    }

    install_pkgs() {
        log "${CYAN}[*] Instalando paquetes del sistema (Debian/Ubuntu)...${NC}"
        # Actualizar índice una sola vez al inicio
        log "${CYAN}[*] Actualizando índice de paquetes (apt update)...${NC}"
        sudo apt-get update -qq

        # ── BOOTSTRAP: Herramientas esenciales para Debian minimalista ────────────
        log "${CYAN}[*] Instalando herramientas base del sistema...${NC}"
        sudo apt-get install -y curl wget git build-essential sudo policykit-1 \
            network-manager xdg-user-dirs xdg-utils ca-certificates gnupg \
            pipewire pipewire-pulse wireplumber \
            fonts-noto fonts-noto-color-emoji 2>/dev/null || true
        sudo systemctl enable NetworkManager 2>/dev/null || true
        log "${GREEN}  [\u2713]   Bootstrap base Debian completado${NC}"

        ask "¿Instalar Hyprland?" && {
            if ! command_exists hyprland; then
                sudo apt-get install -y hyprland hyprpaper hyprlock hypridle 2>/dev/null || \
                    log "${YELLOW}[!] Hyprland no disponible en repos. Instala manualmente.${NC}"
            fi
        }
        ask "¿Instalar Waybar?"                  && pac waybar
        ask "¿Instalar Kitty?"                   && pac kitty
        ask "¿Instalar lanzadores?"              && pac rofi wofi
        ask "¿Instalar audio (Pipewire)?"        && pac pipewire pipewire-pulse wireplumber pavucontrol \
                                                        xdg-desktop-portal-hyprland xdg-portal-gtk 2>/dev/null || \
                                                    pac pipewire pipewire-pulse wireplumber pavucontrol
        ask "¿Instalar brillo?"                  && pac brightnessctl
        ask "¿Instalar notificaciones (Mako)?"   && pac mako-notifier libnotify-bin
        ask "¿Instalar Bluetooth?"               && { pac bluez blueman; sudo systemctl enable bluetooth || true; }
        ask "¿Instalar utilidades Wayland?"      && pac wl-clipboard xdg-user-dirs xdg-utils flatpak grim slurp
        ask "¿Instalar Fastfetch?"               && { pac fastfetch 2>/dev/null || install_fastfetch_deb; } || true
        ask "¿Instalar tmux?"                    && pac tmux
        ask "¿Instalar swww (fondos de pantalla)?" && install_swww_deb
        ask "¿Instalar Starship?"                && {
            curl -sS https://starship.rs/install.sh | sudo sh -s -- --yes || true
        }
        ask "¿Instalar ZSH + plugins?"           && {
            pac zsh zsh-autosuggestions zsh-syntax-highlighting
            # Cambiar shell por defecto a zsh
            command_exists zsh && (chsh -s "$(command -v zsh)" "$REAL_USER" 2>/dev/null || true)
        }
        ask "¿Instalar playerctl (control multimedia)?" && pac playerctl
        ask "¿Instalar Thunar?"                  && pac thunar gvfs tumbler
        ask "¿Instalar Yazi?"                    && { pac yazi 2>/dev/null || install_yazi_deb; } || true
        ask "¿Instalar Soporte para Impresoras?" && {
            pac cups cups-pdf system-config-printer hplip
            sudo systemctl enable --now cups || true
        }
        ask "¿Instalar multimedia?"              && pac mpv vlc
        ask "¿Instalar KeePassXC?"               && pac keepassxc
        ask "¿Instalar herramientas PDF?"        && pac ghostscript qpdf imagemagick poppler-utils
        ask "¿Instalar Tesseract OCR?"           && pac tesseract-ocr tesseract-ocr-spa
        ask "¿Instalar Docker?"                  && {
            pac docker.io docker-compose
            sudo systemctl disable docker || true
            sudo usermod -aG docker "$REAL_USER" || true
            log "${YELLOW}  [!]   Docker instalado pero DESHABILITADO por defecto (usa: sudo systemctl start docker)${NC}"
        }
        ask "¿Instalar Virtualización (QEMU/KVM)?" && {
            pac qemu-system libvirt-daemon-system libvirt-clients bridge-utils virt-manager
            sudo systemctl enable --now libvirtd || true
            sudo usermod -aG libvirt "$REAL_USER" || true
            sudo usermod -aG kvm "$REAL_USER" 2>/dev/null || true
        }
        ask "¿Instalar herramientas de Seguridad?" && {
            pac ufw usbguard rkhunter macchanger
            sudo systemctl enable --now ufw || true
        }
        ask "¿Instalar Ly (Display Manager)?" && {
            pac ly 2>/dev/null || log "${YELLOW}[!] Ly no disponible en repos de Debian. Instala manualmente.${NC}"
            # Deshabilitar otros gestores para evitar conflictos
            for dm in gdm sddm lightdm lxdm slim; do
                sudo systemctl disable "$dm" 2>/dev/null || true
            done
            sudo systemctl disable display-manager.service 2>/dev/null || true
            sudo systemctl enable ly.service 2>/dev/null || true
            log "${GREEN}  [✓]   Ly habilitado como gestor de sesión.${NC}"
        }

        # Instalar todos los paquetes acumulados de una vez
        apt_flush
        log "${GREEN}[✓] Paquetes instalados.${NC}"
    }
fi

# ==============================================================================
# DEPLOY DE DOTFILES (tema + shared)
# ==============================================================================
_put() {
    local from="$1" to="$2"
    [ ! -e "$from" ] && { log "${YELLOW}  [skip] $(basename "$from") (no existe)${NC}"; return 0; }
    if [ -e "$to" ] && [ ! -L "$to" ]; then
        local bak; bak="${to}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$to" "$bak" && log "${YELLOW}  [bak]  $(basename "$bak")${NC}"
    fi
    [ -L "$to" ] && rm -f "$to"
    mkdir -p "$(dirname "$to")"
    if [ -d "$from" ]; then cp -r "$from" "$to"; else cp "$from" "$to"; fi
    
    # Asegurar propiedad del usuario real si corre como root/sudo
    if [ "$EUID" -eq 0 ] && [ -n "${REAL_USER:-}" ]; then
        chown -R "$REAL_USER:$REAL_USER" "$to"
    fi
    log "${GREEN}  [✓]   $to${NC}"
}

deploy_firefox() {
    log ""
    log "${CYAN}════════════════════════════════════════════════${NC}"
    log "${CYAN}     CONFIGURANDO FIREFOX (user.js + Profil)    ${NC}"
    log "${CYAN}════════════════════════════════════════════════${NC}"
    
    if command_exists firefox; then
        log "${CYAN}[*] Forzando inicio headless para generar perfil...${NC}"
        # Intentar generar perfil como el usuario real
        sudo -u "$REAL_USER" firefox --headless --createprofile "default" >/dev/null 2>&1 || true
        timeout 2 sudo -u "$REAL_USER" firefox --headless >/dev/null 2>&1 || true

        local FF_PROF_DIR; FF_PROF_DIR=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" | head -n 1)
        if [ -z "$FF_PROF_DIR" ]; then
            FF_PROF_DIR=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default" | head -n 1)
        fi
        if [ -n "$FF_PROF_DIR" ]; then
            log "${CYAN}  [*]   Descargando última versión de Arkenfox user.js...${NC}"
            if curl -sSL "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js" -o "$FF_PROF_DIR/user.js"; then
                # Appending custom overrides (Maintain sessions/cookies)
                cat >> "$FF_PROF_DIR/user.js" << 'EOF'

// ── CAZIL OVERRIDES (Mantener sesiones y cookies) ────────────────────────────
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.sessions", false);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
EOF
                [ "$EUID" -eq 0 ] && [ -n "$REAL_USER" ] && chown "$REAL_USER:$REAL_USER" "$FF_PROF_DIR/user.js"
                log "${GREEN}  [✓]   user.js (Arkenfox + Cazil Overrides) aplicado al perfil: $(basename "$FF_PROF_DIR")${NC}"
            else
                log "${RED}  [!]   Error al descargar user.js de GitHub.${NC}"
            fi
        else
            log "${YELLOW}  [!]   No se detectó el directorio del perfil de Firefox para $REAL_USER.${NC}"
        fi
    else
        log "${RED}  [!]   Firefox no está instalado.${NC}"
    fi

    log ""
    log "${GREEN}  ══ Configuración de Firefox Finalizada ══${NC}"
    log ""
}

# ==============================================================================
# MODULOS DE INSTALACIÓN INDIVIDUAL
# ==============================================================================
install_module_kitty() {
    log "${CYAN}[*] Instalando Ecosistema Kitty (Terminal + ZSH + Fastfetch + Starship)...${NC}"
    
    # ── 1. Instalación de Paquetes ──────────────────────────────────────
    if [ "$DISTRO" = "arch" ]; then
        pac kitty zsh starship fastfetch fzf zoxide
    else
        # Fastfetch PPA para Debian
        log "${CYAN}[*] Añadiendo PPA de Fastfetch para Debian...${NC}"
        sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
        sudo apt-get update
        sudo apt-get install -y kitty zsh fastfetch fzf zoxide
        
        # Starship (usar script oficial en Debian para mayor compatibilidad)
        if ! command_exists starship; then
            log "${CYAN}[*] Instalando Starship vía script oficial...${NC}"
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
    fi

    # ── 2. Cambiar shell a ZSH ──────────────────────────────────────────
    if [ -n "$REAL_USER" ]; then
        log "${CYAN}[*] Activando ZSH para $REAL_USER...${NC}"
        sudo chsh -s /usr/bin/zsh "$REAL_USER" 2>/dev/null || true
    fi

    # ── 3. Desplegar Configuraciones y Assets ───────────────────────────
    log "${CYAN}[*] Desplegando configuraciones y assets...${NC}"
    
    # Kitty
    _put "$THEME_DIR/kitty" "$HOME/.config/kitty"
    
    # Fastfetch (Config + Logo Asset)
    mkdir -p "$HOME/.config/fastfetch/assets"
    _put "$THEME_DIR/fastfetch" "$HOME/.config/fastfetch"
    
    local LOGO_SRC="$SHARED_DIR/assets/logos/cazil_logo_transparente.png"
    if [ -f "$LOGO_SRC" ]; then
        cp "$LOGO_SRC" "$HOME/.config/fastfetch/assets/cazil_logo_transparente.png"
        log "${GREEN}  [✓]   Logo Fastfetch desplegado${NC}"
    fi

    # Starship
    if [ -f "$THEME_DIR/starship/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        cp "$THEME_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
    fi

    # .zshrc
    if [ -f "$SHARED_DIR/config/zsh/.zshrc" ]; then
        cp "$SHARED_DIR/config/zsh/.zshrc" "$HOME/.zshrc"
    fi

    log "${GREEN}[✓] Ecosistema Kitty instalado y configurado.${NC}"
}

install_module_firefox() {
    log "${CYAN}[*] Instalando Firefox...${NC}"
    if [ "$DISTRO" = "arch" ]; then
        pac firefox
    else
        sudo apt-get install -y firefox || log "${RED}Considera instalar desde PPA o Snap si usas Debian/Ubuntu.${NC}"
    fi
    deploy_firefox
    log "${GREEN}[✓] Módulo Firefox instalado.${NC}"
}

install_module_work_env() {
    log "${CYAN}[*] Instalando Entorno de Virtualización (QEMU/KVM)...${NC}"
    if [ "$DISTRO" = "arch" ]; then
        pac qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat edk2-ovmf
    else
        sudo apt-get install -y qemu-system libvirt-daemon-system libvirt-clients bridge-utils virt-manager
    fi

    sudo systemctl enable --now libvirtd
    sudo usermod -aG libvirt "$REAL_USER"
    sudo usermod -aG kvm "$REAL_USER" 2>/dev/null || true
    
    # ── Kali Linux ISO Download ──────────────────────────────────────
    log "${CYAN}[*] Configurando repositorio de ISOs en ~/proyectos/qemu/isos...${NC}"
    local ISO_DIR="$HOME/proyectos/qemu/isos"
    mkdir -p "$ISO_DIR"
    
    if ask "¿Deseas descargar la última ISO de Kali Linux ahora?"; then
        log "${CYAN}[*] Buscando la última versión de Kali Linux...${NC}"
        local KALI_VER; KALI_VER=$(curl -sL https://cdimage.kali.org/ | grep -oP 'kali-[0-9]+\.[0-9]+' | sort -V | tail -1)
        if [ -n "$KALI_VER" ]; then
            local KALI_URL="https://cdimage.kali.org/${KALI_VER}/kali-linux-${KALI_VER}-installer-amd64.iso"
            log "${CYAN}[*] Descargando Kali Linux ${KALI_VER} (Installer amd64)...${NC}"
            curl -L -C - --progress-bar "$KALI_URL" -o "$ISO_DIR/kali-linux-latest.iso"
            [ "$EUID" -eq 0 ] && [ -n "$REAL_USER" ] && chown "$REAL_USER:$REAL_USER" "$ISO_DIR/kali-linux-latest.iso"
            log "${GREEN}  [✓]   ISO guardada en: $ISO_DIR/kali-linux-latest.iso${NC}"
        else
            log "${YELLOW}  [!] No se pudo obtener la versión de Kali — saltando descarga${NC}"
        fi
    fi

    log "${GREEN}[✓] Servicios habilitados y usuario añadido a grupos (libvirt, kvm).${NC}"
        log "${YELLOW}[!] Reinicia tu sesión para aplicar los permisos de grupo.${NC}"
    log "${GREEN}[✓] Módulo Entorno de Virtualización instalado.${NC}"
}

setup_plymouth_cazil() {
    log "${CYAN}[*] Configurando Plymouth (Tema: cazil-cyber)...${NC}"
    if [ ! -d "$SHARED_DIR/config/plymouth/themes" ]; then
        log "${RED}  [!]   No se encontró la carpeta del tema Plymouth en $SHARED_DIR${NC}"
        return 1
    fi

    local ply_dest="/usr/share/plymouth/themes/cazil-cyber"
    sudo mkdir -p "$ply_dest"
    sudo cp -r "$SHARED_DIR/config/plymouth/themes"/. "$ply_dest/"
    [ -f "$SHARED_DIR/assets/wallpapers/bg_grub1_con_logo.png" ] && \
        sudo cp "$SHARED_DIR/assets/wallpapers/bg_grub1_con_logo.png" "$ply_dest/"

    # ── MKINITCPIO Setup (Arch Only) ────────────────────────────────────
    if [ "$DISTRO" = "arch" ] && [ -f /etc/mkinitcpio.conf ]; then
        if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
            sudo sed -i 's/udev/udev plymouth/' /etc/mkinitcpio.conf
            log "${GREEN}  [✓]   mkinitcpio: hook 'plymouth' añadido después de 'udev'${NC}"
        fi
    fi

    # ── GRUB Setup: quiet splash ───────────────────────────────────────
    if [ -f /etc/default/grub ]; then
        local changed=false
        if ! grep -q "quiet" /etc/default/grub; then
            sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 quiet"/' /etc/default/grub
            changed=true
        fi
        if ! grep -q "splash" /etc/default/grub; then
            sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 splash"/' /etc/default/grub
            changed=true
        fi
        if [ "$changed" = true ]; then
            log "${GREEN}  [✓]   GRUB: kernel parameters 'quiet splash' añadidos${NC}"
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
        fi
    fi

    # ── Activar el tema ─────────────────────────────────────────────
    if command_exists plymouth-set-default-theme; then
        sudo plymouth-set-default-theme -R cazil-cyber 2>/dev/null || true
    elif command_exists update-alternatives; then
        sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
            default.plymouth "$ply_dest/cazil-cyber.plymouth" 100 2>/dev/null || true
        sudo update-alternatives --set default.plymouth "$ply_dest/cazil-cyber.plymouth" 2>/dev/null || true
    fi

    # ── Regenerar initramfs ────────────────────────────────────────
    if [ "$DISTRO" = "arch" ]; then
        sudo mkinitcpio -P 2>/dev/null || true
    else
        sudo update-initramfs -u 2>/dev/null || true
    fi

    log "${GREEN}  [✓]   Plymouth CAZIL instalado y activado con integración de sistema.${NC}"
}

install_module_system() {
    log "${CYAN}[*] Instalando Sistema Base (Hyprland + Ecosystem + ZSH) - MODO PERFECTO...${NC}"
    
    # ── Core Packages (Sin preguntas) ──────────────────────────────────
    if [ "$DISTRO" = "arch" ]; then
        pac hyprland hyprpaper hyprlock hypridle hyprpolkitagent \
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
            wl-clipboard grim slurp cliphist swww libnotify \
            waybar kitty rofi-wayland wofi \
            noto-fonts noto-fonts-emoji ttf-dejavu ttf-jetbrains-mono-nerd \
            zsh zsh-autosuggestions zsh-syntax-highlighting starship fastfetch fzf zoxide \
            pkgfile
        aur zsh-fzf-tab-git
        
        # Inicializar base de datos de pkgfile
        log "${CYAN}[*] Inicializando base de datos de pkgfile (esto puede tardar)...${NC}"
        sudo pkgfile -u || true
    else
        pac hyprland hyprpaper waybar kitty rofi wofi mako-notifier libnotify-bin \
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
            fonts-noto-core fonts-noto-color-emoji \
            zsh zsh-autosuggestions zsh-syntax-highlighting starship fzf zoxide \
            command-not-found
        sudo apt update && sudo update-command-not-found || true
        
        # swww y hyprlock (Debian binary fallback)
        if ! command_exists swww; then
            log "${CYAN}[*] Instalando swww (binary skip fallback)...${NC}"
            install_gh_release "L422Y/swww" ".*x86_64.*\.tar\.gz" "swww" "swww"
            install_gh_release "L422Y/swww" ".*x86_64.*\.tar\.gz" "swww-daemon" "swww-daemon"
        fi
        if ! command_exists hyprlock; then
            log "${CYAN}[*] Instalando hyprlock (Intentando apt)...${NC}"
            sudo apt-get install -y hyprlock 2>/dev/null || log "${YELLOW}  [!] hyprlock no disponible en repos Debian estables${NC}"
        fi
    fi

    # ── Cambiar shell a ZSH ────────────────────────────────────────────
    if [ -n "$REAL_USER" ]; then
        log "${CYAN}[*] Activando ZSH para $REAL_USER...${NC}"
        sudo chsh -s /usr/bin/zsh "$REAL_USER" 2>/dev/null || true
    fi

    # ── Desplegar Configuraciones (.zshrc incluido) ───────────────────
    deploy_configs
    
    log "${GREEN}[✓] Sistema Base y ZSH instalados y configurados perfectamente.${NC}"
}

install_module_audio_pro() {
    log "${CYAN}[*] Instalando Ecosistema Audio Pro (Pipewire + EasyEffects)...${NC}"
    
    if [ "$DISTRO" = "arch" ]; then
        pac pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
            easyeffects lsp-plugins calf zam-plugins qpwgraph
    else
        sudo apt-get install -y pipewire pipewire-pulse wireplumber \
            easyeffects lsp-plugins-lv2 calf-plugins zam-plugins qpwgraph
    fi

    log "${CYAN}[*] Habilitando servicios de audio (User level)...${NC}"
    # Asegurar que los servicios de usuario estén activos
    systemctl --user daemon-reload
    systemctl --user enable --now pipewire pipewire-pulse wireplumber

    log "${GREEN}[✓] Ecosistema Audio Pro instalado y activo.${NC}"
    log "${CYAN}[i] Usa 'EasyEffects' para mejorar el sonido de tu Nitro 5.${NC}"
}

install_module_audit() {
    log "${CYAN}[*] Iniciando Auditoría de Seguridad con Reporte Detallado...${NC}"
    
    # 1. Instalación de herramientas
    log "${CYAN}[*] Instalando herramientas (Lynis, Rkhunter, ClamAV)...${NC}"
    if [ "$DISTRO" = "arch" ]; then
        pac lynis rkhunter chkrootkit clamav
    else
        echo "postfix postfix/main_mailer_type string No configuration" | sudo debconf-set-selections 2>/dev/null || true
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q lynis rkhunter chkrootkit clamav clamav-daemon
    fi

    # 2. Escaneos
    log "${CYAN}--- [1/4] Análisis de Red y Puertos ---${NC}"
    # Formato: Local Address:Port (Service)
    local NET_ST; NET_ST=$(ss -tulnp | grep LISTEN | awk '{print $5, $7}' | sed 's/users:(("//g; s/")//g; s/",pid=.*//g')
    
    log "${CYAN}--- [2/4] Análisis de Rootkits (Sistema de Ficheros) ---${NC}"
    sudo rkhunter --propupd >/dev/null 2>&1
    local RK_RES; RK_RES=$(sudo rkhunter --check --sk --nocolor 2>/dev/null | grep "Warning")
    local CHK_RES; CHK_RES=$(sudo chkrootkit 2>/dev/null | grep "INFECTED")

    log "${CYAN}--- [3/4] Auditoría Integral de Robustez (Lynis) ---${NC}"
    sudo lynis audit system --quick 2>/dev/null > /tmp/lynis_audit.log
    local LYNIS_SCORE; LYNIS_SCORE=$(grep "Hardening index" /tmp/lynis_audit.log | sed 's/[^0-9]//g' || echo "--")
    local LYNIS_SUG; LYNIS_SUG=$(grep "Suggestion:" /tmp/lynis_audit.log | head -n 3)

    log "${CYAN}--- [4/4] Búsqueda de Malware (ClamAV) ---${NC}"
    sudo freshclam >/dev/null 2>&1 || true
    local CLAM_RES; CLAM_RES=$(sudo clamscan -r /etc /bin /usr/bin "$HOME" --quiet --no-summary)

    # 3. Reporte Final Detallado
    log ""
    log "${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
    log "${MAGENTA}║           INFORME DE SEGURIDAD CAZIL SYSTEM          ║${NC}"
    log "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"
    
    # SECCIÓN: RED
    log "${CYAN}[ RED Y CONEXIONES ]${NC}"
    if [ -z "$NET_ST" ]; then
        log "  ${GREEN}[✓] No hay puertos externos escuchando sospechosos.${NC}"
    else
        log "  ${YELLOW}[!] Puertos abiertos detectados:${NC}"
        echo "$NET_ST" | while read -r line; do
            local port; port=$(echo "$line" | grep -oP ':\d+' | cut -d: -f2 || echo "")
            if [ -n "$port" ]; then
                log "      - $line -> ${CYAN}Para cerrar: sudo ufw deny $port${NC}"
            else
                log "      - $line"
            fi
        done
    fi

    # SECCIÓN: ROOTKITS
    log "\n${CYAN}[ ROOTKITS Y ANOMALÍAS ]${NC}"
    if [ -z "$RK_RES" ] && [ -z "$CHK_RES" ]; then
        log "  ${GREEN}[✓] No se detectaron anomalías en el kernel ni binarios.${NC}"
    else
        log "  ${RED}[!] Posibles anomalías encontradas:${NC}"
        [ -n "$RK_RES" ] && echo "$RK_RES" | while read -r line; do log "      - [Rkhunter] $line"; done
        [ -n "$CHK_RES" ] && echo "$CHK_RES" | while read -r line; do log "      - [Chkrootkit] $line"; done
        log "      ${YELLOW}Consejo: Revisa los logs en /var/log/rkhunter.log${NC}"
    fi

    # SECCIÓN: LYNIS
    log "\n${CYAN}[ ROBUSTEZ DEL SISTEMA (LYNIS) ]${NC}"
    log "  Puntaje (Hardening Index): ${MAGENTA}${LYNIS_SCORE}/100${NC}"
    if [ -n "$LYNIS_SUG" ]; then
        log "  ${YELLOW}[!] Recomendaciones principales:${NC}"
        echo "$LYNIS_SUG" | sed 's/Suggestion: //g' | while read -r line; do log "      - $line"; done
    fi

    # SECCIÓN: ANTIVIRUS
    log "\n${CYAN}[ MALWARE Y AMENAZAS ]${NC}"
    if [ -z "$CLAM_RES" ]; then
        log "  ${GREEN}[✓] ClamAV no encontró amenazas en carpetas críticas.${NC}"
    else
        log "  ${RED}[!] ¡AMENAZAS DETECTADAS!${NC}"
        echo "$CLAM_RES" | while read -r line; do log "      - $line"; done
        log "      ${YELLOW}Consejo: Mueve o borra los archivos infectados manualmente.${NC}"
    fi

    # 4. Limpieza absoluta
    log ""
    log "${CYAN}[*] Finalizando y limpiando entorno de auditoría...${NC}"
    if [ "$DISTRO" = "arch" ]; then
        sudo pacman -Rs --noconfirm lynis rkhunter chkrootkit clamav 2>/dev/null || true
    else
        sudo apt-get purge -y lynis rkhunter chkrootkit clamav clamav-daemon 2>/dev/null || true
        sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -q >/dev/null 2>&1
    fi
    log "${GREEN}[✓] Auditoría Terminada. Sistema Limpio.${NC}"
}

cleanup_orphans() {
    log "${CYAN}[*] Limpiando dependencias huérfanas y paquetes innecesarios...${NC}"
    if [ "$DISTRO" = "arch" ]; then
        if pacman -Qtdq >/dev/null 2>&1; then
            sudo pacman -Rns $(pacman -Qtdq) --noconfirm
        else
            log "${GREEN}[✓] No se hallaron huérfanos en Arch.${NC}"
        fi
    else
        sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -q
        sudo apt-get clean
    fi
    log "${GREEN}[✓] Sistema optimizado y limpio.${NC}"
}

install_module_luks() {
    log "${CYAN}[*] Instalando Módulo LUKS (Plymouth Theme)...${NC}"
    if [ "$DISTRO" = "arch" ]; then
        pac plymouth
    else
        pac plymouth plymouth-themes
    fi
    setup_plymouth_cazil
}

install_module_fans() {
    log "${CYAN}[*] Configurando control de Ventiladores (NitroSense)...${NC}"
    
    # ── Dependencias ─────────────────────────────────────────────────────
    if [ "$DISTRO" = "arch" ]; then
        pac vim-runtime  # Provee xxd
    else
        pac xxd
    fi

    # ── Despliegue del script ───────────────────────────────────────────
    local TARGET_DIR="$HOME/sscript/vent"
    mkdir -p "$TARGET_DIR"
    
    local FANS_SRC="$SHARED_DIR/sscript/ventilador/nitrosense"
    if [ -f "$FANS_SRC" ]; then
        cp "$FANS_SRC" "$TARGET_DIR/nitrosense"
        chmod +x "$TARGET_DIR/nitrosense"
        log "${GREEN}[✓] Script desplegado en $TARGET_DIR/nitrosense${NC}"
    else
        log "${RED}[!] Error: Archivo fuente nitrosense no encontrado.${NC}"
        return 1
    fi

    log "${YELLOW}[i] Uso: sudo $TARGET_DIR/nitrosense <m|a|i|r>${NC}"
    log "    m=Max, a=Auto, i=Info, r=Read EC"
}

install_module_ly() {
    log "${CYAN}[*] Instalando Ly Display Manager...${NC}"
    if [ "$DISTRO" = "arch" ]; then
        pac ly 2>/dev/null || aur ly
    else
        pac ly 2>/dev/null || log "${YELLOW}[!] Ly no disponible en repos de Debian. Instala manualmente.${NC}"
    fi

    # Deshabilitar otros posibles gestores de sesión para evitar conflictos
    log "${CYAN}[*] Configurando servicios de Ly...${NC}"
    for dm in gdm sddm lightdm lxdm slim; do
        sudo systemctl disable "$dm" 2>/dev/null || true
    done
    sudo systemctl disable display-manager.service 2>/dev/null || true

    sudo mkdir -p /etc/ly
    if [ -f "$SHARED_DIR/config/ly/config.ini" ]; then
        sudo cp "$SHARED_DIR/config/ly/config.ini" /etc/ly/config.ini
    fi

    sudo systemctl enable ly.service || true
    log "${GREEN}[✓] Módulo Ly instalado y configurado como gestor de sesión.${NC}"
}

deploy_configs() {
    log ""
    log "${CYAN}════════════════════════════════════════════════${NC}"
    log "${CYAN}  DESPLEGANDO CONFIGS GLOBALES → sistema ($THEME_NAME)${NC}"
    log "${CYAN}════════════════════════════════════════════════${NC}"

    # ── Crear Carpetas Estándar ──────────────────────────────────────────────
    log "${CYAN}[*] Creando carpetas de usuario estándar...${NC}"
    if command_exists xdg-user-dirs-update; then
        xdg-user-dirs-update
        log "${GREEN}  [✓]   Carpetas XDG actualizadas (Documents, Downloads, etc.)${NC}"
    else
        mkdir -p "$HOME/Documents" "$HOME/Downloads" "$HOME/Music" "$HOME/Pictures" "$HOME/Videos" "$HOME/Public" "$HOME/Templates"
        log "${GREEN}  [✓]   Carpetas creadas manualmente${NC}"
    fi
    
    # ── Wallpapers ───────────────────────────────────────────────────────────
    log "${CYAN}[*] Desplegando fondos de pantalla...${NC}"
    local WALLPAPER_DIR="$HOME/Imagenes/wallpapers"
    mkdir -p "$WALLPAPER_DIR"
    if [ -d "$SHARED_DIR/assets/wallpapers" ]; then
        cp -r "$SHARED_DIR/assets/wallpapers"/* "$WALLPAPER_DIR/"
        log "${GREEN}  [✓]   Fondos copiados a $WALLPAPER_DIR${NC}"
    fi

    # ── Tema ────────────────────────────────────────────────────────────────────
    _put "$THEME_DIR/hypr"     "$HOME/.config/hypr"
    _put "$THEME_DIR/waybar"   "$HOME/.config/waybar"
    _put "$THEME_DIR/kitty"    "$HOME/.config/kitty"
    _put "$THEME_DIR/rofi"     "$HOME/.config/rofi"
    _put "$THEME_DIR/wofi"     "$HOME/.config/wofi"
    _put "$THEME_DIR/mako"     "$HOME/.config/mako"
    _put "$THEME_DIR/fastfetch" "$HOME/.config/fastfetch"
    _put "$THEME_DIR/yazi"     "$HOME/.config/yazi"
    _put "$SHARED_DIR/config/tmux" "$HOME/.config/tmux"
    _put "$THEME_DIR/vscode-user" "/tmp/vscode-user-tmp" 2>/dev/null || true
    [ -d "$THEME_DIR/vscode-user" ] && {
        mkdir -p "$HOME/.config/Code/User"
        cp -r "$THEME_DIR/vscode-user"/. "$HOME/.config/Code/User/"
        # Fix ownership
        if [ "$EUID" -eq 0 ] && [ -n "${REAL_USER:-}" ]; then
            chown -R "$REAL_USER:$REAL_USER" "$HOME/.config/Code/User"
        fi
        log "${GREEN}  [✓]   VSCode User settings${NC}"
    }

    [ -f "$THEME_DIR/starship/starship.toml" ] && \
        _put "$THEME_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

    # .zshrc → usa el shared si existe, si no el del tema
    if [ -f "$SHARED_DIR/config/zsh/.zshrc" ]; then
        _put "$SHARED_DIR/config/zsh/.zshrc" "$HOME/.zshrc"
    elif [ -f "$THEME_DIR/zsh/.zshrc" ]; then
        _put "$THEME_DIR/zsh/.zshrc" "$HOME/.zshrc"
    fi

    # Gestos del Touchpad
    if [ -f "$SHARED_DIR/config/libinput-gestures.conf" ]; then
        _put "$SHARED_DIR/config/libinput-gestures.conf" "$HOME/.config/libinput-gestures.conf"
    fi

    # Actualizar alias de scripts para que apunten a ~/.local/bin (independiente del repo)
    if [ -f "$HOME/.zshrc" ]; then
        sed -i "s|alias limpiar-kali=.*|alias limpiar-kali=\"bash \$HOME/.local/bin/limpiar-kali\"|" "$HOME/.zshrc"
        sed -i "s|alias crear-maquina=.*|alias crear-maquina=\"bash \$HOME/.local/bin/crear-maquina\"|" "$HOME/.zshrc"
        sed -i 's|alias battery-100=.*|alias battery-100="battery-limit 100"|' "$HOME/.zshrc"
        sed -i "s|alias docker_init=.*|alias docker_init=\"bash \$HOME/.local/bin/docker_init\"|" "$HOME/.zshrc"
        sed -i "s|alias delete_total=.*|alias delete_total=\"bash \$HOME/.local/bin/delete_total\"|" "$HOME/.zshrc"
        sed -i "s|alias dots=.*|alias dots=\"cd \$HOME/cazil-dotfiles\"|" "$HOME/.zshrc"
        sed -i "s|~/Proyectos/qemu/maquinas/|~/VirtualMachines/qemu/|g" "$HOME/.zshrc"
        log "${GREEN}  [✓]   Alias de scripts y VMs actualizados en ~/.zshrc (persistent)${NC}"
    fi

    # env.conf + hypridle.conf → shared unificado → ~/.config/hypr/
    if [ -f "$SHARED_DIR/config/hypr/env.conf" ]; then
        cp "$SHARED_DIR/config/hypr/env.conf" "$HOME/.config/hypr/env.conf"
        log "${GREEN}  [✓]   env.conf (shared) → ~/.config/hypr/env.conf${NC}"
    fi
    if [ -f "$SHARED_DIR/config/hypr/hypridle.conf" ]; then
        cp "$SHARED_DIR/config/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
        log "${GREEN}  [✓]   hypridle.conf (shared) → ~/.config/hypr/hypridle.conf${NC}"
    fi

    # WinApps Config
    if [ -f "$SHARED_DIR/config/winapps/winapps.conf" ]; then
        mkdir -p "$HOME/.config/winapps"
        cp "$SHARED_DIR/config/winapps/winapps.conf" "$HOME/.config/winapps/winapps.conf"
        log "${GREEN}  [✓]   winapps.conf (shared) → ~/.config/winapps/winapps.conf${NC}"
    fi

    # Wallpapers → ~/Pictures/wallpapers/
    if [ -d "$SHARED_DIR/assets/wallpapers" ]; then
        mkdir -p "$HOME/Pictures/wallpapers"
        cp -r "$SHARED_DIR/assets/wallpapers"/. "$HOME/Pictures/wallpapers/"
        log "${GREEN}  [✓]   Wallpapers → ~/Pictures/wallpapers/${NC}"
    fi

    # GIFs animados → ~/Pictures/gifs/
    if [ -d "$SHARED_DIR/assets/gifs" ]; then
        mkdir -p "$HOME/Pictures/gifs"
        cp -r "$SHARED_DIR/assets/gifs"/. "$HOME/Pictures/gifs/"
        log "${GREEN}  [✓]   GIFs → ~/Pictures/gifs/${NC}"
    fi

    # ── Shared: wlogout ─────────────────────────────────────────────────────────
    if [ -d "$SHARED_DIR/config/wlogout" ]; then
        mkdir -p "$HOME/.config/wlogout"
        cp -r "$SHARED_DIR/config/wlogout"/. "$HOME/.config/wlogout/"
        log "${GREEN}  [✓]   wlogout → ~/.config/wlogout/${NC}"
    fi

    # ── Shared: GTK Settings ───────────────────────────────────────────────────
    if [ -d "$SHARED_DIR/config/gtk" ]; then
        mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
        [ -f "$SHARED_DIR/config/gtk/gtk-3.0/settings.ini" ] && cp "$SHARED_DIR/config/gtk/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"
        [ -f "$SHARED_DIR/config/gtk/gtk-4.0/settings.ini" ] && cp "$SHARED_DIR/config/gtk/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"
        log "${GREEN}  [✓]   GTK settings applied${NC}"
    fi

    # ── Shared: Fuentes ─────────────────────────────────────────────────────────
    if [ -d "$SHARED_DIR/assets/fonts" ]; then
        mkdir -p "$HOME/.local/share/fonts/cazil"
        cp -r "$SHARED_DIR/assets/fonts"/. "$HOME/.local/share/fonts/cazil/"
        [ -f "$SHARED_DIR/assets/fonts/10-nerd-font-symbols.conf" ] && {
            mkdir -p "$HOME/.config/fontconfig/conf.d"
            cp "$SHARED_DIR/assets/fonts/10-nerd-font-symbols.conf" \
               "$HOME/.config/fontconfig/conf.d/"
        }
        fc-cache -f > /dev/null 2>&1
        log "${GREEN}  [✓]   Fuentes → ~/.local/share/fonts/cazil/${NC}"
    fi

    # ── Shared: GRUB ────────────────────────────────────────────────────────────
    if [ -d "$SHARED_DIR/config/grub/cyberpunk" ]; then
        local grub_dest="/boot/grub/themes/cazil-cyberpunk"
        sudo mkdir -p "$grub_dest"
        sudo cp -r "$SHARED_DIR/config/grub/cyberpunk"/. "$grub_dest/"
        [ -f "$SHARED_DIR/assets/wallpapers/bg_grub1_con_logo.png" ] && \
            sudo cp "$SHARED_DIR/assets/wallpapers/bg_grub1_con_logo.png" "$grub_dest/"
        grep -q "^GRUB_THEME=" /etc/default/grub 2>/dev/null && \
            sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$grub_dest/theme.txt\"|" /etc/default/grub || \
            echo "GRUB_THEME=\"$grub_dest/theme.txt\"" | sudo tee -a /etc/default/grub > /dev/null
        grep -q "^GRUB_GFXMODE=" /etc/default/grub 2>/dev/null || \
            printf "GRUB_GFXMODE=1920x1080,auto\nGRUB_GFXPAYLOAD_LINUX=keep\n" | \
            sudo tee -a /etc/default/grub > /dev/null
        [ -f "$grub_dest/Cazil-pixel-32.pf2" ] && {
            grep -q "^GRUB_FONT=" /etc/default/grub 2>/dev/null && \
                sudo sed -i "s|^GRUB_FONT=.*|GRUB_FONT=\"$grub_dest/Cazil-pixel-32.pf2\"|" /etc/default/grub || \
                echo "GRUB_FONT=\"$grub_dest/Cazil-pixel-32.pf2\"" | sudo tee -a /etc/default/grub > /dev/null
        }
        sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || \
            sudo update-grub 2>/dev/null || true
        log "${GREEN}  [✓]   GRUB theme → $grub_dest${NC}"
    fi

    # ── Shared: Plymouth ────────────────────────────────────────────────────────
    setup_plymouth_cazil

    # ── Shared: Protección GRUB con contraseña ───────────────────────────────────
    if ask "¿Configurar contraseña de GRUB? (protege edición de entradas ante acceso físico)"; then
        if [ -f "$SHARED_DIR/config/grub/setup-grub-password.sh" ]; then
            bash "$SHARED_DIR/config/grub/setup-grub-password.sh"
        else
            log "${YELLOW}[!] setup-grub-password.sh no encontrado. Puedes correrlo después manualmente.${NC}"
            log "${CYAN}    sudo bash $SHARED_DIR/config/grub/setup-grub-password.sh${NC}"
        fi
    fi

    # ── Shared: Scripts de utilidad (rgb, fans, brillo, gpu, etc.) ───────────────
    mkdir -p "$HOME/.local/bin"
    local SSCRIPT="$SHARED_DIR/sscript"

    # Copiar todos los scripts disponibles
    for script in "$SSCRIPT"/*.sh "$SSCRIPT"/*/*.sh; do
        [ -f "$script" ] || continue
        local name; name=$(basename "$script" .sh)
        # Nombres amigables
        case "$name" in
            nitro-fans) name="fans" ;;
            rgb-load) name="rgb-load" ;;
            alternar_pantallas) name="monitor-toggle" ;;
            power-save) name="eco-mode" ;;
            gpu-check) name="gpu-check" ;;
            modo_exponer) name="modo_exponer" ;;
            limpiar-sistema) name="limpiar-sistema" ;;
            wallpaper-dinamico) name="gif-on" ;;
            ocr-pantalla) name="ocr-magico" ;;
            pdf) name="pdf" ;;
            tema) name="tema" ;;
            limpiar-kali) name="limpiar-kali" ;;
            crear-maquina) name="crear-maquina" ;;
            docker-init) name="docker-init" ;;
            delete-total) name="delete-total" ;;
            toggle-animations) name="toggle-animations" ;;
            modo) name="modo" ;;
            zoom) name="zoom" ;;
            apagar-redes-grub) name="apagar-redes-grub" ;;
            perfil-energia) name="perfil-energia" ;;
            toggle-radio) name="toggle-radio" ;;
            privacy-action) name="privacy-action" ;;
            volumen) name="volumen" ;;
            subir-brillo) name="subir-brillo" ;;
            bajar-brillo) name="bajar-brillo" ;;
            ctf-stats) name="ctf-stats" ;;
            ctf-setup) name="ctf-setup" ;;
        esac
        cp "$script" "$HOME/.local/bin/$name"
        chmod +x "$HOME/.local/bin/$name"
        # Scripts que systemd usa deben estar también en /usr/local/bin
        case "$name" in
            battery-limit|limpiar-sistema)
                sudo cp "$HOME/.local/bin/$name" "/usr/local/bin/$name"
                sudo chmod +x "/usr/local/bin/$name"
                ;;
        esac
        log "${GREEN}  [✓]   $name → ~/.local/bin/$name${NC}"
    done

    # ── Shared: Fixes de Brillo → /usr/local/bin/brillo1/2 (persistent) ─────────
    if [ -f "$SHARED_DIR/docs/ResolverBrilloBug.sh" ]; then
        sudo cp "$SHARED_DIR/docs/ResolverBrilloBug.sh" "/usr/local/bin/brillo1"
        sudo chmod +x "/usr/local/bin/brillo1"
    fi
    if [ -f "$SHARED_DIR/docs/ResolverBrilloBug2.sh" ]; then
        sudo cp "$SHARED_DIR/docs/ResolverBrilloBug2.sh" "/usr/local/bin/brillo2"
        sudo chmod +x "/usr/local/bin/brillo2"
    fi

    # Ajustes especiales para fans
    if [ -f "$HOME/.local/bin/fans" ]; then
        log "${CYAN}[*] Configurando persistencia para control de ventiladores (ec_sys)...${NC}"
        # Carga automática del módulo
        if ! grep -q "ec_sys" /etc/modules-load.d/ec_sys.conf 2>/dev/null; then
            echo "ec_sys" | sudo tee /etc/modules-load.d/ec_sys.conf > /dev/null
        fi
        # Habilitar soporte de escritura
        if ! grep -q "write_support=1" /etc/modprobe.d/ec_sys.conf 2>/dev/null; then
            echo "options ec_sys write_support=1" | sudo tee /etc/modprobe.d/ec_sys.conf > /dev/null
        fi
        sudo modprobe ec_sys write_support=1 2>/dev/null || true
        log "${GREEN}  [✓]   ec_sys configurado con write_support=1 para control de fans${NC}"
    fi

    # Configuración de límite de batería (Service)
    if [ -f "$SSCRIPT/battery-limit.service" ]; then
        sudo cp "$SSCRIPT/battery-limit.service" "/etc/systemd/system/battery-limit.service"
        sudo systemctl daemon-reload
        sudo systemctl enable battery-limit.service 2>/dev/null || true
        log "${GREEN}  [✓]   battery-limit.service habilitado (80% Default)${NC}"
    fi

    # Asegurar propiedad de los archivos desplegados en el HOME del usuario real
    if [ "$EUID" -eq 0 ] && [ -n "${REAL_USER:-}" ]; then
        log "${CYAN}[*] Ajustando permisos de archivos en $HOME...${NC}"
        # .config, .local, Pictures, Music, Videos, etc.
        chown -R "$REAL_USER:$REAL_USER" "$HOME/.config" "$HOME/.local" "$HOME/Pictures" "$HOME/Documents" "$HOME/Downloads" 2>/dev/null || true
        # Archivos de inicio
        for f in .zshrc .bashrc .bash_profile .zprofile .profile; do
            [ -f "$HOME/$f" ] && chown "$REAL_USER:$REAL_USER" "$HOME/$f"
        done
    fi

    log ""
    log "${GREEN}  ══ Deploy completo. Sistema independiente del repo. ══${NC}"
    log ""
}

install-rgb() {
    ask "¿Instalar driver RGB Acer Nitro/Predator (JafarAkhondali module)?" || return

    # ── Blacklist acer_wmi (conflictivo con este driver) ─────────────────
    local ACER_BLACKLIST="/etc/modprobe.d/blacklist-acer-wmi.conf"
    if [ ! -f "$ACER_BLACKLIST" ]; then
        log "${CYAN}[*] Blacklisteando acer_wmi para evitar conflictos...${NC}"
        echo "blacklist acer_wmi" | sudo tee "$ACER_BLACKLIST" > /dev/null
        echo "install acer_wmi /bin/false" | sudo tee -a "$ACER_BLACKLIST" > /dev/null
    fi

    if [ "$DISTRO" = "arch" ]; then
        log "${CYAN}[*] Instalando desde AUR: acer-predator-turbo-and-rgb-dkms-git...${NC}"
        # Asegurar headers primero
        local kernel; kernel=$(uname -r)
        echo "$kernel" | grep -q "lts" && pac linux-lts-headers || \
        echo "$kernel" | grep -q "zen" && pac linux-zen-headers || pac linux-headers
        
        aur acer-predator-turbo-and-rgb-dkms-git
    else
        log "${CYAN}[*] Instalando vía Git para Debian/Ubuntu...${NC}"
        pac git dkms build-essential rsync "linux-headers-$(uname -r)"
        
        local tmp; tmp=$(mktemp -d)
        git clone --depth=1 https://github.com/JafarAkhondali/acer-predator-turbo-and-rgb-keyboard-linux-module "$tmp/acer-rgb"
        cd "$tmp/acer-rgb"
        chmod +x ./*.sh
        sudo ./install_service.sh
    fi

    # ── Despliegue de scripts personalizados ($HOME/sscript) ──────────────
    local TARGET_DIR="$HOME/sscript"
    log "${CYAN}[*] Desplegando scripts en $TARGET_DIR...${NC}"
    mkdir -p "$TARGET_DIR"
    
    local RGB_SCRIPTS_SRC="$SHARED_DIR/sscript/rgb/scripts"
    if [ -d "$RGB_SCRIPTS_SRC" ]; then
        cp "$RGB_SCRIPTS_SRC"/*.{py,sh} "$TARGET_DIR/"
        chmod +x "$TARGET_DIR"/*.sh "$TARGET_DIR"/*.py
    fi

    # ── Configurar Servicio Persistente ──────────────────────────────────
    log "${CYAN}[*] Configurando nitro-rgb.service...${NC}"
    sudo bash -c "cat > /etc/systemd/system/nitro-rgb.service" <<EOF
[Unit]
Description=Servicio de Control RGB Acer Nitro (Battery Monitor)
After=multi-user.target

[Service]
Type=simple
User=$REAL_USER
ExecStart=/bin/bash $TARGET_DIR/teclado-rgb.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nitro-rgb.service
    sudo systemctl restart nitro-rgb.service

    log "${GREEN}[✓] RGB y servicio de automatización instalados en $TARGET_DIR.${NC}"
    log "${CYAN}[i] Control: ~/sscript/nitro-rgb.py --all -cR 0 -cG 255 -cB 255${NC}"
}

configure_autostart() {
    ask "¿Configurar auto-inicio de Hyprland al login (tty1)?" || return
    cat > "$HOME/.bash_profile" << 'PROFILE'
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec Hyprland
fi
PROFILE
    cat > "$HOME/.zprofile" << 'ZPROFILE'
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec Hyprland
fi
ZPROFILE

    # Asegurar propiedad del usuario real
    if [ "$EUID" -eq 0 ] && [ -n "${REAL_USER:-}" ]; then
        chown "$REAL_USER:$REAL_USER" "$HOME/.bash_profile" "$HOME/.zprofile"
    fi
    log "${GREEN}[✓] Auto-inicio Hyprland configurado.${NC}"
}

ensure_path() {
    local bin_path="$HOME/.local/bin"
    if [[ ":$PATH:" != *":$bin_path:"* ]]; then
        log "${CYAN}[*] Agregando $bin_path al PATH...${NC}"
        local shell_configs=("$HOME/.zshrc" "$HOME/.bashrc")
        for config in "${shell_configs[@]}"; do
            if [ -f "$config" ]; then
                if ! grep -q "$bin_path" "$config"; then
                    echo -e "\n# Cazil scripts\nexport PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$config"
                    log "${GREEN}  [✓]   PATH actualizado en $(basename "$config")${NC}"
                fi
            fi
        done
    fi
}

# ==============================================================================
# EJECUCIÓN PRINCIPAL
# ==============================================================================
log ""
log "${CYAN}════════════════════════════════════════════════${NC}"
log "${CYAN}  Log: $LOG_FILE${NC}"
log "${CYAN}════════════════════════════════════════════════${NC}"
log ""

if [ "$DOTFILES_ONLY" = true ]; then
    echo ""
    log "${MAGENTA}╔══════════════════════════════════════════════╗${NC}"
    log "${MAGENTA}║          OPCIONES DE RECONFIGURACIÓN         ║${NC}"
    log "${MAGENTA}╠══════════════════════════════════════════════╣${NC}"
    log "${MAGENTA}║  ${GREEN}[1]${NC} Instalar Solo Kitty (App + Config)        ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[2]${NC} Instalar Solo Firefox (App + Config)      ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[3]${NC} Solo Entorno Virtual (QEMU/KVM)           ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[4]${NC} Sistema Base (Hyprland+Waybar+Rofi)       ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[5]${NC} Instalar Solo LUKS (Plymouth Theme)       ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[6]${NC} Instalar Solo Ly (Display Manager)        ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[7]${NC} Instalar Solo RGB (Keyboard)              ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[8]${NC} Instalar Solo Ventiladores (Fans)         ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[9]${NC} Audio Pro (Pipewire+EasyEffects)          ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[10]${NC} Revisando Sistema (Auditoría)            ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[11]${NC} Limpiar Dependencias (Huérfanos)         ${MAGENTA}║${NC}"
    log "${MAGENTA}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${YELLOW}  Opción [1-11]: ${NC}"
    
    CONFIG_CHOICE="$MODULE_CHOICE"
    if [ -z "$CONFIG_CHOICE" ]; then
        if [ "$AUTO_INSTALL" = true ]; then
            CONFIG_CHOICE=5; echo "5 (AUTO)"
        else
            read -r CONFIG_CHOICE
        fi
    fi

    case "$CONFIG_CHOICE" in
        1) install_module_kitty ;;
        2) install_module_firefox ;;
        3) install_module_work_env ;;
        4) install_module_system ;;
        5) install_module_luks ;;
        6) install_module_ly ;;
        7) install-rgb ;;
        8) install_module_fans ;;
        9) install_module_audio_pro ;;
        10) install_module_audit ;;
        11) cleanup_orphans ;;
        *)
            log "${RED}[!] Opción inválida. Saliendo...${NC}"
            exit 1
            ;;
    esac
    exit 0
fi

log "${CYAN}════ PASO 1: PAQUETES ════${NC}"
install_pkgs

log "${CYAN}════ PASO 2: RGB + Características especiales ════${NC}"
install-rgb

log "${CYAN}════ PASO 3: DEPLOY CONFIGS ════${NC}"
deploy_configs

ensure_path

configure_autostart

echo ""
log "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
log "${GREEN}║   CAZIL SYSTEM — TEMA: $THEME_NAME — LISTO      ║${NC}"
log "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
log ""
log "${CYAN}  PRÓXIMOS PASOS:${NC}"
log "${YELLOW}1.${NC} Reinicia: ${CYAN}sudo reboot${NC}"
log "${YELLOW}2.${NC} Si tienes problema de brillo: ${CYAN}sudo brillo1${NC} → reboot → ${CYAN}sudo brillo2${NC}"
log "${YELLOW}3.${NC} Hyprland arrancará en tty1 automáticamente"
log "${YELLOW}4.${NC} Log completo: ${CYAN}cat $LOG_FILE${NC}"
log ""
log "${GREEN}Fuentes instaladas en: ~/.local/share/fonts/cazil/${NC}"
log "${GREEN}Wallpapers en: ~/Pictures/wallpapers/${NC}"
log "${GREEN}Scripts: fans | brillo1 | brillo2 | subir-brillo | bajar-brillo | volumen | perfil-energia | toggle-radio | privacy-action | nitro-rgb${NC}"
