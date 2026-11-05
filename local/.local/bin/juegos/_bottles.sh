#!/usr/bin/env bash
# _bottles.sh — helpers comunes para los lanzadores de ~/.local/bin/juegos
#
# En Bazzite los juegos de Bottles viven dentro del sandbox Flatpak:
#   ~/.var/app/com.usebottles.bottles/data/bottles/
# y NO en ~/.local/share/bottles (NixOS) ni en ~/.wine (Lutris viejo).
#
# Los ejecutables se pasan SIEMPRE en ruta Windows (C:\...), igual que en la GUI
# de Bottles. El lanzamiento oficial es `bottles-cli run`, que aplica runtime,
# DXVK/VKD3D, NVAPI, overrides y variables de la botella. El segundo camino
# (runner + standalone) sólo se usa si Bottles/Flatpak no está disponible.

BOTTLES_APP_ID="com.usebottles.bottles"

# Devuelve el directorio base de datos de Bottles (el que contiene bottles/ y runners/).
bottles_data_dir() {
  local d
  for d in \
    "$HOME/.var/app/$BOTTLES_APP_ID/data/bottles" \
    "$HOME/.local/share/bottles" \
    "$HOME/.local/bottles"; do
    if [ -d "$d/bottles" ]; then
      printf '%s\n' "$d"
      return 0
    fi
  done
  return 1
}

# Directorio de una botella concreta.
bottles_bottle_dir() {
  local base
  base=$(bottles_data_dir) || return 1
  [ -f "$base/bottles/$1/bottle.yml" ] || return 1
  printf '%s/bottles/%s\n' "$base" "$1"
}

# Directorio del runner (wine) que usa una botella, leído de bottle.yml.
bottles_runner_dir() {
  local base bdir runner
  base=$(bottles_data_dir) || return 1
  bdir="$base/bottles/$1"
  [ -f "$bdir/bottle.yml" ] || return 1
  runner=$(sed -n 's/^Runner:[[:space:]]*//p' "$bdir/bottle.yml" 2>/dev/null | head -1)
  [ -n "$runner" ] || return 1
  [ -x "$base/runners/$runner/bin/wine" ] || return 1
  printf '%s/runners/%s\n' "$base" "$runner"
}

# Primer runner instalado (para prefijos Wine clásicos tipo ~/.wine).
bottles_any_runner() {
  local base w
  base=$(bottles_data_dir) || return 1
  for w in "$base"/runners/*/bin/wine; do
    [ -x "$w" ] || continue
    dirname "$(dirname "$w")"
    return 0
  done
  return 1
}

# Busca un componente dentro de un directorio ignorando mayúsculas/minúsculas
# (en Linux el drive_c real suele estar en minúsculas: users, games, ...).
_bottles_resolve_ci() {
  local base="$1" comp="$2" d name needle
  [ -e "$base/$comp" ] && { printf '%s/%s' "$base" "$comp"; return 0; }
  needle=$(printf '%s' "$comp" | tr '[:upper:]' '[:lower:]')
  for d in "$base"/*; do
    [ -e "$d" ] || continue
    name=$(basename "$d" | tr '[:upper:]' '[:lower:]')
    if [ "$name" = "$needle" ]; then
      printf '%s' "$d"
      return 0
    fi
  done
  return 1
}

# Convierte C:\ruta\windows a la ruta Unix dentro del drive_c de la botella,
# resolviendo mayúsculas/minúsculas. Si algo no existe, devuelve la ruta
# esperada igual (sirve para los mensajes de "instalalo en ...").
bottles_exe_unix() {
  local bdir p cur comp resolved missing=0 i
  local -a parts
  bdir=$(bottles_bottle_dir "$1") || return 1
  p="${2#*:}"          # quita "C:"
  p="${p//\\//}"       # backslashes -> slashes
  IFS='/' read -r -a parts <<< "$p"
  cur="$bdir/drive_c"
  for ((i = 0; i < ${#parts[@]}; i++)); do
    comp="${parts[i]}"
    [ -z "$comp" ] && continue
    if [ "$missing" -eq 0 ] && resolved=$(_bottles_resolve_ci "$cur" "$comp"); then
      cur="$resolved"
    else
      cur="$cur/$comp"
      missing=1
    fi
  done
  printf '%s\n' "$cur"
}

# De una lista de rutas Windows, imprime la primera que exista en disco.
bottles_pick_exe() {
  local bottle="$1" cand unix
  shift
  for cand in "$@"; do
    unix=$(bottles_exe_unix "$bottle" "$cand" 2>/dev/null) || continue
    if [ -f "$unix" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  return 1
}

# Ruta Unix esperada aunque Bottles no esté instalado (para mensajes de ayuda).
bottles_expected_unix() {
  local bottle="$1" p
  if bottles_bottle_dir "$bottle" >/dev/null 2>&1; then
    bottles_exe_unix "$bottle" "$2"
  else
    p="${2#*:}"
    p="${p//\\//}"
    printf '%s/.var/app/%s/data/bottles/bottles/%s/drive_c%s\n' \
      "$HOME" "$BOTTLES_APP_ID" "$bottle" "$p"
  fi
}

# ¿Hay Bottles utilizable?
bottles_cli_available() {
  if command -v flatpak >/dev/null 2>&1 && flatpak info "$BOTTLES_APP_ID" >/dev/null 2>&1; then
    return 0
  fi
  command -v bottles-cli >/dev/null 2>&1
}

# Ejecuta bottles-cli (Flatpak directo para poder inyectar BOTTLES_ENV con --env).
bottles_cli() {
  local -a envargs=() kv
  if [ -n "${BOTTLES_ENV:-}" ]; then
    for kv in $BOTTLES_ENV; do
      envargs+=("--env=$kv")
    done
  fi
  if command -v flatpak >/dev/null 2>&1 && flatpak info "$BOTTLES_APP_ID" >/dev/null 2>&1; then
    flatpak run "${envargs[@]}" --command=bottles-cli "$BOTTLES_APP_ID" "$@"
  elif command -v bottles-cli >/dev/null 2>&1; then
    bottles-cli "$@"
  else
    echo "bottles: no se encontró Bottles (flatpak $BOTTLES_APP_ID ni bottles-cli)" >&2
    return 127
  fi
}

# bottles_run <botella> <exe-windows> [args...]
# BOTTLES_DRY_RUN=1 imprime lo que haría sin lanzar nada.
bottles_run() {
  local bottle="$1" exe="$2" bdir rdir wine
  shift 2

  bdir=$(bottles_bottle_dir "$bottle") || {
    echo "bottles: no existe la botella '$bottle' en $(bottles_data_dir 2>/dev/null || echo '(sin Bottles)')" >&2
    return 1
  }

  if [ "${BOTTLES_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] botella: $bdir"
    echo "[dry-run] bottles-cli run -b $bottle -e '$exe' -- $*"
    return 0
  fi

  # 1) Camino oficial: Bottles (sandbox, runtime, DXVK, env de la botella).
  if bottles_cli_available; then
    bottles_cli run -b "$bottle" -e "$exe" -- "$@"
    return $?
  fi

  # 2) Fallback: runner de la botella con el entorno generado por Bottles.
  rdir=$(bottles_runner_dir "$bottle") || {
    echo "bottles: no hay runner instalado para '$bottle'" >&2
    return 1
  }
  wine="$rdir/bin/wine"
  if [ -f "$bdir/standalone" ]; then
    bash "$bdir/standalone" "$wine" "$exe" "$@"
  else
    WINEPREFIX="$bdir" WINEARCH=win64 \
      LD_LIBRARY_PATH="$rdir/lib:$rdir/lib/wine/x86_64-unix:$rdir/lib/wine/i386-unix${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      "$wine" "$exe" "$@"
  fi
}

# wine_run_prefix <prefijo> <exe> [args...]
# Prefijos Wine clásicos (~/.wine). En Bazzite no hay wine en el host: usa el
# runner de Bottles, que sí funciona fuera del sandbox para esto.
wine_run_prefix() {
  local prefix="$1" exe="$2" rdir wine
  shift 2
  if command -v wine >/dev/null 2>&1; then
    WINEPREFIX="$prefix" wine "$exe" "$@"
    return $?
  fi
  rdir=$(bottles_any_runner) || {
    echo "wine: no hay wine nativo ni runner de Bottles" >&2
    return 1
  }
  wine="$rdir/bin/wine"
  [ -x "$wine" ] || return 1
  WINEPREFIX="$prefix" WINEARCH=win64 \
    LD_LIBRARY_PATH="$rdir/lib:$rdir/lib/wine/x86_64-unix:$rdir/lib/wine/i386-unix${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$wine" "$exe" "$@"
}
