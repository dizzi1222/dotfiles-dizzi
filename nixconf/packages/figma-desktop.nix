{ lib, pkgs }:

# Figma Desktop (real Electron client) con servidor MCP local en 127.0.0.1:3845.
# Basado en el flake cmptr/figma-linux, con ajustes para nixpkgs actual:
#   - hash del instalador (FigmaSetup.exe) corregido
#   - parche argv no-fatal (Figma cambió el código minificado; el MCP no depende de él)
#   - nodejs_20 → nodejs_22 (node 20 EOL, removido de nixpkgs)
let
  correctedSource = {
    version = "126.6.9";
    url = "https://desktop.figma.com/win/FigmaSetup.exe";
    hash = "sha256-TRs7L8COi1XlcA9V4I70RxmsLkUmnkiHX9qHs/RqZ1A=";
    expectedElectronMajor = 39;
  };
  electron =
    if builtins.hasAttr "electron_39" pkgs
    then pkgs.electron_39
    else pkgs.electron;
in
  pkgs.callPackage ./figma-desktop/nix/package.nix {
    figmaSource = correctedSource;
    inherit electron;
    nodejs_20 = pkgs.nodejs_22;
  }