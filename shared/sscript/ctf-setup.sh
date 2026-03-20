#!/bin/bash
# ctf-setup.sh - Initial configuration for CTF platforms

CONFIG="$HOME/.config/ctf-stats/ctf.conf"
mkdir -p "$(dirname "$CONFIG")"

[ -f "$CONFIG" ] && grep -q "=" "$CONFIG" && exit 0

echo "⚡ Primera configuración CTF"
echo "Deja en blanco lo que no uses"
echo ""

plataformas=(
    "HTB_USER:HackTheBox username"
    "PICO_USER:picoCTF username"
    "THM_USER:TryHackMe username"
    "CTF_USER:CTFtime username"
)

for p in "${plataformas[@]}"; do
    key="${p%%:*}"
    desc="${p##*:}"
    echo -ne "👾 $desc: "
    read -r valor
    [ -n "$valor" ] && echo "export $key=\"$valor\"" >> "$CONFIG"
done

echo ""
notify-send -t 5000 "⚡ SYSTEM" "Configuración CTF guardada 🔥"
