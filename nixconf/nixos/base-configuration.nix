{ config, pkgs, lib, stateVersion, username, hostname, ... }:

{
  system.stateVersion = stateVersion;

  # ── Locale & Time ──────────────────────────────────────────
  time.timeZone = "America/Santo_Domingo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_DO.UTF-8";
    LC_IDENTIFICATION = "es_DO.UTF-8";
    LC_MEASUREMENT = "es_DO.UTF-8";
    LC_MONETARY = "es_DO.UTF-8";
    LC_NAME = "es_DO.UTF-8";
    LC_NUMERIC = "es_DO.UTF-8";
    LC_PAPER = "es_DO.UTF-8";
    LC_TELEPHONE = "es_DO.UTF-8";
    LC_TIME = "es_DO.UTF-8";
  };

  # ── User ───────────────────────────────────────────────────
  users.users.${username} = {
    isNormalUser = true;
    description = "Diego";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager" "wheel" "docker" "video" "input" "audio"
      "kvm" "uinput" "plugdev"
    ];
  };

  # ── Nix Settings ───────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # ── Networking ─────────────────────────────────────────────
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };

  # ── Boot ───────────────────────────────────────────────────
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # ── Display Manager ────────────────────────────────────────
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # ── Services ───────────────────────────────────────────────
  services = {
    openssh.enable = true;
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    xserver.xkb = {
      layout = "us";
      variant = "";
    };
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        middleEmulation = true;
      };
    };
  };

  # ── Firewall ──────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 3000 8080 ];
    allowedUDPPorts = [ ];
    allowedTCPPortRanges = [ ];
    allowedUDPPortRanges = [ ];
  };

  # ── logind (laptop lid/suspend) ───────────────────────────
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "lock";
      HandleLidSwitchDocked = "ignore";
    };
  };

  # ── Flatpak ───────────────────────────────────────────────
  services.flatpak.enable = true;

  # ── Packages (system-level) ────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core
    vim
    wget
    curl
    git
    unzip
    p7zip
    wget
    rsync
    stow

    # System utilities
    htop
    btop
    bottom
    ncdu
    tree
    jq
    socat
    file
    which
    gparted
    acpi
    inotify-tools

    # Audio
    pavucontrol
    easyeffects
    pamixer

    # Bluetooth extras
    blueman
    networkmanagerapplet

    # Wayland / Hyprland helpers
    cliphist
    udiskie
    nwg-displays
    swaynotificationcenter
    polkit_gnome
    qt5.qtwayland
    qt6.qtwayland
    wl-clipboard
    wlr-randr
    grim
    slurp
    brightnessctl
    playerctl
    xdg-utils
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr

    # Codecs
    ffmpeg
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    ntfs3g
    exfat
    fuse
    fuse3

    # Image
    imagemagick
    loupe

    # Clipboard history
    cliphist

    # Misc
    scrcpy
    ydotool
    rclone
    gedit
    gnome-calculator
    gnome-system-monitor
    gnome-keyring

    # Qt/GTK theme managers
    kdePackages.qt6ct
    lxappearance
    nwg-look

    # Input remapping
    input-remapper

    # Text expanders
    espanso

    # Dev tools (system level)
    cmake
    llvm
    clang
    patchelf
    gh
    glow
    postgresql
    nodejs
    python3
    pyenv

    # System inspection
    pciutils
    usbutils
    lshw
    intel-gpu-tools
    vulkan-tools
    vulkan-loader

    # Fonts
    font-awesome
    dejavu_fonts
    source-han-sans
    source-han-serif
    nerd-fonts.symbols-only
    iosevka
    mononoki
  ];

  # ── Docker ─────────────────────────────────────────────────
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    storageDriver = "overlay2";
  };

  # ── Fish Shell ─────────────────────────────────────────────
  programs.fish.enable = true;

  # ── Git ────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  # ── Polkit ─────────────────────────────────────────────────
  security.polkit.enable = true;

  # ── Audio (PipeWire) ───────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ── Bluetooth ──────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;

  # ── Power Management ───────────────────────────────────────
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
      USB_AUTOSUSPEND = 0;
    };
  };

  # ── udev rules ────────────────────────────────────────────
  services.udev.extraRules = ''
    # 8BitDo Ultimate 2C Wireless (BT → xinput)
    ACTION=="add", ATTRS{idVendor}=="2dc8", ATTRS{idProduct}=="310a", RUN+="${pkgs.kmod}/bin/modprobe xpad", RUN+="/bin/sh -c 'echo 2dc8 310a > /sys/bus/usb/drivers/xpad/new_id'"
    ACTION=="add", ATTRS{idVendor}=="2dc8", ATTRS{idProduct}=="310a", MODE="0666"

    # DualSense (PS5) — full feature support
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", GROUP="input", TAG+="uaccess"

    # DualShock 4 (PS4) — full feature support
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0660", GROUP="input", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0660", GROUP="input", TAG+="uaccess"

    # DualShock 3 (PS3) via Bluetooth/USB
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0268", MODE="0660", GROUP="input", TAG+="uaccess"

    # Xbox controllers
    KERNEL=="hidraw*", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02ea", MODE="0660", GROUP="input", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="0b12", MODE="0660", GROUP="input", TAG+="uaccess"

    # Keyboard backlight permission
    KERNEL=="leds", MODE="0666"

    # Input Remapper
    KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
    KERNEL=="event*", MODE="0660", GROUP="input"
    SUBSYSTEM=="misc", KERNEL=="uinput", MODE="0660", GROUP="input"

    # General input automation tools (ydotool, PyMacroRecord, etc.)
    KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
  '';

  # ── GNOME Keyring (for SDDM auto-unlock) ──────────────────
  security.pam.services = {
    sddm.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
    Hyprland.enableGnomeKeyring = true;
  };

  # ── Fontconfig ─────────────────────────────────────────────
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      font-awesome
      dejavu_fonts
      source-han-sans
      source-han-serif
      iosevka
      mononoki
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrains Mono Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };
    };
  };
}
