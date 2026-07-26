{ config, pkgs, ... }:

{
  # ── GUI Applications ───────────────────────────────────────
  home.packages = with pkgs; [
    # Media players
    vlc
    mpv
    imv

    # Audio
    pavucontrol
    easyeffects

    # File Managers
    thunar
    thunar-volman
    thunar-archive-plugin
    nemo

    # Communication
    signal-desktop
    telegram-desktop
    discord
    vencord

    # Graphics / Creative
    gimp
    inkscape
    krita
    obs-studio
    flameshot
    satty

    # Office
    libreoffice-fresh
    kdePackages.okular

    # Utilities
    grim
    slurp
    wl-clipboard
    wofi
    fuzzel
    wlr-randr
    hyprpicker
    brightnessctl
    libnotify
    dunst
    playerctl
    eza
    bat
    scrcpy
    syncthing
    syncthingtray
    rquickshare
    filezilla
    transmission_4-gtk

    # Appearance
    lxappearance
    nwg-look
    gruvbox-gtk-theme
    colloid-gtk-theme
    catppuccin-gtk
    papirus-icon-theme
    nixos-icons

    # Nerd Fonts
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  # ── Spicetify (Spotify theming) ────────────────────────────
  # Theme managed by Stylix
  programs.spicetify.enable = true;

  # ── Zen Browser ────────────────────────────────────────────
  programs.zen-browser = {
    enable = true;
  };

}
