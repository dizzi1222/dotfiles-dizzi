#!/bin/bash
export WINEDEBUG=-all
export WINEPREFIX="/home/diego/.var/app/com.usebottles.bottles/data/bottles/bottles/gaming"
export WINEDLLOVERRIDES="mscoree,mscoreei,mscoreeis=n"
export LUTRIS_SKIP_INIT=1
# Fija el ICD Vulkan: GTX 1650 (NVK) o iGPU Intel (UHD 630). NVK en mesa 26.1.5
# aborta en vkCreateGraphicsPipelines (Assertion winevulkan); para PokeOne (ligero)
# usamos la iGPU que además es determinista con shaders.
export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
wine "C:\\Games\\PokeOne\\Launcher.exe"
