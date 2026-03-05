#!/bin/bash

# Configuration
KALI_DIR="/home/p4x/Proyectos/qemu/maquinas"
KALI_GENERAL="$KALI_DIR/kali_general.qcow2"
KALI_01="$KALI_DIR/kali01.qcow2"

echo "Limpiando máquina Kali..."

# 1. Borrar kali01 si existe
if [ -f "$KALI_01" ]; then
    echo "Borrando $KALI_01..."
    rm "$KALI_01"
else
    echo "No se encontró $KALI_01, procediendo a clonar..."
fi

# 2. Clonar desde kali_general
if [ -f "$KALI_GENERAL" ]; then
    echo "Clonando $KALI_GENERAL en $KALI_01..."
    cp "$KALI_GENERAL" "$KALI_01"
    echo "¡Listo! La máquina ha sido restaurada."
else
    echo "Error: No se encontró la imagen original $KALI_GENERAL."
    exit 1
fi
