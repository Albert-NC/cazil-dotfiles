#!/bin/bash

DRIVER_PATH="/usr/local/lib/nitro-rgb/nitro-rgb.py"

# Variables de control
last_percent=""
last_power_state=""

while true; do
    # 1. Obtener datos actuales
    current_power=$(cat /sys/class/power_supply/ACAD/online)
    current_percent=$(cat /sys/class/power_supply/BAT1/capacity)

    # 2. Verificar si hubo cambios
    if [ "$current_power" != "$last_power_state" ] || [ "$current_percent" != "$last_percent" ]; then
        
        if [ "$current_power" == "1" ]; then
            # --- MODO ENCHUFADO: Efecto Wave ---
            python3 "$DRIVER_PATH" -m 3 -s 5 -b 100 -d 2
        else
            # --- MODO BATERÍA ---
            if [ "$current_percent" -ge 20 ]; then
                # Rango 100% - 20%: Cyan y Magenta (Cyberpunk)
                python3 "$DRIVER_PATH" -m 0 -z 1 -cR 0 -cG 255 -cB 255 -b 80
                python3 "$DRIVER_PATH" -m 0 -z 2 -cR 0 -cG 255 -cB 255 -b 80
                python3 "$DRIVER_PATH" -m 0 -z 3 -cR 255 -cG 0 -cB 255 -b 80
                python3 "$DRIVER_PATH" -m 0 -z 4 -cR 255 -cG 0 -cB 255 -b 80

            elif [ "$current_percent" -ge 10 ]; then
                # Rango 19% - 10%: Naranja Estático [255, 165, 0]
                for zone in 1 2 3 4; do
                    python3 "$DRIVER_PATH" -m 0 -z $zone -cR 0 -cG 255 -cB 255 -b 90
                done

            else
                # Rango < 10%: Rojo Alerta (Default Static) [255, 0, 0]
                for zone in 1 2 3 4; do
                    python3 "$DRIVER_PATH" -m 0 -z $zone -cR 255 -cG 0 -cB 0 -b 100
                done
            fi
        fi

        # Guardar estados para la próxima vuelta
        last_power_state=$current_power
        last_percent=$current_percent
    fi

    # 3. Espera de 30 segundos (Eficiencia máxima)
    sleep 5
done
