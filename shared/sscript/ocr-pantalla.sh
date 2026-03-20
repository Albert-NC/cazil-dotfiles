#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — ocr_pantalla.sh
# Captura un área de la pantalla y copia el texto al portapapeles (OCR)
# ==============================================================================

TEMP_IMG="/tmp/ocr_capture.png"

# 1. Verificar dependencias
if ! command -v tesseract &> /dev/null; then
    notify-send "OCR Error" "Instala 'tesseract-ocr' y 'tesseract-ocr-spa'" -u critical
    exit 1
fi

# 2. Capturar área con grim y slurp
grim -g "$(slurp)" "$TEMP_IMG" || exit 1

# 3. Procesar con Tesseract (en español e inglés)
# -l spa+eng: lenguajes combinados
# stdout: manda el resultado a la salida estándar en lugar de a un archivo
TEXTO=$(tesseract "$TEMP_IMG" stdout -l spa+eng 2>/dev/null)

# 4. Limpiar y copiar al portapapeles
if [ -n "$TEXTO" ]; then
    echo "$TEXTO" | wl-copy
    notify-send "OCR Completado" "Texto copiado al portapapeles" -i edit-paste
else
    notify-send "OCR Fallido" "No se detectó texto en la imagen" -u normal
fi

# 5. Limpieza
rm "$TEMP_IMG"
