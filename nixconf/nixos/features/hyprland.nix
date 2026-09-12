{ config, pkgs, inputs, ... }:

{
  # ── Hyprland (System Level) ────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    package = pkgs.hyprland.override { wrapRuntimeDeps = true; };
  };

  # ── XDG Portal ──────────────────────────────────────────────
  # Backends declarativos (sin duplicación de units). El routing por WM lo
  # declara cada WM: Hyprland se auto-detecta vía UseIn=Hyprland
  # (portalPackage) y niri vía su niri-portals.conf del paquete
  # (default=gnome;gtk; → screencast por xdg-desktop-portal-gnome).
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  # ── Hyprland ecosystem packages ────────────────────────────
  environment.systemPackages = with pkgs; [
    # Hyprland core
    hyprland
    hyprlock
    hypridle
    hyprshot
    hyprpicker
    hyprpaper
    hyprsunset
    hyprcursor
    hyprutils
    hyprland-qtutils

    # Waybar + widgets
    waybar
    eww
    quickshell

    # Launchers
    wofi
    fuzzel
    rofi
    wlogout
    vicinae


    # Notifications
    dunst
    swaynotificationcenter
    mako

    # Screenshot / screen tools
    grim
    slurp
    satty
    flameshot
    wl-color-picker
    wl-clipboard
    cliphist
    swappy
    wayshot

    # Display / outputs
    nwg-displays
    wlr-randr
    kanshi

    # Terminal
    kitty
    ghostty
    alacritty

    # Wallpaper
    awww
    swaybg

    # Session / polkit
    polkit_gnome
    thunar
    thunar-volman
    thunar-archive-plugin
    nemo

    # Clipboard / input
    copyq
    cliphist
    ydotool
    wtype
    input-remapper
    kanata

    # Color picker
    gpick

    # Audio visualizer
    cava

    # Network TUI (for system_control.sh)
    impala

    # Bluetooth TUI
    bluetui

    # Input devices / controllers
    antimicrox
    evtest
    sc-controller

    # File bind mount (waydroid sync)
    bindfs

    # Emoji picker (for rofimoji keybind)
    rofimoji

    # Misc Wayland
    cage
    mpvpaper
    wlsunset
    brightnessctl
    playerctl
    pamixer
    libnotify
    networkmanagerapplet
    udiskie

    # Dev tools
    opencode
    # opencode-desktop

    # Qt/GTK Wayland
    qt5.qtwayland
    qt6.qtwayland
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum
    gtk-layer-shell
  ];

}
