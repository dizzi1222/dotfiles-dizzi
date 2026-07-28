{ config, pkgs, lib, ... }:
{
  # ── Waydroid (Android container) ──────────────────────────
  # Official NixOS module — handles binder, gbinder, systemd, firewall, LXC
  virtualisation.waydroid.enable = true;

  # Use nftables instead of legacy iptables (kernel doesn't have ip_tables)
  virtualisation.waydroid.package = pkgs.waydroid.override { withNftables = true; };

  hardware.graphics.enable = true;

  networking.firewall.trustedInterfaces = [ "waydroid0" ];

  # waydroid_script — install libhoudini, Magisk, GApps, etc.
  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/waydroid-script.nix {})
  ];

  # ── GPU / display config ──────────────────────────────────
  # Override Waydroid's startup to pin the Intel iGPU (or SwiftShader fallback).
  # Without this, Waydroid may pick the wrong render node on hybrid GPU systems
  # (renderD numbers swap between boots), causing SurfaceFlinger to crash.
  systemd.services.waydroid-container = {
    serviceConfig.Delegate = true;
    preStart = ''
      PROP_FILE="/var/lib/waydroid/waydroid.prop"
      BASE_PROP="/var/lib/waydroid/waydroid_base.prop"
      touch "$PROP_FILE" "$BASE_PROP"

      for f in "$PROP_FILE" "$BASE_PROP"; do
        ${pkgs.gnused}/bin/sed -i "/^gralloc\\.gbm\\.device=/d" "$f"
        ${pkgs.gnused}/bin/sed -i "/^ro\\.hardware\\.gralloc=/d" "$f"
        ${pkgs.gnused}/bin/sed -i "/^ro\\.hardware\\.egl=/d" "$f"
        ${pkgs.gnused}/bin/sed -i "/^persist\\.waydroid\\.width=/d" "$f"
        ${pkgs.gnused}/bin/sed -i "/^persist\\.waydroid\\.height=/d" "$f"
        echo "ro.hardware.egl=swiftshader" >> "$f"
        echo "ro.hardware.gralloc=default" >> "$f"
        echo "persist.waydroid.width=1920" >> "$f"
        echo "persist.waydroid.height=1080" >> "$f"
      done
    '';
  };

  # ── Display config (pinned to SwiftShader) ─────────────────
  # With the MAINLINE vendor's hwcomposer, Intel UHD 630 crashes on boot.
  # Use SwiftShader (software rendering) as the default renderer.
  # HW acceleration can be debugged by changing egl=mesa + gralloc=gbm
  # and pointing to the correct render node.
  systemd.tmpfiles.rules = [
    "f /var/lib/waydroid/waydroid_base.prop 0644 root root -"
  ];
}
