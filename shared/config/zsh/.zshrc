# ==============================================================================
# CAZIL SYSTEM - ZSHRC MASTER CONFIGURATION
# Version: 2.1 Ultra-Optimized (Arch/Debian Agnostic)
# ==============================================================================

# --- PERFORMANCE: ZPROF (Descomentar para diagnosticar) ---
# zmodload zsh/zprof

# --- 1. PROMPT Y PLUGINS ---
# Cache de Starship para arranque instantáneo
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh"
else
  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/starship"
  starship init zsh > "${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh"
  source "${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh"
fi

# Cargar plugins esenciales (Arch/Debian fallback)
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null || source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#fff3a3'
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)
bindkey '^[[C' autosuggest-accept

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# Plugin fzf-tab (completado avanzado)
if [[ -f /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
    source /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
elif [[ -f /usr/share/zsh-fzf-tab/fzf-tab.plugin.zsh ]]; then
    source /usr/share/zsh-fzf-tab/fzf-tab.plugin.zsh
fi

# Configuración fzf-tab (estética y preview)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' switch-group ',' '.'

# --- 2. PATHS Y ENTORNO ---
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export TERM=xterm-256color

# --- 3. CONFIGURACIÓN DE HISTORIAL ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS

# --- 4. STARTUP Y VISUALES ---
if [[ -o interactive ]] && [[ -z "$FASTFETCH_SHOWN" ]]; then
    if command -v fastfetch &>/dev/null; then
        fastfetch
        export FASTFETCH_SHOWN=1
    fi
fi

# Aliases de productividad (con fallback)
alias ls='ls --color=auto'
alias ll='ls -lv --group-directories-first'
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
fi

preexec() { echo }

# --- 5. ALIASES GENERALES Y MANTENIMIENTO ---
alias v='nvim'
alias y='yazi'
alias shut='sudo shutdown now'
alias reb='sudo reboot'

# Detectar gestor de paquetes
if command -v pacman &>/dev/null; then
    alias update='sudo pacman -Syu'
else
    alias update='sudo apt update && sudo apt upgrade'
fi

# Mantenimiento local (independiente del repo tras instalación)
alias limpiar-kali='bash $HOME/.local/bin/limpiar-kali'
alias crear-maquina='bash $HOME/.local/bin/crear-maquina'
alias dots='cd $HOME/cazil-dotfiles'
alias pdf='bash $HOME/.local/bin/pdf'
alias ctf-stats='bash $HOME/.local/bin/ctf-stats'
alias ctf-setup='bash $HOME/.local/bin/ctf-setup'

# --- 6. ENERGÍA Y BATERÍA ---
alias battery-limit='bash $HOME/.local/bin/battery-limit'
alias battery-100='bash $HOME/.local/bin/battery-limit 100'
alias eco-on='bash $HOME/.local/bin/eco-mode on'
alias eco-off='bash $HOME/.local/bin/eco-mode off'
alias anims='bash $HOME/.local/bin/toggle-animations'
alias gif-on='bash $HOME/.local/bin/gif-on on'
alias gif-off='bash $HOME/.local/bin/gif-on off'
alias tema='bash $HOME/.local/bin/tema'
alias gaming-mode='bash $HOME/.local/bin/gaming-mode'

# --- MODOS DE SEGURIDAD COMBINADOS ---
alias modo='bash $HOME/.local/bin/modo'
alias modo-uni='bash $HOME/.local/bin/modo uni'
alias modo-cafe='bash $HOME/.local/bin/modo cafe'
alias modo-casa='bash $HOME/.local/bin/modo casa'
alias modo-avion='bash $HOME/.local/bin/modo avion'
alias modo-normal='bash $HOME/.local/bin/modo normal'
alias modo-estado='bash $HOME/.local/bin/modo estado'

# --- 7. RGB Y PERIFÉRICOS ---
alias docker_init='bash $HOME/.local/bin/docker_init'
alias delete_total='bash $HOME/.local/bin/delete_total'
alias rgb_on='sudo systemctl start nitro-rgb.service'
alias rgb_off='sudo systemctl stop nitro-rgb.service'
alias rgb_restart='sudo systemctl restart nitro-rgb.service'
alias rgb_status='sudo systemctl status nitro-rgb.service'
alias rgb_log='journalctl -u nitro-rgb.service -f'
alias gpu-status='nvidia-smi --query-gpu=pstate --format=csv,noheader 2>/dev/null && cat /proc/driver/nvidia/gpus/*/power 2>/dev/null'
alias prime-run='__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia'
alias gpu-integrada='sudo envycontrol -s integrated'
alias gpu-hibrido='sudo envycontrol -s hybrid'

# --- 8. DESARROLLO WEB Y DB ---
alias web_on='xdg-open http://127.0.0.1:5500'
alias web_off='kill -9 $(ss -tulpn | grep :5500 | awk -F"pid=" '\''{print $2}'\'' | cut -d"," -f1) 2>/dev/null && echo "Puerto 5500 liberado" || echo "No hay nada corriendo ahí"'
alias mysql_on='sudo systemctl start mysql'
alias mysql_off='sudo systemctl stop mysql'
alias mysql_status='sudo systemctl status mysql'
alias psql_on="sudo systemctl start postgresql"
alias psql_off="sudo systemctl stop postgresql"
alias psql_status="sudo systemctl status postgresql"

# --- 9. QEMU Y VIRTUALIZACIÓN ---
alias kali_on='qemu-system-x86_64 -hda ~/VirtualMachines/qemu/kali01.qcow2 -m 4096 -smp 4 -enable-kvm -netdev bridge,id=net0,br=virbr0 -device virtio-net-pci,netdev=net0 &'
alias kali1_on='qemu-system-x86_64 -hda ~/VirtualMachines/qemu/kali01.qcow2 -m 4096 -smp 4 -enable-kvm -netdev bridge,id=net0,br=virbr0 -device virtio-net-pci,netdev=net0 -display none -daemonize'
alias kali_ssh='ssh kali01@192.168.122.77'
alias kali_off='ssh -t kali01@192.168.122.77 "sudo poweroff"'

alias debian_on='qemu-system-x86_64 -hda ~/VirtualMachines/qemu/debian01.qcow2 -m 2048 -smp 2 -enable-kvm -netdev bridge,id=net0,br=virbr0 -device virtio-net-pci,netdev=net0 -display none -daemonize'
alias debian_ssh='ssh debian01@192.168.122.76'
alias debian_off='ssh -t debian01@192.168.122.76 "sudo poweroff"'
alias arch_on='qemu-system-x86_64 -name arch-hyprland -machine type=q35,accel=kvm -cpu host -smp 8 -m 8G -drive file=$HOME/VirtualMachines/qemu/arch-hyprland.qcow2,format=qcow2,if=virtio -vga std -display sdl,gl=on -netdev bridge,id=net0,br=virbr0 -device virtio-net-pci,netdev=net0 -enable-kvm &'
alias android_on='qemu-system-x86_64 -enable-kvm -m 6144 -smp 6 -cpu host -hda ~/VirtualMachines/qemu/android-final.qcow2 -boot c -vga qxl -display gtk,zoom-to-fit=on -audiodev pa,id=snd0 -device intel-hda -device hda-duplex,audiodev=snd0 &'
alias android_off='pkill -9 qemu-system-x86'
# Herramientas de Mantenimiento
alias limpiar="/usr/local/bin/limpiar-sistema"
alias backup="sudo timeshift-gtk"
alias backup-cli="sudo timeshift"
alias vms='virt-manager'
alias vm-list='virsh list --all'
alias scrcpy_game='scrcpy --turn-screen-off --max-fps 60 --video-bit-rate 12M --audio-source=output'
alias scrcpy_pelis="scrcpy --fullscreen --capture-orientation=0 --video-bit-rate=8M --audio-source=output --audio-buffer=50 > /dev/null 2>&1 &"
alias reset_ssh='ssh-keygen -f ~/.ssh/known_hosts -R "[localhost]:2223"'

# --- 10. ALIASES DE SEGURIDAD ---
alias firewall='sudo ufw status verbose'
alias firewall-lista='sudo ufw status numbered'
alias firewall-activar='sudo ufw enable'
alias firewall-desactivar='sudo ufw disable'
alias firewall-recargar='sudo ufw reload'
alias firewall-reset='sudo ufw --force reset'
alias puerto-abrir='sudo ufw allow'
alias puerto-cerrar='sudo ufw deny'
alias puerto-eliminar='sudo ufw delete'

alias usb-ls='sudo usbguard list-devices'
alias usb-bloqueados='sudo usbguard list-devices | grep block'
alias usb-autorizados='sudo usbguard list-devices | grep allow'
alias usb-autorizar='sudo usbguard allow-device'
alias usb-confiar='sudo usbguard allow-device'
alias usb-bloquear='sudo usbguard block-device'
alias usb-rechazar='sudo usbguard reject-device'
alias usb-log='sudo tail -f /var/log/usbguard/usbguard-audit.log'
alias usb-reglas='sudo nano /etc/usbguard/rules.conf'
alias puertos='sudo ss -tulnp'
alias puertos-escucha='sudo lsof -i -P -n | grep LISTEN'
alias conexiones='sudo ss -tup'
alias conexiones-tcp='sudo ss -antp'
alias log-autenticacion='sudo tail -f /var/log/auth.log 2>/dev/null || sudo tail -f /var/log/secure 2>/dev/null'
alias log-sistema='sudo tail -f /var/log/syslog 2>/dev/null || sudo journalctl -f'
alias log-intentos-fallidos='sudo grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20'
alias log-sudo='sudo grep "sudo" /var/log/auth.log 2>/dev/null | tail -20'
alias estado-seguridad='echo "╔════════════════════════════════════════════════════════════╗"; echo "║           ESTADO DE SEGURIDAD SISTEMA                    ║"; echo "╚════════════════════════════════════════════════════════════╝"; echo ""; echo "🛡️  UFW:       $(systemctl is-active ufw 2>/dev/null || echo "N/A")"; echo "🔌 USBGuard:  $(systemctl is-active usbguard 2>/dev/null || echo "N/A")"; echo ""'
alias seguridad='estado-seguridad'

alias redes-on='bash $HOME/.local/bin/redes on'
alias redes-off='bash $HOME/.local/bin/redes off'
alias bt-on='bash $HOME/.local/bin/bt on'
alias bt-off='bash $HOME/.local/bin/bt off'


usb_autorizar_permanente() {
    if [[ -z "$1" ]]; then echo "Uso: usb_autorizar_permanente <ID>"; else
        info=$(sudo usbguard list-devices | grep "^$1:"); [[ -z "$info" ]] && return 1
        regla=$(echo "$info" | sed 's/^[0-9]*: //')
        echo -n "¿Autorizar permanentemente? $regla (s/n): "; read confirmar
        [[ "$confirmar" == "s" ]] && sudo usbguard append-rule "$regla"
    fi
}
bloquear_ip() { [[ -z "$1" ]] && echo "Uso: bloquear_ip <IP>" || sudo ufw deny from "$1"; }
desbloquear_ip() { [[ -z "$1" ]] && echo "Uso: desbloquear_ip <IP>" || echo "Fail2Ban no instalado"; }
resumen_seguridad() {
    echo "🛡️  FIREWALL: $(sudo ufw status | head -1)"; 
    echo "🔌 USBGUARD: $(sudo usbguard list-devices 2>/dev/null | wc -l) dispositivos";
}

# --- 11. CTF STATS SETUP ---
# Primera vez pregunta, después carga silencioso
[ -f "$HOME/.config/ctf-stats/ctf.conf" ] || {
    [ -x "$HOME/.local/bin/ctf-setup" ] && bash "$HOME/.local/bin/ctf-setup"
}
source "$HOME/.config/ctf-stats/ctf.conf" 2>/dev/null

# --- 12. INICIALIZACIÓN DE HERRAMIENTAS ---
eval "$(zoxide init zsh)"

# --- 13. COMPLETADO INSENSIBLE A MAYÚSCULAS ---
# Permite que 'cd descargas' complete a 'Downloads' o 'Descargas'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'm:{A-Z}={a-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# --- 13. COMMAND NOT FOUND HANDLER (PROMPT TO INSTALL) ---
autoload -Uz compinit && compinit
# Colores para el prompt (fallback si no están definidos)
[ -z "$NC" ] && NC='\033[0m'
[ -z "$CYAN" ] && CYAN='\033[0;36m'
[ -z "$YELLOW" ] && YELLOW='\033[1;33m'
[ -z "$GREEN" ] && GREEN='\033[0;32m'

command_not_found_handler() {
    local cmd="$1"
    local pkgs=()
    
    # ── Buscar paquetes que contienen el comando ──────────────────────
    if command -v pkgfile &>/dev/null; then
        # Arch Linux con pkgfile (rápido)
        pkgs=($(pkgfile -b "$cmd" 2>/dev/null))
    elif [[ -f /usr/lib/command-not-found ]] || command -v command-not-found &>/dev/null; then
        # Debian/Ubuntu (usar su lógica interna)
        if [[ -x /usr/lib/command-not-found ]]; then
           /usr/lib/command-not-found -- "$cmd"
           return $?
        fi
    elif command -v pacman &>/dev/null; then
        # Arch Linux fallback (pacman -F)
        pkgs=($(pacman -Fq "/usr/bin/$cmd" 2>/dev/null | cut -d'/' -f2))
    fi

    [[ ${#pkgs[@]} -eq 0 ]] && {
        echo -e "zsh: command not found: $cmd"
        return 127
    }

    # ── Preguntar al usuario ──────────────────────────────────────────
    echo -e "${YELLOW}ℹ El comando '${cmd}' no está instalado.${NC}"
    echo -ne "${CYAN}¿Deseas instalar el paquete '${pkgs[1]}'? (s/n): ${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Ss]$ ]]; then
        if command -v pacman &>/dev/null; then
            sudo pacman -S "${pkgs[1]}"
        elif command -v apt &>/dev/null; then
            sudo apt update && sudo apt install "${pkgs[1]}"
        fi
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[✓] Instalado correctamente. Ejecutando de nuevo...${NC}\n"
            # Recargar el hash de comandos para que ZSH encuentre el nuevo ejecutable
            rehash
            "$@"
        fi
    else
        return 127
    fi
}
