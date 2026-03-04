#!/bin/bash
# gpu-check.sh — Monitor de estado de GPU NVIDIA

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}[!] Drivers NVIDIA no detectados.${NC}"
    exit 1
fi

PSTATE=$(nvidia-smi --query-gpu=pstate --format=csv,noheader)
TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
POWER=$(cat /proc/driver/nvidia/gpus/*/power 2>/dev/null | grep "Runtime" | awk '{print $NF}')

echo -e "${YELLOW}--- Estado de GPU NVIDIA ---${NC}"
echo -e "Modo Energético: ${GREEN}$PSTATE${NC} (P8=Off/Idle, P0=Máximo)"
echo -e "Temperatura:    ${GREEN}$TEMP°C${NC}"

if [ -n "$POWER" ]; then
    echo -e "Runtime D3:     ${GREEN}$POWER${NC}"
fi

if [[ "$PSTATE" == "P8" ]]; then
    echo -e "\n${GREEN}[✓] La GPU está actualmente en reposo (Ahorrando batería).${NC}"
else
    echo -e "\n${YELLOW}[!] La GPU está activa.${NC}"
fi
