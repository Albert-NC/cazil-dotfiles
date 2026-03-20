#!/bin/bash
# toggle-animations.sh — Activa/Desactiva animaciones de Hyprland al instante

STATUS=$(hyprctl getoption animations:enabled | grep "int:" | awk '{print $2}')

ROFI_218="$HOME/.config/rofi/cazil_theme.rasi"
ROFI_ILI="$HOME/.config/rofi/ilidary_theme.rasi"

if [ "$STATUS" = "1" ]; then
    # --- MODO ECO ON (Bajo Consumo) ---
    hyprctl keyword animations:enabled 0
    hyprctl keyword decoration:blur:enabled 0
    hyprctl keyword decoration:drop_shadow 0
    
    # Rofi: Quitar transparencias (rgba -> hex sólido)
    [ -f "$ROFI_218" ] && sed -i 's/rgba(13, 13, 20, 0.9)/#0d0d14/g' "$ROFI_218"
    [ -f "$ROFI_ILI" ] && sed -i 's/rgba(6, 11, 15, 0.92)/#060b0f/g' "$ROFI_ILI"

    notify-send "Eco Mode" "Máximo ahorro activado (Sin animaciones/blur/transparencia)" -i power-profile-battery-symbolic
    echo "ECO MODE: ON"
else
    # --- MODO ECO OFF (Máxima Estética) ---
    hyprctl keyword animations:enabled 1
    hyprctl keyword decoration:blur:enabled 1
    hyprctl keyword decoration:drop_shadow 1
    
    # Rofi: Restaurar transparencias
    [ -f "$ROFI_218" ] && sed -i 's/#0d0d14/rgba(13, 13, 20, 0.9)/g' "$ROFI_218"
    [ -f "$ROFI_ILI" ] && sed -i 's/#060b0f/rgba(6, 11, 15, 0.92)/g' "$ROFI_ILI"

    notify-send "Estética" "Modo visual completo activado" -i power-profile-balanced-symbolic
    echo "ECO MODE: OFF (Visuales ON)"
fi
