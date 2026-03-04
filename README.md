# 🌌 cazil-dotfiles

Unificado y potente set de configuraciones para **Hyprland** en Arch Linux y Debian/Ubuntu. Diseñado para la eficiencia, con estéticas premium y herramientas de grado profesional integradas.

![Cyberpunk](https://img.shields.io/badge/Theme-218_Cyberpunk-magenta)
![Minimal](https://img.shields.io/badge/Theme-Ilidary_Green-green)
![Hyprland](https://img.shields.io/badge/WM-Hyprland-blue)
![Virtualization](https://img.shields.io/badge/Virtualization-QEMU%2FDocker-orange)

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

## 🎨 Los Dos Mundos

### 1. 🌈 218 — Cyberpunk (Modo Dinámico)
- **Presets de Color:** Cambia el alma del sistema con un comando (9 paletas neón).
- **Estética:** Futurista, bordes brillantes, animaciones fluidas.
- **Barra Inteligente:** Waybar con *autohide* y monitor de conexiones inteligentes.

### 2. 🌿 Ilidary — Minimalista
- **Estética:** Abisal, pacífica y eficiente.
- **Foco:** Máximo contraste y limpieza visual.

---

## ⌨️ Atajos de Poder

| Atajo                  | Acción                              |
|------------------------|-------------------------------------|
| `SUPER` (Soltar)       | **Lanzador Rofi Futurista**         |
| `SUPER + T`            | Terminal (Kitty)                    |
| `SUPER + B`            | Navegador (Brave)                   |
| `SUPER + F`            | Archivos (Thunar)                   |
| `SUPER + C`            | Código (VSCode)                     |
| `SUPER + L`            | Bloqueo Cyberpunk (hyprlock)        |
| `SUPER + SHIFT + C`    | Recargar Configuración              |
| `SUPER + V`            | Historial del Portapapeles          |
| `SUPER + Print`        | Screenshot de pantalla              |
| `SUPER + 1–5`          | Navegación Pacman Workspaces        |

---

## 🛠️ Super-Comandos Integrados

Tu sistema incluye un set de scripts optimizados para manejar tu hardware y entorno:

### ⚡ Estética y Energía
- `tema [PC|PP|VV|LG...]`: Cambia instantáneamente los colores de **todo** el tema 218.
- `anims`: **Modo Eco Inteligente**. Activa/desactiva animaciones, blur y transparencias para ahorrar batería máxima.

### 🐳 Virtualización y Red
- **Docker**: Alias integrados (`dps`, `dc`, `dstop`) para control total.
- **QEMU/KVM**: Gestor de máquinas virtuales (`vms`) pre-configurado.
- **SSH Intelligent Monitor**: Icono dinámico (󰖟) en la barra cuando hay conexiones abiertas.
- **WiFi Detail**: Nombre de red (SSID) y tooltip con IP y señal.

### 🛡️ Seguridad y Hardware
- **Nmap & Firewall**: Atajos rápidos para auditoría y seguridad.
- **USBGuard**: Bloqueo de dispositivos USB desconocidos.
- **RGB & Fans**: `nitro-rgb` y `fans` para laptops Acer Nitro.

---

## 📁 Estructura del Proyecto

```
cazil-dotfiles/
├── install.sh             ← El cerebro del despliegue
├── shared/
│   ├── zsh/.zshrc         ← Shell pro con alias de seguridad/docker
│   ├── hypr/              ← Entorno unificado (NVIDIA, Input ES)
│   ├── sscript/           ← El arsenal: tema, anims, ssh-monitor...
│   └── fonts/             ← Nerd Fonts & Emojis
└── themes/
    ├── 218/               ← Cyberpunk (Dinámico)
    └── ilidary/           ← Minimalista Abisal
```

---
*Diseñado por **Cazil**. Llevando Arch Linux al límite de lo visual.*
