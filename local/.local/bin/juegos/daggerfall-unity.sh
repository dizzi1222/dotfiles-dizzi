#!/bin/bash
set -euo pipefail

# Unity necesita el entorno FHS de NixOS y autodetectar los drivers SDL.
unset SDL_VIDEODRIVER SDL_AUDIODRIVER
cd "$HOME"
exec steam-run "$HOME/DaggerfallUnity.x86_64" -screen-fullscreen 0 -screen-width 1280 -screen-height 720 "$@"
