#!/bin/bash
export WINEDEBUG=-all
export LUTRIS_SKIP_INIT=1
export SDL_VIDEODRIVER=x11
export MESA_LOADER_DRIVER_OVERRIDE=iris
export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
export LD_LIBRARY_PATH="/run/opengl-driver/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
cd "/home/diego/.wine/drive_c/Games/KONAMI/Pro Evolution Soccer 6" || exit 1
wine "PES6.exe"