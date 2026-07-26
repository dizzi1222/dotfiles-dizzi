{ config, pkgs, ... }:

{
  # ── Background Services ────────────────────────────────────

  # ── Dunst ──────────────────────────────────────────────────
  # Config symlinked from dotfiles-dizzi/dunst/.config/dunst

  # ── EasyEffects ────────────────────────────────────────────
  # Config symlinked from dotfiles-dizzi/easyeffects/.config/EasyEffects

  # ── Espanso (Text Expander) ────────────────────────────────
  # Config managed via symlink from dotfiles-dizzi/espanso/.config/espanso
  # HM service disabled — it conflicts with the out-of-store symlink

  # ── Flameshot ──────────────────────────────────────────────
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        savePath = "$HOME/Pictures/Screenshots";
        uiColor = "#a6d189";
        showStartupLaunchMessage = false;
      };
    };
  };

  # ── XDG Portals ────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };

  # ── Services packages ──────────────────────────────────────
  home.packages = with pkgs; [
    # Clipboard
    wl-clipboard
    cliphist

    # File manager
    thunar
    thunar-volman
    thunar-archive-plugin

    # Image viewer
    imv

    # PDF viewer
    zathura

    # Screenshot tools
    flameshot
    satty
    grim
    slurp
    swappy

    # Color picker
    hyprpicker
    wl-color-picker
    gpick

    # Screen recording
    wf-recorder
    obs-studio

    # Notification tools
    libnotify
    dunst

    # System tray
    networkmanagerapplet
    blueman

    # Misc
    espanso
    ydotool
    wtype
    wlr-randr
    nwg-look
    lxappearance

    # Rclone (cloud storage)
    rclone

    # Qt theming
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum

    # Pywal
    pywal16
  ];

}
