#!/usr/bin/env bash
set -euo pipefail

app_root="@out@/share/figma-desktop"
source "$app_root/launcher-common.sh"

setup_logging || exit 1
setup_electron_env
: "${WAYLAND_DISPLAY:=}"
: "${FIGMA_USE_WAYLAND:=}"
if ! detect_display_backend; then
  :
fi
build_electron_args 'deb'

electron_args+=("$app_root/app.asar")

log_message '--- Figma Desktop Nix Start ---'
log_message "Timestamp: $(date)"
log_message "Arguments: $*"
log_message "App root: $app_root"
log_message "Electron binary: @electron@/bin/electron"
log_message "Electron arguments: ${electron_args[*]}"

cd "$HOME" || exit 1
exec "@electron@/bin/electron" "${electron_args[@]}" "$@" >> "$log_file" 2>&1
