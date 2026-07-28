{ config, pkgs, lib, inputs, stateVersion, username, hostname, ... }:

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
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "video"
      "input"
      "audio"
      "kvm"
      "uinput"
      "plugdev"
    ];
  };

  # sudo NOPASSWD para usuario en grupo wheel
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # ── Nix Settings ───────────────────────────────────────────
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-39.8.10"
      "openclaw-2026.6.33"
    ];
  };
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # ── Overlays ───────────────────────────────────────────────
  # Niri overlay commented: build broken (libdisplay-info-sys v0.3.0 incompatible with libdisplay-info 0.4.0)
  # nixpkgs.overlays = [
  #   (final: prev: {
  #     niri = prev.niri.overrideAttrs (old: {
  #       preConfigure = (old.preConfigure or "") + ''
  #         for f in $(find "$NIX_BUILD_TOP" -path '*/libdisplay-info-sys*/build.rs' 2>/dev/null); do
  #           sed -i 's/checking libdisplay-info version/echo "check bypassed"/' "$f" 2>/dev/null || true
  #         done
  #       '';
  #     });
  #   })
  # ];

  # ── Desktop Environments ───────────────────────────────────
  services.xserver.desktopManager.cinnamon.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ── Niri (Wayland compositor) ──────────────────────────────
  # programs.niri.enable = true;  # Comentado: build broken (libdisplay-info-sys v0.3.0 vs libdisplay-info 0.4.0)
  programs.niri.enable = true;
  # niri-stable del flake sigue hardcodeado a v25.08 (sin soporte `include`);
  # usamos niri-unstable (rama main de niri, includes desde v25.11).
  programs.niri.package = inputs.niri-flake.packages.${pkgs.system}.niri-unstable;

  # ── Networking ─────────────────────────────────────────────
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };

  # Waydroid / iptables support
  boot.kernelModules = [ "ip_tables" "ip6_tables" "nf_nat" "nf_conntrack" "xt_MASQUERADE" ];

  # ── Boot (GRUB + Secure Boot + Minegrub Minecraft theme) ──
  boot.loader =
    let
      minegrub = pkgs.callPackage ./pkgs/minegrub-theme.nix { };
    in
    {
      efi.canTouchEfiVariables = true;
      timeout = 5;
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = true;
        configurationLimit = 3;
        theme = "${minegrub}/share/grub/themes/minegrub";
        # Remember the last selected entry (like GRUB_SAVEDEFAULT in CachyOS):
        # `saved_entry` is saved on boot and reused as default on the next one,
        # so booting Windows once makes GRUB keep booting Windows until changed.
        default = "saved";

        # Fix "grubenv not found" + entry not remembered: this GRUB is a
        # standalone image (Secure Boot), so at runtime `$prefix` = (memdisk)
        # and NixOS's generated `load_env`/`save_env` ($prefix/grubenv) point
        # to the read-only memdisk. Reload the REAL ESP grubenv explicitly and
        # redefine `savedefault` to write there too.
        # CRITICO: en GRUB 2.12 el archivo de envblock se pasa con `-f FILE`
        # (como en loadenv.c: `save_env -f FILE var`), NO como arg posicional.
        # `save_env path var` interpretaria `path` como nombre de variable y
        # escribiria al default $prefix/grubenv (= memdisk read-only) -> error
        # "file boot/grub/grubenv not found" en cada boot.
        extraConfig = ''
          if [ -s ($drive1)/grub/grubenv ]; then
            load_env -f ($drive1)/grub/grubenv
          fi
          set default="''${saved_entry}"
          function savedefault {
              if [ -z "''${boot_once}" ]; then
                  saved_entry="''${chosen}"
                  save_env -f ($drive1)/grub/grubenv saved_entry
              fi
          }
        '';

        # ── Secure Boot (GRUB 2.12) ───────────────────────────────────────────
        # GRUB 2.06+ (boothole) blocks sideloading .mod when Secure Boot is active;
        # .mod are ELF so sbctl can never sign them. Fix = embed EVERY module into a
        # standalone EFI binary via `grub-mkstandalone --disable-shim-lock`, and sign
        # that single binary. Two CRITICAL gotchas for GRUB 2.12 (NixOS 26.11):
        #
        #  1) DO NOT `set prefix=($esp)/grub` before delegating to the real grub.cfg.
        #     That makes every `insmod` in the external config resolve to UNSIGNED
        #     .mod on disk -> GRUB 2.12 lockdown refuses -> falls to `grub>` prompt.
        #     Keep $prefix on (memdisk) so all modules load from the signed image.
        #  2) GRUB 2.12 verifies the KERNEL against the firmware db. The NixOS kernel
        #     (bzImage, PE format) MUST be signed too. initrd does NOT need signing.
        # Ref: wejn.org/2021/09 + https://wejn.org/2024/08/grub-2.12-broke-my-secureboot-again/,
        #   sbctl #91/#94, ArchWiki GRUB#Secure_Boot_support.
        extraInstallCommands = ''
                    echo
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "  GUÍA SECURE BOOT + Flatpak (README):"
                    echo "  https://github.com/dizzi1222/dotfiles-dizzi/blob/main/nixconf/README.md#installation-from-nixos-iso"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo

                    export PATH="$PATH:/run/current-system/sw/bin"

                    if ! command -v sbctl &>/dev/null || ! command -v grub-mkstandalone &>/dev/null; then
                      echo "WARNING: sbctl/grub-mkstandalone not found — Secure Boot NOT configured" >&2
                      exit 0
                    fi

                    ESP="${config.boot.loader.efi.efiSysMountPoint}"
                    OUT_DIR="$ESP/EFI/NixOS-boot"
                    FALLBACK_DIR="$ESP/EFI/BOOT"
                    mkdir -p "$OUT_DIR" "$FALLBACK_DIR"
                    OUT="$OUT_DIR/grubx64.efi"
                    FALLBACK="$FALLBACK_DIR/BOOTX64.EFI"

                    # Buscar la ESP por UUID (como hace el grub.cfg autogenerado de NixOS).
                    # `search --file` en GRUB 2.12 no auto-carga search_fs_file y deja $esp
                    # vacío -> "no such device: ... grub.cfg not found".
                    ESP_UUID=$("${pkgs.grub2}/bin/grub-probe" -t=fs_uuid "$ESP" 2>/dev/null \
                      || blkid -s UUID -o value "$(findmnt -no SOURCE "$ESP")" 2>/dev/null \
                      || true)

                    echo "=== Building standalone GRUB (all modules embedded) ==="
                    # Bare delegate config — NO prefix override. Modules resolve from (memdisk).
                    # El archivo se escribe en runtime (heredoc bash) para poder interpolar
                    # $ESP_UUID (detectado en el arranque del script) sin que Nix toque "$esp" de GRUB.
                    # CRITICO: --modules= DEBE incluir search_fs_uuid. Sin el modulo embebido,
                    # GRUB 2.12 responde "syntax error"/"Incorrect command" a la linea search --fs-uuid,
                    # deja $esp vacio y cae a ()/grub/grub.cfg (crash que teniamos).
                    STANDALONE_CFG=$(mktemp)
                    cat > "$STANDALONE_CFG" <<GRUBCFG
          search --no-floppy --fs-uuid --set=esp $ESP_UUID
          if [ -n "\$esp" ] && [ -f (\$esp)/grub/grub.cfg ]; then
            configfile (\$esp)/grub/grub.cfg
          else
            echo "Error: no se encontro (\$esp)/grub/grub.cfg o no se identifico la ESP."
            echo "UUID ESP: $ESP_UUID"
            sleep 10
          fi
          GRUBCFG

                    grub-mkstandalone -O x86_64-efi \
                      -o "$OUT" \
                      --disable-shim-lock \
                      --modules="part_gpt part_msdos fat ext2 search search_fs_uuid search_fs_file configfile normal all_video gfxterm font png jpeg echo sleep" \
                      "boot/grub/grub.cfg=$STANDALONE_CFG" \
                      || { echo "✗ grub-mkstandalone FAILED" >&2; exit 1; }

                    rm -f "$STANDALONE_CFG"

                    rm -f "$STANDALONE_CFG"

                    echo "=== Patching GRUB lockdown (wejn fix: SecureBoot -> SecureB00t) ==="
                    # GRUB 2.12: verifica Secure Boot leyendo la variable UEFI "SecureBoot".
                    # Con la DB firmada por Microsoft/el vendor, el bootloader queda en lockdown
                    # y muestra "verification requested but nobody cares" / "you need to load
                    # the kernel first". Renombrando la variable en el binario (SecureBoot ->
                    # SecureB00t) GRUB ya no la encuentra y NO entra en lockdown.
                    # Referencia: https://github.com/rhboot/shim/issues/250 (wejn).
                    # IMPORTANTE: el parche va ANTES que el cp + sbctl sign, porque sed cambia
                    # bytes del binario y altera los hashes que luego se firman.
                    if grep -q "SecureBoot" "$OUT"; then
                      sed -i 's/SecureBoot/SecureB00t/g' "$OUT"
                      grep -q "SecureB00t" "$OUT" && echo "  ✓ parche aplicado" || echo "  ✗ parche FALLO" >&2
                    else
                      echo "  ✓ ya parcheado (SecureBoot no presente)"
                    fi

                    cp -f "$OUT" "$FALLBACK"

                    echo "=== Signing GRUB + Linux kernels (GRUB 2.12) for Secure Boot ==="
                    for f in "$OUT" "$FALLBACK" "$ESP"/kernels/*-bzImage; do
                      [ -e "$f" ] || continue
                      sbctl sign -s "$f" >/dev/null 2>&1 && echo "  ✓ $f" || echo "  ✗ FAILED: $f" >&2
                    done

                    if sbctl verify 2>/dev/null | grep -E -q "✗ $OUT|✗ $FALLBACK"; then
                      echo "⚠️  GRUB NOT signed! Run 'sudo sbctl verify' before reboot." >&2
                    else
                      echo "✓ Standalone GRUB + kernels signed for Secure Boot."
                    fi
        '';
      };
    };

  # ── Display Manager (SDDM with Astronaut "Jake the Dog" theme) ──
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs; [
      kdePackages.qtmultimedia
      kdePackages.qtdeclarative
      kdePackages.qtvirtualkeyboard
    ];
    settings = {
      General = {
        InputMethod = "qtvirtualkeyboard";
      };
    };
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

    # Ollama (local LLM) — ollama-cuda fails to build; use standard package
    ollama = {
      enable = true;
      package = pkgs.ollama;
    };

    # Input Remapper
    input-remapper.enable = true;

    # Syncthing
    syncthing = {
      enable = true;
      user = username;
      openDefaultPorts = true;
    };

    # Espanso (text expander) — use the nixpkgs module so the cap_dac_override
    # wrapper is applied, fixing EVDEV on Wayland (without it the worker keeps
    # dropping /dev/input devices and silently stops expanding text).
    espanso = {
      enable = true;
      package = pkgs.espanso-wayland;
    };
  };

  # ── Espanso autostart fix ──────────────────────────────────
  # espanso-wayland panics with "NoCompositor" (exit 101) if started before
  # Hyprland is up, so it must NOT be started by systemd at boot. It is
  # launched via `exec-once = espanso daemon` in Hyprland (exec-autostart.conf),
  # guaranteeing the Wayland compositor exists first. The home-manager/NixOS
  # module's service (graphical-session.target) never activates on this
  # SDDM+Hyprland session, so it stays dormant.

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

  # ── systemd-sleep: no congelar user.slice al hibernar ──────
  # El cgroup freezer de systemd-sleep congela user.slice antes del hibernate.
  # Si hay UN proceso en D-state (I/O FUSE/loop USB colgado, ej. vicinae
  # escaneando un disco muerto) el freeze se cuelga 60s y falla con
  # "Failed to freeze unit 'user.slice': Connection timed out" → hibernate
  # muere → poweroff inesperado.
  # En systemd >= 256 el control de este freeze NO es FreezeUserspace=
  # (eliminado de sleep.conf: "Unknown key") sino la variable de entorno
  # SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false. systemd-sleep entonces salta
  # el congelamiento de la sesión con el cgroup freezer y el kernel congela
  # todo en el snapshot (systemd issue #37590/#33083).
  systemd.sleep.settings.Sleep = {
    SuspendState = "mem";
  };
  systemd.services.systemd-hibernate.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  systemd.services.systemd-hybrid-sleep.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

  # ── Flatpak ───────────────────────────────────────────────
  services.flatpak.enable = true;

  # kbuildsycoca/plasma busca 'applications.menu' literal (ningun paquete lo trae);
  # enlazamos al menu de plasma para silenciar el warning.
  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  # ── Packages (system-level) ────────────────────────────────
  environment.systemPackages = with pkgs; [
    sbctl
    grub2_efi
    (pkgs.sddm-astronaut.override { embeddedTheme = "jake_the_dog"; })
    kdePackages.qtmultimedia

    # Xephyr: servidor X anidado, lo pide el healthcheck de Cinnamon
    xorg-server

    # Apps X11 bajo Niri (lo busca en PATH al arrancar)
    xwayland-satellite

    # Core
    vim
    neovim
    wget
    curl
    git
    git-filter-repo
    unzip
    p7zip
    wget
    rsync
    stow
    lsof

    # System utilities
    htop
    btop
    bottom
    ncdu
    tree
    jq
    psmisc
    gum
    marksman
    socat
    file
    which
    gparted
    gnome-disk-utility
    udisks2
    xinput
    acpi
    inotify-tools
    linuxPackages.cpupower
    man-db
    gucharmap
    font-manager
    kdePackages.partitionmanager
    bleachbit

    # Audio
    pavucontrol
    easyeffects
    pamixer
    cava
    wireplumber
    pulseaudio
    alsa-utils
    alsa-tools

    # Bluetooth extras
    blueman
    bluez
    bluez-tools
    bluetuith
    networkmanagerapplet

    # Wayland / Hyprland helpers
    cliphist
    udiskie
    nwg-displays
    swaynotificationcenter
    polkit_gnome
    qt5.qtwayland
    qt6.qtwayland
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum
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
    exfatprogs
    fuse
    fuse3

    # Image
    imagemagick
    loupe

    # File transfer / MTP
    android-file-transfer
    gvfs
    simple-mtpfs

    # Clipboard history
    cliphist

    # Misc
    scrcpy
    ydotool
    wtype
    rclone
    gedit
    pokemon-colorscripts
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
    espanso-wayland

    # TheFuck replacement (pay-respects)
    pay-respects

    # Network Manager dmenu
    networkmanager_dmenu

    # Dev tools (system level)
    android-tools # adb
    cmake
    llvm
    clang
    patchelf
    tree-sitter
    gh
    glow
    postgresql
    nodejs
    pnpm
    marksman
    python3
    pyenv
    python3Packages.pygobject3
    python3Packages.setuptools
    python3Packages.pillow
    expect

    # System inspection
    pciutils
    usbutils
    lshw
    intel-gpu-tools
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers

    # Fonts
    font-awesome
    dejavu_fonts
    source-han-sans
    source-han-serif
    nerd-fonts.symbols-only
    nerd-fonts.hurmit
    iosevka
    mononoki
  ];

  # ── Nix LD (for dynamically linked binaries like tree-sitter) ─
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse3
      icu
      libsodium
      openssl
    ];
  };

  # ── Docker ─────────────────────────────────────────────────
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    storageDriver = "overlay2";
  };

  # Fish Shell (desactivado en system, gestionado por home-manager)
  # programs.fish.enable = true;

  # ── Google Gemini & Cloud API ──────────────────────────────
  environment.sessionVariables = {
    OPENCODE_GEMINI_PROJECT_ID = "cic-ptd-dev";
    GOOGLE_CLOUD_PROJECT = "cic-ptd-dev";
    XCURSOR_THEME = "Kafka";
    XCURSOR_SIZE = "24";
  };

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

  # ── Audio (Intel HDA ThinkPad) ────────────────────
  # WirePlumber + PipeWire handle audio. Hardware firmware
  # (sof-firmware/alsa-ucm-conf) excluded — broken build in this nixpkgs.

  # ── Bluetooth ──────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Experimental=true rompe la reconexion automatica de earbuds baratos
        # (AZ09): bluez 5.8x responde "br-connection-key-missing" aunque el
        # LinkKey este guardado en /var/lib/bluetooth. El AZ09 es BR/EDR puro
        # (Class=0x240404), no necesita LE Audio/BAP.
        Experimental = false;
        FastConnectable = true;
        JustWorksRepairing = "always";
      };
      Policy = {
        AutoEnable = true;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
      };
    };
  };
  services.blueman.enable = true;

  # ── Power Management ───────────────────────────────────────
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;
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

    # Keyboard backlight permission (ThinkPad X1E2)
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="tpacpi::kbd_backlight", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/tpacpi::kbd_backlight/brightness"
    # Generic LED access (Dell etc.)
    KERNEL=="leds", MODE="0666"

    # Input Remapper
    KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
    KERNEL=="event*", MODE="0660", GROUP="input"
    SUBSYSTEM=="misc", KERNEL=="uinput", MODE="0660", GROUP="input"

    # General input automation tools (ydotool, PyMacroRecord, etc.)
    KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
  '';

  # ── ThinkPad X1E2: Fn key mode (F-keys primary) ───────────
  systemd.services.thinkpad-fn-mode = {
    description = "Set ThinkPad Fn lock OFF (F1-F12 by default, media keys with Fn)";
    after = [ "sys-subsystem-platform-devices-thinkpad_acpi.device" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Use procfs interface (sysfs fn_lock not available on this model)
      echo "fnlock 0" > /proc/acpi/ibm/hotkey 2>/dev/null || true
      # Restore recommended hotkey mask (fnlock command may reset it)
      cat /sys/devices/platform/thinkpad_acpi/hotkey_recommended_mask 2>/dev/null | head -1 | xargs -I{} sh -c 'echo "{}" > /proc/acpi/ibm/hotkey' 2>/dev/null || true
    '';
  };

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
      # bibata-cursors (replaced by Kafka via dotfiles symlink)
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrains Mono Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };
    };
  };

  # CachyOS compatibility: scripts use hardcoded paths that don't exist on NixOS
  system.activationScripts.cachyos-compat = ''
    mkdir -p /bin /usr/bin
    ln -sf /run/current-system/sw/bin/bash /bin/bash
    ln -sf /run/current-system/sw/bin/swaync-client /usr/bin/swaync-client
    ln -sf /run/current-system/sw/bin/nvim /usr/bin/nvim
  '';
}
