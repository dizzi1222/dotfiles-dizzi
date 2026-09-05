{
  description = "Diego's NixOS + Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
    };
    swww = {
      url = "github:LGFae/swww";
    };
  quickshell = {
    url = "github:outfoxxed/quickshell";
  };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, zen-browser, swww, quickshell, spicetify-nix, vicinae, niri-flake, ... }@inputs:
  let
    system = "x86_64-linux";

    # mongodb-compass: el package.nix de nixpkgs (rev 624af66, 1.49.10) llama
    # `wrapGAppsHook $out/bin/mongodb-compass` como comando directo al final del
    # buildCommand. wrapGAppsHook solo funciona como fixupOutputHook (corre en
    # fixupPhase, donde $output existe); llamado directo falla con
    # "wrapGAppsHookHasRunForOutput: bad array subscript". El wrapGAppsHook3 de
    # fixupPhase ya envuelve el binario igual, asi que la llamada es redundante.
    overlays = [
      (final: prev: {
        mongodb-compass = prev.mongodb-compass.overrideAttrs (old: {
          buildCommand = builtins.replaceStrings
            [ "wrapGAppsHook $out/bin/mongodb-compass" ]
            [ "# wrapGAppsHook direct call removed: runs via fixupPhase" ]
            old.buildCommand;
        });
        # wine-discord-ipc-bridge: el package.nix de nixpkgs compila el .exe
        # con mingw (i686-windows) → falla en Linux sin cross-toolchain.
        # Usamos el paquete local con los binarios precompilados del release
        # v0.0.3 + el script .sh (ver packages/wine-discord-ipc-bridge.nix).
        # Uso en Steam → Launch Options por juego:
        #   winediscordipcbridge-steam.sh %command%
        wine-discord-ipc-bridge = prev.callPackage ./packages/wine-discord-ipc-bridge.nix { };
      })
    ];

    pkgs = import nixpkgs {
      inherit system overlays;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-39.8.10"
          "openclaw-2026.6.33"
        ];
      };
    };
    stateVersion = "25.05";
    username = "diego";
    hostname = "thinkpad-x1e2";

    # Suwayomi actualizado a 2.3.x: nixpkgs trae 2.1.1867, que NO soporta el
    # formato nuevo de index.json de keiyoushi (Mihon 0.20.1+ con signing keys).
    suwayomiServerPkg = pkgs.suwayomi-server.overrideAttrs (old: {
      version = "2.3.2243";
      src = pkgs.fetchurl {
        url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v2.3.2243/Suwayomi-Server-v2.3.2243.jar";
        hash = "sha256-ghFBsy4XDUoC08vf7Vd+2PB70iOD/19BMuu1rkDpjdU=";
      };
    });

    # kew 4.1.8 crashea en NixOS (abort/core dump al abrir la TUI): bug
    # upstream en set_full_path() que usa buffer fijo KEW_PATH_MAX con snprintf
    # y glibc-fortify lo detecta (__snprintf_chk -> __chk_fail). Fix del PR
    # upstream #559: pasar el tamaño real `needed`. kew 4.2.7 ya lo incluye.
    kewPatchedPkg = pkgs.kew.overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        ./patches/kew-set-full-path-buffer.patch
        ./patches/kew-list-persists-playlist.patch
        ./patches/kew-window-title-prefix.patch
      ];
    });

    # Pear Desktop (fork de th-ch/youtube-music): renombrar el desktop entry
    # de "Pear Desktop" a "YouTube Music" (el nombre upstream original).
    pearDesktopPkg = pkgs.pear-desktop.overrideAttrs (old: {
      desktopItems = [
        (pkgs.makeDesktopItem {
          name = "com.github.th-ch.youtube-music";
          exec = "pear-desktop %u";
          icon = "pear-desktop";
          desktopName = "YouTube Music";
          startupWMClass = "com.github.th-ch.youtube-music";
          categories = [ "AudioVideo" ];
        })
      ];
    });

    # Vicinae parcheado: en la lista del store (vicinae y raycast) mostrar
    # "Install extension" cuando no esta instalada y "Uninstall" solo cuando
    # lo esta (bugs upstream: uninstall incondicional, sin boton install).
    vicinaePatchedPkg =
      (vicinae.packages.${system}.default or vicinae.packages.x86_64-linux.default)
      .overrideAttrs (old: {
        patches = (old.patches or [])
          ++ [
            ./patches/vicinae-store-list-actions.patch
            ./patches/raycast-store-list-actions.patch
          ];
      });
  in
  {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs stateVersion hostname username; };
      modules = [
        ./hosts/${hostname}/configuration.nix
        stylix.nixosModules.stylix
        inputs.niri-flake.nixosModules.niri
      ];
    };

    homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs stateVersion username;
        homeDirectory = "/home/${username}";
        spicePkgs = spicetify-nix.legacyPackages.${system};
        figureDesktopPkg = pkgs.callPackage ./packages/figma-desktop.nix { };
        vicinaePatchedPkg = vicinaePatchedPkg;
        suwayomiServerPkg = suwayomiServerPkg;
        pearDesktopPkg = pearDesktopPkg;
        kewPatchedPkg = kewPatchedPkg;
      };
      modules = [
        ./hosts/${hostname}/home-manager.nix
        stylix.homeModules.stylix
        vicinae.homeManagerModules.default
      ];
    };
  };
}
