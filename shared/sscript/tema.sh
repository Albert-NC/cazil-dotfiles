#!/bin/bash
# tema.sh — Selector dinámico de colores para el tema 218 (Cyberpunk)
# Uso: tema [PC|PP|VV|PM|PB|CC|BG|WB|LG]
if ! command -v hyprctl &> /dev/null; then echo "Error: hyprctl no está instalado."; exit 1; fi
if ! command -v notify-send &> /dev/null; then echo "[!] notify-send no instalado."; fi

# --- Archivos de config ---
CONFIG_DIR="$HOME/.config/hypr"
ROFI_FILE="$HOME/.config/rofi/cazil_theme.rasi"
WAYBAR_FILE="$HOME/.config/waybar/style.css"
WINDOWS_FILE="$HOME/.config/hypr/windows.conf"
LOCK_FILE="$HOME/.config/hypr/hyprlock.conf"
MAKO_FILE="$HOME/.config/mako/config"
FF_FILE="$HOME/.config/fastfetch/sample_1.jsonc"

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
    "EX")  C1="#ffffff"; C2="#000000" ;; # Modo Exponer (Blanco + Negro)
    *)
        echo "Uso: tema [PC|PP|VV|PM|PB|CC|BG|WB|LG|EX]"
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
    # Borde principal (SIEMPRE C2) - Soporte para el nuevo diseño floating
    sed -i "s/border: [0-9]px solid #[0-9a-fA-F]\{6\}/border: 2px solid $C2/g" "$WAYBAR_FILE"
    sed -i "s/border-bottom: [0-9]px solid #[0-9a-fA-F]\{6\}/border-bottom: 3px solid $C2/g" "$WAYBAR_FILE"
    
    # Transparencia
    if [ "${1^^}" == "EX" ]; then
        sed -i "s/background: rgba(13, 13, 20, 0.[0-9]\{2\})/background: rgba(13, 13, 20, 1.0)/g" "$WAYBAR_FILE"
    else
        sed -i "s/background: rgba(13, 13, 20, 1.0)/background: rgba(13, 13, 20, 0.95)/g" "$WAYBAR_FILE"
    fi
    
    # Iconos y Texto de acento (SIEMPRE C1)
    # Actualizar Reloj, Network, SSH, Sound, Battery, BT y Workspace activo
    sed -i "/window#waybar {/,/}/ s/color: #[0-9a-fA-F]\{6\}/color: $C1/" "$WAYBAR_FILE"
    sed -i "/#workspaces button.active/,/}/ s/color: #[0-9a-fA-F]\{6\}/color: $C1/" "$WAYBAR_FILE"
    
    # Asegurar que todos los módulos de la derecha usen C1
    for mod in "#cpu" "#memory" "#custom-mac" "#custom-dns" "#custom-ssh" "#custom-sound" "#custom-gpu" "#battery" "#pulseaudio" "#bluetooth" "#network" "#clock"; do
        sed -i "s/$mod { color: #[0-9a-fA-F]\{6\}/$mod { color: $C1/g" "$WAYBAR_FILE"
        # Fallback para archivos que usen saltos de línea
        sed -i "/$mod/,/}/ s/color: #[0-9a-fA-F]\{6\}/color: $C1/" "$WAYBAR_FILE"
    done
    
    # Círculo de Seguridad (Fondo = C2 para contrastar con iconos C1)
    sed -i "s/#custom-security { background: #[0-9a-fA-F]\{6\}/#custom-security { background: $C2/g" "$WAYBAR_FILE"
fi

# 3. Actualizar Windows.conf (Bordes Hyprland y Opacidad)
if [ -f "$WINDOWS_FILE" ]; then
    # Actualizar bordes activos (usan rgba estático)
    sed -i "s/col.active_border = rgba([0-9a-fA-F]\{8\})/col.active_border = rgba(${C1_HEX}ee)/g" "$WINDOWS_FILE"

    # Transparencia global de ventanas
    if [ "${1^^}" == "EX" ]; then
        # Modo Exponer: todo opaco, sin transparencias
        sed -i "s/active_opacity = [0-9.]\+/active_opacity = 1.0/g" "$WINDOWS_FILE"
        sed -i "s/inactive_opacity = [0-9.]\+/inactive_opacity = 1.0/g" "$WINDOWS_FILE"
        # Opacidad en windowrulev2 (kitty y Code)
        sed -i "/windowrulev2 = opacity .* class:\^(kitty)/ s/opacity [0-9.]\+ [0-9.]\+/opacity 1.0 1.0/" "$WINDOWS_FILE"
        sed -i "/windowrulev2 = opacity .* class:\^(Code)/  s/opacity [0-9.]\+ [0-9.]\+/opacity 1.0 1.0/" "$WINDOWS_FILE"
    else
        # Modo normal: restaurar opacidades por defecto
        sed -i "s/active_opacity = [0-9.]\+/active_opacity = 1.0/g" "$WINDOWS_FILE"
        sed -i "s/inactive_opacity = [0-9.]\+/inactive_opacity = 0.95/g" "$WINDOWS_FILE"
        # Restaurar opacidad de kitty (0.9 activa / 0.8 inactiva)
        sed -i "/windowrulev2 = opacity .* class:\^(kitty)/ s/opacity [0-9.]\+ [0-9.]\+/opacity 0.9 0.8/" "$WINDOWS_FILE"
        # Restaurar opacidad de Code (0.95 activa / 0.9 inactiva)
        sed -i "/windowrulev2 = opacity .* class:\^(Code)/  s/opacity [0-9.]\+ [0-9.]\+/opacity 0.95 0.9/" "$WINDOWS_FILE"
    fi
fi

# 4. Actualizar Hyprlock.conf
if [ -f "$LOCK_FILE" ]; then
    sed -i "s/outer_color = rgb([0-9a-fA-F]\{6\})/outer_color = rgb(${C2_HEX})/g" "$LOCK_FILE"
    sed -i "s/font_color = rgb([0-9a-fA-F]\{6\})/font_color = rgb(${C2_HEX})/g" "$LOCK_FILE"
    sed -i "s/check_color = rgb([0-9a-fA-F]\{6\})/check_color = rgb(${C1_HEX})/g" "$LOCK_FILE"
fi

# 5. Actualizar Mako (notificaciones) — bordes con los colores del tema
if [ -f "$MAKO_FILE" ]; then
    # Border global (fuera de secciones)
    sed -i "0,/^border-color=#[0-9a-fA-F]\{6\}/s//border-color=$C2/" "$MAKO_FILE"
    # Normal: usa C2
    sed -i "/^\[urgency=normal\]/,/^\[/ s/^border-color=#[0-9a-fA-F]\{6\}/border-color=$C2/" "$MAKO_FILE"
    # Critical: usa C1
    sed -i "/^\[urgency=critical\]/,/^\[/ s/^border-color=#[0-9a-fA-F]\{6\}/border-color=$C1/" "$MAKO_FILE"
    makoctl reload 2>/dev/null || true
fi


# 7. Actualizar Fastfetch (Colores de las llaves)
if [ -f "$FF_FILE" ]; then
    sed -i "s/\"keyColor\": \"[^\"]*\"/\"keyColor\": \"$C1\"/g" "$FF_FILE"
fi

# 8. Fondo de Pantalla Estático (vía swww para eficiencia)
WALLPAPER="$HOME/Pictures/wallpapers/fondocentral.png"
if command -v swww &> /dev/null; then
    swww img "$WALLPAPER" --transition-type wipe --transition-step 90 &
fi


# --- Función Hex to RGB ---
hex_to_rgb() {
    local hex=${1#\#}
    printf "%d %d %d" 0x${hex:0:2} 0x${hex:2:2} 0x${hex:4:2}
}

# ... (código existente hasta el final de las actualizaciones) ...

# 9. Actualizar Teclado (Acer Nitro RGB - 4 Zonas)
if command -v nitro-rgb &> /dev/null; then
    read -r R1 G1 B1 <<< $(hex_to_rgb "$C1")
    read -r R2 G2 B2 <<< $(hex_to_rgb "$C2")
    
    # Zonas 1 y 2 -> Color Principal (C1)
    nitro-rgb -m 0 -z 1 -cR "$R1" -cG "$G1" -cB "$B1" -b 80 &>/dev/null
    nitro-rgb -m 0 -z 2 -cR "$R1" -cG "$G1" -cB "$B1" -b 80 &>/dev/null
    
    # Zonas 3 y 4 -> Color Secundario (C2)
    nitro-rgb -m 0 -z 3 -cR "$R2" -cG "$G2" -cB "$B2" -b 80 &>/dev/null
    nitro-rgb -m 0 -z 4 -cR "$R2" -cG "$G2" -cB "$B2" -b 80 &>/dev/null
fi

# --- Notificar y Recargar ---
killall waybar && waybar & disown

# Notificacion breve con estilo en los colores del tema activo
notify-send -t 3000 "tema $1" "$C1 · $C2" --hint=string:synchronous:tema
echo "¡Tema $1 aplicado! ($C1 + $C2)"
