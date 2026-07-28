{ config, pkgs, ... }:

{
  # Fish Shell (desactivado: se usa symlink de home.nix a fish/.config/fish)
  # programs.fish = {
  #   enable = true;
  #   interactiveShellInit = ''
  #     set -g fish_greeting ""
  #     # Agregar ~/.local/bin al PATH
  #     set -gx PATH $PATH $HOME/.local/bin
  #   '';
  #   shellAliases = {
  #     ll = "eza -la --icons";
  #     ls = "eza --icons";
  #     cat = "bat --style=plain";
  #     grep = "rg";
  #     find = "fd";
  #     top = "btm";
  #     vim = "nvim";
  #     vi = "nvim";
  #     rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles-dizzi/nixconf#thinkpad-x1e2";
  #     hm = "home-manager switch --flake ~/dotfiles-dizzi/nixconf#diego@thinkpad-x1e2";
  #     cd = "z";
  #     geforceNow = "flatpak run com.nvidia.geforcenow";
  #   };
  #   plugins = [
  #     {
  #       name = "z";
  #       src = pkgs.fetchFromGitHub {
  #         owner = "jethrokuan";
  #         repo = "z";
  #         rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
  #         sha256 = "TEaIR1NbadNk1ParPDR72rfHRvtWk/CpklfyJU2OdjU=";
  #       };
  #     }
  #     {
  #       name = "fzf";
  #       src = pkgs.fetchFromGitHub {
  #         owner = "PatrickF1";
  #         repo = "fzf.fish";
  #         rev = "6a6136998879dcc1f29a405dfdd6b92c5f229c39";
  #         sha256 = "0fbir8vmkkjsdcsvpfrn3m2agz25q9bc6g9fr0ly5h66qnfi8pxa";
  #       };
  #     }
  #   ];
  # };

  # ── Zsh ────────────────────────────────────────────────────
  # HM manages OMZ + .zshenv; .zshrc is symlinked from repo (home.nix)
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # History options (also set in repo's .zshrc; HM ensures they're applied)
    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      share = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };

    oh-my-zsh = {
      enable = true;
      package = pkgs.oh-my-zsh;
      theme = "robbyrussell"; # fallback — p10k is the real theme
      plugins = [ "git" ];
    };

    shellAliases = {
      ll = "eza -la --icons";
      ls = "eza --icons";
      la = "eza -a --icons";
      lt = "eza -T --icons";
      lta = "eza -Ta --icons";
      cat = "bat --style=plain";
      grep = "rg";
      find = "fd";
      top = "btm";
      vim = "nvim";
      vi = "nvim";
      rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles-dizzi/nixconf#thinkpad-x1e2";
      hm = "home-manager switch --flake ~/dotfiles-dizzi/nixconf#diego@thinkpad-x1e2";
      nixrb = "sudo nixos-rebuild switch --flake ~/dotfiles-dizzi/nixconf#thinkpad-x1e2";
      cd = "z";
      geforceNow = "flatpak run com.nvidia.geforcenow";
    };

    # Env vars for .zshenv (ZSH_CUSTOM points to writable dir so OMZ finds plugins)
    envExtra = ''
      export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
      export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
      export QT_QPA_PLATFORMTHEME=gtk3
    '';

    # Lock dotDir behavior (silences future-default warning)
    dotDir = config.home.homeDirectory;

    # Source repo .zshrc after HM's generated content
    initContent = ''
      source "$HOME/dotfiles-dizzi/zsh/.zshrc"
    '';
  };

  # OMZ custom plugins/themes handled via activation (zshSetup in home.nix)

  # ── Starship Prompt ────────────────────────────────────────
  programs.starship = {
    enable = false; # disabled — p10k is the primary prompt
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
      # Allow git operations as root on user-owned repos
      "safe" = { directory = "/home/diego/dotfiles-dizzi"; };


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
    gitflow
    lazydocker
    rustc
  ];
}
