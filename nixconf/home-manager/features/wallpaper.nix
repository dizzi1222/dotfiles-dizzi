{ pkgs, ... }: {
  # Wallpaper restore: handled via Hyprland exec-once (exec-autostart.conf)
  # Systemd service removed — Hyprland loads before graphical-session.target
  # on Wayland, so the service would never trigger at the right time.
}
