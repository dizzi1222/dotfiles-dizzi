{ config, pkgs, lib, stateVersion, username, hostname, inputs, ... }:

{
  imports = [
    ../../nixos/base-configuration.nix
    ../../nixos/features/hyprland.nix
    ../../nixos/features/cinnamon-debug.nix
    ../../nixos/features/steam.nix
    ../../nixos/features/waydroid.nix
    ./features/nvidia.nix
    ./hardware-configuration.nix
  ];

  # Disco externo USB Seagate 500GB (enclosure JMicron JMS561) en sda1 (exfat).
  # nofail: no bloquea el boot si el disco no está conectado. Usa el módulo
  # exfat del kernel (boot.kernelModules = [ "exfat" ]) en vez del driver FUSE.
  fileSystems."/media/diego/0828-67C1" = {
    device = "/dev/disk/by-uuid/0828-67C1";
    fsType = "exfat";
    options = [ "nofail" "uid=1000" "gid=100" "umask=022" ];
  };

  # Hook de systemd-sleep: desmonta los mounts rclone (FUSE) antes de dormir/hibernar
  # (evita "Freezing user space processes failed" por I/O en FUSE). El re-montaje tras
  # despertar lo hacen los servicios user rclone-mount-* (services.nix) porque este
  # hook corre con KillMode=control-group y los procesos en background del post-sleep
  # mueren con SIGKILL cuando el servicio sale.
  environment.etc."systemd/system-sleep/90-rclone.sh".source = pkgs.writeShellScript "90-rclone-sleep.sh" ''
    #!/bin/sh
    # Hook blindado: NADA puede colgarse. Cada operación va con "timeout" corto;
    # si un mount USB/FUSE está muerto, umount/fuser bloquearían el pre-sleep y
    # systemd-sleep agotaría el timeout (90s) del servicio -> SIGKILL -> apagado.
    rclone_bin=${pkgs.rclone}/bin/rclone
    umount_bin=${pkgs.util-linux}/bin/umount
    fuse3_bin=${pkgs.fuse3}/bin/fusermount3
    fuse2_bin=${pkgs.fuse}/bin/fusermount
    pkill_bin=${pkgs.procps}/bin/pkill
    fuser_bin=${pkgs.psmisc}/bin/fuser
    sleep_bin=${pkgs.coreutils}/bin/sleep
    timeout_bin=${pkgs.coreutils}/bin/timeout
    runuser_bin=${pkgs.util-linux}/bin/runuser
    env_bin=${pkgs.coreutils}/bin/env
    logger_bin=${pkgs.util-linux}/bin/logger

    # só0 segundos máx por operación crítica
    t() { $timeout_bin 3 "$@"; }

    case "$1/$2" in
      pre/*)
        $logger_bin -t 90-rclone "pre-sleep start"
        # Mata al indexer PRIMERO (pkill no se colga; solo señala).
        $pkill_bin -KILL -f "vicinae-file-indexer" 2>/dev/null || true
        $pkill_bin -KILL -f "rclone mount" 2>/dev/null || true
        $sleep_bin 1
        # Desmonta TODO de forma NO bloqueante. umount -l detacha al instante;
        # fuser -k no puede matar D-state, así que solo señalamos sin espera.
        $fuser_bin -k -m /home/diego/mi_gdmusica 2>/dev/null || true
        $fuser_bin -k -m /home/diego/mi_gdrive 2>/dev/null || true
        $fuser_bin -k -m /home/diego/mi_gdlibros 2>/dev/null || true
        for m in /home/diego/mi_gdmusica /home/diego/mi_gdrive /home/diego/mi_gdlibros; do
          t $fuse3_bin -u "$m" 2>/dev/null \
            || t $fuse2_bin -u "$m" 2>/dev/null \
            || t $umount_bin "$m" 2>/dev/null || true
        done
        # ISOs automontadas (udisks2) + loops
        for m in /run/media/diego/* /mnt/iso-* /media/diego/*; do
          t $umount_bin -l "$m" 2>/dev/null || true
        done
        $logger_bin -t 90-rclone "pre-sleep done"
        ;;
    esac
    exit 0
  '';
}
