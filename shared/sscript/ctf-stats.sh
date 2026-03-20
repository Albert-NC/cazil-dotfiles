#!/bin/bash
# ctf-stats.sh - Fetch CTF scores from various platforms

CONFIG="$HOME/.config/ctf-stats/ctf.conf"
PUNTOS_FILE="$HOME/.local/share/puntos"

[ -f "$CONFIG" ] && source "$CONFIG" 2>/dev/null

resultado=""

# picoCTF
[ -n "$PICO_USER" ] && {
    pico=$(curl -s "https://play.picoctf.org/api/v1/user/$PICO_USER/" \
        -H "Accept: application/json" | \
        python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('score','?'))
" 2>/dev/null || echo "?")
    resultado="pico:$pico"
}

# HackTheBox
[ -n "$HTB_USER" ] && {
    htb=$(curl -s "https://www.hackthebox.com/api/v4/user/profile/basic/$HTB_USER" \
        -H "Accept: application/json" | \
        python3 -c "
import sys,json
d=json.load(sys.stdin).get('profile',{})
print(d.get('points','?'))
" 2>/dev/null || echo "?")
    resultado="${resultado:+$resultado | }htb:$htb"
}

# TryHackMe
[ -n "$THM_USER" ] && \
    resultado="${resultado:+$resultado | }thm:?"

# CTFtime
[ -n "$CTF_USER" ] && \
    resultado="${resultado:+$resultado | }ctf:?"

# puntos propios
pts=$(cat "$PUNTOS_FILE" 2>/dev/null || echo 0)
resultado="${resultado:+$resultado | }pts:$pts"

echo "$resultado"
