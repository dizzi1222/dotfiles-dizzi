{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "exfat" ];
  boot.extraModulePackages = [ ];

  # JMicron JMS561 enclosure (USB 152d:9561, "External Disk 3.0") has a broken
  # UAS implementation: it drops off the bus mid-write (DID_NO_CONNECT, offline,
  # reconnect loops). Force the plain usb-storage driver for it via quirk `u`.
  boot.kernelParams = [ "usb-storage.quirks=152d:9561:u" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/607a3ab5-9b2f-45d5-ab91-82701e590e28";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4EAA-7AC1";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/b397f244-be0d-40fc-92ac-f2e7ebcb5860"; } ];

  # Hibernation: resume from the swap partition. NixOS adds `resume=` to the
  # kernel cmdline and enables the resume initrd stage from boot.resumeDevice.
  boot.resumeDevice = "/dev/disk/by-uuid/b397f244-be0d-40fc-92ac-f2e7ebcb5860";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
