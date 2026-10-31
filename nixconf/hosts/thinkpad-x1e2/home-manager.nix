{ config, pkgs, lib, inputs, stateVersion, username, homeDirectory, spicePkgs, figureDesktopPkg, vicinaePatchedPkg, ... }:
{
  imports = [
    ../../home-manager/home.nix
    ../../home-manager/features/desktop.nix
    ../../home-manager/features/shell.nix
    ../../home-manager/features/wayland.nix
    ../../home-manager/features/services.nix
    ../../home-manager/features/wallpaper.nix
    ../../home-manager/features/stylix.nix
    ../../home-manager/features/work.nix
    ../../home-manager/features/codex-desktop.nix
    ../../home-manager/features/media.nix
    ../../home-manager/features/cleanup.nix
    ../../home-manager/features/stardew.nix
    inputs.spicetify-nix.homeManagerModules.default
    inputs.zen-browser.homeModules.default
  ];

  # Host-specific Home Manager overrides go here

  # Figma Desktop (real Electron client with local MCP server at 127.0.0.1:3845)
  home.packages = [
    figureDesktopPkg
  ];

  # Vicinae (Raycast alternative for Linux)
  programs.vicinae = {
    enable = true;
    # Parcheado: fix del bug "Uninstall Extension" en el store para no-instaladas.
    package = vicinaePatchedPkg;
    # Cada compositor lo inicia una sola vez con su entorno gráfico real.
    # Evita competir contra un servicio atado a graphical-session.target.
    systemd.enable = false;
    # Exportado desde ~/.config/vicinae/settings.json (imperativo → declarativo).
    settings = {
      theme = {
        light = {
          name = lib.mkForce "pywal";
        };
        dark = {
          name = lib.mkForce "catppuccin-mocha";
        };
      };
      keybinds = {
        toggle-action-panel = "control+K";
      };
      # 'top' layer en niri queda DETRÁS de las ventanas fullscreen.
      # 'overlay' sí se dibuja encima de fullscreen (ver docs vicinae FAQ).
      launcher_window = {
        layer_shell = {
          layer = "overlay";
        };
      };
      favorites = [
        "clipboard:history"
        "@knoopx/store.vicinae.nix:packages"
        "applications:display-setup"
        "applications:waydroid-start-sd"
        "applications:Stremio_Web"
      ];
      fallbacks = [ "files:search" ];
      providers = {
        files = {
          preferences = {
            autoIndexing = true;
            indexingPaths = map (path: "${homeDirectory}/${path}") [
              "Documentos"
              "Documents"
              "Descargas"
              "Escritorio"
              "Imágenes"
              "Pictures"
              "Música"
              "Vídeos"
              "workspace"
              "Proyectos"
              "dotfiles-dizzi"
            ];
            excludedIndexingPaths = [ ];
          };
        };
        "@meshal/store.raycast.antigravity" = {
          entrypoints = {
            open-with-antigravity = {
              enabled = false;
            };
          };
        };
        applications = {
          entrypoints = {
            Dorion = {
              enabled = false;
            };
            Shadow_PC = {
              enabled = false;
            };
            discord = {
              enabled = false;
            };
            "gaming--PokeMMO--1772229200.475779" = {
              enabled = false;
            };
            "net.lutris.neovim-124" = {
              enabled = false;
            };
            vim = {
              enabled = false;
            };
            "wine.Programs.CustomRP.CustomRP" = {
              enabled = false;
            };
            "wine.Programs.Shadow PC" = {
              enabled = false;
            };
          };
        };
      };
    };
  };

  # ── xwayland-satellite.service (desactivar el duplicado de systemd) ──
  # niri spawnea su PROPIO xwayland-satellite y setea DISPLAY dinámicamente
  # (al display real del satellite, p.ej. :1). Hyprland tiene Xwayland nativo.
  # Tener además el service de systemd causaba carreras de display ("server
  # already running"): el service se quedaba con :0/:2 y niri con :1, mientras
  # envs.kdl forzaba DISPLAY=:0 → apuntaba al Xorg de SDDM (auth) y Steam moría
  # con "Unable to open X11 display". Se elimina el symlink de enablement.
  home.activation.disableXwaylandSatellite =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.coreutils}/bin/rm -f "$HOME/.config/systemd/user/graphical-session.target.wants/xwayland-satellite.service"
    '';
}
