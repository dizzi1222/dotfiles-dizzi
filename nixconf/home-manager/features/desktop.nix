{ config, pkgs, lib, spicePkgs, suwayomiServerPkg, pearDesktopPkg, kewPatchedPkg, ... }:

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

  # Discord nativo + bridge 0e4ef622 (Rich Presence): al abrir Discord se levanta
  # el bridge IPC en ~/.wine para que CustomRP/juegos Wine conecten al socket nativo
  # del host (/run/user/<uid>/discord-ipc-*). El bridge es la pestilla del método 2.
  #
  # ⚠️ CONFIG IDEAL (concluido): el wrapper de Discord es NECESARIO. Setup:
  #   1) Discord nativo SIEMPRE corriendo MINIMIZADO (sostiene el socket IPC y el bridge)
  #   2) Vesktop + Discord se lanzan juntos en el startup
  # El bridge 0e4ef622 se ancla al socket IPC MÁS RECIENTE y NO se re-mapea solo si
  # ese peer muere: si se cierra Discord, reiniciar el bridge. Para publicar via
  # Vesktop: cerrar Discord nativo y relanzar el bridge con solo Vesktop arriba.
  discord-bridge-wrapped = pkgs.writeShellScriptBin "discord" ''
    # 1) arranca el Discord nativo (paquete real de nixpkgs)
    ${pkgs.discord}/bin/discord "$@" &
    DISCORD_PID=$!

    # 2) espera el socket IPC nativo (máx ~15s)
    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    for _ in $(seq 1 30); do
      [ -S "$RUNTIME_DIR/discord-ipc-0" ] && break
      sleep 0.5
    done

    # 3) levanta el bridge 0e4ef622 en ~/.wine (CustomRP → Discord nativo)
    nohup "$HOME/.local/bin/juegos/wine-discord-ipc-bridge.sh" wine >/dev/null 2>&1 &

    # 4) levanta el bridge 0e4ef622 en la botella "gaming" de Bottles
    nohup "$HOME/.local/bin/juegos/wine-discord-ipc-bridge.sh" bottles >/dev/null 2>&1 &

    wait "$DISCORD_PID"
  '';
in
{
  # ── GUI Applications ───────────────────────────────────────
  home.packages = with pkgs; [
    # Media players
    vlc
    mpv
    imv

    # Mod managers
    curseforge        # AppImage oficial Overwolf: mods Minecraft/WoW (no en nixpkgs/Flathub)
    vortex            # Vortex (NexusMods.App UNFREE, soporta .rar) + .desktop con keywords
    r2modman          # Unofficial Thunderstore mod manager (AppImage→nixpkgs 3.2.18, Thunderstore)
    #amethyst         # DESCARTADO: AppImages 2.5.1/2.5.2 dañados (offset SQUASHFS desalineado,
    #                 #   "Can't find a valid SQUASHFS superblock" en appimageTools.extract)
    #ModDrop          # NO existe Linux: Windows-only, sin AppImage/flatpak; comunidad desaconseja

    # Audio
    pavucontrol
    easyeffects
    cava
    kewPatchedPkg
    musicpresence

    # Spicetify CLI (el módulo spicetify-nix lo usa internamente para el apply;
    # lo exponemos en PATH para comandos manuales como spicetify -c)
    spicetify-cli

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
    discord-bridge-wrapped
    vencord
    vesktop
    # wine-discord-ipc-bridge
    # Rich presence para juegos de Proton/Wine (Steam): bridge IPC entre el
    # juego y Discord. El .exe corre dentro del wineprefix (compilado para
    # i686-windows); el .sh `winediscordipcbridge-steam.sh` es Linux y va en
    # Steam → Launch Options por juego:
    #   /nix/store/<...>-wine-discord-ipc-bridge-0.0.3/bin/winediscordipcbridge-steam.sh %command%
    wine-discord-ipc-bridge

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
    handbrake

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
    megasync
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
  # El módulo spicetify-nix construye con pkgs.spicetify-cli y pre-parchea
  # el binario de Spotify. Marketplace se habilita como custom app.
  programs.spicetify = {
    enable = true;
    enabledCustomApps = [ spicePkgs.apps.marketplace ];
    # Restaurados declarativamente desde el backup de Marketplace:
    #   home/restore/spicetify-marketplace-settings-2026-01-11.json
    enabledExtensions = [
      {
        src = pkgs.runCommand "spicetify-autoSkipVideo" { } ''
          mkdir -p $out
          cp ${pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/spicetify/cli/main/Extensions/autoSkipVideo.js";
            hash = "sha256-ner2VhfQoj1vrNL7RTXQ60brxHGneWYSzHxbUsVWQHk=";
          }} $out/autoSkipVideo.js
        '';
        name = "autoSkipVideo.js";
      }
      {
        src = pkgs.runCommand "spicetify-adblockify" { } ''
          mkdir -p $out
          cp ${pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/rxri/spicetify-extensions/main/adblock/adblock.js";
            hash = "sha256-tgckOgKnmbuo5AKJ/x5di2MriF3f7pUaqvHD1zPoABs=";
          }} $out/adblock.js
        '';
        name = "adblock.js";
      }
    ];
    # Snippet "Rotating Cover Art" (del mismo backup)
    enabledSnippets = [
      ''
        @keyframes rotating {from {transform: rotate(0deg);}to {transform: rotate(360deg);}}
        .cover-art, .main-nowPlayingView-coverArtContainer::after, .main-nowPlayingView-coverArtContainer::before {animation: rotating 10s linear infinite;border-radius: 50%;}
        .cover-art {clip-path: circle(50% at 50% 50%);}
        .main-nowPlayingBar-left button {background: transparent;}
        .main-nowPlayingView-coverArt {box-shadow:none; filter: drop-shadow(0 9px 9px rgba(0,0,0,.271));}
      ''
    ];
  };

  # ── Zen Browser ────────────────────────────────────────────
  programs.zen-browser = {
    enable = true;
  };

}
