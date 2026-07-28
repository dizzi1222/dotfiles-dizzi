# Sesión Wayland de Cinnamon instrumentada para diagnosticar su muerte
# instantánea bajo SDDM (muere en <1s sin emitir nada al journal).
# Captura entorno + stdout/stderr de cinnamon-session Y de sus hijos a
# ~/cinnamon-debug.log, junto con el exit code final.
#
# Además registra la sesión con Exec ABSOLUTO (a diferencia del
# cinnamon-wayland.desktop oficial que usa nombre pelado), eliminando
# esa variable de la ecuación.
{ pkgs, ... }: {
  services.displayManager.sessionPackages = [
    (pkgs.runCommand "cinnamon-wayland-debug-session"
      {
        # Requerido por el tipo packageWithProvidedSessions de NixOS:
        # debe coincidir con el basename del .desktop.
        passthru.providedSessions = [ "cinnamon-wayland-debug" ];
      }
      ''
        mkdir -p $out/bin $out/share/wayland-sessions

        cat > $out/bin/cinnamon-debug-wrapper <<'EOF'
        #!/run/current-system/sw/bin/bash
        LOG="$HOME/cinnamon-debug.log"
        {
          echo "════════ $(date -Is) ════════"
          echo "-- entorno recibido del script wayland-session:"
          echo "PATH=$PATH"
          echo "XDG_DATA_DIRS=$XDG_DATA_DIRS"
          echo "DBUS_SESSION_BUS_ADDRESS=''${DBUS_SESSION_BUS_ADDRESS:-<unset>}"
          echo "XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-<unset>}"
          echo "WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-<unset>}"
          echo "DISPLAY=''${DISPLAY:-<unset>}"
          echo "-- lanzando cinnamon-session-cinnamon --wayland (G_MESSAGES_DEBUG=all)..."
          export G_MESSAGES_DEBUG=all
          /run/current-system/sw/bin/cinnamon-session-cinnamon --wayland 2>&1
          rc=$?
          echo "════════ EXIT CODE: $rc ════════"
        } >> "$LOG" 2>&1
        exit $rc
        EOF
        chmod +x $out/bin/cinnamon-debug-wrapper

        # $out se interpola en tiempo de build => Exec absoluto garantizado.
        cat > $out/share/wayland-sessions/cinnamon-wayland-debug.desktop <<EOF
        [Desktop Entry]
        Name=Cinnamon Wayland (Debug)
        Comment=Sesión instrumentada para diagnóstico
        Exec=$out/bin/cinnamon-debug-wrapper
        TryExec=$out/bin/cinnamon-debug-wrapper
        Type=Application
        DesktopNames=Cinnamon
        Keywords=cinnamon;debug;
        EOF
      '')
  ];
}
