# 🌌 cazil-dotfiles

Unificado y potente set de configuraciones para **Hyprland** en Arch Linux y Debian/Ubuntu. Diseñado para la eficiencia, con estéticas premium y herramientas de grado profesional integradas.

![Cyberpunk](https://img.shields.io/badge/Theme-218_Cyberpunk-magenta)
![Minimal](https://img.shields.io/badge/Theme-Ilidary_Green-green)
![Hyprland](https://img.shields.io/badge/WM-Hyprland-blue)
![Laptop](https://img.shields.io/badge/Optimization-Laptop_Nitro-red)

---

## 🚀 Instalación Relámpago

```bash
git clone https://github.com/cazil/cazil-dotfiles.git
cd cazil-dotfiles
bash install.sh
```

### Opciones del instalador

| Flag             | Descripción                                   |
|------------------|-----------------------------------------------|
| `--auto`         | Instalación completa sin preguntas            |
| `--dotfiles-only`| Solo copia configs, no instala paquetes       |
| `--arch`         | Fuerza modo Arch Linux (recomendado)          |
| `--debian`       | Fuerza modo Debian/Ubuntu                     |

---

## 💻 Optimizaciones de Laptop (Acer Nitro)

Este set de dotfiles incluye mejoras específicas para laptops de alto rendimiento:

### � Control de Hardware
- **Ventiladores**: Control total mediante el script `fans` (requiere `ec_sys`).
- **Luces RGB**: Driver `nitro-rgb` integrado para teclados de 4 zonas.
- **Batería**: Límite de carga al 80% configurable para extender la vida útil.

### 🖖 Gestos y Navegación
Gestos multi-toque de 3 y 4 dedos mediante `libinput-gestures`:
- **3 Dedos**: Deslizar para cambiar de escritorio, arriba para menú, abajo para cerrar.
- **Pinch (Zoom)**: Pellizcar para hacer zoom global en la pantalla (In/Out).
- **4 Dedos**: Volver al escritorio anterior o alternar monitor externo.

### 🔊 Audio Premium
- **EasyEffects**: Configuración pre-cargada para mejorar la respuesta de bajos y claridad en altavoces de laptop.

---

## �🎨 Los Dos Mundos

### 1. 🌈 218 — Cyberpunk (Modo Dinámico)
Cambia el alma del sistema con el comando `tema [CÓDIGO]`. Nueve paletas neón diseñadas para el máximo contraste:

| Código | Nombre del Estilo | Colores Primarios | Descripción |
| :--- | :--- | :--- | :--- |
| `PC` | **Cyber-Classic** | 💗 Rosa + 🩵 Cyan | El look oficial de Cazil Dotfiles (Neo-Tokyo). |
| `PP` | **Hyper-Purple** | 💜 Púrpura + 💗 Rosa | Estética nocturna profunda. |
| `VV` | **Acid-Sunset** | 🟣 Violeta + 🟠 Vermellón | Atardecer tóxico y vibrante. |
| `PM` | **Ultra-Magenta** | 💜 Púrpura + 💖 Magenta | Puramente eléctrico. |
| `PB` | **Neon-Bubble** | 💗 Rosa + 💙 Azul | Estética retro-wave intensa. |
| `CC` | **Coral-Reef** | 🩵 Cyan + 🪸 Coral | Fresco, veraniego y nítido. |
| `BG` | **Matrix-Dark** | 🖤 Negro + 💚 Verde | Terminal hacker de bajo perfil. |
| `WB` | **Paper-White** | 🤍 Blanco + 🖤 Negro | El contraste más alto (Claro/Oscuro). |
| `LG` | **Aero-Glacial** | 💜 Lavanda + 🧊 Glacial | Tonos pasteles y gélidos. |

---

## ⌨️ Atajos de Poder

| Categoría | Atajo | Acción |
| :--- | :--- | :--- |
| **General** | `SUPER` (Soltar) | Lanzador de Aplicaciones (Rofi) |
| | `SUPER + T` | Abrir **Kitty Terminal** |
| | `SUPER + V` | **Abrir VSCode** |
| | `SUPER + B` | Navegador Brave |
| | `SUPER + F` | Gestor de Archivos (Thunar) |
| | `SUPER + ALT + T` | Scratchpad (**Kitty**) |
| | `SUPER + ALT + C` | **Notas Joplin** (Sincronización) |
| **Ventanas** | `ALT + F4` / `SUPER + Q` | Cerrar Ventana |
| | `SUPER + F1` / `Enter` | Pantalla Completa |
| | `SUPER + Tab` | Ciclar entre Ventanas |
| | `SUPER + Espacio` | Alternar modo Flotante |
| | `SUPER + Flechas / HJKL` | Cambiar foco de ventana |
| | `SUPER + Shift + Flechas` | **Mover ventana (HJKL)** |
| **Navegación** | `SUPER + Ctrl + Flechas` | Cambiar de Workspace  |
| | `SUPER + Ctrl+Shift + Fl` | Mover ventana a otro Workspace |
| | `3 Dedos Swipe` | Gestos de Workspace / Menú |
| | `Pinch 2 Dedos` | **Global Zoom In / Out** |
| **Utilidades** | `Print` | **Pantalla Completa** (Guarda en `Capture`) |
| | `Shift + Print` | Captura de Área (Copia + Guarda) |
| | `SUPER + CTRL + Print`| **Captura Interactiva** (Imagen) |
| | `SUPER + Shift + V` | Historial del Portapapeles |
| | `SUPER + ALT + Print` | **OCR Mágico** (Copiar texto de pantalla) |
| | `SUPER + O` | **Alternar Monitor Externo** |
| **Sistema** | `SUPER + ESC` / `L` | Bloquear Pantalla |
| | `SUPER + Shift + ESC` | Menú de Apagado / Salida |
| **Hardware** | `Fn + Brillo Up/Down` | Brillo Inteligente (ACPI Scripts) |
| | `SUPER + F7 / F8` | Silenciar Audio / Micrófono |

---

## 🛠️ Super-Comandos Integrados (Zsh)

- `tema [PC|PP|VV...]`: Cambia instantáneamente los colores de **todo**.
- `gif-on`: Activa el modo animado (aleatoriedad pesada).
- `gif-off`: Regresa al fondo de pantalla estático (hyprpaper).
- `limpiar`: Mantenimiento Arch (cache, huérfanos, logs).
- `backup`: Punto de restauración (Timeshift).
- `anims`: **Modo Eco**. Desactiva efectos para ahorrar batería.
- `web_on` / `web_off`: Control rápido de servidor local (puerto 5500).
- `vms`: Gestor de Virtualización (Virt-Manager).
- **Proteus / Teams**: Automatizado vía **WinApps** (ver guía).

---
*Diseñado por **Cazil**. Llevando Arch Linux al límite de lo visual.*
