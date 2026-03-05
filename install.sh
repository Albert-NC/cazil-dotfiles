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

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$REPO_DIR/themes"
SHARED_DIR="$REPO_DIR/shared"
LOG_FILE="/tmp/cazil_install_$(date +%Y%m%d_%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

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

# ==============================================================================
# PARSE ARGUMENTOS
# ==============================================================================
for arg in "$@"; do
    case "$arg" in
        --auto)           AUTO_INSTALL=true ;;
        --dotfiles-only)  DOTFILES_ONLY=true ;;
        --arch)           DISTRO="arch" ;;
        --debian)         DISTRO="debian" ;;
    esac
done

# ==============================================================================
# BANNER
# ==============================================================================
clear
log "${CYAN}"
log "  ██████╗ █████╗ ███████╗██╗██╗     "
log " ██╔════╝██╔══██╗╚════██║██║██║     "
log " ██║     ███████║    ██╔╝██║██║     "
log " ██║     ██╔══██║   ██╔╝ ██║██║     "
log " ╚██████╗██║  ██║   ██║  ██║███████╗"
log "  ╚═════╝╚═╝  ╚═╝   ╚═╝  ╚═╝╚══════╝"
log "          DOTFILES — INSTALADOR v3.0"
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
# 2. SELECCIÓN DE TEMA
# ==============================================================================
echo ""
log "${MAGENTA}╔══════════════════════════════════════════════╗${NC}"
log "${MAGENTA}║            SELECCIONAR TEMA                  ║${NC}"
log "${MAGENTA}╠══════════════════════════════════════════════╣${NC}"
log "${MAGENTA}║  ${GREEN}[1]${NC} 218 — Cyberpunk (Cyan + Magenta)        ${MAGENTA}║${NC}"
log "${MAGENTA}║  ${GREEN}[2]${NC} Ilidary — Minimalista (Verde)            ${MAGENTA}║${NC}"
log "${MAGENTA}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -ne "${YELLOW}  Tema [1/2]: ${NC}"

if [ "$AUTO_INSTALL" = true ]; then
    THEME_CHOICE=1; echo "1 (AUTO)"
else
    read -r THEME_CHOICE
fi

case "$THEME_CHOICE" in
    1) THEME_NAME="218";     THEME_DIR="$THEMES_DIR/218" ;;
    2) THEME_NAME="ilidary"; THEME_DIR="$THEMES_DIR/ilidary" ;;
    *) log "${YELLOW}[!] Opción inválida. Usando 218.${NC}"; THEME_NAME="218"; THEME_DIR="$THEMES_DIR/218" ;;
esac

if [ ! -d "$THEME_DIR" ]; then
    log "${RED}[!] No se encontró el tema en $THEME_DIR${NC}"
    exit 1
fi
log "${GREEN}[✓] Tema: $THEME_NAME → $THEME_DIR${NC}"

# ==============================================================================
# 3. MODO: ¿Solo dotfiles o instalación completa?
# ==============================================================================
if [ "$DOTFILES_ONLY" = false ] && [ "$AUTO_INSTALL" = false ]; then
    echo ""
    log "${MAGENTA}╔══════════════════════════════════════════════╗${NC}"
    log "${MAGENTA}║             MODO DE INSTALACIÓN              ║${NC}"
    log "${MAGENTA}╠══════════════════════════════════════════════╣${NC}"
    log "${MAGENTA}║  ${GREEN}[1]${NC} Completa (paquetes + dotfiles)          ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[2]${NC} Auto-completa (sin preguntas)           ${MAGENTA}║${NC}"
    log "${MAGENTA}║  ${GREEN}[3]${NC} Solo dotfiles / configs                 ${MAGENTA}║${NC}"
    log "${MAGENTA}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${YELLOW}  Modo [1/2/3]: ${NC}"
    read -r MODE_CHOICE
    case "$MODE_CHOICE" in
        1) AUTO_INSTALL=false ;;
        2) AUTO_INSTALL=true ;;
        3) DOTFILES_ONLY=true ;;
        *) AUTO_INSTALL=false ;;
    esac
fi

# ==============================================================================
# FUNCIONES DE INSTALACIÓN DE PAQUETES
# ==============================================================================
if [ "$DISTRO" = "arch" ]; then
    pac() {
        # Optimizar pacman antes de la primera instalación
        if ! grep -q "ParallelDownloads" /etc/pacman.conf; then
            sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
            sudo sed -i '/^#Color/a ILoveCandy' /etc/pacman.conf
            sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
            log "${GREEN}  [✓]   Pacman optimizado (Descargas paralelas + ILoveCandy)${NC}"
        fi

        for pkg in "$@"; do
            is_installed_pac "$pkg" && continue
            ask "¿Instalar $pkg?" && sudo pacman -S --needed --noconfirm "$pkg" || true
        done
    }

    aur() {
        for pkg in "$@"; do
            is_installed_pac "$pkg" && continue
            if ask "¿Instalar $pkg (AUR)?"; then
                if ! command_exists yay; then
                    log "${YELLOW}[!] yay no encontrado. ¿Instalar yay para paquetes AUR?${NC}"
                    if ask "Instalar yay ahora?"; then
                        local tmp; tmp=$(mktemp -d)
                        git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp"
                        (cd "$tmp" && makepkg -si --noconfirm)
                        rm -rf "$tmp"
                    else
                        log "${RED}[!] Saltando $pkg (requiere yay)${NC}"; continue
                    fi
                fi
                yay -S --needed --noconfirm "$pkg" || true
            fi
        done
    }

    install_pkgs() {
        log "${CYAN}[*] Instalando paquetes del sistema (Arch)...${NC}"
        ask "¿Instalar Hyprland y utilidades Wayland?" && \
            pac hyprland hyprpaper hyprlock hypridle hyprpolkitagent

        # ── Microcode ────────────────────────────────────────────────────────────
        ask "¿Instalar parches de seguridad del Microprocesador (Microcode)?" && {
            if grep -q "vendor_id.*GenuineIntel" /proc/cpuinfo; then
                pac intel-ucode
                log "${GREEN}  [✓]   Microcode Intel instalado${NC}"
            elif grep -q "vendor_id.*AuthenticAMD" /proc/cpuinfo; then
                pac amd-ucode
                log "${GREEN}  [✓]   Microcode AMD instalado${NC}"
            fi
            # Regenerar GRUB para aplicar microcode
            [ -f /etc/default/grub ] && {
                sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            }
        }

        ask "¿Instalar Waybar?" && pac waybar

        ask "¿Instalar Kitty?" && pac kitty

        ask "¿Instalar lanzadores (Rofi + Wofi)?" && pac rofi-wayland wofi

        ask "¿Instalar soporte para Emojis y caracteres Asiáticos (CJK)?" && \
            pac noto-fonts-emoji noto-fonts-cjk

        ask "¿Instalar utilidades Wayland?" && \
            pac wl-clipboard xdg-user-dirs xdg-utils

        ask "¿Instalar audio (Pipewire)?" && {
            pac pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol \
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
            # Habilitar Pipewire como servicio de usuario (crítico en Arch mínimo)
            systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
            log "${GREEN}  [✓]   Pipewire habilitado como servicio de usuario${NC}"

            # GRUB: añadir parámetro para evitar cortes de audio HDA Intel
            # snd_hda_intel.power_save=0 → desactiva el power-save del codec (evita clicks/cortes)
            if [ -f /etc/default/grub ]; then
                if ! grep -q "snd_hda_intel.power_save=0" /etc/default/grub; then
                    sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 snd_hda_intel.power_save=0"/' \
                        /etc/default/grub
                    sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || \
                        sudo update-grub 2>/dev/null || true
                    log "${GREEN}  [✓]   GRUB: snd_hda_intel.power_save=0 añadido${NC}"
                else
                    log "${CYAN}  [~]   GRUB: snd_hda_intel.power_save ya configurado${NC}"
                fi
            fi
        }

        ask "¿Instalar control de brillo?" && \
            pac brightnessctl

        ask "¿Instalar notificaciones (Mako)?" && pac mako libnotify

        ask "¿Instalar Bluetooth?" && \
            pac bluez bluez-utils blueman && \
            sudo systemctl enable bluetooth

        ask "¿Instalar gestor de energía y CPU?" && \
            pac tlp auto-cpufreq && \
            sudo systemctl enable tlp auto-cpufreq

        ask "¿Configurar Límite de Carga de Batería (Acer Nitro)?" && {
            pac linux-headers
            aur acer-wmi-battery-dkms
            # El despliegue real ocurre en deploy_configs
        }

        ask "¿Instalar utilidades de laptop (OSD, Night Light, Auto-mount)?" && \
            pac gammastep udiskie network-manager-applet && \
            aur swayosd-git
        
        ask "¿Instalar soporte para Periféricos? (Logitech, Razer, Gaming Mice)" && {
            ask "  ¿Instalar Solaar (Logitech)?" && pac solaar
            ask "  ¿Instalar Piper/libratbag (Mouses Gaming)?" && pac piper libratbag
            ask "  ¿Instalar OpenRazer (Teclados/Mouses Razer)?" && {
                aur openrazer-meta polyrgb-git
                sudo usermod -aG plugdev "$USER"
            }
        }

        # Multimedia y Utilidades
        aur_install swww mako fastfetch-git starship python-pyprland playerctl vlc

        ask "¿Instalar herramientas de Seguridad (USBGuard, Firewall, etc.)?" && {
            pac usbguard ufw clamav rkhunter
            aur chkrootkit
            sudo systemctl enable --now usbguard
            sudo systemctl enable --now ufw
            log "${GREEN}[✓] Seguridad configurada básica (Recuerda autorizar tus USBs).${NC}"
        }

        ask "¿Instalar Herramientas Power User (eza, bat, btop, lazygit, lazydocker)?" && {
            pac eza bat btop tldr fd ripgrep
            aur lazygit-bin lazydocker-bin
            log "${GREEN}[✓] Herramientas de productividad instaladas.${NC}"
        }

        ask "¿Instalar Fastfetch?" && pac fastfetch

        ask "¿Instalar Starship?" && pac starship

        ask "¿Instalar ZSH + plugins?" && {
            pac zsh zsh-autosuggestions zsh-syntax-highlighting
            chsh -s /usr/bin/zsh "$USER" 2>/dev/null || true
        }

        ask "¿Instalar Thunar (gestor de archivos)?" && \
            pac thunar gvfs tumbler thunar-volman
        
        ask "¿Instalar Yazi (gestor de archivos terminal)?" && \
            pac yazi imagemagick ffmpegthumbnailer poppler fzf zoxide
        
        ask "¿Instalar Soporte para Impresoras (CUPS)?" && {
            pac cups cups-pdf system-config-printer ghostscript avahi nss-mdns
            sudo systemctl enable --now cups
            sudo systemctl enable --now avahi-daemon
            
            # Configurar Avahi para resolución de nombres .local (común en impresoras WiFi)
            sudo sed -i 's/^hosts: .*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' /etc/nsswitch.conf
            
            if ask "¿Tu impresora es Brother?"; then
                echo -ne "${YELLOW}  Introduce el modelo (ej: dcpt520w): ${NC}"
                read -r B_MODEL
                B_MODEL=${B_MODEL:-dcpt520w}
                # La mayoría de drivers Brother en AUR siguen el patrón brother-modelo
                aur "brother-$B_MODEL" brscan4 sane
                log "${GREEN}  [✓]   Driver brother-$B_MODEL (AUR) añadido a la cola de instalación${NC}"
            fi
        }

        ask "¿Instalar multimedia (mpv, vlc, imv)?" && \
            pac mpv vlc imv

        ask "¿Instalar KeePassXC?" && pac keepassxc

        ask "¿Instalar navegadores (Firefox + Brave)?" && {
            pac firefox
            aur brave-bin
        }

        ask "¿Instalar Visual Studio Code (Oficial - AUR)?" && {
            aur visual-studio-code-bin
        }

        ask "¿Instalar TLP (ahorro de energía)?" && {
            pac tlp
            sudo systemctl enable tlp
        }

        ask "¿Instalar auto-cpufreq (Optimización de CPU)?" && {
            pac auto-cpufreq
            sudo systemctl enable --now auto-cpufreq
        }

        ask "¿Instalar Docker?" && {
            pac docker docker-compose
            sudo systemctl enable docker
            sudo usermod -aG docker "$USER"
        }

        ask "¿Instalar Virtualización (QEMU/KVM/Virt-Manager)?" && {
            pac qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat edk2-ovmf
            sudo systemctl enable --now libvirtd
            sudo usermod -aG libvirt "$USER"
            sudo usermod -aG kvm "$USER"
            log "${GREEN}[✓] Virtualización instalada. Reinicia para aplicar grupos.${NC}"
        }

        ask "¿Instalar wlogout (Menú de salida)?" && pac wlogout

        ask "¿Instalar Ly (Display Manager con animación Matrix)?" && {
            if ! is_installed_pac ly; then
                # Ly está en los repos oficiales de Arch desde 2024
                if sudo pacman -S --needed --noconfirm ly 2>/dev/null; then
                    log "${GREEN}  [✓]   ly instalado desde repos oficiales${NC}"
                else
                    # Fallback: AUR
                    aur ly
                fi
            fi
            # Deshabilitar otros display managers si están activos
            for dm in gdm sddm lightdm; do
                sudo systemctl disable "$dm" 2>/dev/null || true
            done
            # Desplegar config con animación Matrix
            sudo mkdir -p /etc/ly
            if [ -f "$SHARED_DIR/ly/config.ini" ]; then
                sudo cp "$SHARED_DIR/ly/config.ini" /etc/ly/config.ini
                log "${GREEN}  [✓]   ly config → /etc/ly/config.ini (Matrix animation + Hyprland)${NC}"
            fi
            sudo systemctl enable ly.service
            log "${GREEN}  [✓]   ly.service habilitado — arrancará con el sistema${NC}"
        }

        ask "¿Instalar DKMS / herramientas de compilación?" && \
            pac base-devel linux-headers dkms python python-setuptools

        ask "¿Instalar NVIDIA (Optimus)?" && install_nvidia_arch

        log "${GREEN}[✓] Paquetes instalados.${NC}"
    }

    install_nvidia_arch() {
        if ! lspci | grep -qi nvidia; then
            log "${YELLOW}[!] No se detectó GPU NVIDIA. Saltando.${NC}"; return
        fi
        pac nvidia nvidia-utils nvidia-settings lib32-nvidia-utils

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
        local gmode; [ "$AUTO_INSTALL" = true ] && gmode="h" || read -r gmode
        case "$gmode" in
            i) sudo envycontrol -s integrated ;;
            n) sudo envycontrol -s nvidia ;;
            *) sudo envycontrol -s hybrid --force-comp --rtd3 ;;
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
    pac() {
        for pkg in "$@"; do
            is_installed_apt "$pkg" && continue
            ask "¿Instalar $pkg?" && sudo apt-get install -y "$pkg" || true
        done
    }

    install_pkgs() {
        log "${CYAN}[*] Instalando paquetes del sistema (Debian/Ubuntu)...${NC}"
        ask "¿Instalar Hyprland?" && {
            if ! command_exists hyprland; then
                sudo apt-get install -y hyprland hyprpaper hyprlock hypridle 2>/dev/null || \
                    log "${YELLOW}[!] Hyprland no disponible en repos. Instala manualmente.${NC}"
            fi
        }
        ask "¿Instalar Waybar?" && pac waybar
        ask "¿Instalar Kitty?" && pac kitty
        ask "¿Instalar lanzadores?" && pac rofi wofi
        ask "¿Instalar audio?" && pac pipewire pipewire-pulse wireplumber pavucontrol
        ask "¿Instalar brillo?" && pac brightnessctl
        ask "¿Instalar notificaciones?" && pac mako-notifier libnotify-bin
        ask "¿Instalar Bluetooth?" && { pac bluez blueman; sudo systemctl enable bluetooth; }
        ask "¿Instalar Fastfetch?" && pac fastfetch
        ask "¿Instalar Starship?" && {
            curl -sS https://starship.rs/install.sh | sudo sh -s -- --yes || true
        }
        ask "¿Instalar ZSH + plugins?" && {
            pac zsh zsh-autosuggestions zsh-syntax-highlighting
            chsh -s /usr/bin/zsh "$USER" 2>/dev/null || true
        }
        ask "¿Instalar Thunar?" && pac thunar gvfs tumbler
        ask "¿Instalar Yazi?" && pac yazi imagemagick ffmpegthumbnailer poppler-utils
        ask "¿Instalar Soporte para Impresoras?" && {
            pac cups cups-pdf system-config-printer hplip
            sudo systemctl enable --now cups
        }
        ask "¿Instalar multimedia?" && pac mpv vlc
        ask "¿Instalar KeePassXC?" && pac keepassxc
        ask "¿Instalar Docker?" && {
            pac docker.io docker-compose
            sudo systemctl enable docker
            sudo usermod -aG docker "$USER"
        }
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
        local bak="${to}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$to" "$bak" && log "${YELLOW}  [bak]  $(basename "$bak")${NC}"
    fi
    [ -L "$to" ] && rm -f "$to"
    mkdir -p "$(dirname "$to")"
    if [ -d "$from" ]; then cp -r "$from" "$to"; else cp "$from" "$to"; fi
    log "${GREEN}  [✓]   $to${NC}"
}

deploy_configs() {
    log ""
    log "${CYAN}════════════════════════════════════════════════${NC}"
    log "${CYAN}  DESPLEGANDO CONFIGS → sistema ($THEME_NAME)   ${NC}"
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

    # ── Tema ────────────────────────────────────────────────────────────────────
    _put "$THEME_DIR/hypr"     "$HOME/.config/hypr"
    _put "$THEME_DIR/waybar"   "$HOME/.config/waybar"
    _put "$THEME_DIR/kitty"    "$HOME/.config/kitty"
    _put "$THEME_DIR/rofi"     "$HOME/.config/rofi"
    _put "$THEME_DIR/wofi"     "$HOME/.config/wofi"
    _put "$THEME_DIR/mako"     "$HOME/.config/mako"
    _put "$THEME_DIR/fastfetch" "$HOME/.config/fastfetch"
    _put "$THEME_DIR/yazi"     "$HOME/.config/yazi"
    _put "$THEME_DIR/vscode-user" "/tmp/vscode-user-tmp" 2>/dev/null || true
    [ -d "$THEME_DIR/vscode-user" ] && {
        mkdir -p "$HOME/.config/Code/User"
        cp -r "$THEME_DIR/vscode-user"/. "$HOME/.config/Code/User/"
        log "${GREEN}  [✓]   VSCode User settings${NC}"
    }

    [ -f "$THEME_DIR/starship/starship.toml" ] && \
        _put "$THEME_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

    # .zshrc → usa el shared si existe, si no el del tema
    if [ -f "$SHARED_DIR/zsh/.zshrc" ]; then
        _put "$SHARED_DIR/zsh/.zshrc" "$HOME/.zshrc"
    elif [ -f "$THEME_DIR/zsh/.zshrc" ]; then
        _put "$THEME_DIR/zsh/.zshrc" "$HOME/.zshrc"
    fi

    # Actualizar alias de scripts para que apunten a ~/.local/bin (independiente del repo)
    if [ -f "$HOME/.zshrc" ]; then
        sed -i 's|alias limpiar-kali=.*|alias limpiar-kali="bash $HOME/.local/bin/limpiar-kali"|' "$HOME/.zshrc"
        sed -i 's|alias crear-maquina=.*|alias crear-maquina="bash $HOME/.local/bin/crear-maquina"|' "$HOME/.zshrc"
        sed -i 's|alias battery-100=.*|alias battery-100="battery-limit 100"|' "$HOME/.zshrc"
        sed -i 's|alias docker_init=.*|alias docker_init="bash $HOME/.local/bin/docker_init"|' "$HOME/.zshrc"
        sed -i 's|alias delete_total=.*|alias delete_total="bash $HOME/.local/bin/delete_total"|' "$HOME/.zshrc"
        log "${GREEN}  [✓]   Alias de scripts actualizados en ~/.zshrc (persistent)${NC}"
    fi

    # env.conf + hypridle.conf → shared unificado → ~/.config/hypr/
    if [ -f "$SHARED_DIR/hypr/env.conf" ]; then
        cp "$SHARED_DIR/hypr/env.conf" "$HOME/.config/hypr/env.conf"
        log "${GREEN}  [✓]   env.conf (shared) → ~/.config/hypr/env.conf${NC}"
    fi
    if [ -f "$SHARED_DIR/hypr/hypridle.conf" ]; then
        cp "$SHARED_DIR/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
        log "${GREEN}  [✓]   hypridle.conf (shared) → ~/.config/hypr/hypridle.conf${NC}"
    fi
    # Configuración compartida de Pyprland
    if [ -f "$SHARED_DIR/hypr/pyprland.toml" ]; then
        cp "$SHARED_DIR/hypr/pyprland.toml" "$HOME/.config/hypr/pyprland.toml"
        log "${GREEN}  [✓]   pyprland.toml (shared) → ~/.config/hypr/pyprland.toml${NC}"
    fi

    # Wallpapers → ~/Pictures/wallpapers/
    if [ -d "$THEME_DIR/wallpapers" ]; then
        mkdir -p "$HOME/Pictures/wallpapers"
        cp -r "$THEME_DIR/wallpapers"/. "$HOME/Pictures/wallpapers/"
        log "${GREEN}  [✓]   Wallpapers → ~/Pictures/wallpapers/${NC}"
    fi

    # ── Shared: wlogout ─────────────────────────────────────────────────────────
    if [ -d "$SHARED_DIR/wlogout" ]; then
        mkdir -p "$HOME/.config/wlogout"
        cp -r "$SHARED_DIR/wlogout"/. "$HOME/.config/wlogout/"
        log "${GREEN}  [✓]   wlogout → ~/.config/wlogout/${NC}"
    fi

    # ── Shared: GTK Settings ───────────────────────────────────────────────────
    if [ -d "$SHARED_DIR/gtk" ]; then
        mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
        [ -f "$SHARED_DIR/gtk/gtk-3.0/settings.ini" ] && cp "$SHARED_DIR/gtk/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"
        [ -f "$SHARED_DIR/gtk/gtk-4.0/settings.ini" ] && cp "$SHARED_DIR/gtk/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"
        log "${GREEN}  [✓]   GTK settings applied${NC}"
    fi

    # ── Shared: Fuentes ─────────────────────────────────────────────────────────
    if [ -d "$SHARED_DIR/fonts" ]; then
        mkdir -p "$HOME/.local/share/fonts/cazil"
        cp -r "$SHARED_DIR/fonts"/. "$HOME/.local/share/fonts/cazil/"
        [ -f "$SHARED_DIR/fonts/10-nerd-font-symbols.conf" ] && {
            mkdir -p "$HOME/.config/fontconfig/conf.d"
            cp "$SHARED_DIR/fonts/10-nerd-font-symbols.conf" \
               "$HOME/.config/fontconfig/conf.d/"
        }
        fc-cache -f > /dev/null 2>&1
        log "${GREEN}  [✓]   Fuentes → ~/.local/share/fonts/cazil/${NC}"
    fi

    # ── Shared: GRUB ────────────────────────────────────────────────────────────
    if [ -d "$SHARED_DIR/grub/cyberpunk" ]; then
        local grub_dest="/boot/grub/themes/cazil-cyberpunk"
        sudo mkdir -p "$grub_dest"
        sudo cp -r "$SHARED_DIR/grub/cyberpunk"/. "$grub_dest/"
        [ -f "$SHARED_DIR/grub/wallpapers/bg_grub1_con_logo.png" ] && \
            sudo cp "$SHARED_DIR/grub/wallpapers/bg_grub1_con_logo.png" "$grub_dest/"
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
    if [ -d "$SHARED_DIR/plymouth/themes" ]; then
        local ply_dest="/usr/share/plymouth/themes/cazil-cyber"
        sudo mkdir -p "$ply_dest"
        sudo cp -r "$SHARED_DIR/plymouth/themes"/. "$ply_dest/"
        # Si el wallpaper existe, copiarlo al tema también
        [ -f "$SHARED_DIR/grub/wallpapers/bg_grub1_con_logo.png" ] && \
            sudo cp "$SHARED_DIR/grub/wallpapers/bg_grub1_con_logo.png" "$ply_dest/"
        # Activar el tema (Debian y Arch)
        if command_exists plymouth-set-default-theme; then
            sudo plymouth-set-default-theme -R cazil-cyber 2>/dev/null || true
        elif command_exists update-alternatives; then
            sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
                default.plymouth "$ply_dest/cazil-cyber.plymouth" 100 2>/dev/null || true
            sudo update-alternatives --set default.plymouth "$ply_dest/cazil-cyber.plymouth" 2>/dev/null || true
            sudo update-initramfs -u 2>/dev/null || sudo mkinitcpio -P 2>/dev/null || true
        fi
        log "${GREEN}  [✓]   Plymouth → $ply_dest (tema activo)${NC}"
    fi

    # ── Shared: Protección GRUB con contraseña ───────────────────────────────────
    if ask "¿Configurar contraseña de GRUB? (protege edición de entradas ante acceso físico)"; then
        if [ -f "$SHARED_DIR/grub/setup-grub-password.sh" ]; then
            bash "$SHARED_DIR/grub/setup-grub-password.sh"
        else
            log "${YELLOW}[!] setup-grub-password.sh no encontrado. Puedes correrlo después manualmente.${NC}"
            log "${CYAN}    sudo bash $SHARED_DIR/grub/setup-grub-password.sh${NC}"
        fi
    fi

    # ── Shared: Scripts de utilidad (rgb, fans, brillo, gpu, etc.) ───────────────
    mkdir -p "$HOME/.local/bin"
    local SSCRIPT="$SHARED_DIR/sscript"

    # Copiar todos los scripts disponibles
    for script in "$SSCRIPT"/*.sh "$SSCRIPT"/*/*.sh; do
        [ -f "$script" ] || continue
        local name=$(basename "$script" .sh)
        # Nombres amigables
        case "$name" in
            nitro-fans) name="fans" ;;
            ResolverBrilloBug) name="brillo1" ;;
            ResolverBrilloBug2) name="brillo2" ;;
            load_acer_rgb) name="rgb-load" ;;
            alternar_pantallas) name="monitor-toggle" ;;
            power-save) name="eco-mode" ;;
            gpu-check) name="gpu-check" ;;
            modo_avion) name="modo_avion" ;;
            tema) name="tema" ;;
            ssh-monitor) name="ssh-monitor" ;;
            limpiar_kali) name="limpiar-kali" ;;
            crear_maquina) name="crear-maquina" ;;
            battery-limit) name="battery-limit" ;;
            docker_init) name="docker_init" ;;
            docker_delete) name="delete_total" ;;
        esac
        cp "$script" "$HOME/.local/bin/$name"
        chmod +x "$HOME/.local/bin/$name"
        log "${GREEN}  [✓]   $name → ~/.local/bin/$name${NC}"
    done

    # Ajustes especiales para fans
    if [ -f "$HOME/.local/bin/fans" ]; then
        if ! grep -q "ec_sys" /etc/modules-load.d/*.conf 2>/dev/null; then
            echo "ec_sys" | sudo tee /etc/modules-load.d/ec_sys.conf > /dev/null
        fi
        if ! grep -q "write_support" /etc/modprobe.d/*.conf 2>/dev/null; then
            echo "options ec_sys write_support=1" | sudo tee /etc/modprobe.d/ec_sys.conf > /dev/null
        fi
        sudo modprobe ec_sys write_support=1 2>/dev/null || true
    fi

    # Configuración de límite de batería (Service)
    if [ -f "$SSCRIPT/battery-limit.service" ]; then
        sudo cp "$SSCRIPT/battery-limit.service" "/etc/systemd/system/battery-limit.service"
        sudo systemctl daemon-reload
        sudo systemctl enable battery-limit.service 2>/dev/null || true
        log "${GREEN}  [✓]   battery-limit.service habilitado (80% Default)${NC}"
    fi

    log ""
    log "${GREEN}  ══ Deploy completo. Sistema independiente del repo. ══${NC}"
    log ""
}

install_rgb() {
    local RGB_SRC="$SHARED_DIR/sscript/rgb"
    if [ ! -f "$RGB_SRC/install.sh" ]; then
        log "${YELLOW}[!] sscript/rgb/install.sh no encontrado. Saltando.${NC}"; return
    fi
    ask "¿Instalar driver RGB Acer Nitro?" || return

    if [ "$DISTRO" = "arch" ]; then
        pac dkms python base-devel
        local kernel; kernel=$(uname -r)
        echo "$kernel" | grep -q "lts" && pac linux-lts-headers || \
        echo "$kernel" | grep -q "zen" && pac linux-zen-headers || pac linux-headers
    else
        pac dkms python3 build-essential "linux-headers-$(uname -r)"
    fi

    sudo bash "$RGB_SRC/install.sh"

    local LIB_DIR="/usr/local/lib/nitro-rgb"
    sudo mkdir -p "$LIB_DIR"
    for f in nitro_rgb.py facer_rgb.py teclado_neon.py teclado_rgb.sh; do
        [ -f "$RGB_SRC/$f" ] && sudo cp "$RGB_SRC/$f" "$LIB_DIR/"
    done
    [ -f "$LIB_DIR/teclado_rgb.sh" ] && sudo chmod +x "$LIB_DIR/teclado_rgb.sh"

    sudo tee /usr/local/bin/nitro-rgb > /dev/null << 'WRAPPER'
#!/bin/bash
python3 /usr/local/lib/nitro-rgb/nitro_rgb.py "$@"
WRAPPER
    sudo chmod +x /usr/local/bin/nitro-rgb
    log "${GREEN}[✓] RGB instalado. Uso: nitro-rgb --all -cR 0 -cG 255 -cB 0${NC}"
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
    deploy_configs
    log "${GREEN}[✓] Dotfiles aplicados. ¡Listo!${NC}"
    exit 0
fi

log "${CYAN}════ PASO 1: PAQUETES ════${NC}"
install_pkgs

log "${CYAN}════ PASO 2: RGB + Características especiales ════${NC}"
install_rgb

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
log "${GREEN}Scripts: fans | brillo1 | brillo2 | nitro-rgb${NC}"
