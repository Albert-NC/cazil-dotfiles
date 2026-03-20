#!/bin/bash

# Directorio base para las máquinas
BASE_DIR="$HOME/VirtualMachines/qemu"
mkdir -p "$BASE_DIR"

# Asegurar que el directorio existe
mkdir -p "$BASE_DIR"

# Pedir la ruta de la ISO si no se pasa como argumento
if [ -z "$1" ]; then
    read -p "Introduce la ruta completa de la ISO: " ISO_PATH
else
    ISO_PATH="$1"
fi

# Validar que la ISO existe
if [ ! -f "$ISO_PATH" ]; then
    echo "Error: El archivo $ISO_PATH no existe."
    exit 1
fi

# Extraer el nombre de la distribución (ej: kali-linux-2024.1-installer-amd64.iso -> kali)
# Tomamos la primera palabra antes de un guion o punto
FILENAME=$(basename "$ISO_PATH")
DISTRO=$(echo "$FILENAME" | cut -d'-' -f1 | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')

# Construir el nombre del disco
QCOW2_FILE="$BASE_DIR/${DISTRO}_general.qcow2"

echo "Distribución detectada: $DISTRO"
echo "Archivo de destino: $QCOW2_FILE"

# Crear la imagen de disco (40G por defecto, qcow2 crece dinámicamente)
if [ -f "$QCOW2_FILE" ]; then
    read -p "El archivo $QCOW2_FILE ya existe. ¿Sobrescribir? (s/n): " confirm
    if [[ ! $confirm =~ ^[sS]$ ]]; then
        echo "Operación cancelada."
        exit 0
    fi
fi

echo "Creando imagen de disco qcow2..."
qemu-img create -f qcow2 "$QCOW2_FILE" 40G

echo "----------------------------------------------------------"
echo "¡Imagen creada con éxito!"
echo "Ahora puedes iniciar la instalación con qemu usando la ISO"
echo "----------------------------------------------------------"
echo "Ejemplo de comando para iniciar la instalación:"
echo "qemu-system-x86_64 -hda $QCOW2_FILE -cdrom $ISO_PATH -m 4096 -smp 4 -enable-kvm"
