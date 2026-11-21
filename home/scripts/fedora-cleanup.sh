#!/usr/bin/env bash
# fedora-cleanup.sh — Limpieza acotada Bazzite/Fedora KDE
#
# Rutina repetible y segura. Solo toca:
#   - metadatos/temporales de rpm-ostree (cleanup -bm)
#   - journal y coredumps (systemd)
#   - cachés regenerables de usuario bajo ~/.cache (lista blanca)
#   - cachés sandbox de Flatpak (lista blanca, nunca Zen)
#   - cachés de gestores de paquetes (npm, pip, bun)
#   - restos de instalaciones fallidas de Hermes, sus cachés de paquetes y
#     los entornos Python obsoletos (nunca el que usa facts.json)
#   - releases antiguos del daemon de Codex (nunca el que apunta 'current')
#
# NUNCA toca: juegos, Steam/compatdata/shadercache, Lutris, Bottles, Waydroid,
# Zen Browser (perfil, sesión, datos ni caché), apps instaladas, dotfiles,
# repos, archivos personales, papelera, /var/mnt/games-swap, despliegues ni
# rollback de rpm-ostree.
#
# Uso: ./fedora-cleanup.sh [--dry-run] [--quick]
#   --dry-run  muestra qué haría sin borrar nada
#   --quick    pasada mínima para el timer de cada minuto: solo cachés
#              regenerables, y solo si el disco está por debajo del umbral

set -uo pipefail

ROOT_FS="/var/home"
DRY_RUN=0
QUICK=0
# Umbral de presión: en --quick no se toca nada mientras haya margen.
QUICK_THRESHOLD_MB="${FEDORA_CLEANUP_THRESHOLD_MB:-3072}"
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --quick) QUICK=1 ;;
  esac
done

# Toda la salida queda en un log (útil cuando la terminal se queda a medias).
# En --quick se usa un log aparte y compacto: guarda solo la última pasada.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
if [ "$QUICK" -eq 1 ]; then
  LOG_FILE="$STATE_DIR/fedora-cleanup-quick.log"
  mkdir -p "$STATE_DIR" 2>/dev/null
  if [ "${FEDORA_CLEANUP_LOGGED:-0}" != "1" ]; then
    export FEDORA_CLEANUP_LOGGED=1
    # Solo la última ejecución: el fichero no crece con el timer.
    : >"$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
  fi
else
  LOG_FILE="$STATE_DIR/fedora-cleanup.log"
  if [ "${FEDORA_CLEANUP_LOGGED:-0}" != "1" ]; then
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
    export FEDORA_CLEANUP_LOGGED=1
    exec > >(tee -a "$LOG_FILE") 2>&1
  fi
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

FREED_START=$(df -B1 --output=avail "$ROOT_FS" 2>/dev/null | tail -1 | tr -d '[:space:]')
[ -z "$FREED_START" ] && FREED_START=0
SEC_MARK=$FREED_START
FREED_TOTAL=0
SEC_LABELS=(); SEC_VALUES=()

# Rutas que jamás se tocan, ni por error de lista blanca.
FORBIDDEN=(
  "$HOME/.var/app/app.zen_browser.zen"
  "$HOME/.local/share/Steam"
  "$HOME/.local/share/lutris"
  "$HOME/.local/share/waydroid"
  "$HOME/.var/app/com.usebottles.bottles"
  "$HOME/.local/share/Trash"
  "/var/mnt/games-swap"
)

human() { numfmt --to=iec --suffix=B "${1:-0}" 2>/dev/null || echo "${1:-0}B"; }
disk_free() { df -B1 --output=avail "$ROOT_FS" 2>/dev/null | tail -1 | tr -d '[:space:]' || echo 0; }

is_forbidden() {
  local p="$1" f
  for f in "${FORBIDDEN[@]}"; do
    case "$p" in "$f"|"$f"/*) return 0 ;; esac
  done
  return 1
}

sec_mark() { SEC_MARK=$(disk_free); }

sec_end() {
  local label="$1" after freed
  after=$(disk_free)
  freed=$(( after - SEC_MARK ))
  [ "$freed" -lt 0 ] && freed=0
  FREED_TOTAL=$(( FREED_TOTAL + freed ))
  SEC_LABELS+=("$label"); SEC_VALUES+=("$freed")
  if [ "$freed" -gt 0 ]; then
    printf "   %-34s %10b\n" "$label" "${GREEN}$(human "$freed")${NC}"
  else
    printf "   %-34s %10s\n" "$label" "0B"
  fi
  SEC_MARK=$after
}

# Borra el contenido de un directorio de caché, respetando la lista negra.
clear_cache() {
  local label="$1" path="$2"
  [ -d "$path" ] && [ ! -L "$path" ] || return 0
  if is_forbidden "$path"; then
    echo -e "   ${RED}✗ $label: ruta protegida, omitida${NC}"
    return 0
  fi
  local size; size=$(du -sh "$path" 2>/dev/null | cut -f1); size=${size:-0B}
  if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "   [dry-run] $label ($size)"
    return 0
  fi
  echo -ne "   $label ($size)..."
  if find "$path" -xdev -mindepth 1 -delete 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
  else
    echo -e " ${YELLOW}parcial${NC}"
  fi
}

# ── 1. rpm-ostree: solo metadatos/temporales ────────────────────────────
# Nunca se queda colgado esperando autenticación: sudo sin contraseña o,
# si hay sesión gráfica, pkexec con límite de tiempo.
cleanup_rpm_ostree() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "   [dry-run] rpm-ostree cleanup -bm"; return; fi
  echo -ne "   rpm-ostree cleanup -bm..."
  if timeout 20 sudo -n rpm-ostree cleanup -bm &>/dev/null; then
    echo -e " ${GREEN}✓${NC}"; return
  fi
  if command -v pkexec >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    echo -ne " (autoriza el diálogo, máx 2 min)..."
    if timeout 120 pkexec rpm-ostree cleanup -bm &>/dev/null; then
      echo -e " ${GREEN}✓${NC}"; return
    fi
    echo -e " ${YELLOW}sin autorización${NC}"
    return
  fi
  echo -e " ${YELLOW}omitido: corre 'sudo rpm-ostree cleanup -bm'${NC}"
}

# ── 2. journal + coredumps ──────────────────────────────────────────────
cleanup_journal() {
  [ "$DRY_RUN" -eq 1 ] && { echo "   [dry-run] journal vacuum 200M"; return; }
  journalctl --vacuum-size=200M &>/dev/null && echo -e "   journal <= 200M ${GREEN}✓${NC}" || true
}

cleanup_coredumps() {
  local dir="/var/lib/systemd/coredump"
  [ -d "$dir" ] || return 0
  local size; size=$(du -sh "$dir" 2>/dev/null | cut -f1); size=${size:-0B}
  [ "$DRY_RUN" -eq 1 ] && { echo "   [dry-run] coredumps ($size)"; return; }
  [ "$(du -sb "$dir" 2>/dev/null | cut -f1)" = "0" ] && return 0
  sudo -n rm -f "$dir"/* &>/dev/null && echo -e "   coredumps ($size) ${GREEN}✓${NC}" || true
}

# ── 3. ~/.cache con lista blanca ────────────────────────────────────────
cleanup_user_cache() {
  local p
  for p in \
    mesa_shader_cache \
    qtshadercache-x86_64-little_endian-lp64 \
    ksvg-elements \
    kwin \
    plasmashell \
    thumbnails \
    fontconfig \
    libdnf5 \
    flatpak \
    uv
  do
    clear_cache "~/.cache/$p" "$HOME/.cache/$p"
  done
  # Indexador de Vicinae: se hincha hasta ~450 MB y se reconstruye solo.
  clear_cache "vicinae/file-indexer" "$HOME/.cache/vicinae/file-indexer"
  clear_cache "vicinae/images" "$HOME/.cache/vicinae/images"
  [ "$DRY_RUN" -eq 1 ] || rm -f "$HOME/.cache"/ksycoca6_* "$HOME"/.cache/*.kcache 2>/dev/null
  [ "$DRY_RUN" -eq 1 ] || rm -f "$HOME/.cache/ibus/bus/registry" 2>/dev/null
}

# ── 4. Caché VFS de rclone (Drive montado con --vfs-cache-mode full) ────
# Es la causa típica de quedarse a 0 B: un video de Drive se cachea entero en
# ~/.cache/rclone/vfs. Se borran solo ficheros sin actividad reciente (10 min)
# para no cortar una reproducción en curso; rclone los re-descarga si hacen falta.
cleanup_rclone_vfs() {
  local vfs="$HOME/.cache/rclone/vfs"
  is_forbidden "$vfs" && return 0
  [ -d "$vfs" ] || return 0
  local size; size=$(du -sh "$vfs" 2>/dev/null | cut -f1); size=${size:-0B}
  if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "   [dry-run] rclone vfs ($size, solo ficheros >10 min)"
    return 0
  fi
  echo -ne "   rclone vfs ($size)..."
  find "$vfs" -xdev -type f -mmin +10 -delete 2>/dev/null
  find "$vfs" -xdev -type d -empty -delete 2>/dev/null
  echo -e " ${GREEN}✓${NC}"
}

# ── 5. Cachés sandbox de Flatpak (nunca Zen) ────────────────────────────
cleanup_flatpak_caches() {
  local app
  for app in \
    org.waywallen.waywallen \
    com.brave.Browser \
    com.moonlight_stream.Moonlight \
    io.github.hmlendea.geforcenow-electron \
    dev.lizardbyte.app.Sunshine \
    online.hatsune_miku.tachidesk-vaadinui
  do
    clear_cache "flatpak:$app" "$HOME/.var/app/$app/cache"
  done
}

# ── 6. Runtimes Flatpak sin usar (interactivo, sin -y) ──────────────────
cleanup_flatpak_unused() {
  command -v flatpak >/dev/null || return 0
  local out
  out=$(flatpak uninstall --unused </dev/null 2>&1 || true)
  if echo "$out" | grep -qE '^[[:space:]]*[0-9]+\.'; then
    echo -e "   ${YELLOW}Hay runtimes sin usar; revisar manualmente:${NC}"
    echo "$out" | sed 's/^/     /'
  else
    echo -e "   ${GREEN}sin runtimes sin usar${NC}"
  fi
}

# ── 7. Gestores de paquetes ─────────────────────────────────────────────
cleanup_pkg_managers() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "   [dry-run] npm/pip/bun/go cache"; return; fi
  command -v npm >/dev/null && npm cache clean --force &>/dev/null && echo -e "   npm ${GREEN}✓${NC}" || true
  command -v pip3 >/dev/null && pip3 cache purge &>/dev/null && echo -e "   pip ${GREEN}✓${NC}" || true
  command -v bun >/dev/null && bun pm cache rm &>/dev/null && echo -e "   bun ${GREEN}✓${NC}" || true
  command -v go >/dev/null && go clean -modcache &>/dev/null && echo -e "   go modcache ${GREEN}✓${NC}" || true
}

# ── 8. Hermes / Codex: restos, cachés y versiones viejas ────────────────
cleanup_hermes_leftovers() {
  local d
  for d in "$HOME"/.hermes/.hermes-clone-*; do
    [ -d "$d" ] || continue
    if pgrep -u "$UID" -f 'hermes-agent|hermes.*install' >/dev/null 2>&1; then
      echo -e "   ${YELLOW}Hermes activo: se conserva $d${NC}"
      continue
    fi
    clear_cache "hermes:$(basename "$d")" "$d"
  done
  [ "$DRY_RUN" -eq 1 ] || find "$HOME/.hermes/logs" -maxdepth 1 -type f -name '*.log' -delete 2>/dev/null
}

# Cachés de paquetes: se vuelven a descargar cuando hagan falta.
cleanup_hermes_caches() {
  local p
  for p in pnpm uv; do
    clear_cache "hermes cache:$p" "$HOME/.hermes/cache/$p"
  done
  [ "$DRY_RUN" -eq 1 ] || rm -rf "$HOME/.hermes/cache/spillover" 2>/dev/null
}

# Borra los entornos Python que facts.json ya no referencia (los deja
# 'hermes update'). El activo se conserva siempre.
cleanup_hermes_stale_envs() {
  local facts envdir active e
  for facts in "$HOME"/.hermes/installs/*/facts.json; do
    [ -f "$facts" ] || continue
    envdir="$(dirname "$facts")/environments"
    [ -d "$envdir" ] || continue
    active=$(grep -o 'environments/[0-9a-fA-F-]\{16,\}' "$facts" 2>/dev/null | head -1 | cut -d/ -f2)
    if [ -z "$active" ]; then
      echo -e "   ${YELLOW}hermes envs: no se pudo leer el activo, se omite${NC}"
      continue
    fi
    for e in "$envdir"/*; do
      [ -d "$e" ] || continue
      [ "$(basename "$e")" = "$active" ] && continue
      is_forbidden "$e" && continue
      local size; size=$(du -sh "$e" 2>/dev/null | cut -f1); size=${size:-0B}
      if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "   [dry-run] hermes env obsoleto $(basename "$e") ($size)"
      else
        echo -ne "   hermes env obsoleto $(basename "$e") ($size)..."
        if rm -rf "$e" 2>/dev/null; then echo -e " ${GREEN}✓${NC}"; else echo -e " ${YELLOW}parcial${NC}"; fi
      fi
    done
  done
}

# Releases del app-server de Codex: solo se conserva el de 'current'.
cleanup_codex_old_releases() {
  local base="$HOME/.codex/packages/app-server-daemon" cur r
  [ -d "$base/releases" ] || return 0
  cur=$(readlink -f "$base/current" 2>/dev/null || true)
  [ -n "$cur" ] || { echo -e "   ${YELLOW}codex: 'current' no resuelve, se omite${NC}"; return 0; }
  for r in "$base/releases"/*; do
    [ -d "$r" ] || continue
    [ "$r" = "$cur" ] && continue
    if pgrep -u "$UID" -f "$(basename "$r")" >/dev/null 2>&1; then
      echo -e "   ${YELLOW}codex: $(basename "$r") en uso, se conserva${NC}"
      continue
    fi
    clear_cache "codex $(basename "$r")" "$r"
  done
}

# ── 9. Solo informe (no borra) ──────────────────────────────────────────
report_only() {
  echo -e "\n${BLUE}══ Solo informe (no se borra nada) ══${NC}"
  printf "   %-34s %10s\n" "Papelera" "$(du -sh "$HOME/.local/share/Trash" 2>/dev/null | cut -f1)"
  printf "   %-34s %10s\n" "Zen Browser" "$(du -sh "$HOME/.var/app/app.zen_browser.zen" 2>/dev/null | cut -f1)"
  printf "   %-34s %10s\n" "Steam (juegos)" "$(du -sh "$HOME/.local/share/Steam/steamapps/common" 2>/dev/null | cut -f1)"
  printf "   %-34s %10s\n" "Waydroid" "$(du -sh "$HOME/.local/share/waydroid" 2>/dev/null | cut -f1)"
  printf "   %-34s %10s\n" "/var/log/wtmp" "$(du -sh /var/log/wtmp 2>/dev/null | cut -f1)"
  echo -e "   ${YELLOW}Nada de esto se elimina automáticamente.${NC}"
}

print_summary() {
  local now delta
  now=$(disk_free); delta=$(( now - FREED_START )); [ "$delta" -lt 0 ] && delta=0
  echo -e "\n${BLUE}═══════════ ESPACIO ═══════════${NC}"
  for i in "${!SEC_LABELS[@]}"; do
    printf "    %-38s %10s\n" "${SEC_LABELS[$i]}" "$(human "${SEC_VALUES[$i]}")"
  done
  printf "    %-38s %10s\n" "Suma por secciones" "$(human "$FREED_TOTAL")"
  printf "    %-38s %10b\n" "LIBERADO REAL (delta disco)" "${GREEN}$(human "$delta")${NC}"
  printf "    %-38s %10s\n" "Libre antes" "$(human "$FREED_START")"
  printf "    %-38s %10s\n" "Libre ahora" "$(human "$now")"
  df -h "$ROOT_FS" | sed -n '1,2p'
}

# ── Main ────────────────────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] && { echo -e "${RED}No ejecutar como root.${NC}"; exit 1; }

free_mb() { echo $(( $(disk_free) / 1048576 )); }

# Modo rápido (timer de cada minuto): barato y con guarda de presión.
if [ "$QUICK" -eq 1 ]; then
  FREE_MB=$(free_mb)
  if [ "$FREE_MB" -ge "$QUICK_THRESHOLD_MB" ]; then
    echo "[$(date '+%F %T')] quick: ${FREE_MB} MB libres (>= ${QUICK_THRESHOLD_MB} MB), nada que hacer"
    exit 0
  fi
  echo -e "${YELLOW}[$(date '+%F %T')] quick: ${FREE_MB} MB libres → limpiando cachés${NC}"
  sec_mark; echo -e "\n${BLUE}~/.cache (lista blanca)${NC}"; cleanup_user_cache; sec_end "~/.cache"
  sec_mark; echo -e "\n${BLUE}rclone VFS${NC}"; cleanup_rclone_vfs; sec_end "rclone vfs"
  sec_mark; echo -e "\n${BLUE}Cachés Flatpak (sin Zen)${NC}"; cleanup_flatpak_caches; sec_end "flatpak caches"
  sec_mark; echo -e "\n${BLUE}Cachés de paquetes Hermes${NC}"; cleanup_hermes_caches; sec_end "hermes caches"
  print_summary
  exit 0
fi

[ "$DRY_RUN" -eq 1 ] && echo -e "${YELLOW}MODO DRY-RUN: no se borra nada${NC}"

echo -e "${YELLOW}═══ Bazzite — Limpieza acotada (modo seguro) ═══${NC}"
echo "Libre al inicio: $(human "$FREED_START")"
echo "Log: $LOG_FILE"

sec_mark; echo -e "\n${BLUE}rpm-ostree${NC}"; cleanup_rpm_ostree; sec_end "rpm-ostree -bm"
sec_mark; echo -e "\n${BLUE}Journal / coredumps${NC}"; cleanup_journal; cleanup_coredumps; sec_end "journal+coredumps"
sec_mark; echo -e "\n${BLUE}~/.cache (lista blanca)${NC}"; cleanup_user_cache; sec_end "~/.cache"
sec_mark; echo -e "\n${BLUE}rclone VFS${NC}"; cleanup_rclone_vfs; sec_end "rclone vfs"
sec_mark; echo -e "\n${BLUE}Cachés Flatpak (sin Zen)${NC}"; cleanup_flatpak_caches; sec_end "flatpak caches"
sec_mark; echo -e "\n${BLUE}Flatpak unused${NC}"; cleanup_flatpak_unused; sec_end "flatpak unused"
sec_mark; echo -e "\n${BLUE}Gestores de paquetes${NC}"; cleanup_pkg_managers; sec_end "npm/pip/bun"
sec_mark; echo -e "\n${BLUE}Hermes / Codex${NC}"; cleanup_hermes_leftovers; cleanup_hermes_caches; cleanup_hermes_stale_envs; cleanup_codex_old_releases; sec_end "hermes/codex"

report_only
print_summary

echo -e "\n${GREEN}✓ Limpieza acotada completada${NC}"
echo -e "${YELLOW}Zen, juegos, apps y datos personales intactos.${NC}"
echo "Log: $LOG_FILE"
