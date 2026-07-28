{ config, pkgs, ... }:

{
  # ── Steam ──────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # ── Gaming packages ────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Launchers
    steam
    lutris
    heroic

    # Wine
    wine
    winetricks
    wineWow64Packages.stable
    wineWow64Packages.unstable
    wine64Packages.stable

    # Performance
    gamemode
    mangohud
    gamescope

    # Cloud gaming / streaming
    moonlight-qt
    sunshine

    # Compatibility layers
    protonup-qt
    dxvk
    vkd3d-proton

    # Emulators
    dolphin-emu
    ryubing
    snes9x
    rpcs3
    cemu
    xemu
    mgba
    dosbox
    melonds

    # Minecraft
    prismlauncher
    modrinth-app-unwrapped

    # More Games
    pokemmo-installer

    # Misc gaming
    protontricks
  ];

  # ── Gamemode ───────────────────────────────────────────────
  programs.gamemode.enable = true;

}
