import os
import sys
from time import sleep

# Colores definidos (tus neones)
CEL_NEON = [0, 255, 255]  # Celeste Neón (Cyan)
ROS_NEON = [255, 0, 255]  # Rosado Neón (Magenta)

# Configuracion de las 4 Zonas: (ID_Zona, Color_RGB)
zones_config = [
    (1, CEL_NEON), (2, CEL_NEON),
    (3, ROS_NEON), (4, ROS_NEON)
]

mode = 0  # Modo Estático (el más confiable)

print("Aplicando Logo HAUNTER NEÓN (Celeste / Rosado)...")

try:
    for zone_id, color_rgb in zones_config:
        r, g, b = color_rgb
        # Comando para aplicar color estático a la zona
        cmd = f"./facer_rgb.py -m {mode} -cR {r} -cG {g} -cB {b} -z {zone_id}"
        os.system(cmd)
        sleep(0.15) # Pequeña pausa para asegurar la aplicación
    
    print("Logo NEÓN aplicado con éxito: Celeste-Celeste-Rosado-Rosado.")

except Exception as e:
    print(f"\n--- ERROR: {e} ---")
    sys.exit(1)
