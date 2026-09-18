#!/bin/bash
export WINEDEBUG=-all
export WINEPREFIX="/home/diego/.var/app/com.usebottles.bottles/data/bottles/bottles/gaming"
export WINEDLLOVERRIDES="mscoree,mscoreei,mscoreeis=n"
export LUTRIS_SKIP_INIT=1
export SDL_VIDEODRIVER=x11
# Fija el ICD Vulkan: GTX 1650 (NVK) o iGPU Intel (UHD 630). NVK en mesa 26.1.5
# aborta en vkCreateGraphicsPipelines (Assertion winevulkan); para PokeOne (ligero)
# usamos la iGPU que además es determinista con shaders.
export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
# NVIDIA instalado: mesa no crea el screen EGL del 10de:1f91 -> forzar iGPU Iris.
export MESA_LOADER_DRIVER_OVERRIDE=iris
export LD_LIBRARY_PATH="/run/opengl-driver/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
wine "C:\\Games\\PokeOne\\Launcher.exe"