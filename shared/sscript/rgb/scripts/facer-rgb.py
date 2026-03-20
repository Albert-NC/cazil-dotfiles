#!/usr/bin/env python3
"""
facer_rgb.py — Monitor de batería con control RGB automático
Acer Nitro AN515-58 — Requiere: driver facer.ko cargado + nitro_rgb.py

Lógica de colores:
  - Enchufado:     Cyan en todas las zonas
  - Batería ≥ 20%: Cyan (zonas 0-1) + Magenta (zonas 2-3)
  - Batería 10-19%: Magenta en todas las zonas
  - Batería < 10%:  Rojo alerta en todas las zonas
"""

import subprocess
import sys
import time
from pathlib import Path

NITRO_RGB = Path(__file__).parent / "nitro_rgb.py"
POWER_SUPPLY = Path("/sys/class/power_supply")
BATTERY_PATH = POWER_SUPPLY / "BAT1" / "capacity"
AC_PATH      = POWER_SUPPLY / "ACAD" / "online"
POLL_INTERVAL = 5  # segundos


def read_int(path: Path, default: int = 0) -> int:
    try:
        return int(path.read_text().strip())
    except Exception:
        return default


def rgb(zone: int | None, r: int, g: int, b: int) -> None:
    """Envía un color al driver. zone=None significa todas las zonas."""
    cmd = [sys.executable, str(NITRO_RGB)]
    if zone is None:
        cmd += ["--all"]
    else:
        cmd += ["-z", str(zone)]
    cmd += ["-cR", str(r), "-cG", str(g), "-cB", str(b)]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        print(f"[!] Error controlando luces: {e.stderr.decode().strip()}", file=sys.stderr)
    except FileNotFoundError:
        print(f"[!] No se encontró nitro_rgb.py en: {NITRO_RGB}", file=sys.stderr)
        sys.exit(1)


def apply_color(plugged: bool, percent: int) -> None:
    if plugged:
        # Enchufado — Cyan
        rgb(None, 0, 200, 255)
    elif percent >= 20:
        # Batería normal — Cyan + Magenta
        rgb(0, 0, 255, 255)
        rgb(1, 0, 255, 255)
        rgb(2, 255, 0, 255)
        rgb(3, 255, 0, 255)
    elif percent >= 10:
        # Batería baja — Magenta en todo
        rgb(None, 255, 0, 255)
    else:
        # Crítico — Rojo
        rgb(None, 255, 0, 0)


def main() -> None:
    if not NITRO_RGB.exists():
        print(f"[-] No se encontró nitro_rgb.py junto a este script.", file=sys.stderr)
        sys.exit(1)

    print("[*] Monitor de batería Nitro RGB iniciado.")
    last_plugged  = None
    last_percent  = None

    while True:
        plugged  = read_int(AC_PATH,      default=1) == 1
        percent  = read_int(BATTERY_PATH, default=50)

        if plugged != last_plugged or percent != last_percent:
            estado = "enchufado" if plugged else f"batería {percent}%"
            print(f"[~] Cambio detectado: {estado}")
            apply_color(plugged, percent)
            last_plugged = plugged
            last_percent = percent

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[*] Monitor detenido.")
