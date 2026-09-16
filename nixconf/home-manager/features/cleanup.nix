{ pkgs, ... }:

{
  # ── nixconf-cleanup: limpieza de disco de un solo comando (ghaerdi) ──
  home.packages = [
    (pkgs.writeShellScriptBin "nixconf-cleanup" ''
            #!/bin/bash

            # Colors
            RED='\033[0;31m'
            GREEN='\033[0;32m'
            YELLOW='\033[1;33m'
            BLUE='\033[0;34m'
            NC='\033[0m' # No Color

            echo -e "''${YELLOW}Starting System Cleanup...''${NC}"

            # Helper function to cleanup a directory
            cleanup_dir() {
              name=$1
              path=$2

              if [ -d "$path" ]; then
                # Get size - handled safely if directory is empty or permission denied
                size=$(du -sh "$path" 2>/dev/null | cut -f1)
                if [ -z "$size" ]; then size="0B"; fi

                echo -ne "Cleaning $name cache... found ''${RED}$size''${NC}"

                # Remove contents but keep directory
                find "$path" -mindepth 1 -delete 2>/dev/null

                echo -e " ''${GREEN}✓''${NC}"
              fi
            }

            # Browsers
            cleanup_dir "Brave Browser" "$HOME/.cache/BraveSoftware/Brave-Browser/Default/Cache"
            cleanup_dir "Brave Code" "$HOME/.cache/BraveSoftware/Brave-Browser/Default/Code Cache"
            cleanup_dir "Brave Service Worker" "$HOME/.cache/BraveSoftware/Brave-Browser/Default/Service Worker/CacheStorage"

            # Communication
            cleanup_dir "Slack" "$HOME/.config/Slack/Cache"
            cleanup_dir "Slack Service Worker" "$HOME/.config/Slack/Service Worker/CacheStorage"
            cleanup_dir "Telegram" "$HOME/.local/share/TelegramDesktop/tdata/user_data/cache"
            cleanup_dir "Telegram Media" "$HOME/.local/share/TelegramDesktop/tdata/user_data/media_cache"

            # Vesktop (Discord)
            cleanup_dir "Vesktop" "$HOME/.config/vesktop/sessionData/Cache"
            cleanup_dir "Vesktop Code" "$HOME/.config/vesktop/sessionData/Code Cache"
            cleanup_dir "Vesktop GPU" "$HOME/.config/vesktop/sessionData/GPUCache"

            # Development
            echo -e "\n''${YELLOW}Cleaning Development Tools...''${NC}"

            if command -v npm &> /dev/null; then
              echo -ne "Running npm cache clean..."
              npm cache clean --force &> /dev/null
              echo -e " ''${GREEN}✓''${NC}"
            fi

            if command -v pip &> /dev/null; then
              echo -ne "Running pip cache purge..."
              pip cache purge &> /dev/null
              echo -e " ''${GREEN}✓''${NC}"
            elif command -v pip3 &> /dev/null; then
              echo -ne "Running pip3 cache purge..."
              pip3 cache purge &> /dev/null
              echo -e " ''${GREEN}✓''${NC}"
            fi

            if command -v go &> /dev/null; then
              echo -ne "Running go clean..."
              go clean -cache -modcache &> /dev/null
              echo -e " ''${GREEN}✓''${NC}"
            fi

            if command -v bun &> /dev/null; then
              echo -ne "Running bun cache rm..."
              bun pm cache rm &> /dev/null
              echo -e " ''${GREEN}✓''${NC}"
            fi

            # System
            cleanup_dir "Thumbnails" "$HOME/.cache/thumbnails"
            cleanup_dir "Trash" "$HOME/.local/share/Trash"

            # Media
            cleanup_dir "YouTube Music" "$HOME/.config/YouTube Music/Cache"
            cleanup_dir "YouTube Music Code" "$HOME/.config/YouTube Music/Code Cache"

            # Flatpak
            flatpak uninstall --unused 

            # Steam (runtime/cache/no-juegos — los juegos NO se tocan)
            cleanup_dir "Steam compat tools" "$HOME/.local/share/Steam/compatibilitytools.d"
            cleanup_dir "Steam runtime.old" "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime.old"
            cleanup_dir "Steam htmlcache" "$HOME/.local/share/Steam/config/htmlcache"
            cleanup_dir "Steam package/depot" "$HOME/.local/share/Steam/package"

            # Bottles (solo temp/cache/templates — las bottles INTACTAS)
            cleanup_dir "Bottles temp" "$HOME/.var/app/com.usebottles.bottles/data/bottles/temp"
            cleanup_dir "Bottles templates" "$HOME/.var/app/com.usebottles.bottles/data/bottles/templates"
            cleanup_dir "Bottles data cache" "$HOME/.var/app/com.usebottles.bottles/cache"
            cleanup_dir "Bottles bottle cache" "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/gaming/cache"

            # Antigravity IDE (perfil mkOutOfStoreSymlink — caches VOLÁTILES:
            # el spike transitorio de ~11GB vive en Cache/Cache_Data + logs/exthost)
            cleanup_dir "Antigravity profile Cache" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/Cache"
            cleanup_dir "Antigravity profile CachedData" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/CachedData"
            cleanup_dir "Antigravity profile GPUCache" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/GPUCache"
            cleanup_dir "Antigravity profile Code Cache" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/Code Cache"
            cleanup_dir "Antigravity profile Service Worker" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/Service Worker"
            cleanup_dir "Antigravity profile VSIXs" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/CachedExtensionVSIXs"
            # segundo config-root posible según cómo se lance el binario
            cleanup_dir "Antigravity Cache" "$HOME/.config/Antigravity IDE/Cache"
            cleanup_dir "Antigravity CachedData" "$HOME/.config/Antigravity IDE/CachedData"
            cleanup_dir "Antigravity GPUCache" "$HOME/.config/Antigravity IDE/GPUCache"

            # Vicinae (índice retenido ~1.4GB borrado-abierto + store cache)
            cleanup_dir "Vicinae cache" "$HOME/.cache/vicinae"

# Wine (solo temp/cache — el prefix INTACTO)
      cleanup_dir "Wine windows temp" "$HOME/.wine/drive_c/windows/temp"
      cleanup_dir "Wine shadercache" "$HOME/.wine/shadercache"

      # Flatpak (runtimes no usados + caches por app)
      if command -v flatpak &> /dev/null; then
        echo -e "\n''${BLUE}Cleaning Flatpak...''${NC}"
        flatpak uninstall --unused -y &> /dev/null
        echo -e "''${GREEN}✓ Flatpak unused runtimes removed''${NC}"
        for appdir in "''$HOME"/.var/app/*/; do
          [ -d "''$appdir" ] || continue
          cleanup_dir "Flatpak ''${appdir##*/} root cache" "''$appdir"cache
          for cdir in "''$appdir"config/*/Cache* "''$appdir"config/*/*/Cache*; do
            cleanup_dir "Flatpak ''${appdir##*/} ''${cdir##*/}" "''$cdir"
          done
        done
      fi

      # Docker Cleanup
            if command -v docker &> /dev/null; then
              if docker info &> /dev/null; then
                echo -e "\n''${BLUE}Cleaning Docker...''${NC}"
                docker system prune -a --volumes -f
                echo -e "''${GREEN}✓ Docker pruned''${NC}"
              else
                echo -e "\n''${RED}Skipping Docker: Daemon not running''${NC}"
              fi
            fi

            # Home Manager Cleanup
            if command -v home-manager &> /dev/null; then
              echo -e "\n''${BLUE}Expiring Home Manager generations (older than 7 days)...''${NC}"
              home-manager expire-generations "-7 days"
              echo -e "''${GREEN}✓ Home Manager generations expired''${NC}"
            fi

            # Nix Cleanup
            if command -v nix-collect-garbage &> /dev/null; then
              echo -e "\n''${BLUE}Collecting Nix garbage (older than 7 days)...''${NC}"
              nix-collect-garbage --delete-older-than 7d
              echo -e "''${GREEN}✓ Nix garbage collected''${NC}"
            fi

            if command -v nix-store &> /dev/null; then
              echo -e "\n''${BLUE}Optimizing Nix store (deduplicating files)...''${NC}"
              nix-store --optimise
              echo -e "''${GREEN}✓ Nix store optimized''${NC}"
            fi

            echo -e "\n''${GREEN}Cleanup Complete!''${NC}"
    '')
  ];
}

