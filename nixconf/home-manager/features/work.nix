{ config, pkgs, ... }:

{
  # ── Development Tools ──────────────────────────────────────
  home.packages = with pkgs; [
    # Editors
    code-cursor

    # Languages
    python3
    python3Packages.pip
    python3Packages.setuptools
    python3Packages.wheel
    python3Packages.pillow
    python3Packages.pygobject3
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
    docker-client
    docker-compose
    # docker-desktop — no disponible en nixpkgs actual; instalar via flatpak si se necesita
    kubectl
    helm
    terragrunt
    vault
    tig
    gh
    glow

    # AI tools
    ollama
    opencommit
    aichat
    gemini-cli

    # DB tools
    pgadmin4

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

    # Wine (64-bit WoW64 — el `wine` default de nixpkgs es solo 32-bit
    # y tira "Bad EXE format" con instaladores PE32+ x86-64)
    wineWow64Packages.stable
    winetricks

    # Cloud
    google-cloud-sdk
    google-cloud-sql-proxy
    rclone

    # Misc
    nh
    # n8n comment: hash mismatch, rebuild later
    # n8n
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
