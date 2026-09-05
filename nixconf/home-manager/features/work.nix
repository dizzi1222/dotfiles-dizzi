{ config, pkgs, ... }:

{
  # ── Development Tools ──────────────────────────────────────
  home.packages = with pkgs; [
    # Editors
    code-cursor
    antigravity

    # Languages
    # python3 env con debugpy (para nvim-dap: `python3 -m debugpy.adapter`).
    # Usar withPackages fusiona pip/setuptools/etc + debugpy en el MISMO python
    # del PATH, así `python3 -m debugpy.adapter` funciona sin pip install manual.
    (python3.withPackages (ps: [
      ps.pip
      ps.setuptools
      ps.wheel
      ps.pillow
      ps.pygobject3
      ps.debugpy
      # Nix Only — runtime de sweep.nvim (proxy Python en :5555). Puro Nix,
      # NO mexclar con pip. En caché binaria (14 MiB), no compila:
      #   ps.llama-cpp-python  # bindings llama.cpp (NO el binario llama-cpp)
      #   ps.fastapi           # HTTP fallback del proxy
      #   ps.uvicorn           # servidor del proxy
      ps.llama-cpp-python
      ps.fastapi
      ps.uvicorn
    ]))
    pyenv
    nodejs
    pnpm #  pnpm add -D jest
    yarn
    go
    rustup
    gcc
    gdb
    gnumake
    cmake
    pkg-config
    gnucobol # binario cobc

    # Java / C# / PHP
    jdk
    dotnet-sdk
    # PHP con la extensión Xdebug (necesaria para depurar PHP via DAP:
    # `php -m | grep xdebug` debe listarla; sin ella el debug nunca conecta).
    (php.withExtensions ({ enabled, all }: enabled ++ (with all; [ xdebug ])))
    phpPackages.composer

    # Dev tools
    git
    lazygit
    docker-client
    docker-compose
    # docker-desktop — no disponible en nixpkgs actual; instalar via flatpak si se necesita
    kubectl
    helm
    terragrunt
    # vault — temporal: sin caché binaria y la red resetea la descarga de go-modules (proxy.golang.org); revertir cuando la red estable
    # vault
    tig
    gh
    glow

    # Utilidades de desarrollo adicionales
    uv
    postman
    llama-cpp

    # AI tools & Agents
    ollama
    opencommit
    aichat
    # gemini-cli # Deshabilitado: Reemplazado por antigravity-cli (agy). Usar alias `gemini` -> `agy`
    antigravity-cli
    claude-code
    opencode
    qwen-code
    (mistral-vibe.overrideAttrs (old: { doCheck = false; }))
    # openclaw # Omitido: requiere construir monorepo gigante de 1390 paquetes pnpm; ejecutar via npx openclaw si se necesita
    codex
    # kilo # Omitido: monorepo gigante que agota espacio en build; ejecutar via npx kilo si se necesita
    pi-coding-agent
    ctx7
    openspec
    cursor-cli
    python3Packages.huggingface-hub # huggingface-cli

    # Agentes no empaquetados en nixpkgs oficial (se pueden ejecutar via npx/npm/pip):
    # openclaude, qoder, cactus-needle, keelcode, kimchi, mimocode, engram, codegraph,
    # minimax-cli, oh-my-pi, gentle-ai, gga, hermes-agent, kimi-code, command-code,
    # freebuff, supercode, cline, ampcode, droid-factory, cactus, walkie

    # DB tools
    pgadmin4
    # mongodb [compila 2h 󰚌 ] (motor) NO se instala: el daemon corre via docker-compose
    # (~/workspace/mongodb, mongo:7). Estos clientes conectan por TCP.
    mongodb-compass # GUI oficial (browser de datos y JSON)
    mongosh # shell moderno (MongoDB 6+ no trae `mongo`)
    mongodb-tools # mongodump / mongorestore / mongoimport

    # QA / Testing automation (binarios nativos de Nix; los frameworks npm
    # como jests/react-testing-library se instalan por proyecto con npm)
    playwright-driver.browsers
    cypress
    chromedriver
    geckodriver
    chromium
    # L-11: JEST: # No se añade jest aquí: se instala con pnpm/npm en el proyecto
    #  󱞩Referencia: /home/diego/dotfiles-dizzi/nixconf/home-manager/features/work.nix

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
    television # TUI fuzzy-finder (álgebra de consultas tipo tv)

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

    # ── Debug opcional: toolchains de DAP extras (nvim/nvim-dap/*.lua) ──────
    # Los adapters (rdbg, ocamlearlybird, local-lua-debugger, haskell-debug-adapter,
    # erlang-debugger) se COMPILAN desde fuente con `:MasonInstall <adapter>` SOLO
    # si la toolchain existe; sin ella, Mason reintenta/falla en cada arranque.
    # Son PESADAS → descomentar a demanda + correr el MasonInstall del adapter.
    # MAPEO:
    #   ruby/rdbg           | ruby   (rdbg vive en el stdlib `ruby/debug`)
    #   ocamlearlybird      | ocaml  (via `opam` y dune es de la toolchain)
    #   local-lua-debugger  | lua    (local-lua-debugger-vscode)
    #   haskell-debug-adapter | cabal-install
    #   erlang-debugger     | rebar3
    # ruby
    # ocaml
    # lua
    # cabal-install
    # rebar3
  ];

  # ── QA env: forzar binarios de Nix, no downloads de npm ────
  home.sessionVariables = {
    # Playwright: usar navegadores empaquetados por nixpkgs
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    # Cypress: usar el binario parchado de Nix
    CYPRESS_INSTALL_BINARY = "0";
    CYPRESS_RUN_BINARY = "${pkgs.cypress}/bin/Cypress";
  };

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

    # ── DB tools ─────────────────────────
    mongoup = "cd ~/workspace/mongodb && docker compose up -d";
    mongodown = "cd ~/workspace/mongodb && docker compose down";
    mongosh = "docker exec -it mongodb mongosh";
    pgadmin = "pgadmin4";

    # ── AI Tools ─────────────────────────
    gemini = "agy --dangerously-skip-permissions";
    agy = "agy --dangerously-skip-permissions";
  };
}
