{ config, pkgs, lib, suwayomiServerPkg, pearDesktopPkg, kewPatchedPkg, ... }:

let
  # Colloid with Dark + Pink variants so Colloid-Pink-Dark is available
  colloidTheme = pkgs.colloid-gtk-theme.override {
    themeVariants = [ "default" "pink" ];
    colorVariants = [ "dark" ];
  };

  # Suwayomi launcher: start the headless server (if not running) and open its web UI
  suwayomi-launcher = pkgs.writeShellScriptBin "suwayomi-launcher" ''
    if ! pgrep -f "Suwayomi-Server" >/dev/null; then
      ${suwayomiServerPkg}/bin/tachidesk-server &
    fi
    sleep 2
    ${pkgs.xdg-utils}/bin/xdg-open http://localhost:4567
  '';

  # Zen Browser flake installs the binary as `zen-beta`; expose the canonical
  # `zen-browser` name so desktop entries, keybinds, etc. don't need fallbacks.
  zen-browser = pkgs.writeShellScriptBin "zen-browser" ''
    exec ${config.programs.zen-browser.finalPackage}/bin/zen-beta "$@"
  '';
in
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
    kewPatchedPkg
    musicpresence

    # File Managers
    thunar
    thunar-volman
    thunar-archive-plugin
    nemo
    nautilus
    ranger

    # Communication
    signal-desktop
    telegram-desktop
    discord
    vencord
    vesktop

    # Browsers
    brave
    zen-browser

    # Graphics / Creative
    gimp
    inkscape
    krita
    obs-studio
    flameshot
    satty
    kdePackages.kdenlive

    # ── Editors ─────────────────────────────────────────────────────
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
    qtscrcpy
    syncthing
    syncthingtray
    rquickshare
    filezilla
    transmission_4-gtk
    copyq
    gpick

    # VPN
    proton-vpn

    # YouTube Music desktop (pear-desktop renombrado a YouTube Music)
    pearDesktopPkg

    # Stremio (media center)
    stremio-linux-shell
    stremio-service

    # Manga reader server (actualizado a 2.3.x via suwayomiServerPkg)
    suwayomiServerPkg
    suwayomi-launcher

    # Appearance
    lxappearance
    nwg-look
    gruvbox-gtk-theme
    colloidTheme
    catppuccin-gtk
    papirus-icon-theme
    nixos-icons

    # Nerd Fonts
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only

    # Cursors
    bibata-cursors
  ];

  # ── Symlink Colloid-Pink-Dark → ~/.themes/ (for nwg-look) ──
  # mkForce: Stylix también genera ~/.themes/Colloid-Pink-Dark vía su módulo gtk.
  home.file = {
    ".themes/Colloid-Pink-Dark".source =
      lib.mkForce "${colloidTheme}/share/themes/Colloid-Pink-Dark";
    ".themes/Colloid-Pink-Dark-hdpi".source =
      lib.mkForce "${colloidTheme}/share/themes/Colloid-Pink-Dark-hdpi";
    ".themes/Colloid-Pink-Dark-xhdpi".source =
      lib.mkForce "${colloidTheme}/share/themes/Colloid-Pink-Dark-xhdpi";
  };

  # ── Spicetify (Spotify theming) ────────────────────────────
  # Theme managed by Stylix
  programs.spicetify.enable = true;

  # ── Zen Browser ────────────────────────────────────────────
  programs.zen-browser = {
    enable = true;
  };

}
