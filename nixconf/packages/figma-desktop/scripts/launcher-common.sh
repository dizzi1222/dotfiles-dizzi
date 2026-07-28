#!/usr/bin/env bash
# Common launcher functions for Figma Desktop (AppImage and deb)
# This file is sourced by both launchers to avoid code duplication

# Setup logging directory and file
# Sets: log_dir, log_file
setup_logging() {
	log_dir="${XDG_CACHE_HOME:-$HOME/.cache}/figma-desktop-linux"
	mkdir -p "$log_dir" || return 1
	log_file="$log_dir/launcher.log"
}

# Log a message to the log file
# Usage: log_message "message"
log_message() {
	echo "$1" >> "$log_file"
}

# Detect display backend (Wayland vs X11)
# Sets: is_wayland, use_x11_on_wayland
detect_display_backend() {
	# Detect if Wayland is running
	is_wayland=false
	[[ -n $WAYLAND_DISPLAY ]] && is_wayland=true

	# Default: Use X11/XWayland on Wayland for compatibility
	# Set FIGMA_USE_WAYLAND=1 to use native Wayland
	use_x11_on_wayland=true
	[[ $FIGMA_USE_WAYLAND == '1' ]] && use_x11_on_wayland=false
}

# Check if we have a valid display (not running from TTY)
# Returns: 0 if display available, 1 if not
check_display() {
	[[ -n $DISPLAY || -n $WAYLAND_DISPLAY ]]
}

# Build Electron arguments array based on display backend
# Requires: is_wayland, use_x11_on_wayland to be set
#           (call detect_display_backend first)
# Sets: electron_args array
# Arguments: $1 = "appimage" or "deb" (affects --no-sandbox behavior)
build_electron_args() {
	local package_type="${1:-deb}"

	electron_args=()

	# Disable Chromium sandbox for all package types. Figma's
	# web_app_binding_renderer.js preload uses process.getSystemMemoryInfo()
	# and process.getHeapStatistics(), which Electron blocks inside a sandboxed
	# renderer. Without this flag, the preload fails to load and the desktop
	# bridge never initializes, so OAuth callbacks ("Unable to get profile
	# information from Google") and IPC silently break. AppImage already needed
	# this for FUSE; deb/rpm need it for the preload.
	electron_args+=('--no-sandbox')

	# Disable CustomTitlebar for better Linux integration
	electron_args+=('--disable-features=CustomTitlebar')

	# X11 session - no special flags needed
	if [[ $is_wayland != true ]]; then
		log_message 'X11 session detected'
		return
	fi

	if [[ $use_x11_on_wayland == true ]]; then
		# Default: Use X11 via XWayland for compatibility
		log_message 'Using X11 backend via XWayland'
		electron_args+=('--ozone-platform=x11')
	else
		# Native Wayland mode (user opted in via FIGMA_USE_WAYLAND=1)
		log_message 'Using native Wayland backend'
		electron_args+=('--enable-features=UseOzonePlatform,WaylandWindowDecorations')
		electron_args+=('--ozone-platform=wayland')
		electron_args+=('--enable-wayland-ime')
		electron_args+=('--wayland-text-input-version=3')
	fi
}

# Set common environment variables
setup_electron_env() {
	export ELECTRON_FORCE_IS_PACKAGED=true
	export ELECTRON_USE_SYSTEM_TITLE_BAR=1
}

# Register figma-desktop as the per-user default handler for figma:// URLs.
# Idempotent (safe to call on every launch); non-fatal on failure.
# update-desktop-database alone is enough on some distros (Fedora), but
# Ubuntu/snap-sandboxed browsers need an explicit xdg-mime default.
register_url_scheme() {
	local desktop_id="${1:-figma-desktop.desktop}"
	command -v xdg-mime > /dev/null 2>&1 || return 0
	xdg-mime default "$desktop_id" x-scheme-handler/figma > /dev/null 2>&1 || true
}
