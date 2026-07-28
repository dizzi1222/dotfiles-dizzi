{ config, pkgs, ... }:

let
  rcloneMount = { remote, target }: {
    Unit = {
      Description = "Rclone mount ${remote} → ${target}";
      After = [ "network-online.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 10;
      ExecStart = "${pkgs.writeShellScript "mount-${target}.sh" ''
        set -euo pipefail
        TARGET="$HOME/${target}"
        # Espera red tras el resume de sleep/hibernate (hasta ~90s)
        i=0
        while [ $i -lt 45 ]; do
          if ${pkgs.iputils}/bin/ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
            break
          fi
          ${pkgs.coreutils}/bin/sleep 2
          i=$((i+1))
        done
        ${pkgs.util-linux}/bin/mountpoint -q "$TARGET" && exit 0
        ${pkgs.coreutils}/bin/mkdir -p "$TARGET"
        exec ${pkgs.rclone}/bin/rclone mount ${remote}:/ "$TARGET" --vfs-cache-mode full
      ''}";
    };
  };
in
{
  # ── Background Services ────────────────────────────────────

  # ── Dunst ──────────────────────────────────────────────────
  # Config symlinked from dotfiles-dizzi/dunst/.config/dunst

  # ── EasyEffects ────────────────────────────────────────────
  # Config symlinked from dotfiles-dizzi/easyeffects/.config/EasyEffects

  # ── Espanso (Text Expander) ────────────────────────────────
  # Config managed via symlink from dotfiles-dizzi/espanso/.config/espanso
  # Service managed by the NixOS `services.espanso` module (base-configuration.nix),
  # which provides the cap_dac_override wrapper that fixes the EVDEV Wayland issue.

  # ── Flameshot ──────────────────────────────────────────────
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        savePath = "$HOME/Pictures/Screenshots";
        uiColor = "#a6d189";
        showStartupLaunchMessage = false;
      };
    };
  };

  # El daemon Qt-Wayland de flameshot crashea bajo Muffin (Cinnamon Wayland)
  # → autoarranque solo en Hyprland.
  systemd.user.services.flameshot.Unit.ConditionEnvironment =
    "XDG_CURRENT_DESKTOP=Hyprland";

  # ── Rclone mounts (sistema) ───────────────────────────────
  # Re-montan ~/mi_gdrive, ~/mi_gdmusica y ~/mi_gdlibros sin depender del hook
  # post-sleep de systemd-sleep (que muere con KillMode=control-group). Los
  # scripts manuales montar_g*.sh quedan como fallback.
  systemd.user.services."rclone-mount-gdrive" = rcloneMount {
    remote = "gdrive";
    target = "mi_gdrive";
  };
  systemd.user.services."rclone-mount-gd-musica" = rcloneMount {
    remote = "gd-musica";
    target = "mi_gdmusica";
  };
  systemd.user.services."rclone-mount-gd-libros" = rcloneMount {
    remote = "gd-libros";
    target = "mi_gdlibros";
  };

  # ── Services packages ──────────────────────────────────────
  home.packages = with pkgs; [
    # Clipboard
    wl-clipboard
    cliphist

    # File manager
    thunar
    thunar-volman
    thunar-archive-plugin

    # Image viewer
    imv

    # PDF viewer
    zathura

    # Screenshot tools
    flameshot
    satty
    grim
    slurp
    swappy

    # Color picker
    hyprpicker
    wl-color-picker
    gpick

    # Screen recording
    wf-recorder

    # Notification tools
    libnotify
    dunst

    # System tray
    networkmanagerapplet
    blueman

    # Misc
    espanso-wayland
    ydotool
    wtype
    wlr-randr
    nwg-look
    lxappearance

    # Rclone (cloud storage)
    rclone

    # Qt theming
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum

    # Pywal
    pywal16
  ];

}
