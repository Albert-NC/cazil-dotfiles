#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — wallpaper-dinamico.sh
# Activa (gif-on) o Desactiva (gif-off) fondos animados
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
GIF_DIR="$HOME/Pictures/gifs"
FAVORITE="22222332.gif"
MODE=$1 # "on" o "off"

if [ "$MODE" == "off" ]; then
    echo -e "${YELLOW}[*] Desactivando modo animado y regresando a estático...${NC}"
    pkill swww-daemon
    if ! pgrep -x "hyprpaper" > /dev/null; then
        hyprpaper &
    fi
    notify-send "Wallpaper" "Modo Estático Activado 🖼️" -i image-x-generic
    exit 0
fi

# MODO ON (por defecto)
# 1. Verificar si swww está instalado
if ! command -v swww &> /dev/null; then
    echo -e "${RED}[!] swww no está instalado. Instálalo con 'pacman -S swww'${NC}"
    exit 1
fi

# 2. Detener hyprpaper para evitar conflictos de recursos
pkill hyprpaper

# 3. Iniciar el daemon de swww si no está corriendo
if ! pgrep -x "swww-daemon" > /dev/null; then
    echo -e "${GREEN}[*] Iniciando swww-daemon...${NC}"
    swww-init &
    sleep 1
fi

# 4. Aplicar GIF Favorito (Siempre)
GIF_FINAL="$FAVORITE"

GIF_FULL_PATH="$GIF_DIR/$GIF_FINAL"

# 4. Aplicar el GIF seleccionado
if [ -f "$GIF_FULL_PATH" ]; then
    echo -e "${GREEN}[*] Aplicando fondo animado ($DADO%): $GIF_FINAL${NC}"
    swww img "$GIF_FULL_PATH" --transition-type center --transition-step 90
    # Restaurar tema normal (y transparencia) si veníamos del modo exponer
    tema PC
    notify-send "Wallpaper" "Modo Animado: $GIF_FINAL 🌌 (Transparencia Restaurada)" -i video-display
else
    echo -e "${RED}[!] No se encontró el GIF en $GIF_FULL_PATH${NC}"
fi
