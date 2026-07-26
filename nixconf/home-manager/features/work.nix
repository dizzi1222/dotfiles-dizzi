{ config, pkgs, ... }:

{
  # ── Development Tools ──────────────────────────────────────
  home.packages = with pkgs; [
    # Editors
    vscodium

    # Languages
    python3
    python3Packages.pip
    pyenv
    nodejs
    yarn
    go
    rustup
    gcc
    gnumake
    cmake

    # Dev tools
    git
    lazygit
    docker
    docker-compose
    kubectl
    helm
    terragrunt
    vault
    tig
    gh
    glow

    # Nix
    nil
    nixfmt
    nixpkgs-fmt
    nix-output-monitor

    # Terminals
    ghostty

    # Multiplexers
    zellij
    tmux

    # File managers
    yazi
    ranger

    # Search
    ripgrep
    fd
    fzf
    silver-searcher-ng

    # JSON/YAML
    jq
    yq
    fx

    # System utils
    dust
    tokei
    hyperfine
    procs
    sd
    hexyl
    doge
    doggo
    gping
    tree
    file
    unzip
    p7zip

    # Wine
    wine
    winetricks

    # Cloud
    google-cloud-sdk

    # Misc
    nh
  ];

  # ── Terminal Configs ───────────────────────────────────────
  # Ghostty — symlinked from dotfiles-dizzi
  # Kitty — symlinked from dotfiles-dizzi
  # Zellij — symlinked from dotfiles-dizzi
  # Neovim — symlinked from dotfiles-dizzi
  # Fastfetch — symlinked from dotfiles-dizzi

  # ── Nix Helper Scripts ─────────────────────────────────────
  home.shellAliases = {
    ns = "nix search nixpkgs";
    nixup = "nix flake update --flake ~/dotfiles-dizzi/nixconf";
    nixrb = "sudo nixos-rebuild switch --flake ~/dotfiles-dizzi/nixconf#thinkpad-x1e2";
    nixgc = "sudo nix-collect-garbage -d";
    nixos = "nix-shell -p";
  };
}
