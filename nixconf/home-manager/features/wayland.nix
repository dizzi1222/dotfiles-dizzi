{ config, pkgs, inputs, ... }:

{
  # ── Wayland Session Variables ───────────────────────────────
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:/home/diego/.local/share/flatpak/exports/share";
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    MOZ_ENABLE_WAYLAND = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    ECORE_EVAS_ENGINE = "wayland";
  };

  # ── Hyprland (symlinked from dotfiles-dizzi) ───────────────
  # Config lives in ~/dotfiles-dizzi/hypr/.config/hypr
  # Symlinked via home.nix → ~/.config/hypr
  wayland.windowManager.hyprland.configType = "hyprlang";

  # ── SWWW (Wallpaper Daemon) ────────────────────────────────
  # No HM module — installed as package below

  # ── Wofi (App Launcher) ────────────────────────────────────
  # Config lives in ~/dotfiles-dizzi/wofi/.config/wofi
  # Symlinked via home.nix → ~/.config/wofi
  # programs.wofi.enable is OFF to avoid conflict with symlink

  # ── Mako (Notification Daemon) ─────────────────────────────
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      default-delay = 100;
      max-visible = 5;
      max-history = 50;
      border-radius = 10;
    };
  };

  # ── SWAYNC (Notification Center) ───────────────────────────
  # Config symlinked from dotfiles-dizzi/swaync/.config/swaync

  # ── Playerctl ──────────────────────────────────────────────
  services.playerctld = {
    enable = true;
  };

  # ── Clipboard Manager (Clipman) ────────────────────────────
  services.clipman = {
    enable = true;
  };

  # ── Idle Manager ───────────────────────────────────────────
  # Config managed via symlink from dotfiles-dizzi/hypr/.config/hypr

  # ── Lock Screen ────────────────────────────────────────────
  # Config managed via symlink from dotfiles-dizzi/hypr/.config/hypr

  # ── Color Picker ───────────────────────────────────────────
  # Config managed via symlink from dotfiles-dizzi/hypr/.config/hypr

  # ── Waybar ─────────────────────────────────────────────────
  # Config symlinked from dotfiles-dizzi/waybar/.config/waybar

  # ── Rofi ───────────────────────────────────────────────────
  # Config symlinked from dotfiles-dizzi/rofi/.config/rofi

  # ── System packages ────────────────────────────────────────
  home.packages = with pkgs; [
    inputs.swww.packages.${pkgs.system}.default
    awww
    wofi
    wlogout
    wl-color-picker
    hyprpicker
    grim
    slurp
    swappy
    wayshot
    wlr-randr
    brightnessctl
    playerctl
    pamixer
    pavucontrol
    networkmanagerapplet
    blueman
    clipman
    bluetui
    impala
    rofimoji
    networkmanager_dmenu
  ];
}
