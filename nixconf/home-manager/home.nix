{ config, pkgs, stateVersion, username, homeDirectory, inputs, ... }:

{
  home = {
    inherit username stateVersion;
    homeDirectory = homeDirectory;
    # pointerCursor.enable = true;
  sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "kitty";
    BROWSER = "zen";
    SHELL = "zsh";
    VSCODE_EXTENSIONS = "$HOME/.antigravity/runtime/lib/antigravity-ide:$VSCODE_EXTENSIONS";
  };
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-39.8.10"
      "openclaw-2026.6.33"
    ];
  };

  # ── Symlinks to dotfiles-dizzi ─────────────────────────────
  # Each app config lives in ~/dotfiles-dizzi/<app>/.config/<app>
  # Home Manager creates symlinks to expected XDG paths
  home.file =
    let
      df = "${homeDirectory}/dotfiles-dizzi";
      link = path: config.lib.file.mkOutOfStoreSymlink "${df}/${path}";
    in
    {
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
      ".config/dunst".source = link "dunst/.config/dunst";
      # SwayNC
      ".config/swaync".source = link "swaync/.config/swaync";
      # Quickshell
      ".config/quickshell".source = link "quickshell/.config/quickshell";
      # Espanso
      ".config/espanso".source = link "espanso/.config/espanso";
      # EasyEffects
      ".config/EasyEffects".source = link "easyeffects/.config/EasyEffects";
      # Wal
      ".config/wal".source = link "wal/.config/wal";
      # Qt5CT
      ".config/qt5ct".source = link "qt5ct/.config/qt5ct";
      # Qt6CT
      ".config/qt6ct".source = link "qt6ct/.config/qt6ct";
      # Fish
      ".config/fish".source = link "fish/.config/fish";
      # Htop — single file htoprc, not a directory
      ".config/htoprc".source = link "htop/.config/htoprc";
      # Bottom
      ".config/bottom".source = link "bottom/.config/bottom";
      # Sunshine
      ".config/sunshine".source = link "sunshine/.config/sunshine";
      # Tmux
      ".config/tmux".source = link "tmux/.config/tmux";
      # OpenCode
      ".config/opencode".source = link "opencode/.config/opencode";
      # PipeWire
      ".config/pipewire".source = link "pipewire/.config/pipewire";
      # Niri
      ".config/niri".source = link "niri/.config/niri";
      # Kanata
      ".config/kanata".source = link "kanata/.config/kanata";
      # Caelestia
      ".config/caelestia".source = link "caelestia/.config/caelestia";
      # Eww
      ".config/eww".source = link "eww/.config/eww";
      # Wofi
      ".config/wofi".source = link "wofi/.config/wofi";
      # Yazi
      ".config/yazi".source = link "yazi/.config/yazi";
      # Thunar
      ".config/Thunar".source = link "thunar/.config/Thunar";
      # WirePlumber
      ".config/wireplumber".source = link "wireplumber/.config/wireplumber";
      # Dolphin
      ".config/dolphin".source = link "dolphin-files/.config/dolphin";
      # Autostart (comentado: conflicto con home-manager — usa systemd.user.services en su lugar)
      #".config/autostart".source = link "autostart/.config/autostart";
      # Autostart comentado (rclone): los mounts se manejan con systemd.user.services
      # rclone-mount-* en services.nix (sobreviven al resume, Restart=on-failure).
      #".config/autostart/montar_gdrive.desktop".source = link "autostart/.config/autostart/montar_gdrive.desktop";
      #".config/autostart/montar_gd-musica.desktop".source = link "autostart/.config/autostart/montar_gd-musica.desktop";
      #".config/autostart/montar_gd-libros.desktop".source = link "autostart/.config/autostart/montar_gd-libros.desktop";
      # NetworkManager-fuzzel
      ".config/networkmanager-fuzzel".source = link "networkmanager-fuzzel/.config/networkmanager-fuzzel";
      # Nwg-panel (GTK3/4)
      ".config/nwg-panel".source = link "nwg-gtk-4.0/.config/nwg-panel";
      # Input Remapper
      ".config/input-remapper".source = link "input-remapper/.config/input-remapper";
      # Kew
      ".config/kew".source = link "kew/.config/kew";
      # VSCode / VSCodium
      ".config/VSCodium".source = link "vscode/.config/VSCodium";
      # Polybar
      ".config/polybar".source = link "polybar/.config/polybar";
      # Qtile
      ".config/qtile".source = link "qtile/.config/qtile";
      # Vicinae (Raycast alternative)
      ".config/vicinae".source = link "Raycast-vicinae/.config/vicinae";
      # Satty (screenshots)
      ".config/satty".source = link "sattyScreenshots/.config/satty";
      # Kdenlive
      ".config/kdenlive".source = link "kdenlive-compressor-editor/.config/kdenlive";
      # KGlobalShortcuts (Plasma — atajos personalizados; válido también para Cinnamon por las dudas)
      ".config/kglobalshortcutsrc".source = link "global-keyboard-shortcutsrc/.config/kglobalshortcutsrc";
      # McpHub
      ".config/mcphub".source = link "mcphub/.config/mcphub";
      # Neofetch
      ".config/neofetch".source = link "neofetch/.config/neofetch";
      # Fuzzel / Rofimoji
      ".config/fuzzel".source = link "fuzzel-glyphs-rofimoji/.config/fuzzel";
      # Antigravity IDE (VSCode extension config)
      ".config/Antigravity IDE".source = link "Antigravity/.config/Antigravity IDE";
      # Antigravity CLI Settings
      ".gemini/antigravity-cli/settings.json".source = link "Antigravity/.gemini/antigravity-cli/settings.json";
      # Antimicrox (gamepad mapper)
      ".config/antimicrox".source = link "antimicrox/.config/antimicrox";
      # Cursor/Editor (VS Code-based editor settings)
      ".config/Cursor/User".source = link "cursor/.config/Cursor/User";
      # Cursor themes (Kafka, default, etc.)
      ".icons".source = link "icons/.icons";
      # Fonts (manual - Steam bwrap needs real dir)
      #".local/share/fonts".source = link "fonts/.local/share/fonts";
      # Systemd (rclone mount services) — disabled; conflicts with HM services (flameshot, vicinae, etc.)
      #".config/systemd".source = link "systemd/.config/systemd";
      # If you need specific services from dotfiles, use home-manager's systemd.user.services instead

      # Wallpapers — commented: managed manually by CachyOS dotfiles (symlink ~/dotfiles-dizzi/wallpapers)
      # get-wallpapers.sh busca en ~/wallpapers/, wal usa ~/wallpapers/wallpapers/
      # HM would point to ~/dotfiles-dizzi/wallpapers/wallpapers, but existing symlink points to parent
      #"wallpapers".source = link "wallpapers/wallpapers";

      # Scripts (~/scripts → dotfiles-dizzi/home/scripts)
      "scripts".source = link "home/scripts";

      # Wrapper scripts (~/wrapper → dotfiles-dizzi/home/wrapper)
      "wrapper".source = link "home/wrapper";

      # Rclone mount scripts
      "montar_gdrive.sh".source = link "home/montar_gdrive.sh";
      "montar_gd-musica.sh".source = link "home/montar_gd-musica.sh";
      "montar_gd-libros.sh".source = link "home/montar_gd-libros.sh";
      # Bottles installer (used by system_control.sh)
      "install-bottles.sh".source = link "home/install-bottles.sh";
      # Local bin scripts
      ".local/bin".source = link "local/.local/bin";
      # Local app entries (.desktop files)
      ".local/share/applications".source = link "local/.local/share/applications";
      # Local icons
      ".local/share/icons".source = link "local/.local/share/icons";
      # Bottles (Wine)
      ".local/share/bottles".source = link "local/.local/share/bottles";
      # Lutris (game manager)
      ".local/share/lutris".source = link "local/.local/share/lutris";

      # Omarchy (Arch/CachyOS scripts — available on NixOS as helper stubs)
      "omarchy-arch-bin".source = link "home/omarchy-arch-bin";

      # Zsh (.zshrc via activation — overrides HM-generated one after linkGeneration)
      ".zsh".source = link "zsh/.zsh";
      ".p10k.zsh".source = link "zsh/.p10k.zsh";
      # OpenCommit config (~/.opencommit)
      ".opencommit".source = link "home/.opencommit";
      # Engram config (~/.engram/config.json)
      ".engram/config.json".source = link "home/.engram/config.json";
      # Claude config (~/.claude/CLAUDE.md) — fuente única versionada en el repo
      ".claude/CLAUDE.md".source = link "home/.claude/CLAUDE.md";

      # Starship config
      #".config/starship.toml".source = link "starship/.config/starship/starship.toml";

      # Cursor
      #".icons".source = link "cursor/.icons";
      #".local/share/icons".source = link "icons/.local/share/icons";

      # Fonts (not symlinked — Steam's bwrap needs a real dir)
      #".local/share/fonts".source = link "fonts/.local/share/fonts";

      # xdg-terminal-exec: forja la terminal por defecto a kitty. Sin esto,
      # .desktop con Terminal=true (ej. nvim) caen a gnome-terminal porque
      # gsettings apunta a "xdg-terminal-exec" no instalado.
      ".config/xdg-terminals.list".text = ''
        kitty.desktop
      '';
    };

  # ── XDG dirs ───────────────────────────────────────────────
  xdg = {
    enable = true;
    mime.enable = true;
  };

  # ── Steam: ensure ~/.local/share/fonts is a real directory ─
  home.activation.ensureFontDir = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.local/share/fonts" ]; then
      mkdir -p "$HOME/.local/share/fonts"
      # Copy minecraft font if present in dotfiles
      if [ -f "$HOME/dotfiles-dizzi/fonts/minecraft_font.ttc" ]; then
        cp "$HOME/dotfiles-dizzi/fonts/minecraft_font.ttc" "$HOME/.local/share/fonts/"
      fi
    fi
  '';

  # ── Git submodules auto-init ──────────────────────────────
  # Ensure submodules (nvim config, fzf-tab, etc.) are pulled
  # on every home-manager switch
  home.activation.initSubmodules = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    cd ~/dotfiles-dizzi && git submodule update --init --recursive 2>/dev/null || true
  '';

  # ── mcp-hub (neovim plugin dependency, not in nixpkgs) ───
  home.activation.mcpHub = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if ! command -v mcp-hub &>/dev/null; then
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      mkdir -p "$NPM_CONFIG_PREFIX"
      PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
      npm install -g mcp-hub@latest 2>/dev/null || true
    fi
  '';

  # ── Guía Secure Boot + Flatpak ────────────────────────────
  # Se muestra en cada home-manager switch: enlaza al README con los pasos
  home.activation.guide = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    echo
    echo "════════════════════════════════════════════════════════════════"
    echo "  GUÍA SECURE BOOT + Flatpak (README):"
    echo "  https://github.com/dizzi1222/dotfiles-dizzi/blob/main/nixconf/README.md#installation-from-nixos-iso"
    echo "════════════════════════════════════════════════════════════════"
    echo
  '';

  # ── Cursor: runtime writable (custom-ui-style EROFS fix) ──
  # code-cursor en el store Nix es read-only; la extensión custom-ui-style
  # parchea resources/app/out en runtime y muere con EROFS. Copiamos el
  # runtime a ~/.cursor/runtime (writable) y repuntamos el wrapper. El shim
  # ~/.local/bin/cursor (local/.local/bin/cursor) escribe al runtime.
  home.activation.cursorWritable = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    CURSOR_SOURCE="${pkgs.code-cursor}"
    RUNTIME="$HOME/.cursor/runtime"
    MARKER="$RUNTIME/.store-path"
    if [ -d "$RUNTIME" ] && [ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$CURSOR_SOURCE" ]; then
      # ya copiado; solo re-asegurar permisos de escritura
      chmod -R u+w "$RUNTIME" 2>/dev/null || true
    elif [ -d "$CURSOR_SOURCE" ]; then
      echo "  cursor: copiando runtime writable ($CURSOR_SOURCE → $RUNTIME)"
      rm -rf "$RUNTIME"
      mkdir -p "$(dirname "$RUNTIME")"
      cp -a "$CURSOR_SOURCE" "$RUNTIME"
      chmod -R u+w "$RUNTIME"
      # repuntar rutas absolutas del store hacia el runtime writable
      grep -rIl "$CURSOR_SOURCE" "$RUNTIME" 2>/dev/null | while read -r f; do
        sed -i "s|$CURSOR_SOURCE|$RUNTIME|g" "$f"
      done
      echo "$CURSOR_SOURCE" > "$MARKER"
      echo "  cursor: runtime writable listo en $RUNTIME"
    fi
  '';

  # ── Antigravity: runtime writable (extensions need write access) ──
  # antigravity en el store Nix es read-only; las extensiones y configuraciones
  # requieren escritura en runtime. Copiamos el runtime a ~/.antigravity/runtime
  # (writable) y repuntamos el wrapper. El shim
  # ~/.local/bin/antigravity (local/.local/bin/antigravity) escribe al runtime.
  home.activation.antigravityWritable = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    ANTIGRAVITY_SOURCE="${pkgs.antigravity}"
    RUNTIME="$HOME/.antigravity/runtime"
    MARKER="$RUNTIME/.store-path"
    if [ -d "$RUNTIME" ] && [ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$ANTIGRAVITY_SOURCE" ]; then
      # ya copiado; solo re-asegurar permisos de escritura
      chmod -R u+w "$RUNTIME" 2>/dev/null || true
    elif [ -d "$ANTIGRAVITY_SOURCE" ]; then
      echo "  antigravity: copiando runtime writable ($ANTIGRAVITY_SOURCE → $RUNTIME)"
      rm -rf "$RUNTIME"
      mkdir -p "$(dirname "$RUNTIME")"
      cp -a "$ANTIGRAVITY_SOURCE" "$RUNTIME"
      chmod -R u+w "$RUNTIME"
      # repuntar rutas absolutas del store hacia el runtime writable
      grep -rIl "$ANTIGRAVITY_SOURCE" "$RUNTIME" 2>/dev/null | while read -r f; do
        sed -i "s|$ANTIGRAVITY_SOURCE|$RUNTIME|g" "$f"
      done
      echo "$ANTIGRAVITY_SOURCE" > "$MARKER"
      echo "  antigravity: runtime writable listo en $RUNTIME"
    fi
  '';

  # ── oklch-color-picker (Neovim picker binary) ─────────────
  # El plugin de nvim (oklch-color-picker.nvim) auto-descarga un binario
  # compilado para distros estándar que dlopen libwayland/libEGL desde rutas
  # del sistema; en NixOS no hay /usr/lib → panic NoWaylandLib. La solución
  # sólida es reemplazar ese binario descargado por el de nixpkgs (oklch-
  # color-picker), que trae RPATH correcto y funciona sin LD_LIBRARY_PATH.
  # El plugin valida contra el archivo app_version; lo fijamos a la misma
  # versión (2.3.4) para que no reintente descargar de GitHub.
  home.activation.oklchPicker = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    PICKER_DIR="$HOME/.local/share/nvim/oklch-color-picker"
    mkdir -p "$PICKER_DIR"
    if [ -x "${pkgs.oklch-color-picker}/bin/oklch-color-picker" ]; then
      ln -sfn "${pkgs.oklch-color-picker}/bin/oklch-color-picker" "$PICKER_DIR/oklch-color-picker"
      # Sin newline: el plugin compara app_version byte a byte (usa printf %s).
      printf '%s' "${pkgs.oklch-color-picker.version}" > "$PICKER_DIR/app_version"
      echo "  oklch: binario de nixpkgs enlazado (v${pkgs.oklch-color-picker.version})"
    else
      echo "  oklch: paquete no disponible en nixpkgs, se deja el autodescargado" >&2
    fi
  '';

  # ── GeForce NOW (flatpak) ─────────────────────────────────
  home.activation.geforceNow = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if ! flatpak info com.nvidia.geforcenow &>/dev/null 2>&1; then
      flatpak remote-add --user --if-not-exists GeForceNOW \
        https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo 2>/dev/null || true
      flatpak install -y --user GeForceNOW com.nvidia.geforcenow 2>/dev/null || true
    fi
  '';

  # ── Bottles (flatpak) ─────────────────────────────────────
  home.activation.bottles = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if ! flatpak info com.usebottles.bottles &>/dev/null 2>&1; then
      flatpak install -y --user flathub com.usebottles.bottles 2>/dev/null || true
    fi
  '';

  # ── Podman Desktop (flatpak) ──────────────────────────────
  home.activation.podmanDesktop = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if ! flatpak info io.podman_desktop.PodmanDesktop &>/dev/null 2>&1; then
      flatpak install -y --user flathub io.podman_desktop.PodmanDesktop 2>/dev/null || true
    fi
  '';

  # ── Minecraft Bedrock (mcpelauncher flatpak) ──────────────
  # Nota: el login con cuenta Microsoft puede dar error "drowned"/"13089"
  # (bug upstream mcpelauncher), NO es problema de la config/flatpak.
  home.activation.mcpelauncher = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if ! flatpak info io.mrarm.mcpelauncher &>/dev/null 2>&1; then
      flatpak install -y --user flathub io.mrarm.mcpelauncher 2>/dev/null || true
    fi
  '';

  # ── JDownloader2 (flatpak) ─────────────────────────────────
  # No existe en nixpkgs (issue NixOS/nixpkgs#388061 closed not_planned).
  # Restaurar config: copiar el .jd2backup a la carpeta de datos del flatpak
  # (ver sección "Post-Install" del README).
  home.activation.jdownloader = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if ! flatpak info org.jdownloader.JDownloader &>/dev/null 2>&1; then
      flatpak install -y --user flathub org.jdownloader.JDownloader 2>/dev/null || true
    fi
  '';

  # ── Open WebUI ────────────────────────────────────────────
  home.packages = with pkgs; [
    # open-webui
    xdg-terminal-exec
    oklch-color-picker
  ];

  # ── Cinnamon dconf ────────────────────────────────────────
  home.activation.cinnamonDconf = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if command -v cinnamon &>/dev/null && [ -f "$HOME/dotfiles-dizzi/cinnamon/.config/cinnamon/settings.dconf" ]; then
      # El switch reinicia dbus-broker y la carga puede chocar con eso: reintentar y avisar fuerte.
      DCONF_FILE="$HOME/dotfiles-dizzi/cinnamon/.config/cinnamon/settings.dconf"
      dconf load /org/cinnamon/ < "$DCONF_FILE" 2>/dev/null \
        || { sleep 2; dconf load /org/cinnamon/ < "$DCONF_FILE" 2>/dev/null \
             || echo "⚠️  cinnamonDconf FALLO (¿sin session bus?). Recarga manual:" \
                "dconf load /org/cinnamon/ < $DCONF_FILE"; }
    fi
  '';

  # ── ZSH: override HM .zshrc with repo symlink + OMZ Nix store links ─
  home.activation.zshSetup = config.lib.dag.entryAfter [ "linkGeneration" ] ''
        # ~/.oh-my-zsh debe ser un directorio real (no symlink de HM): si una GC
        # borro el target de una generacion vieja queda colgante y los ln fallan.
        if [ -L "$HOME/.oh-my-zsh" ] && [ ! -e "$HOME/.oh-my-zsh" ]; then
          rm -f "$HOME/.oh-my-zsh"
        fi
        mkdir -p "$HOME/.oh-my-zsh"
        # Link OMZ Nix store components so $ZSH="$HOME/.oh-my-zsh" finds everything
        ZSH_STORE="${pkgs.oh-my-zsh}/share/oh-my-zsh"
        for dir in lib plugins templates themes; do
          ln -sfn "$ZSH_STORE/$dir" "$HOME/.oh-my-zsh/$dir"
        done
        ln -sfn "$ZSH_STORE/oh-my-zsh.sh" "$HOME/.oh-my-zsh/oh-my-zsh.sh"
        ln -sfn "$ZSH_STORE/tools" "$HOME/.oh-my-zsh/tools" 2>/dev/null || true

        # Fix Ctrl+Backspace: OMZ's bindkey -e resets ^H to backward-delete-char
        # Re-apply via $ZSH_CUSTOM/*.zsh (OMZ sources these after plugins)
        mkdir -p "$HOME/.oh-my-zsh/custom"
        f="$HOME/.oh-my-zsh/custom/ctrl-backspace.zsh"
        if [ ! -f "$f" ] || ! grep -q 'backward-kill-word' "$f" 2>/dev/null; then
          cat > "$f" << 'EOF'
    bindkey -M emacs '^H' backward-kill-word
    EOF
        fi

        # Writable plugin dirs (NOT Nix store symlinks) so OMZ .plugin.zsh stubs can be created
        setup_plugin() {
          local name="$1" pkg="$2"
          local dir="$HOME/.oh-my-zsh/custom/plugins/$name"
          rm -f "$dir" 2>/dev/null       # remove any previous store symlink
          mkdir -p "$dir"
          for item in "$pkg"/*; do
            ln -sfn "$item" "$dir/"
          done
          # OMZ expects .plugin.zsh; create stub if only .zsh exists
          if [ ! -f "$dir/$name.plugin.zsh" ] && [ -f "$dir/$name.zsh" ]; then
            ln -sfn "$name.zsh" "$dir/$name.plugin.zsh"
          fi
        }
        setup_plugin zsh-syntax-highlighting "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting"
        setup_plugin zsh-autosuggestions "${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions"
        setup_plugin zsh-completions "${pkgs.zsh-completions}/share/zsh/site-functions"
        # zsh-completions has no .zsh file; create minimal stub that adds its dir to fpath
        zc_stub="$HOME/.oh-my-zsh/custom/plugins/zsh-completions/zsh-completions.plugin.zsh"
        if [ ! -f "$zc_stub" ]; then
          printf 'fpath+=("%s" $fpath)\n' "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" > "$zc_stub"
        fi
        setup_plugin zsh-history-substring-search "${pkgs.zsh-history-substring-search}/share/zsh/plugins/zsh-history-substring-search"

        # Writable theme dir for p10k
        rm -f "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" 2>/dev/null
        mkdir -p "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
        for item in "${pkgs.zsh-powerlevel10k}/share/zsh/themes/powerlevel10k"/*; do
          ln -sfn "$item" "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/"
        done
  '';

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
