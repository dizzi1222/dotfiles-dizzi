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
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, zen-browser, swww, quickshell, spicetify-nix, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    stateVersion = "25.05";
    username = "diego";
    hostname = "thinkpad-x1e2";
  in
  {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs stateVersion hostname username; };
      modules = [
        ./hosts/${hostname}/configuration.nix
        stylix.nixosModules.stylix
      ];
    };

    homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs stateVersion username;
        homeDirectory = "/home/${username}";
        spicePkgs = spicetify-nix.legacyPackages.${system};
      };
      modules = [
        ./hosts/${hostname}/home-manager.nix
        stylix.homeModules.stylix
      ];
    };
  };
}
