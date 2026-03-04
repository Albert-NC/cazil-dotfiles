# .zshrc — cazil-dotfiles (Compartido entre todos los temas)
# ============================================================

# --- PATH ---
export PATH=$HOME/.local/bin:$PATH

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory histignorespace histignoredups

# --- Starship prompt ---
eval "$(starship init zsh)"

# --- Shell options ---
setopt interactive_comments
bindkey -e
autoload -U colors && colors

# --- Plugins ---
# Intenta cargar desde paths de Arch y Debian indistintamente
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || \
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null || \
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null

# --- Aliases generales ---
alias ls='ls --color=auto'
alias ll='ls -lv --group-directories-first'
alias grep='grep --color=auto'
alias v='nvim'
alias shut='sudo shutdown now'
alias reb='sudo reboot'

# Detectar gestor de paquetes y ajustar alias update
if command -v pacman &>/dev/null; then
    alias update='sudo pacman -Syu'
elif command -v apt &>/dev/null; then
    alias update='sudo apt update && sudo apt upgrade'
fi

# Alias para ir al repo de dotfiles (ajusta la ruta si cambias la ubicación)
alias dots='cd ~/Proyectos/VisualS/cazil-dotfiles'

# --- Aliases de GPU / NVIDIA ---
alias gpu-status='nvidia-smi --query-gpu=pstate --format=csv,noheader 2>/dev/null && cat /proc/driver/nvidia/gpus/*/power 2>/dev/null'
alias prime-run='__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia'

# --- Aliases de energía ---
alias eco-on='eco-mode on'
alias eco-off='eco-mode off'
alias anims='anims'
alias tema='tema'

# --- Aliases de seguridad ---
alias usb-security='sudo usbguard list-devices'
alias usb-allow='sudo usbguard allow-device'
alias usb-block='sudo usbguard block-device'
alias usb-reject='sudo usbguard reject-device'
alias fw-status='sudo ufw status verbose'
alias scan-virus='sudo freshclam && clamscan -r ~'
alias scan-rootkit='sudo rkhunter --check'

# --- Aliases de Docker ---
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias di='docker images'
alias dc='docker-compose'
alias dstop='docker stop $(docker ps -aq)'
alias dremove='docker rm $(docker ps -aq) && docker rmi $(docker images -q)'

# --- Aliases de Virtualización ---
alias vms='virt-manager'
alias vm-list='virsh list --all'

# --- Fastfetch al inicio ---
fastfetch
