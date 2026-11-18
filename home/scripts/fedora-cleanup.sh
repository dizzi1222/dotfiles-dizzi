#!/usr/bin/env bash
# fedora-cleanup.sh — Limpieza acotada Bazzite/Fedora KDE
#
# Rutina repetible y segura. Solo toca:
#   - metadatos/temporales de rpm-ostree (cleanup -bm)
#   - journal y coredumps (systemd)
#   - cachés regenerables de usuario bajo ~/.cache (lista blanca)
#   - cachés sandbox de Flatpak (lista blanca, nunca Zen)
#   - cachés de gestores de paquetes (npm, pip, bun)
#   - restos de instalaciones fallidas de Hermes
#
# NUNCA toca: juegos, Steam/compatdata/shadercache, Lutris, Bottles, Waydroid,
# Zen Browser (perfil, sesión, datos ni caché), apps instaladas, dotfiles,
# repos, archivos personales, papelera, /var/mnt/games-swap, despliegues ni
# rollback de rpm-ostree.
#
# Uso: ./fedora-cleanup.sh [--dry-run]

set -uo pipefail

ROOT_FS="/var/home"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

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
cleanup_rpm_ostree() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "   [dry-run] rpm-ostree cleanup -bm"; return; fi
  echo -ne "   rpm-ostree cleanup -bm..."
  if sudo -n rpm-ostree cleanup -bm &>/dev/null || pkexec rpm-ostree cleanup -bm &>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
  else
    echo -e " ${YELLOW}omitido (requiere autorización)${NC}"
  fi
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
    uv \
    rclone
  do
    clear_cache "~/.cache/$p" "$HOME/.cache/$p"
  done
  [ "$DRY_RUN" -eq 1 ] || rm -f "$HOME/.cache"/ksycoca6_* "$HOME"/.cache/*.kcache 2>/dev/null
  [ "$DRY_RUN" -eq 1 ] || rm -f "$HOME/.cache/ibus/bus/registry" 2>/dev/null
}

# ── 4. Cachés sandbox de Flatpak (nunca Zen) ────────────────────────────
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

# ── 5. Runtimes Flatpak sin usar (interactivo, sin -y) ──────────────────
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

# ── 6. Gestores de paquetes ─────────────────────────────────────────────
cleanup_pkg_managers() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "   [dry-run] npm/pip/bun/go cache"; return; fi
  command -v npm >/dev/null && npm cache clean --force &>/dev/null && echo -e "   npm ${GREEN}✓${NC}" || true
  command -v pip3 >/dev/null && pip3 cache purge &>/dev/null && echo -e "   pip ${GREEN}✓${NC}" || true
  command -v bun >/dev/null && bun pm cache rm &>/dev/null && echo -e "   bun ${GREEN}✓${NC}" || true
  command -v go >/dev/null && go clean -modcache &>/dev/null && echo -e "   go modcache ${GREEN}✓${NC}" || true
}

# ── 7. Restos de instalación Hermes fallida ─────────────────────────────
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

# ── 8. Solo informe (no borra) ──────────────────────────────────────────
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
[ "$DRY_RUN" -eq 1 ] && echo -e "${YELLOW}MODO DRY-RUN: no se borra nada${NC}"

echo -e "${YELLOW}═══ Bazzite — Limpieza acotada (modo seguro) ═══${NC}"
echo "Libre al inicio: $(human "$FREED_START")"

sec_mark; echo -e "\n${BLUE}rpm-ostree${NC}"; cleanup_rpm_ostree; sec_end "rpm-ostree -bm"
sec_mark; echo -e "\n${BLUE}Journal / coredumps${NC}"; cleanup_journal; cleanup_coredumps; sec_end "journal+coredumps"
sec_mark; echo -e "\n${BLUE}~/.cache (lista blanca)${NC}"; cleanup_user_cache; sec_end "~/.cache"
sec_mark; echo -e "\n${BLUE}Cachés Flatpak (sin Zen)${NC}"; cleanup_flatpak_caches; sec_end "flatpak caches"
sec_mark; echo -e "\n${BLUE}Flatpak unused${NC}"; cleanup_flatpak_unused; sec_end "flatpak unused"
sec_mark; echo -e "\n${BLUE}Gestores de paquetes${NC}"; cleanup_pkg_managers; sec_end "npm/pip/bun"
sec_mark; echo -e "\n${BLUE}Hermes (restos)${NC}"; cleanup_hermes_leftovers; sec_end "hermes restos"

report_only
print_summary

echo -e "\n${GREEN}✓ Limpieza acotada completada${NC}"
echo -e "${YELLOW}Zen, juegos, apps y datos personales intactos.${NC}"
