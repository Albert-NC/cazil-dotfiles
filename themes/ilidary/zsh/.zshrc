# .zshrc - cazil-dotfiles (Tema Ilidary - Minimal Green)

# --- Path ---
export PATH=$HOME/.local/bin:$PATH

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt appendhistory sharehistory histignorespace histignoredups

# --- Starship ---
eval "$(starship init zsh)"

# --- Shell options ---
setopt interactive_comments
bindkey -e

# --- Aliases ---
alias ls='ls --color=auto'
alias ll='ls -lv --group-directories-first'
alias grep='grep --color=auto'
alias gs='git status'
alias update='sudo apt update && sudo apt upgrade' # Debian default
alias gpu-status='nvidia-smi --query-gpu=pstate --format=csv,noheader && cat /proc/driver/nvidia/gpus/*/power'
alias prime-run='__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia'
alias eco-on='bash ~/.local/bin/eco-mode on'
alias eco-off='bash ~/.local/bin/eco-mode off'

# --- Security ---
alias usb-security='sudo usbguard list-devices'
alias usb-allow='sudo usbguard allow-device'
alias usb-block='sudo usbguard block-device'
alias fw-status='sudo ufw status'
alias scan-virus='clamscan -r ~'

# --- Fastfetch (simple) ---
fastfetch
