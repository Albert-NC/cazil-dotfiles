#!/bin/bash

# Ruta de la interfaz del chip EC
RUTA_EC="/sys/kernel/debug/ec/ec0/io"

# Función para escribir en la memoria del chip
escribir_ec() {
    local direccion=$(($1)) # Convierte hex a decimal
    local valor=$2
    printf "$valor" | sudo dd of="$RUTA_EC" bs=1 seek="$direccion" count=1 conv=notrunc status=none
}

# Verificamos si el módulo está cargado
if [ ! -f "$RUTA_EC" ]; then
    echo "❌ Cargando módulo del sistema (ec_sys)..."
    sudo modprobe ec_sys write_support=1
fi

case "${1:-}" in
    a)
        echo "🌀 Modo: AUTOMÁTICO (Control de Acer)"
        escribir_ec 0x03 '\x11' # Desbloqueo
        escribir_ec 0x21 '\x10' # GPU Auto
        escribir_ec 0x22 '\x04' # CPU Auto
        ;;
    m)
        echo "🚀 Modo: MÁXIMO (A fondo)"
        escribir_ec 0x03 '\x11'
        escribir_ec 0x21 '\x20' # GPU Max
        escribir_ec 0x22 '\x08' # CPU Max
        ;;
    p)
        if [[ -n ${2:-} && $2 -ge 0 && $2 -le 100 ]]; then
            VAL_HEX=$(printf '\\x%02x' "$2")
            echo "⚙️ Modo: PORCENTAJE ($2%)"
            escribir_ec 0x03 '\x11'
            escribir_ec 0x21 '\x30' # Modo Manual GPU
            escribir_ec 0x22 '\x0c' # Modo Manual CPU
            escribir_ec 0x37 "$VAL_HEX" # Velocidad CPU
            escribir_ec 0x3a "$VAL_HEX" # Velocidad GPU
        else
            echo "❌ Error: Usa p seguido de un número entre 0 y 100"
            echo "Ejemplo: fans p 80"
        fi
        ;;
    *)
        echo "Uso: fans {a|m|p [0-100]}"
        echo "  a: automático"
        echo "  m: máximo"
        echo "  p: porcentaje"
        ;;
esac