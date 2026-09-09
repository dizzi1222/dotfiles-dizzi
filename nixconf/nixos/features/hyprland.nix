{ config, pkgs, inputs, ... }:

{
  # ── Hyprland (System Level) ────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    package = pkgs.hyprland.override { wrapRuntimeDeps = false; };
  };

  # ── XDG Portal ──────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    # Backends declarativos (sin duplicación de units):
    #  - gtk:   portal base (file chooser, settings fallback)
    #  - gnome: solo expone Settings sobre niri (50.0) — NO ScreenCapture
    #  - wlr:   ScreenCapture/Screenshot vía wlr-screencopy (niri sí lo soporta)
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-wlr
    ];
    # Routing por WM. En niri, gnome 50 expone su portal UI pero NO captura
    # ("Non-compatible display server, exposing settings only") → forzar
    # wlr para ScreenCast/Screenshot; Settings se queda en gtk;gnome.
    # Hyprland se auto-detecta vía UseIn=Hyprland (portalPackage).
    config = {
      niri = {
        default = "gtk";
        ScreenCast = "wlr";
        Screenshot = "wlr";
        Settings = "gtk;gnome";
      };
    };
  };

  # ── niri portal fix: hacer que el front detecte wlr bajo niri ─
  # xdg-desktop-portal-wlr trae wlr.portal con UseIn sin "niri"
  # (solo wlroots;sway;Wayfire;river;phosh;Hyprland) → el front no selecciona
  # el backend wlr en sesión niri y la captura queda negra/vacía.
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
