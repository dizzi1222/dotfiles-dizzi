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
    systemd = {
      enable = true;
      autoStart = true;
    };
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
      favorites = [
        "clipboard:history"
        "@knoopx/store.vicinae.nix:packages"
        "applications:display-setup"
        "applications:waydroid-start-sd"
        "applications:Stremio_Web"
      ];
      providers = {
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
}
