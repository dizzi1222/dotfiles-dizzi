{ config, pkgs, lib, inputs, ... }:

{
  # ── Stylix ─────────────────────────────────────────────────
  stylix = {
    enable = true;
    autoEnable = true;

    # Base16 color scheme (Catppuccin Mocha)
    base16Scheme = {
      base00 = "#1e1e2e"; # Default Background
      base01 = "#181825"; # Lighter Background
      base02 = "#313244"; # Selection Background
      base03 = "#45475a"; # Comments, Invisibles
      base04 = "#585b70"; # Dark Foreground
      base05 = "#cdd6f4"; # Default Foreground
      base06 = "#f5e0dc"; # Light Foreground
      base07 = "#f5e0dc"; # Light Foreground
      base08 = "#f38ba8"; # Red
      base09 = "#fab387"; # Orange
      base0A = "#f9e2af"; # Yellow
      base0B = "#a6e3a1"; # Green
      base0C = "#94e2d5"; # Cyan
      base0D = "#89b4fa"; # Blue
      base0E = "#cba6f7"; # Magenta
      base0F = "#f2cdcd"; # Pink
    };

    # Fonts
    fonts = {
      monospace = {
        name = "JetBrains Mono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      };
      sansSerif = {
        name = "Noto Sans";
        package = pkgs.noto-fonts;
      };
      serif = {
        name = "Noto Serif";
        package = pkgs.noto-fonts;
      };
      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-color-emoji;
      };
      sizes = {
        applications = 11;
        desktop = 11;
        popups = 11;
        terminal = 12;
      };
    };

    # Opacity
    opacity = {
      applications = 0.9;
      terminal = 0.85;
      desktop = 0.95;
      popups = 0.9;
    };

    # Cursor (desactivado: requiere package+name+size, conflict with system fonts.packages)
    # cursor = {
    #   name = "Bibata-Modern-Ice";
    #   package = pkgs.bibata-cursors;
    #   size = 24;
    # };

    targets.zen-browser.profileNames = [ "default" ];
  };

  # ── GTK Theme ──────────────────────────────────────────────
  gtk = {
    enable = true;
    # Tema oscuro explícito (en ~/.themes vía desktop.nix); Stylix por defecto
    # dejaba adw-gtk3 (claro) → apps GTK blancas.
    theme.name = lib.mkForce "Colloid-Pink-Dark";
    font = {
      name = "Noto Sans";
      size = 11;
    };
    cursorTheme = {
      name = "Kafka";
      size = 24;
    };
    iconTheme = {
      name = "Gruvbox-Plus-Dark";
      package = pkgs.gruvbox-plus-icons;
    };
  };

  # ── Qt Theme ───────────────────────────────────────────────
  # Qt sigue al GTK (oscuro). Se quitó el estilo kvantum huérfano (no había
  # tema en ~/.config/Kvantum) y el platformTheme qtct que se pisaban con Stylix.
  qt = {
    enable = true;
    platformTheme = {
      name = "gtk3";
    };
  };

  # ── Preferencia oscura global ──────────────────────────────
  # color-scheme=prefer-dark es lo que oscurece apps nativas/Chromium que
  # ignoran GTK/Qt (Zed, Figma, Electron). Stylix lo dejaba en 'default' (claro).
  dconf.enable = true;
  dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce "prefer-dark";

  # ── Fonts ──────────────────────────────────────────────────
  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    jetbrains-mono
    inter
    source-sans-pro
  ];
}
