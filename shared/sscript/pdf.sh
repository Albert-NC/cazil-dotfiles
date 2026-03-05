#!/bin/bash
# ==============================================================================
# CAZIL SYSTEM — pdf.sh
# Utilidad multi-función para gestión de PDFs en la universidad
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

mostrar_ayuda() {
    echo -e "${GREEN}Uso: pdf <comando> [argumentos]${NC}"
    echo -e "\nComandos disponibles:"
    echo -e "  ${YELLOW}comprimir${NC} <archivo.pdf>     Reduce el tamaño del PDF (Calidad balanceada)"
    echo -e "  ${YELLOW}unir${NC} <salida.pdf> <arch...> Une varios PDFs en uno solo"
    echo -e "  ${YELLOW}imagen${NC} <salida.pdf> <img...> Convierte imágenes (jpg/png) a un solo PDF"
    echo -e "  ${YELLOW}ayuda${NC}                     Muestra este mensaje"
}

comprimir_pdf() {
    if [ -z "$1" ]; then echo "Error: Falta el archivo PDF."; return 1; fi
    local entrada="$1"
    local salida="${entrada%.pdf}_comprimido.pdf"
    
    echo -e "${GREEN}[*] Comprimiendo $entrada...${NC}"
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
       -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$salida" "$entrada"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Guardado como: $salida${NC}"
        du -h "$entrada" "$salida"
    else
        echo -e "${RED}[!] Error al comprimir.${NC}"
    fi
}

unir_pdf() {
    if [ $# -lt 2 ]; then echo "Error: Uso: pdf unir salida.pdf archivo1.pdf archivo2.pdf..."; return 1; fi
    local salida="$1"
    shift
    echo -e "${GREEN}[*] Uniendo archivos en $salida...${NC}"
    qpdf --empty --pages "$@" -- "$salida"
    echo -e "${GREEN}[✓] Archivos unidos con éxito.${NC}"
}

imagen_a_pdf() {
    if [ $# -lt 2 ]; then echo "Error: Uso: pdf imagen salida.pdf imagen1.jpg imagen2.png..."; return 1; fi
    local salida="$1"
    shift
    echo -e "${GREEN}[*] Convirtiendo imágenes a $salida...${NC}"
    magick "$@" "$salida"
    echo -e "${GREEN}[✓] PDF generado desde imágenes.${NC}"
}

case "$1" in
    comprimir) shift; comprimir_pdf "$@" ;;
    unir)      shift; unir_pdf "$@" ;;
    imagen)    shift; imagen_a_pdf "$@" ;;
    ayuda|--help|-h) mostrar_ayuda ;;
    *)         mostrar_ayuda ;;
esac
