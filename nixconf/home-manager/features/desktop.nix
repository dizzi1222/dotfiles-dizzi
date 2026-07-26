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
    cava

    # File Managers
    thunar
    thunar-volman
    thunar-archive-plugin
    nemo
    ranger

    # Communication
    signal-desktop
    telegram-desktop
    discord
    vencord

    # Browsers
    brave
    firefox

    # Graphics / Creative
    gimp
    inkscape
    krita
    obs-studio
    flameshot
    satty
    kdePackages.kdenlive

    # Editors
    neovim

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
    copyq
    gpick

    # VPN
    proton-vpn

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
