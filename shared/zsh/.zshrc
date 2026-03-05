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

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# --- 2. PATHS Y ENTORNO ---
export PATH="$HOME/.local/bin:$PATH"
export PATH=/usr/local/bin:$PATH
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
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lh --icons --grid --group-directories-first'
    alias lt='eza --tree --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -lv --group-directories-first'
fi

if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
    alias catp='bat'
fi

if command -v btop &>/dev/null; then
    alias top='btop'
    alias htop='btop'
fi

alias lg='lazygit'
alias ld='lazydocker'
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
alias dots='cd ~/Proyectos/VisualS/cazil-dotfiles'

# --- 6. ENERGÍA Y BATERÍA ---
alias battery-limit='battery-limit'
alias battery-100='battery-limit 100'
alias eco-on='eco-mode on'
alias eco-off='eco-mode off'
alias anims='anims'
alias tema='tema'

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

# --- 8. DESARROLLO WEB Y DB ---
alias web_on='xdg-open http://127.0.0.1:5500'
alias web_off='kill -9 $(ss -tulpn | grep :5500 | awk -F"pid=" "{print \$2}" | cut -d"," -f1) 2>/dev/null && echo "Puerto 5500 liberado" || echo "No hay nada corriendo ahí"'
alias mysql_on='sudo systemctl start mysql'
alias mysql_off='sudo systemctl stop mysql'
alias mysql_status='sudo systemctl status mysql'
alias psql_on="sudo systemctl start postgresql"
alias psql_off="sudo systemctl stop postgresql"
alias psql_status="sudo systemctl status postgresql"

# --- 9. QEMU Y VIRTUALIZACIÓN ---
alias kali_on='qemu-system-x86_64 -hda ~/Proyectos/qemu/maquinas/kali01.qcow2 -m 4096 -smp 4 -enable-kvm -netdev bridge,id=net0,br=virbr0 -device virtio-net-pci,netdev=net0 &'
alias kali1_on='qemu-system-x86_64 -hda ~/Proyectos/qemu/maquinas/kali01.qcow2 -m 4096 -smp 4 -enable-kvm -netdev bridge,id=net0,br=virbr0 -device virtio-net-pci,netdev=net0 -display none -daemonize'
alias kali_ssh='ssh kali01@192.168.122.77'
alias kali_off='ssh -t kali01@192.168.122.77 "sudo poweroff"'
alias debian_on='qemu-system-x86_64 -hda ~/Proyectos/qemu/maquinas/debian01.qcow2 -m 2048 -smp 2 -enable-kvm -netdev bridge,id=net0,br=virbr0 -device virtio-net-pci,netdev=net0 -display none -daemonize'
alias debian_ssh='ssh debian01@192.168.122.76'
alias debian_off='ssh -t debian01@192.168.122.76 "sudo poweroff"'
alias arch_on='qemu-system-x86_64 -name arch-hyprland -machine type=q35,accel=kvm -cpu host -smp 8 -m 8G -drive file=$HOME/Proyectos/qemu/maquinas/arch-hyprland.qcow2,format=qcow2,if=virtio -vga std -display sdl,gl=on -netdev bridge,id=net0,br=virbr0 -device virtio-net-pci,netdev=net0 -enable-kvm &'
alias android_on='qemu-system-x86_64 -enable-kvm -m 6144 -smp 6 -cpu host -hda ~/Proyectos/qemu/maquinas/android-final.qcow2 -boot c -vga qxl -display gtk,zoom-to-fit=on -audiodev pa,id=snd0 -device intel-hda -device hda-duplex,audiodev=snd0 &'
alias android_off='pkill -9 qemu-system-x86'
alias vms='virt-manager'
alias vm-list='virsh list --all'
alias scrcpy_game='scrcpy --turn-screen-off --max-fps 60 --video-bit-rate 12M --audio-source=output'
alias scrcpy_pelis="scrcpy --fullscreen --capture-orientation=0 --video-bit-rate=8M --audio-source=output --audio-buffer=50 > /dev/null 2>&1 &"
alias reset_ssh='ssh-keygen -f ~/.ssh/known_hosts -R "[localhost]:2223"'

# --- 10. ALIASES DE SEGURIDAD ---
alias aa-estado='sudo aa-status'
alias aa-permisivo='sudo aa-complain'
alias aa-estricto='sudo aa-enforce'
alias firewall='sudo ufw status verbose'
alias firewall-lista='sudo ufw status numbered'
alias firewall-activar='sudo ufw enable'
alias firewall-desactivar='sudo ufw disable'
alias firewall-recargar='sudo ufw reload'
alias firewall-reset='sudo ufw --force reset'
alias puerto-abrir='sudo ufw allow'
alias puerto-cerrar='sudo ufw deny'
alias puerto-eliminar='sudo ufw delete'
alias fail2ban='sudo fail2ban-client status'
alias fail2ban-ssh='sudo fail2ban-client status sshd'
alias fail2ban-bloqueados='sudo fail2ban-client banned'
alias fail2ban-desbloquear='sudo fail2ban-client unban'
alias fail2ban-log='sudo tail -f /var/log/fail2ban.log'
alias fail2ban-reiniciar='sudo systemctl restart fail2ban'
alias antivirus-actualizar='sudo systemctl stop clamav-freshclam && sudo freshclam && sudo systemctl start clamav-freshclam'
alias antivirus-escanear='clamscan -r --bell -i'
alias escanear-home='clamscan -r /home --bell -i'
alias antivirus-estado='sudo systemctl status clamav-freshclam'
alias antivirus-log='sudo tail -f /var/log/clamav/freshclam.log'
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
alias buscar-suid='sudo find / -perm -4000 -type f 2>/dev/null'
alias buscar-777='sudo find / -type f -perm 0777 2>/dev/null'
alias estado-seguridad='echo "╔════════════════════════════════════════════════════════════╗"; echo "║           ESTADO DE SEGURIDAD SISTEMA                    ║"; echo "╚════════════════════════════════════════════════════════════╝"; echo ""; echo "🔒 AppArmor:  $(systemctl is-active apparmor 2>/dev/null || echo "N/A")"; echo "🛡️  UFW:       $(systemctl is-active ufw 2>/dev/null || echo "N/A")"; echo "🚫 Fail2Ban:  $(systemctl is-active fail2ban 2>/dev/null || echo "N/A")"; echo "🦠 ClamAV:    $(systemctl is-active clamav-freshclam 2>/dev/null || echo "N/A")"; echo "🔌 USBGuard:  $(systemctl is-active usbguard 2>/dev/null || echo "N/A")"; echo ""'
alias seguridad='estado-seguridad'

# --- 11. FUNCIONES DE SEGURIDAD ---
escanear_usb() { [[ -z "$1" ]] && echo "Uso: escanear_usb /media/usb" || clamscan -r "$1" --bell -i; }
usb_autorizar_permanente() {
    if [[ -z "$1" ]]; then echo "Uso: usb_autorizar_permanente <ID>"; else
        info=$(sudo usbguard list-devices | grep "^$1:"); [[ -z "$info" ]] && return 1
        regla=$(echo "$info" | sed 's/^[0-9]*: //')
        echo -n "¿Autorizar permanentemente? $regla (s/n): "; read confirmar
        [[ "$confirmar" == "s" ]] && sudo usbguard append-rule "$regla"
    fi
}
bloquear_ip() { [[ -z "$1" ]] && echo "Uso: bloquear_ip <IP>" || sudo ufw deny from "$1"; }
desbloquear_ip() { [[ -z "$1" ]] && echo "Uso: desbloquear_ip <IP>" || sudo fail2ban-client unban "$1"; }
resumen_seguridad() {
    echo "🔒 APPARMOR: $(sudo aa-status --brief 2>/dev/null)"; echo "🛡️  FIREWALL: $(sudo ufw status | head -1)"; 
    echo "🚫 FAIL2BAN: $(sudo fail2ban-client status 2>/dev/null)"; echo "🔌 USBGUARD: $(sudo usbguard list-devices 2>/dev/null | wc -l) dispositivos";
}
