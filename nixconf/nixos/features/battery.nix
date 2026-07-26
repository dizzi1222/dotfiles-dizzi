{ config, pkgs, ... }:

{
  # ── Battery Management ─────────────────────────────────────
  services.thermald.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
      USB_AUTOSUSPEND = 1;
      USB_EXCLUDE_BTUSB = 1;
    };
  };

  # ── Power profiles daemon ──────────────────────────────────
  services.power-profiles-daemon.enable = false;

  # ── Packages ───────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    powertop
    brightnessctl
    light
    acpi
  ];
}
