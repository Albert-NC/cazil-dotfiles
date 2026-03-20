#!/usr/bin/env python3
"""
nitro_rgb.py — Control de luces RGB para Acer Nitro AN515-58
Escribe directamente al driver /dev/acer-gkbbl-static

Uso:
  sudo python3 nitro_rgb.py -z 1 -cR 255 -cG 0 -cB 0       # Zona 1 en rojo
  sudo python3 nitro_rgb.py --all -cR 0 -cG 255 -cB 255     # Todas las zonas en cyan
"""

import argparse
import struct
import sys

STATIC_DEV = "/dev/acer-gkbbl-static"
NUM_ZONES = 4


def set_zone(zone: int, r: int, g: int, b: int) -> None:
    """Escribe un color a una zona del teclado."""
    # El driver espera exactamente 4 bytes: [zone, R, G, B]
    payload = struct.pack("BBBB", zone, r, g, b)
    try:
        with open(STATIC_DEV, "wb") as dev:
            dev.write(payload)
    except PermissionError:
        print(f"[ERROR] Permiso denegado. Ejecuta con sudo.", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"[ERROR] {STATIC_DEV} no encontrado. ¿Está cargado el módulo?", file=sys.stderr)
        print("       Prueba: sudo insmod facer.ko", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Control RGB Acer Nitro AN515-58")
    parser.add_argument("-z", "--zone", type=int, choices=[0, 1, 2, 3],
                        help="Zona del teclado (0-3). Usar con --all para todas.")
    parser.add_argument("--all", action="store_true",
                        help="Aplicar el color a todas las zonas")
    parser.add_argument("-cR", "--red",   type=int, default=0,   metavar="R", help="Rojo (0-255)")
    parser.add_argument("-cG", "--green", type=int, default=0,   metavar="G", help="Verde (0-255)")
    parser.add_argument("-cB", "--blue",  type=int, default=255, metavar="B", help="Azul (0-255)")
    args = parser.parse_args()

    # Validar rango de colores
    for name, val in [("red", args.red), ("green", args.green), ("blue", args.blue)]:
        if not (0 <= val <= 255):
            print(f"[ERROR] Valor de {name} fuera de rango: {val}", file=sys.stderr)
            sys.exit(1)

    if args.all:
        for z in range(NUM_ZONES):
            set_zone(z, args.red, args.green, args.blue)
        print(f"[OK] Todas las zonas → R={args.red} G={args.green} B={args.blue}")
    elif args.zone is not None:
        set_zone(args.zone, args.red, args.green, args.blue)
        print(f"[OK] Zona {args.zone} → R={args.red} G={args.green} B={args.blue}")
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
