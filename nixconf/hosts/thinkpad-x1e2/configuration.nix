{ config, pkgs, lib, stateVersion, username, hostname, inputs, ... }:

{
  imports = [
    ../../nixos/base-configuration.nix
    ../../nixos/features/hyprland.nix
    ../../nixos/features/steam.nix
    ./features/nvidia.nix
    ./hardware-configuration.nix
  ];
}
