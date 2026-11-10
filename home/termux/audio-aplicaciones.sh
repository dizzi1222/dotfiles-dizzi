#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Asistente nativo de Xiaomi: ver AUDIO-APLICACIONES.md para la ROM probada.
if ! command -v am >/dev/null 2>&1; then
    echo "Falta el comando am. Instálalo en Termux: pkg install termux-am" >&2
    exit 1
fi

echo "Abriendo Asistente de sonido de Xiaomi..."
exec am start -n com.miui.misound/com.miui.misound.playervolume.SoundAssistActivity
