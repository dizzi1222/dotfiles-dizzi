{ config, pkgs, inputs, ... }:

{
  # ── Hyprland (System Level) ────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland.override { wrapRuntimeDeps = false; };
  };

  # ── XDG Portal ─────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    # extraPortals y configPackages desactivados porque causan duplicación
    # de xdg-desktop-portal-hyprland.service en systemd.packages.
    # Los portales se instalan via environment.systemPackages en base-configuration.nix.
    # Fix NixOS/nixpkgs#330916: Vesktop no abría enlaces con navegadores
    # de familia Firefox (Zen) bajo Wayland hasta forzar xdg-open por portal.
    xdgOpenUsePortal = true;
    # Routing del portal por WM. En NixOS 26.11, xdg-desktop-portal-gnome 50.0
    # ya NO expone ScreenCast/Screenshot sobre niri ("Non-compatible display
    # server, exposing settings only", bug niri #1932 obsoleto) → se usa
    # xdg-desktop-portal-wlr (vía wlr-screencopy, que niri sí implementa).
    # Settings se mantiene en gtk;gnome: si solo apunta a gtk, ScreenCast nunca
    # se expone. Hyprland se auto-detecta vía UseIn=Hyprland.
    config = {
      niri = {
        default = "gtk";
        ScreenCast = "wlr";
        Screenshot = "wlr";
        Settings = "gtk;gnome";
      };
    };
  };

  # ── niri portal fix ─────────────────────────────────────────
  # El paquete xdg-desktop-portal-wlr trae wlr.portal con UseIn sin "niri"
  # (solo wlroots;sway;Wayfire;river;phosh;Hyprland) → el front portal no lo
  # selecciona en sesión niri y ScreenCapture (PipeWire) de OBS queda vacío.
  # Este .portal adicional declara wlr como backend válido para UseIn=niri.
  environment.systemPackages = with pkgs; [
    (runCommand "wlr-portal-niri" { } ''
      mkdir -p $out/share/xdg-desktop-portal/portals
      cat > $out/share/xdg-desktop-portal/portals/wlr-niri.portal <<'EOF'
[portal]
DBusName=org.freedesktop.impl.portal.desktop.wlr
Interfaces=org.freedesktop.impl.portal.Screenshot;org.freedesktop.impl.portal.ScreenCast;
UseIn=niri
EOF
    '')

    # ── Hyprland ecosystem packages ────────────────────────────
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
    inputs.quickshell.packages.${pkgs.system}.default

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
    opencode-desktop

    # Qt/GTK Wayland
    qt5.qtwayland
    qt6.qtwayland
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum
    gtk-layer-shell
  ];

}
