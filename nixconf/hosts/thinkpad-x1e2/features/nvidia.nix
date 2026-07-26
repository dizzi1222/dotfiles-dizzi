{ config, pkgs, lib, ... }:

{
  # ── NVIDIA Hybrid Graphics (ThinkPad X1E2 — GTX 1650) ─────
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      sync.enable = false;
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ── NVIDIA environment ─────────────────────────────────────
  environment.sessionVariables = {
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };

  # ── Packages for NVIDIA ────────────────────────────────────
  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
    vdpauinfo
    libva
    libva-utils
    mesa-demos
    vulkan-tools
  ];
}
