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
- **Presets de Color:** Cambia el alma del sistema con un comando (9 paletas neón).
- **Estética:** Futurista, bordes brillantes, animaciones fluidas.
- **Barra Inteligente:** Waybar dinámica con autohide y **workspaces inteligentes** (solo muestra lo usado +1 libre).

---

## ⌨️ Atajos de Poder

| Atajo                  | Acción                              |
|------------------------|-------------------------------------|
| `SUPER` (Soltar)       | **Lanzador Rofi Futurista**         |
| `3 Dedos Swipe`        | Cambiar Workspace / Menú / Cerrar   |
| `Pinch 2 Dedos`        | **Zoom In / Out** (Sistema)         |
| `SUPER + T`            | Terminal (Kitty)                    |
| `SUPER + V`            | Historial del Portapapeles          |
| `SUPER + O`            | Toggle Monitor Externo              |

---

## 🛠️ Super-Comandos Integrados

- `tema [PC|PP|VV|LG...]`: Cambia instantáneamente los colores de **todo**.
- `anims`: **Modo Eco**. Desactiva efectos para ahorrar batería.
- `zoom [in|out|reset]`: Control de zoom manual (también vía gestos).
- `fzf-tab`: Autocompletado visual en Zsh con previews de archivos.

---
*Diseñado por **Cazil**. Llevando Arch Linux al límite de lo visual.*
