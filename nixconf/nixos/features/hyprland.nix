{ config, pkgs, ... }:

{
  # ── Hyprland (System Level) ────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ── XDG Portal ─────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
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

    # Waybar + widgets
    waybar
    eww

    # Launchers
    wofi
    fuzzel
    rofi

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
    nemo

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

    # Qt/GTK Wayland
    qt5.qtwayland
    qt6.qtwayland
    gtk-layer-shell
  ];

}
