#!/bin/bash
# tema.sh — Selector dinámico de colores para el tema 218 (Cyberpunk)
# Uso: tema [PC|PP|VV|PM|PB|CC|BG|WB|LG]

# --- Directorios ---
CONFIG_DIR="$HOME/.config/hypr"
ROFI_FILE="$HOME/.config/rofi/cazil_theme.rasi"
WAYBAR_FILE="$HOME/.config/waybar/style.css"
WINDOWS_FILE="$HOME/.config/hypr/windows.conf"
LOCK_FILE="$HOME/.config/hypr/hyprlock.conf"

# --- Paletas de Colores ---
case "${1^^}" in
    "PC")  C1="#ff69b4"; C2="#00ffff" ;; # Pink + Cyan (Oficial)
    "PP")  C1="#8b00ff"; C2="#ff69b4" ;; # Purple + Pink
    "VV")  C1="#ee82ee"; C2="#ff4500" ;; # Violet + Vermillion
    "PM")  C1="#8b00ff"; C2="#ff00ff" ;; # Purple + Magenta
    "PB")  C1="#ff69b4"; C2="#0000ff" ;; # Pink + Blue
    "CC")  C1="#00ffff"; C2="#ff6b6b" ;; # Cyan + Coral
    "BG")  C1="#1a1a1a"; C2="#00ff00" ;; # Black + Green
    "WB")  C1="#f0f0f0"; C2="#1a1a1a" ;; # White + Black
    "LG")  C1="#b57edc"; C2="#a8d8ea" ;; # Lavender + Glacial
    *)
        echo "Uso: tema [PC|PP|VV|PM|PB|CC|BG|WB|LG]"
        echo "Ejemplo: tema PP"
        exit 1
        ;;
esac

echo "Cambiando tema a: $1 ($C1 + $C2)..."

# --- Función de limpieza de hex (quitar #) ---
C1_HEX=${C1#\#}
C2_HEX=${C2#\#}

# 1. Actualizar Rofi
if [ -f "$ROFI_FILE" ]; then
    sed -i "s/color1:  #[0-9a-fA-F]\{6\}/color1:  $C2/g" "$ROFI_FILE"
    sed -i "s/color2:  #[0-9a-fA-F]\{6\}/color2:  $C1/g" "$ROFI_FILE"
fi

# 2. Actualizar Waybar
if [ -f "$WAYBAR_FILE" ]; then
    # Usamos C2 como color de borde inferior (el cyan por defecto)
    sed -i "s/border-bottom: 2px solid #[0-9a-fA-F]\{6\}/border-bottom: 2px solid $C2/g" "$WAYBAR_FILE"
fi

# 3. Actualizar Windows.conf (Bordes Hyprland)
if [ -f "$WINDOWS_FILE" ]; then
    # Actualizar bordes activos (usan rgba)
    # Actualizar bordes activos (usan rgba)
    sed -i "s/rgba([0-9a-fA-F]\{6\}[ef]\{2\}) rgba([0-9a-fA-F]\{6\}[ef]\{2\})/rgba(${C1_HEX}ee) rgba(${C2_HEX}ee)/g" "$WINDOWS_FILE"
fi

# 4. Actualizar Hyprlock.conf
if [ -f "$LOCK_FILE" ]; then
    sed -i "s/outer_color = rgb([0-9a-fA-F]\{6\})/outer_color = rgb(${C2_HEX})/g" "$LOCK_FILE"
    sed -i "s/font_color = rgb([0-9a-fA-F]\{6\})/font_color = rgb(${C2_HEX})/g" "$LOCK_FILE"
    sed -i "s/check_color = rgb([0-9a-fA-F]\{6\})/check_color = rgb(${C1_HEX})/g" "$LOCK_FILE"
fi

# --- Notificar y Recargar ---
# Recargar Waybar
killall waybar && waybar & disown
# Recargar Hyprland (solo si es necesario, Hyprland recarga configs al guardar)
# hyprctl reload

notify-send "Tema Actualizado" "Nuevo estilo: $1" -i colors-symbolic
echo "¡Hecho! Disfruta tu nuevo look."
