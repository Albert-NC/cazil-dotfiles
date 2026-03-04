# .zshrc - cazil-dotfiles (Tema 218 - Cyberpunk)

# --- Path ---
export PATH=$HOME/.local/bin:$PATH

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory histignorespace histignoredups

# --- Starship ---
eval "$(starship init zsh)"

# --- Shell options ---
setopt interactive_comments
bindkey -e

# --- Colors ---
autoload -U colors && colors

# --- Plugins (assuming installed via pacman/apt) ---
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || \
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null || \
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null

# --- Aliases ---
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias cat='bat' 2>/dev/null || alias cat='cat'
alias v='nvim'
alias shut='sudo shutdown now'
alias reb='sudo reboot'
alias update='sudo pacman -Syu' # Arch default
alias dots='cd ~/Proyectos/VisualS/cazil-dotfiles'
alias gpu-status='nvidia-smi --query-gpu=pstate --format=csv,noheader && cat /proc/driver/nvidia/gpus/*/power'
alias prime-run='__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia'
alias eco-on='bash ~/.local/bin/eco-mode on'
alias eco-off='bash ~/.local/bin/eco-mode off'

# --- Security ---
alias usb-security='sudo usbguard list-devices'
alias usb-allow='sudo usbguard allow-device'
alias usb-block='sudo usbguard block-device'
alias usb-reject='sudo usbguard reject-device'
alias fw-status='sudo ufw status verbose'
alias scan-virus='sudo freshclam && clamscan -r ~'
alias scan-rootkit='sudo rkhunter --check'

# --- Custom ---
fastfetch
