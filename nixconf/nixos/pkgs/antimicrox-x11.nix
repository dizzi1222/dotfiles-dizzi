{
  antimicrox,
  coreutils,
  symlinkJoin,
  writeShellScriptBin,
}:

let
  launcher = writeShellScriptBin "antimicrox" ''
    export QT_QPA_PLATFORM=xcb

    if [ -n "''${DISPLAY:-}" ]; then
      display_number="''${DISPLAY#:}"
      display_number="''${display_number%%.*}"

      case "$display_number" in
        ""|*[!0-9]*) ;;
        *)
          display_socket="/tmp/.X11-unix/X$display_number"
          attempts=0
          while [ ! -S "$display_socket" ] && [ "$attempts" -lt 40 ]; do
            ${coreutils}/bin/sleep 0.25
            attempts=$((attempts + 1))
          done
          ;;
      esac
    fi

    exec ${antimicrox}/bin/antimicrox "$@"
  '';
in
symlinkJoin {
  name = "antimicrox-x11-${antimicrox.version}";
  # Se enlaza el paquete original completo (share, lib, .antimicrox-wrapped),
  # pero bin/antimicrox SE SUSTITUYE por el launcher. Antes se hacía
  # `paths = [ launcher antimicrox ]` y como ambos exponen bin/antimicrox,
  # el original ganaba la colisión y el launcher quedaba muerto.
  paths = [ antimicrox ];
  postBuild = ''
    rm "$out/bin/antimicrox"
    ln -s ${launcher}/bin/antimicrox "$out/bin/antimicrox"
  '';
  inherit (antimicrox) meta;
}
