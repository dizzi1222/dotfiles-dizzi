{ config, pkgs, stateVersion, username, homeDirectory, inputs, ... }:

{
  home = {
    inherit username stateVersion;
    homeDirectory = homeDirectory;
    pointerCursor.enable = true;
    sessionVariables = {
      EDITOR = "nvim";
      TERMINAL = "ghostty";
      BROWSER = "zen";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ── Symlinks to dotfiles-dizzi ─────────────────────────────
  # Each app config lives in ~/dotfiles-dizzi/<app>/.config/<app>
  # Home Manager creates symlinks to expected XDG paths
  home.file = let
    df = "${homeDirectory}/dotfiles-dizzi";
    link = path: config.lib.file.mkOutOfStoreSymlink "${df}/${path}";
  in {
    # Hyprland
    ".config/hypr".source = link "hypr/.config/hypr";
    # Waybar
    ".config/waybar".source = link "waybar/.config/waybar";
    # Rofi
    ".config/rofi".source = link "rofi/.config/rofi";
    # Ghostty
    ".config/ghostty".source = link "ghostty/.config/ghostty";
    # Kitty
    ".config/kitty".source = link "kitty/.config/kitty";
    # Starship
    ".config/starship".source = link "starship/.config/starship";
    # Neovim
    ".config/nvim".source = link "nvim/.config/nvim";
    # Fastfetch
    ".config/fastfetch".source = link "fastfetch/.config/fastfetch";
    # Zellij
    ".config/zellij".source = link "zellij/.config/zellij";
    # Dunst
    #".config/dunst".source = link "dunst/.config/dunst";
    # SwayNC
    ".config/swaync".source = link "swaync/.config/swaync";
    # Quickshell
    ".config/quickshell".source = link "quickshell/.config/quickshell";
    # Espanso
    ".config/espanso".source = link "espanso/.config/espanso";
    # EasyEffects
    #".config/EasyEffects".source = link "easyeffects/.config/EasyEffects";
    # Wal
    ".config/wal".source = link "wal/.config/wal";
    # Qt5CT
    ".config/qt5ct".source = link "qt5ct/.config/qt5ct";
    # Qt6CT
    ".config/qt6ct".source = link "qt6ct/.config/qt6ct";
    # Htop
    #".config/htop".source = link "htop/.config/htop";
    # Bottom
    ".config/bottom".source = link "bottom/.config/bottom";
    # Sunshine
    ".config/sunshine".source = link "sunshine/.config/sunshine";
    # OpenCode
    ".config/opencode".source = link "opencode/.config/opencode";
    # PipeWire
    ".config/pipewire".source = link "pipewire/.config/pipewire";
    # Niri
    ".config/niri".source = link "niri/.config/niri";
    # Kanata
    #".config/kanata".source = link "kanata/.config/kanata";
    # Caelestia
    ".config/caelestia".source = link "caelestia/.config/caelestia";
    # Systemd
    #".config/systemd".source = link "systemd/.config/systemd";

    # Wallpapers
    "Wallpapers".source = link "wallpapers/wallpapers";

    # Local bin scripts
    ".local/bin".source = link "local/.local/bin";

    # Zsh (managed by programs.zsh, not symlinked)
    #".zshrc".source = link "zsh/.zshrc";
    #".zshenv".source = link "zsh/.zshenv";
    #".p10k.zsh".source = link "zsh/.p10k.zsh";

    # Starship config
    #".config/starship.toml".source = link "starship/.config/starship/starship.toml";

    # Cursor
    #".icons".source = link "cursor/.icons";
    #".local/share/icons".source = link "icons/.local/share/icons";

    # Fonts
    ".local/share/fonts".source = link "fonts/.local/share/fonts";
  };

  # ── XDG dirs ───────────────────────────────────────────────
  xdg = {
    enable = true;
    mime.enable = true;
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
