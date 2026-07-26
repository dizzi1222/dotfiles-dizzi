{ config, pkgs, ... }:

{
  # ── Bluetooth ──────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    blueman
  ];
}
