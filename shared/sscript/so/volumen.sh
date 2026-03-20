#!/bin/bash
# volumen.sh — Control de volumen con notificaciones discretas
# Uso: volumen [up|down|mute]

case "$1" in
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        echo "Uso: volumen [up|down|mute]"
        exit 1
        ;;
esac

# Obtener volumen actual y estado mute
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED" && echo "true" || echo "false")

if [ "$MUTED" == "true" ]; then
    notify-send -e -t 1000 -h string:x-canonical-private-synchronous:volume "Muted" -i audio-volume-muted
else
    notify-send -e -t 1000 -h string:x-canonical-private-synchronous:volume -h int:value:"$VOL" "Volumen: $VOL%" -i audio-volume-high
fi
