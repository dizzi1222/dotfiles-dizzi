{ lib, pkgs, inputs, ... }:

{
  # Módulo Home Manager oficial de ilysenko/codex-desktop-linux. Reempaqueta el
  # .deb firmado que OpenAI publica en persistent.oaistatic.com (NO convierte el
  # .app de macOS, que era el metodo viejo).
  #
  # El interruptor NO esta aca: se declara en features/work.nix, junto a `codex`,
  # para poder comentarlo y que la GUI no se instale. Ver:
  #   programs.codexDesktopLinux.enable = true;
  imports = [ inputs.codex-desktop.homeManagerModules.default ];

  # Que la GUI invoque el CLI de nixpkgs en vez del embebido en el paquete. Sin
  # esto coexisten dos versiones de codex peleandose por ~/.codex.
  # mkDefault => work.nix puede sobreescribirlo si algun dia hace falta.
  programs.codexDesktopLinux.cliPackage = lib.mkDefault pkgs.codex;
}