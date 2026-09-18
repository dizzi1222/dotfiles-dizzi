{ config, pkgs, lib, ... }:

{
  # ── Remote / Dual-Boot setup (headless-friendly) ──────────
  # Propósito: tras un reinicio remoto, la PC arranca sola a NixOS,
  # autologinea, y Sunshine queda listo para Moonlight sin intervención.
  # Cada bloque es un toggle: comenta/descomenta para activar.

  # ── T1: Autologin SDDM ─────────────────────────────────────
  # Evita quedarse atrapado en el greeter tras un reboot remoto.
  services.displayManager.autoLogin = {
    enable = true;
    user = "diego";
  };
  # El WM real es niri (no Plasma, que es el default del módulo sddm con kwin).
  # Sin esto el autologin arrancaría una sesión kwin/plasma y Sunshine
  # quedaría en otro compositor. Se usa el mismo defaultSession manual.
  services.displayManager.defaultSession = "niri";

  # ── T2: Lid switch (mantener servidor activo) ──────────────
  # Ignora el interruptor físico de la tapa: la ThinkPad sigue encendida
  # aunque la cierres. Se funde con el settings.Login de base-configuration.
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkForce "ignore";
    HandleLidSwitchExternalPower = lib.mkForce "ignore";
    HandleLidSwitchDocked = lib.mkForce "ignore";
  };

  # ── T3: Ping-pong boot NixOS → Windows → NixOS ────────────
  # Servicio oneshot que, al apagar/reiniciar NixOS, fuerza próximo boot a
  # Windows vía `grub-reboot "<TITULO>"`. Se extrae el TÍTULO exacto de la
  # entrada os-prober de Windows (ej: "Windows Boot Manager (on /dev/nvme0n1p1)")
  # directamente del grub.cfg y se le pasa a grub-reboot, que acepta título.
  # Por qué TÍTULO y no ID/índice:
  #  - Índice: GRUB colapsa "NixOS - All configurations" en un SUBMENU (1
  #    entrada) → contar líneas `menuentry` da 4 cuando Windows es top-level 2;
  #    `default=4` no existe → boot cae a NixOS.
  #  - ID: en este build standalone Secure Boot, `$menuentry_id_option` NO se
  #    expande (queda literal en grub.cfg) → la entrada NO gana `--id` → GRUB no
  #    puede resolver `set default="osprober-efi-..."` → cae a entrada 0.
  # El TÍTULO se matchea por texto literal, inmune a submenús, rebuilds y al
  # bug del id. grub-reboot escribe next_entry → la extraConfig de GRUB lo usa
  # UNA vez (boot_once) y lo borra → próximo boot vuelve a NixOS.
  systemd.services.alternar-a-windows = {
    description = "Configurar GRUB para bootear Windows 11 en el próximo arranque";
    wantedBy = [ "halt.target" "reboot.target" ];
    before = [ "halt.target" "reboot.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "alternar-windows" ''
        set -euo pipefail
        cfg=/boot/grub/grub.cfg
        grep=${pkgs.gnugrep}/bin/grep
        # Título EXACTO del menuentry con --class windows (os-prober).
        # Ej: 'Windows Boot Manager (on /dev/nvme0n1p1)'
        win_title=$($grep -oP "menuentry '\K[^']*(?=' --class windows)" "$cfg" | $grep -m1 . || true)
        if [ -z "$win_title" ]; then
          echo "▶ Windows (os-prober) no encontrado; manteniendo boot default" >&2
          exit 0
        fi
        echo "▶ próximo boot → Windows (título: $win_title)"
        exec ${pkgs.grub2}/bin/grub-reboot "$win_title"
      ''}";
    };
  };

  # ── T4: Sunshine declarativo (captura Wayland vía DRM/KMS) ──
  # El módulo oficial de nixpkgs proporciona capSysAdmin (wrapper root)
  # para capturar en Wayland/Hyprland/niri, además de uinput/udev/Avahi.
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    autoStart = true;
  };
  # El paquete sunshine trae su propio autostart .desktop
  # (app-dev.lizardbyte.app.Sunshine.service). Con el módulo activo habría
  # doble instancia → lo deshabilitamos (envía su unit a /dev/null).
  systemd.user.services."app-dev.lizardbyte.app.Sunshine".enable = false;

  # ── Tailscale (red remota) ─────────────────────────────────
  # Parte del flujo "inmune a la distancia" (el objetivo de T1 lo cita).
  # Descomenta si quieres acceso remoto vía Tailnet.
  # services.tailscale.enable = true;

  # ── Shutdown: matar rclone/FUSE antes de desmontar ─────────
  # El hook systemd-sleep 90-rclone.sh solo corre al dormir/hibernar;
  # en poweroff/reboot systemd intenta unmount los mounts de Google Drive
  # (rclone con FUSE en D-state) y se cuelga permanente. Este servicio
  # (oneshot wantedBy halt/reboot, igual patrón que alternar-a-windows)
  # mata rclone + desmonta lazy ANTES de que systemd desmonte filesystems.
  # Cubre botón físico / poweroff / reboot normales (el `--force --force`
  # de power_management.sh salta servicios → ese caso lo cubre el script).
  systemd.services.shutdown-kill-rclone = {
    description = "Matar rclone y desmontar lazy FUSE antes del apagado (evita cuelgue)";
    wantedBy = [ "halt.target" "reboot.target" ];
    before = [ "halt.target" "reboot.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "shutdown-kill-rclone" ''
        ${pkgs.procps}/bin/pkill -KILL -f "rclone mount" 2>/dev/null || true
        ${pkgs.procps}/bin/pkill -KILL -f "vicinae-file-indexer" 2>/dev/null || true
        ${pkgs.coreutils}/bin/sleep 1
        for m in /home/diego/mi_gdmusica /home/diego/mi_gdrive /home/diego/mi_gdlibros; do
          ${pkgs.util-linux}/bin/umount -l "$m" 2>/dev/null || true
        done
        for m in /run/media/diego/*; do
          ${pkgs.util-linux}/bin/umount -l "$m" 2>/dev/null || true
        done
      ''}";
    };
  };
}