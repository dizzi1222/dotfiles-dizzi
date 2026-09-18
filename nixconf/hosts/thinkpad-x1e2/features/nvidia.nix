{ config, pkgs, lib, ... }:

{
  # ── NVIDIA Hybrid Graphics (ThinkPad X1E2 — GTX 1650) ─────
  # ¡OJO! En nixpkgs actual el módulo hardware.nvidia está GATEADO por
  # `services.xserver.videoDrivers` (hardware.nvidia.enabled es readOnly y
  # se calcula de `elem "nvidia" videoDrivers`). Sin esto el driver NUNCA se
  # aplica (corría nouveau/NVK de facto). Se setea aunque no haya X: solo
  # activa el módulo hardware.nvidia (kernel modules, blacklist nouveau,
  # nvidia-smi), no levanta el X server.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    # powerManagement.enable=true → la dGPU entra en runtime PM y se apaga sola
    # antes del shutdown (evita el cuelgue de device_shutdown con la dGPU
    # encendida, síntoma del freeze con frame congelado). Antes estaba en
    # false y además corría nouveau (no se aplicaba el driver propietario).
    powerManagement.enable = true;
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
  # GDK_BACKEND global NO se setea: rompe el screencast portal en niri
  # (https://github.com/niri-wm/niri/wiki/Important-Software#portals).
  # Si alguna app X11 lo necesita, setear solo para esa app.
  environment.sessionVariables = {
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
