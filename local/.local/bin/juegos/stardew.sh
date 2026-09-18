#!/bin/bash
export WINEDEBUG=-all
export LUTRIS_SKIP_INIT=1
export SDL_VIDEODRIVER=x11
export LIBGL_ALWAYS_INDIRECT=0
export MESA_LOADER_DRIVER_OVERRIDE=iris
export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
export LD_LIBRARY_PATH="/run/opengl-driver/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
# antimicrox --profile "$HOME/.config/antimicrox/profiles/8bitdo-stardew.amgp" --tray & # Mejor usar Stema Input.
ANTI_PID=$!
sleep 1
script -e -q -c "wine '/home/diego/.wine/drive_c/Games/Stardew Valley/StardewModdingAPI.exe'" /dev/null
kill $ANTI_PID 2>/dev/null
