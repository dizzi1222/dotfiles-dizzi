{ pkgs, ... }:

let
  # Parchea PT_GNU_STACK para quitar el bit PF_X (execstack). Equivalente a
  # `execstack -c` / `patchelf --clear-execstack` (patchelf 0.15 no lo soporta).
  clearExecstack = pkgs.writeText "stardew-clear-execstack.py" ''
    import struct, sys
    PT_GNU_STACK = 0x6474E551
    PF_X = 0x1
    for path in sys.argv[1:]:
        with open(path, "r+b") as f:
            data = bytearray(f.read())
            if data[:4] != b"\x7fELF" or data[4] != 2:
                print(f"{path}: no es ELF64, omitido")
                continue
            phoff = struct.unpack_from("<Q", data, 0x20)[0]
            phentsize = struct.unpack_from("<H", data, 0x36)[0]
            phnum = struct.unpack_from("<H", data, 0x38)[0]
            changed = False
            for i in range(phnum):
                off = phoff + i * phentsize
                if struct.unpack_from("<I", data, off)[0] == PT_GNU_STACK:
                    flags = struct.unpack_from("<I", data, off + 4)[0]
                    if flags & PF_X:
                        struct.pack_into("<I", data, off + 4, flags & ~PF_X)
                        changed = True
                        print(f"{path}: execstack limpiado")
            if changed:
                f.seek(0); f.write(data)
  '';

  stardewGalaxyFix = pkgs.writeShellScriptBin "stardew-galaxy-fix" ''
    set -eu
    game="''${STARDEW_DIR:-$HOME/.wine/drive_c/Games/Stardew Valley}"
    if [ ! -d "$game" ]; then
      echo "No existe el directorio del juego: $game" >&2
      echo "Ajusta STARDEW_DIR=... o edita el script." >&2
      exit 1
    fi

    # 1) libstdc++.so.6 64-bit en la carpeta del juego (RPATH=\$ORIGIN lo busca ahí).
    lib=""
    for cand in "${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6" "${pkgs.stdenv.cc.cc.lib}/lib64/libstdc++.so.6"; do
      if [ -e "$cand" ] && ${pkgs.file}/bin/file -L "$cand" | ${pkgs.gnugrep}/bin/grep -q 'ELF 64-bit'; then
        lib="$cand"; break
      fi
    done
    if [ -z "$lib" ]; then
      echo "No se encontró libstdc++.so.6 64-bit en el store" >&2
      exit 1
    fi
    if ! ${pkgs.file}/bin/file "$game/libstdc++.so.6" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'ELF 64-bit'; then
      cp -Lf "$lib" "$game/libstdc++.so.6"
      echo "libstdc++.so.6 64-bit copiado desde $lib"
    else
      echo "libstdc++.so.6 64-bit ya presente"
    fi

    # 2) Quitar execstack de las libs de GOG Galaxy (idempotente).
    for so in "$game/libGalaxyCSharpGlue.so" "$game/libGalaxy64.so"; do
      [ -e "$so" ] || continue
      [ -e "$so.bak" ] || cp -f "$so" "$so.bak"
      ${pkgs.python3}/bin/python3 ${clearExecstack} "$so"
    done

    echo "Listo: Galaxy SDK debería cargar en SMAPI."
  '';
in
{
  home.packages = [ stardewGalaxyFix ];
}
