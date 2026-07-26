{ config, pkgs, ... }:

{
  # ── Fish Shell ─────────────────────────────────────────────
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting ""
    '';
    shellAliases = {
      ll = "eza -la --icons";
      ls = "eza --icons";
      cat = "bat --style=plain";
      grep = "rg";
      find = "fd";
      top = "btm";
      vim = "nvim";
      vi = "nvim";
      rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles-dizzi/nixconf#thinkpad-x1e2";
      hm = "home-manager switch --flake ~/dotfiles-dizzi/nixconf#diego@thinkpad-x1e2";
      cd = "z";
    };
    plugins = [
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
          sha256 = "TEaIR1NbadNk1ParPDR72rfHRvtWk/CpklfyJU2OdjU=";
        };
      }
      {
        name = "fzf";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "6a6136998879dcc1f29a405dfdd6b92c5f229c39";
          sha256 = "0fbir8vmkkjsdcsvpfrn3m2agz25q9bc6g9fr0ly5h66qnfi8pxa";
        };
      }
    ];
  };

  # ── Zsh ──────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    # oh-my-zsh
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "history" "dirhistory" "sudo" ];
      theme = "robbyrussell";
    };
    # Plugins extra
    plugins = [
      {
        name = "zsh-autocomplete";
        src = pkgs.fetchFromGitHub {
          owner = "marlonrichert";
          repo = "zsh-autocomplete";
          rev = "20f6c34f20270084b21211428afb6d2534aae8e9";
          sha256 = "06mdclciidl1wh982zj2fac5r0s4hhhmb2yqv031k8px1wx1dj1k";
        };
      }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "24105b15714bfec37989ed5c5b6e60f572253019";
          sha256 = "1qyaw00k1jlic17phr4wm68jvnwcyjsbvhawqxamk67v8fxx4532";
        };
      }
    ];
    initContent = ''
      # pnpm
      export PNPM_HOME="/home/diego/.local/share/pnpm"
      case ":$PATH:" in
        *":$PNPM_HOME/bin:"*) ;;
        *) export PATH="$PNPM_HOME/bin:$PATH" ;;
      esac

      # NVM
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # Pyenv
      export PYENV_ROOT="$HOME/.pyenv"
      command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
      eval "$(pyenv init -)"

      # Cargo
      export PATH="$HOME/.cargo/bin:$PATH"

      # Spicetify
      export PATH="$PATH:$HOME/.local/share/spicetify"

      # Google Cloud SDK
      if [ -f '/tmp/google-cloud-sdk/path.zsh.inc' ]; then . '/tmp/google-cloud-sdk/path.zsh.inc'; fi
      if [ -f '/tmp/google-cloud-sdk/completion.zsh.inc' ]; then . '/tmp/google-cloud-sdk/completion.zsh.inc'; fi
      export PATH="$HOME/Descargas/google-cloud-sdk/bin:$PATH"

      # Editor
      export EDITOR="nvim"
      export VISUAL="nvim"
      export GIT_EDITOR="nvim"

      # Locale
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8
      export LANGUAGE=en_US.UTF-8

      # ydotool
      export YDOTOOL_SOCKET=/tmp/.ydotool_socket

      # Flatpak exports
      export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:/home/$USER/.local/share/flatpak/exports/share"

      # API keys
      if [[ ! -x ~/.api-keys.sh ]]; then
          chmod +x ~/.api-keys.sh 2>/dev/null || true
      fi
      if [ -f ~/.api-keys.sh ]; then
          source ~/.api-keys.sh
      fi

      # Ghostty integration
      if [ -n "''${GHOSTTY_RESOURCES_DIR}" ]; then
          source "''${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
      fi

      # Pywal colors
      if [ -f ~/.cache/wal/colors.sh ]; then
          . ~/.cache/wal/colors.sh
      fi
    '';
    shellAliases = {
      ll = "exa -lha --icons --git --color=always";
      la = "exa -a --icons --color=always";
      lt = "exa -T --icons --color=always";
      ls = "exa --icons --color=always";
      cat = "bat --style=plain";
      grep = "rg";
      find = "fd";
      top = "btm";
      vim = "nvim";
      vi = "nvim";
      code = "code --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto";
      rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles-dizzi/nixconf#thinkpad-x1e2";
      hm = "home-manager switch --flake ~/dotfiles-dizzi/nixconf#diego@thinkpad-x1e2";
      gits = "git status -sb";
      gitlog = "git log --oneline --graph --decorate --all";
      gitundo = "git reset --soft HEAD~1";
      modellist = "ollama list";
      EspacioTotal = "dust /*";
    };
  };

  # ── Starship Prompt ────────────────────────────────────────
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
      directory.truncation_length = 3;
      git_branch.symbol = " ";
      nodejs.symbol = " ";
      python.symbol = " ";
      rust.symbol = " ";
      golang.symbol = " ";
      docker_context.symbol = " ";
    };
  };

  # ── Zoxide ─────────────────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # ── FZF ────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  # ── Eza (ls replacement) ───────────────────────────────────
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    icons = "auto";
    git = true;
  };

  # ── Bat (cat replacement) ──────────────────────────────────
  programs.bat = {
    enable = true;
  };

  # ── Bottom (top replacement) ───────────────────────────────
  programs.bottom = {
    enable = true;
  };

  # ── Lazygit ────────────────────────────────────────────────
  programs.lazygit = {
    enable = true;
  };

  # ── Git ────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      credential.helper = "!gh auth git-credential";
    };
  };

  # ── Dev tools (system packages) ────────────────────────────
  home.packages = with pkgs; [
    jq
    yq
    fd
    ripgrep
    tree
    file
    unzip
    p7zip
    xclip
    xsel
    curl
    wget
    httpie
    fastfetch
    oh-my-posh
    tig
    dust
    xdg-utils
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
  ];
}
