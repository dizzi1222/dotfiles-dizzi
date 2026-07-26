{ config, pkgs, ... }:

{
  # ── Waydroid (Android container) ──────────────────────────
  # Official NixOS module — handles binder, gbinder, systemd, firewall, LXC
  virtualisation.waydroid.enable = true;

  # waydroid_script — install libhoudini, Magisk, GApps, etc.
  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/waydroid-script.nix {})
  ];
}
