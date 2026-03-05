# 🪟 Guía de Configuración WinApps (Cazil Dotfiles)

WinApps te permite correr aplicaciones de Windows (como Microsoft Teams, Office o Adobe) de forma integrada en tu escritorio Hyprland.

## 1. Crear la Máquina Virtual (VM)
1. Abre **Virt-Manager** (`vms` en tu terminal).
2. Crea una nueva VM con Windows 10 u 11 (Pro o Enterprise recomendado).
3. **IMPORTANTE**: Ponle de nombre `Windows` a la VM.

## 2. Configuración dentro de Windows
Una vez instalado Windows, haz lo siguiente:
1. **Activar Escritorio Remoto**: Configuración > Sistema > Escritorio remoto > Activado.
2. **Cambiar Nombre del Equipo**: Cámbialo a `Windows` (para que coincida con la config).
3. **Instalar WinApps dentro de Windows**:
   - Descarga [WinApps para Windows](https://github.com/winapps-org/winapps/blob/main/install/install.bat).
   - Ejecútalo para habilitar las entradas de registro necesarias para el modo "Seamless".

## 3. Configuración en Linux
El instalador ya te habrá dejado el archivo `~/.config/winapps/winapps.conf`. Asegúrate de que los datos coincidan:
- `user`: Tu usuario en Windows.
- `password`: Tu contraseña en Windows.

## 4. Instalar Apps
Una vez la VM esté corriendo y configurada, desde tu Linux ejecuta:
```bash
winapps install
```
Esto buscará las apps instaladas en Windows y creará accesos directos en tu menú de Hyprland (Rofi).

---
> [!TIP]
> **Teams, Office y Proteus**: Instala Microsoft Teams, la suite de Office y software de ingeniería como **Proteus** o **Altium** en la VM de Windows. WinApps las integrará en tu menú de Linux (`SUPER + D`), permitiéndote simular circuitos sin salir de tu entorno Hyprland.
