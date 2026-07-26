{ config, pkgs, inputs, stateVersion, username, homeDirectory, spicePkgs, ... }:

{
  imports = [
    ../../home-manager/home.nix
    ../../home-manager/features/desktop.nix
    ../../home-manager/features/shell.nix
    ../../home-manager/features/wayland.nix
    ../../home-manager/features/services.nix
    ../../home-manager/features/stylix.nix
    ../../home-manager/features/work.nix
    inputs.spicetify-nix.homeManagerModules.default
    inputs.zen-browser.homeModules.default
  ];

  # Host-specific Home Manager overrides go here
}
