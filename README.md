# 🌌 cazil-dotfiles

Unificado y potente set de configuraciones para **Hyprland** en Arch Linux y Debian/Ubuntu. Diseñado para la eficiencia, con estéticas premium y herramientas de grado profesional integradas.

![Cyberpunk](https://img.shields.io/badge/Theme-218_Cyberpunk-magenta)
![Hyprland](https://img.shields.io/badge/WM-Hyprland-blue)
![Laptop](https://img.shields.io/badge/Optimization-Laptop_Nitro-red)
![Security](https://img.shields.io/badge/Security-Hardened-green)

---

## 🚀 Instalación Relámpago

```bash
git clone https://github.com/cazil/cazil-dotfiles.git
cd cazil-dotfiles
bash install.sh
```

### Opciones del instalador

| Flag              | Descripción                             |
|-------------------|-----------------------------------------|
| `--auto`          | Instalación completa sin preguntas      |
| `--dotfiles-only` | Solo copia configs, no instala paquetes |
| `--arch`          | Fuerza modo Arch Linux                  |
| `--debian`        | Fuerza modo Debian/Ubuntu               |

> **Nota:** El instalador pide `sudo` **una sola vez** al inicio y mantiene el ticket activo durante toda la instalación. En Arch detecta y configura un sistema minimalista desde cero (instala `base-devel`, `git`, `NetworkManager`, `Pipewire`, etc. automáticamente).

---

## 🛡️ Modos de Seguridad Combinados

Perfiles que activan/desactivan múltiples protecciones con **un solo comando**:

```bash
modo uni       # 🎓 Universidad — protección MÁXIMA
modo cafe      # ☕ WiFi público (cafetería, aeropuerto)
modo casa      # 🏠 Red confiable — relajado
modo avion     # ✈️  Sin radios — máxima batería
modo normal    # 🔄 Restaurar todo a default
modo estado    # 📊 Ver qué protecciones están activas
```

### Detalle de cada modo

| Modo | MAC Aleatoria | DNS Cifrado | Firewall Estricto | BT Off | USBGuard | Eco/Batería |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **uni** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **cafe** | ✅ | ✅ | ✅ | ✅ | — | — |
| **casa** | ❌ (original) | ✅ | ✅ | disponible | — | ❌ |
| **avion** | — | — | — | ✅ | — | ✅ |
| **normal** | ❌ (original) | — | — | disponible | ❌ | ❌ |

---

## 🔧 Scripts del Sistema (`shared/sscript/`)

### 🛡️ Seguridad y Privacidad

| Script | Alias | Qué hace |
|---|---|---|
| `config-dns-seguro.sh` | `dns-seguro` | Configura DNS over TLS con Cloudflare (1.1.1.1). Cifra todas tus consultas DNS para que ni tu ISP ni la red local vean qué dominios visitas. Quad9 incluido como fallback. |
| `mac-random.sh` | `mac-random` | Randomiza la dirección MAC de tu WiFi. Cada vez que te conectas a una red, apareces como un dispositivo diferente. Esencial en redes universitarias. |
| `config-hardening.sh` | `kernel-hard` | Aplica parámetros de seguridad al kernel vía `sysctl`: desactiva ICMP redirects, protege contra SYN floods, bloquea IP source routing, y más. |
| `security-status.sh` | `security-status` | Muestra el estado de todos los servicios de seguridad: UFW, USBGuard, DNS, AppArmor. |
| `ssh-monitor.sh` | `ssh-monitor` | Monitorea conexiones SSH activas y muestra alertas si alguien está conectado a tu máquina. |
| `privacy-dns.sh` | — | Alternativa de configuración DNS con más opciones de proveedores. |
| `privacy-mac.sh` | — | Alternativa de randomización MAC con persistencia por red. |

### 🔋 Energía y Batería

| Script | Alias | Qué hace |
|---|---|---|
| `battery-limit.sh` | `battery-limit` | Configura el límite de carga de la batería (80% por defecto) usando el driver DKMS de Acer. Prolonga la vida útil de la batería significativamente. |
| `power-save.sh` | `eco-mode` | Activa/desactiva modo eco: reduce brillo, desactiva animaciones, baja frecuencia de CPU. |
| `toggle-animations.sh` | `anims` | Desactiva/activa las animaciones de Hyprland. Cada toggle ahorra ~5-10% de batería. |
| `gaming-mode.sh` | `gaming-mode` | Desactiva eco-mode, sube la frecuencia de CPU al máximo, reactiva animaciones. Para cuando necesitas rendimiento. |
| `powertop-autotune.service` | — | Servicio systemd que ejecuta `powertop --auto-tune` al arrancar. Optimiza USB autosuspend, ASPM, wake-on-LAN, etc. |

### 🖥️ Display y Pantalla

| Script | Alias | Qué hace |
|---|---|---|
| `tema.sh` | `tema` | Cambia el tema de colores de todo el sistema (Hyprland, Waybar, Rofi, Mako) con un código de 2 letras. 9 paletas disponibles. |
| `wallpaper-dinamico.sh` | `gif-on` | Activa fondos de pantalla animados (GIF/video) con swww. |
| `zoom.sh` | `zoom` | Control de zoom global de pantalla para presentaciones o accesibilidad. |
| `so/monitor-toggle.sh` | — | Alterna monitor externo on/off (atajo `SUPER + O`). |
| `subir-brillo.sh` / `bajar-brillo.sh` | — | Control fino de brillo con pasos más pequeños que las teclas Fn por defecto. |
| `ocr-pantalla.sh` | `ocr-magico` | Captura un área de la pantalla y extrae el texto con Tesseract OCR. Lo copia al portapapeles. |

### 🔌 Hardware y Periféricos

| Script | Alias | Qué hace |
|---|---|---|
| `ventiladores/nitro-fans.sh` | `fans` | Control manual de ventiladores del Acer Nitro vía `ec_sys`. Modos: auto, max, silencioso, manual. |
| `rgb/scripts/teclado-rgb.sh` | `nitro-rgb` | Control del LED RGB del teclado Nitro (4 zonas). Colores, modos, brillo. |
| `gpu/gpu-check.sh` | `gpu-check` | Estado detallado de la GPU NVIDIA: temperatura, consumo, estado de energía (P0-P8). |
| `gpu/gpu-monitor.sh` | — | Monitor en tiempo real de GPU para Waybar (usado internamente). |
| `sound-monitor.sh` | — | Detecta reproducción multimedia activa y cambia el ícono de Waybar. |

### 🌐 Red y Conectividad

| Script | Alias | Qué hace |
|---|---|---|
| `apagar-redes-inicio.sh` | — | Apaga WiFi y Bluetooth al arrancar (autostart). Enciendes manualmente cuando necesitas. |
| `redes-on.sh` / `redes-off.sh` | — | Toggle rápido de WiFi + Bluetooth. |
| `bt-on.sh` / `bt-off.sh` | `bt-on` / `bt-off` | Toggle solo Bluetooth. |

### 🐳 Desarrollo y Virtualización

| Script | Alias | Qué hace |
|---|---|---|
| `so/docker-init.sh` | `docker-init` | Inicia Docker + docker-compose en el directorio actual. |
| `so/delete-total.sh` | `delete-total` | Limpieza nuclear de Docker: elimina todos los contenedores, imágenes, volúmenes y redes. **Destructivo.** |
| `so/crear-maquina.sh` | `crear-maquina` | Crea una VM con QEMU/KVM de forma interactiva (nombre, RAM, disco, ISO). |
| `so/limpiar-kali.sh` | `limpiar-kali` | Limpieza específica para VMs de Kali Linux (cache, logs, temporales). |

### 📄 Utilidades

| Script | Alias | Qué hace |
|---|---|---|
| `pdf.sh` | `pdf` | Suite PDF universitaria: comprimir, unir, dividir, convertir, OCR sobre PDFs. |
| `so/limpiar-sistema.sh` | `limpiar` | Mantenimiento de Arch: limpia cache de pacman, paquetes huérfanos, logs antiguos, cache de usuario. |

---

## 🎨 Los Dos Mundos — Temas

### 🌈 218 — Cyberpunk (Modo Dinámico)

Cambia el alma del sistema con `tema [CÓDIGO]`. Nueve paletas neón:

| Código | Nombre | Colores | Descripción |
|:---:|:---|:---|:---|
| `PC` | **Cyber-Classic** | 💗 Rosa + 🩵 Cyan | El look oficial (Neo-Tokyo) |
| `PP` | **Hyper-Purple** | 💜 Púrpura + 💗 Rosa | Estética nocturna profunda |
| `VV` | **Acid-Sunset** | 🟣 Violeta + 🟠 Vermellón | Atardecer tóxico |
| `PM` | **Ultra-Magenta** | 💜 Púrpura + 💖 Magenta | Puramente eléctrico |
| `PB` | **Neon-Bubble** | 💗 Rosa + 💙 Azul | Retro-wave |
| `CC` | **Coral-Reef** | 🩵 Cyan + 🪸 Coral | Fresco y veraniego |
| `BG` | **Matrix-Dark** | 🖤 Negro + 💚 Verde | Terminal hacker |
| `WB` | **Paper-White** | 🤍 Blanco + 🖤 Negro | Alto contraste |
| `LG` | **Aero-Glacial** | 💜 Lavanda + 🧊 Glacial | Pasteles gélidos |
| `EX` | **Modo Exponer** | 🤍+🖤 | Sin transparencias ni animaciones |

---

## 💻 Optimizaciones de Laptop (Acer Nitro)

### ⚙️ Control de Hardware
- **Ventiladores**: Control total con `fans` (requiere `ec_sys`)
- **Luces RGB**: Driver `nitro-rgb` integrado para teclados de 4 zonas
- **Batería**: Límite de carga al 80% con `battery-limit`
- **PowerTOP**: Auto-tune al arrancar para máximo ahorro

### 🖖 Gestos Multi-toque
- **3 Dedos**: Deslizar → cambiar workspace. Arriba → menú. Abajo → cerrar
- **Pinch**: Zoom global In/Out
- **4 Dedos**: Workspace anterior / alternar monitor externo

---

## ⌨️ Atajos de Poder

| Categoría | Atajo | Acción |
|:---|:---|:---|
| **General** | `SUPER` (Soltar) | Lanzador Rofi |
| | `SUPER + T` | Kitty Terminal |
| | `SUPER + V` | VSCode |
| | `SUPER + B` | Brave |
| | `SUPER + F` | Thunar |
| | `SUPER + C` | Calculadora |
| **Ventanas** | `ALT + F4` / `SUPER + Q` | Cerrar |
| | `SUPER + Enter` | Pantalla Completa |
| | `SUPER + Tab` | Ciclar ventanas |
| | `SUPER + Espacio` | Modo flotante |
| **Navegación** | `SUPER + Ctrl + ←/→` | Cambiar workspace |
| | `3 Dedos Swipe` | Gestos de workspace |
| **Capturas** | `Print` | Pantalla completa |
| | `Shift + Print` | Área (copia + guarda) |
| | `SUPER + ALT + Print` | OCR Mágico |
| | `SUPER + Shift + V` | Historial portapapeles |
| **Sistema** | `SUPER + ESC` | Bloquear pantalla |
| | `SUPER + Shift + ESC` | Menú apagado |
| **tmux** | `Ctrl+A + \|` | Split vertical |
| | `Ctrl+A + -` | Split horizontal |
| | `Ctrl+A + h/j/k/l` | Moverse (estilo Vim) |

---

## 🛠️ Super-Comandos Rápidos (Zsh)

```bash
# Seguridad
modo uni          # Protección máxima → universidad
modo cafe         # WiFi público
modo casa         # Red confiable
modo estado       # Ver estado de protección
estado-seguridad  # Estado rápido de servicios

# Tema y Display
tema PC           # Cambiar colores del sistema
gif-on / gif-off  # Fondos animados

# Energía
battery-limit     # Límite de carga al 80%
battery-100       # Cargar al 100% temporalmente
eco-on / eco-off  # Modo ahorro
gaming-mode       # Rendimiento máximo

# Mantenimiento
limpiar           # Limpieza de Arch
gpu-check         # Estado de GPU NVIDIA

# Desarrollo
docker_init       # Iniciar Docker
vms               # Virt-Manager
web_on / web_off  # Servidor local :5500
```

---
*Diseñado por **Cazil**. Arch Linux llevado al límite de lo visual y funcional. 🌌*
