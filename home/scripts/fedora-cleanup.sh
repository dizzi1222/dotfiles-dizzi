#!/usr/bin/env bash
# fedora-cleanup.sh — Limpieza completa Bazzite/Fedora KDE
# Portado completo de nixconf-cleanup con: delta real, coredumps, OpenCode VACUUM,
# flatpak pinned, rpm-ostree rollback safe, bottles runners, protected lists.

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────
ROOT_FS="/var/home"
FREED_START=$(df -B1 --output=avail "$ROOT_FS" 2>/dev/null | tail -1 | tr -d '[:space:]')
[ -z "$FREED_START" ] && FREED_START=0
SEC_MARK=$FREED_START
FREED_TOTAL=0
SEC_LABELS=()
SEC_VALUES=()
DRY_RUN=0

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

human() {
  local val="${1:-0}"
  numfmt --to=iec --suffix=B "$val" 2>/dev/null || echo "${val}B"
}

disk_free() {
  df -B1 --output=avail "$ROOT_FS" 2>/dev/null | tail -1 | tr -d '[:space:]' || echo 0
}

sec_mark() {
  SEC_MARK=$(disk_free) || SEC_MARK=0
}

sec_end() {
  local label="$1"
  local after freed
  after=$(disk_free) || after=0
  freed=$(( after - SEC_MARK )) 2>/dev/null || freed=0
  [ "$freed" -lt 0 ] 2>/dev/null && freed=0
  FREED_TOTAL=$(( FREED_TOTAL + freed )) 2>/dev/null || true
  SEC_LABELS+=("$label")
  SEC_VALUES+=("$freed")
  if [ "$freed" -gt 0 ] 2>/dev/null; then
    printf "   %-36s %10b\n" "$label" "${GREEN}$(human "$freed")${NC}"
  else
    printf "   %-36s %10s\n" "$label" "0B"
  fi
  SEC_MARK=$after
}

print_summary() {
  local now delta
  now=$(disk_free) || now=0
  delta=$(( now - FREED_START )) 2>/dev/null || delta=0
  [ "$delta" -lt 0 ] 2>/dev/null && delta=0

  echo -e "\n${BLUE}═══════════ ESPACIO ═══════════${NC}"
  echo -e "${YELLOW}  Recuento por sección:${NC}"
  for i in "${!SEC_LABELS[@]}"; do
    printf "    %-38s %10s\n" "${SEC_LABELS[$i]}" "$(human "${SEC_VALUES[$i]}" 2>/dev/null || echo "0B")"
  done
  echo -e "${YELLOW}  Totales:${NC}"
  printf "    %-38s %10s\n" "Liberado por secciones (suma)" "$(human "$FREED_TOTAL" 2>/dev/null || echo "0B")"
  printf "    %-38s %10s  ${GREEN}← real (delta disco)${NC}\n" \
         "LIBERADO TOTAL (delta disco)" "$(human "$delta" 2>/dev/null || echo "0B")"
  echo
  printf "    %-38s %10s\n" "Disco libre ANTES" "$(human "$FREED_START" 2>/dev/null || echo "0B")"
  printf "    %-38s %10s\n" "Disco libre AHORA" "$(human "$now" 2>/dev/null || echo "0B")"
  echo
  df -h "$ROOT_FS" | sed -n '1,2p' 2>/dev/null || true
}

cleanup_dir() {
  local name="$1" path="$2"
  [ -d "$path" ] && [ ! -L "$path" ] || return 0
  local size
  size=$(du -sh "$path" 2>/dev/null | cut -f1) || size="0B"
  [ -z "$size" ] && size="0B"
  echo -ne "Cleaning $name cache... found ${RED}$size${NC}"
  if find "$path" -xdev -mindepth 1 -delete 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
  else
    echo -e " ${YELLOW}(limpieza parcial)${NC}"
  fi
}

cleanup_rust_caches() {
  local avante="$1" registry_src="$2"
  local module lib runtime_ok=1
  if pgrep -u "$UID" -x cargo >/dev/null || pgrep -u "$UID" -x rustc >/dev/null; then
    echo -e "  ${YELLOW}Cargo/Rustc activo: se conservan las cachés de compilación.${NC}"
    return 0
  fi

  if [ -d "$avante/target/release" ] && [ ! -L "$avante/lua" ]; then
    # El plugin usa las copias de lua/, no los archivos de target/release.
    for module in tokenizers templates repo_map html2md; do
      lib="$avante/lua/avante_$module.so"
      if [ ! -f "$lib" ] || [ ! -s "$lib" ] || [ -L "$lib" ]; then
        runtime_ok=0
        break
      fi
    done
    if [ "$runtime_ok" -eq 1 ]; then
      cleanup_dir "Avante (compilación Rust)" "$avante/target/release"
    fi
  fi

  # Cargo puede volver a extraer las fuentes de los paquetes .crate.
  cleanup_dir "Cargo (fuentes extraídas)" "$registry_src"
}

cleanup_steam_shaders() {
  local root="$1" app_dir cache
  [ -d "$root" ] && [ ! -L "$root" ] || return 0
  if pgrep -u "$UID" -x steam >/dev/null; then
    echo -e "  ${YELLOW}Cierra Steam para limpiar sus shaders.${NC}"
    return 0
  fi

  for app_dir in "$root"/*; do
    [[ -d "$app_dir" && ! -L "$app_dir" && "${app_dir##*/}" =~ ^[0-9]+$ ]] || continue
    for cache in "$app_dir"/fozpipelinesv*; do
      cleanup_dir "Steam shaders ${app_dir##*/}" "$cache"
    done
  done
}

# ── Coredumps systemd ──────────────────────────────────────────────────
cleanup_coredumps() {
  [ "$DRY_RUN" -eq 1 ] && { echo -e "  ${CYAN}[DRY-RUN]${NC} cleanup_coredumps"; return; }
  local dir="/var/lib/systemd/coredump"
  [ -d "$dir" ] || return
  local size bytes
  size=$(sudo du -sh "$dir" 2>/dev/null | cut -f1 || echo "0B")
  bytes=$(sudo du -sb "$dir" 2>/dev/null | cut -f1 || echo "0")
  [ -z "$size" ] && size="0B"
  [ -z "$bytes" ] && bytes=0
  echo -ne "Cleaning coredumps... found ${RED}$size${NC}"
  sudo rm -f "$dir"/* &>/dev/null || true
  echo -e " ${GREEN}✓${NC}"
}

# ── OpenCode SQLite VACUUM / WIPE ──────────────────────────────────────
prune_opencode() {
  local oc_share="$HOME/.local/share/opencode"
  local oc_cache="$HOME/.cache/opencode"
  [ -d "$oc_share" ] || return 0

  local total=0
  total=$(( total + $(du -sb "$oc_share" 2>/dev/null | cut -f1 || echo 0) ))
  [ -d "$oc_cache" ] && total=$(( total + $(du -sb "$oc_cache" 2>/dev/null | cut -f1 || echo 0) ))

  echo -e "\n${BLUE}OpenCode${NC}"
  echo -e "  ${YELLOW}OpenCode ocupa:${NC} ${RED}$(human "$total" 2>/dev/null || echo "0B")${NC}"

  local dbs
  dbs=$(find "$oc_share" -maxdepth 1 -name '*.db' 2>/dev/null) || dbs=""
  [ -n "$dbs" ] && echo -e "  ${YELLOW}Bases de datos:${NC}"
  for db in $dbs; do
    sz=$(stat -c %s "$db" 2>/dev/null || echo 0)
    free_bytes=$(python3 -c "
import sqlite3, sys
try:
    c = sqlite3.connect('file:' + sys.argv[1] + '?mode=ro', uri=True)
    ps = c.execute('PRAGMA page_size').fetchone()[0]
    fl = c.execute('PRAGMA freelist_count').fetchone()[0]
    c.close(); print(ps * fl)
except Exception:
    print(0)
" "$db" 2>/dev/null || echo 0)
    [ -z "$free_bytes" ] && free_bytes=0
    printf "    %-28s %8s   (freelist: %b)\n" \
           "$(basename "$db")" "$(human "$sz" 2>/dev/null || echo "0B")" "${YELLOW}$(human "$free_bytes" 2>/dev/null || echo "0B")${NC}"
  done

  if pgrep -u "$USER" -f 'opencode' &>/dev/null; then
    echo -e "  ${RED}⚠ opencode CORRIENDO. VACUUM fallará (lock exclusivo).${NC}"
  fi

  local mode
  echo -e "\n  ${YELLOW}Opciones:${NC}"
  echo -e "    ${GREEN}[v]${NC} VACUUM  — compacta BD (conserva historial)"
  echo -e "    ${RED}[w]${NC} WIPE    — borra sesiones + eventos, luego compacta"
  echo -e "    ${NC}[n]${NC} nada"
  if [ ! -t 0 ]; then
    echo -e "  ${YELLOW}Sin stdin interactivo, omitiendo OpenCode${NC}"
    return
  fi
  read -r -p "  Elige [v/w/n]: " mode || mode=n
  case "$mode" in v|V|w|W) ;; *) echo -e "  ${YELLOW}OpenCode: omitido${NC}"; return ;; esac

  local wipe=0; case "$mode" in w|W) wipe=1 ;; esac

  for db in $dbs; do
    echo -ne "  Processing $(basename "$db")...."
    python3 -c "
import sqlite3, sys
db = sys.argv[1]; wipe = int(sys.argv[2])
try:
    con = sqlite3.connect(db)
    cur = con.cursor()
    if wipe:
        cur.execute('PRAGMA foreign_keys = ON')
        cur.execute('DELETE FROM session')
        cur.execute('DELETE FROM event_sequence')
        con.commit()
    con.execute('VACUUM')
    con.commit()
    con.close()
    print('OK')
except Exception as e:
    print('ERROR: ' + str(e))
" "$db" "$wipe" 2>&1 | sed "s/^/${GREEN}${NC}/;s/ERROR:/${RED}${NC}/" || true
  done

  cleanup_dir "OpenCode log"      "$oc_share/log" || true
  cleanup_dir "OpenCode snapshot" "$oc_share/snapshot" || true
  cleanup_dir "OpenCode session_diff" "$oc_share/storage/session_diff" || true
  [ -d "$oc_cache/packages" ] && cleanup_dir "OpenCode cache packages" "$oc_cache/packages" || true

  if [ "$wipe" -eq 1 ]; then
    echo -e "  ${RED}✓ sesiones y eventos borrados${NC}"
  else
    echo -e "  ${GREEN}✓ BD compactada (historial conservado)${NC}"
  fi
}

# ── Flatpak pinned runtimes ────────────────────────────────────────────
cleanup_flatpak_pinned() {
  command -v flatpak >/dev/null || return 0
  echo -e "\n${BLUE}Flatpak: runtimes pinned...${NC}"
  local out
  out=$(flatpak uninstall --unused -y 2>&1) || true
  if echo "$out" | grep -q 'pinned'; then
    echo -e "  ${YELLOW}⚠ runtimes PINNED detectados:${NC}"
    echo "$out" | grep 'runtime/' | while IFS= read -r r; do
      [ -z "$r" ] && continue
      printf "      %-48s " "$(basename "$r")"
      flatpak unpin "$r" &>/dev/null && echo "${GREEN}despinned${NC}" || echo "${YELLOW}(no se pudo)${NC}"
    done
    echo -e "  ${YELLOW}   re-ejecutar para liberarlos${NC}"
  else
    echo -e "  ${GREEN}✓ unused${NC}"
  fi
  echo -ne "  Cleaning Flatpak integrity (repair)..."
  flatpak repair --user &>/dev/null && echo -e " ${GREEN}✓${NC}" || echo -e " ${YELLOW}(omitido)${NC}"
}

# ── Symlinks rotos ────────────────────────────────────────────────────
cleanup_stale_symlinks() {
  echo -e "\n${BLUE}Symlinks rotos en \$HOME...${NC}"
  local count=0 lnp
  for lnp in "$HOME/result" "$HOME/.nix-defexpr" "$HOME/.local/share/Steam"/*/; do
    [ -L "$lnp" ] && [ ! -e "$lnp" ] && { echo -ne "  Cleaning $(basename "$lnp") (roto)..."; rm -f "$lnp"; echo -e " ${GREEN}✓${NC}"; count=$((count+1)); }
  done
  [ "$count" -eq 0 ] && echo -e "  ${GREEN}✓ ninguno${NC}"
}

# ── Bottles runners huérfanos ─────────────────────────────────────────
PROTECTED_GAMES="Hollow Knight Hollow Knight Silksong"
PROTECTED_VAR_APPS="com.usebottles.bottles"

cleanup_bottles_runners() {
  local bbase="$HOME/.var/app/com.usebottles.bottles/data/bottles"
  [ -d "$bbase/runners" ] || return 0
  local used="" y r name total=0
  for y in "$bbase"/bottles/*/bottle.yml; do
    [ -f "$y" ] || continue
    r=$(sed -n 's/^Runner:[[:space:]]*//p' "$y" 2>/dev/null) || r=""
    [ -n "$r" ] && used="$used $r"
  done
  [ -z "$used" ] && used="(ninguna)"
  echo -e "  ${YELLOW}Runners en uso:${NC} $used"
  for r in "$bbase/runners"/*; do
    [ -d "$r" ] || continue
    name=$(basename "$r"); [ "$name" = "LICENSE" ] && continue
    case " $used " in *" $name "*)
      echo -ne "  Cleaning Bottles runner $name... (EN USO) "; echo -e "${YELLOW}conservado${NC}"; continue ;;
    esac
    size=$(du -sh "$r" 2>/dev/null | cut -f1) || size=""
    bytes=$(du -sb "$r" 2>/dev/null | cut -f1) || bytes=0
    [ -z "$bytes" ] && bytes=0
    echo -ne "  Cleaning Bottles runner $name... found ${RED}$size${NC}"
    rm -rf "$r" 2>/dev/null || true
    echo -e " ${GREEN}✓${NC}"
    total=$(( total + bytes )) 2>/dev/null || true
  done
  [ "$total" -gt 0 ] 2>/dev/null && echo -e "  ${GREEN}✓ runners huerfanos: $(human "$total" 2>/dev/null || echo "0B")${NC}"
}

# ── Bottles space report ──────────────────────────────────────────────
report_bottles_space() {
  local bbase="$HOME/.var/app/com.usebottles.bottles/data/bottles"
  [ -d "$bbase" ] || return 0
  local total=0 free_prot=0 used="" y r sz gsz gn
  total=$(du -sb "$bbase" 2>/dev/null | cut -f1) || total=0
  [ -n "$total" ] || total=0
  echo -e "\n${BLUE}═══════════ BOTTLES: espacio a liberar ═══════════${NC}"
  printf "    %-42s %10s\n" "Bottles total" "$(human "$total" 2>/dev/null || echo "0B")"
  for y in "$bbase"/bottles/*/bottle.yml; do
    [ -f "$y" ] || continue
    r=$(sed -n 's/^Runner:[[:space:]]*//p' "$y" 2>/dev/null) || r=""
    [ -n "$r" ] && used="$used $r"
  done
  for r in "$bbase"/runners/*; do
    [ -d "$r" ] || continue
    case " $used " in *" $(basename "$r") "*) continue ;; esac
    sz=$(du -sb "$r" 2>/dev/null | cut -f1) || sz=0
    [ -n "$sz" ] || sz=0
    free_prot=$(( free_prot + sz )) 2>/dev/null || true
  done
  [ "$free_prot" -gt 0 ] 2>/dev/null && printf "    %-42s %10b\n" "runners huerfanos" "${GREEN}$(human "$free_prot" 2>/dev/null || echo "0B")${NC}" || true
  for y in "$bbase"/bottles/*/; do
    [ -d "$y" ] || continue
    name=$(basename "$y"); [ "$name" = "bottles" ] && continue
    sz=$(du -sb "$y" 2>/dev/null | cut -f1) || sz=0
    [ -n "$sz" ] || sz=0
    printf "    %-42s %10s\n" "  botella: $name" "$(human "$sz" 2>/dev/null || echo "0B")" || true
    if [ -d "$y/drive_c/Games" ]; then
      for g in "$y/drive_c/Games"/*/; do
        [ -d "$g" ] || continue
        gsz=$(du -sb "$g" 2>/dev/null | cut -f1) || gsz=0
        gn=$(basename "$g")
        case " $PROTECTED_GAMES " in
          *" $gn "*) printf "      %-40s %8b  %b\n" "$gn" "$(human "$gsz" 2>/dev/null || echo "0B")" "${GREEN}[PROTEGIDO]${NC}" ;;
          *) printf "      %-40s %8s  %b\n" "$gn" "$(human "$gsz" 2>/dev/null || echo "0B")" "${YELLOW}(borrable)${NC}" ;;
        esac
      done
    fi
  done
  echo || true
  printf "    %-42s %10b\n" "LIBERABLE SIN JUEGOS" "${GREEN}$(human "$free_prot" 2>/dev/null || echo "0B")${NC}" || true
  printf "    %-42s %10s\n" "JUEGOS PROTEGIDOS" "$(human 0)" || true
  echo -e "  ${YELLOW}Para liberar más: borra el juego desde Bottles o rm -rf${NC}" || true
}

# ── ~/.var/app report ─────────────────────────────────────────────────
report_var_space() {
  local vard="$HOME/.var/app" total sz
  [ -d "$vard" ] || return 0
  total=$(du -sb "$vard" 2>/dev/null | cut -f1) || total=0
  [ -n "$total" ] || total=0
  echo -e "\n${BLUE}═══════════ ~/.var/app: ocupacion ═══════════${NC}"
  printf "    %-42s %10s\n" "Apps flatpak (datos)" "$(human "$total" 2>/dev/null || echo "0B")"
  for p in "$vard"/*/; do
    [ -d "$p" ] || continue
    name=$(basename "$p")
    sz=$(du -sb "$p" 2>/dev/null | cut -f1) || sz=0
    [ -n "$sz" ] || sz=0
    [ -z "$sz" ] || [ "$sz" -lt 1048576 ] 2>/dev/null && continue
    case " $PROTECTED_VAR_APPS " in
      *" $name "*) printf "    %-42s %10b\n" "  $name" "${GREEN}$(human "$sz" 2>/dev/null || echo "0B")${NC} [PROTEGIDO]" ;;
      *) printf "    %-42s %10s\n" "  $name" "$(human "$sz" 2>/dev/null || echo "0B")" ;;
    esac
  done
  echo -e "  ${YELLOW}Bottles se detalla aparte. Repo real: ~/.local/share/flatpak${NC}" || true
}

# ── Flatpak unused + pinned ───────────────────────────────────────────
cleanup_flatpak_unused() { cleanup_flatpak_pinned; }

# ── Symlinks rotos ────────────────────────────────────────────────────
cleanup_stale_symlinks() {
  echo -e "\n${BLUE}Symlinks rotos en \$HOME...${NC}"
  local count=0 lnp
  for lnp in "$HOME/result" "$HOME/.nix-defexpr" "$HOME/.local/share/Steam"/*/; do
    [ -L "$lnp" ] && [ ! -e "$lnp" ] && { echo -ne "  Cleaning $(basename "$lnp") (roto)..."; rm -f "$lnp"; echo -e " ${GREEN}✓${NC}"; count=$((count+1)); }
  done
  [ "$count" -eq 0 ] && echo -e "  ${GREEN}✓ ninguno${NC}"
}

# ── /tmp selective (NO wipe total) ────────────────────────────────────
cleanup_tmp_selective() {
  echo -e "\n${BLUE}/tmp (selectivo, respeta systemd-tmpfiles)${NC}"
  cleanup_dir "tmp user cache" "$HOME/.cache/tmp" 2>/dev/null || true
  echo -e "  ${YELLOW}systemd-tmpfiles limpia /tmp automáticamente (timer diario).${NC}"
  echo -e "  ${YELLOW}Para forzar: sudo systemd-tmpfiles --clean${NC}"
}

# ── rpm-ostree cleanup -r (fail-safe) ─────────────────────────────────
cleanup_rpm_ostree_rollback() {
  echo -e "\n${BLUE}rpm-ostree rollback deployment...${NC}"
  local current rollback
  current=$(rpm-ostree status --json 2>/dev/null | python3 -c "
import json,sys; d=json.load(sys.stdin); [print(x.get('version')) for x in d.get('deployments',[]) if x.get('booted')]"
  ) || current=""
  rollback=$(rpm-ostree status --json 2>/dev/null | python3 -c "
import json,sys; d=json.load(sys.stdin); [print(x.get('version')) for x in d.get('deployments',[]) if not x.get('booted') and not x.get('staged')]"
  ) || rollback=""
  if [ -z "$rollback" ]; then
    echo -e "  ${GREEN}✓ sin rollback deployment${NC}"
    return
  fi
  echo -e "  Actual: ${GREEN}$current${NC} | Rollback: ${YELLOW}$rollback${NC}"
  printf "  ¿Eliminar rollback? [s/N] "
  if [ -r /dev/tty ]; then read -r ans < /dev/tty || ans=N; else ans=N; fi
  case "${ans:-N}" in s|S) sudo rpm-ostree cleanup -r; echo -e "  ${GREEN}✓ rollback eliminado${NC}" ;; *) echo -e "  ${YELLOW}conservado${NC}" ;; esac
}

# ── Boot cleanup offer ────────────────────────────────────────────────
offer_clean_boot() {
  echo -e "\n${BLUE}═══════════ /boot ═══════════${NC}"
  echo -e "  Kernels viejos, ncdu manual"
  if [ -t 0 ]; then
    read -r -p "  ¿Limpiar /boot manualmente? [y/N] " ans
  else
    ans=N
  fi
  case "${ans:-N}" in y|Y) sudo TERM=xterm-256color /usr/bin/ncdu /boot 2>/dev/null || sudo ls -la /boot;; *) echo -e "  ${YELLOW}omitido${NC}" ;; esac
}

# ── Main ──────────────────────────────────────────────────────────────
echo -e "${YELLOW}═══════════ Fedora / Bazzite — Limpieza del sistema ═══════════${NC}"

sec_mark

# dnf5
echo -e "\n${BLUE}dnf5...${NC}"
sudo dnf5 clean all 2>/dev/null || true
cleanup_dir "libdnf5" "$HOME/.cache/libdnf5" || true
sec_end "dnf5 clean" || true

sec_mark

# rpm-ostree metadata + temp
echo -e "\n${BLUE}rpm-ostree...${NC}"
sudo rpm-ostree cleanup -bm 2>/dev/null || true
sec_end "rpm-ostree -bm" || true

sec_mark

# Flatpak
echo -e "\n${BLUE}Flatpak...${NC}"
cleanup_flatpak_unused || true
flatpak repair --user &>/dev/null && echo -e "  ${GREEN}✓ repair${NC}" || true
sec_end "Flatpak" || true

sec_mark

# Journal
echo -e "\n${BLUE}Journal...${NC}"
journalctl --vacuum-size=200M &>/dev/null || true
sec_end "journal" || true

sec_mark

# Coredumps
cleanup_coredumps || true
sec_end "coredumps" || true

sec_mark

# User caches
echo -e "\n${BLUE}~/.cache...${NC}"
cleanup_dir "thumbnails" "$HOME/.cache/thumbnails" || true
cleanup_dir "kwin" "$HOME/.cache/kwin" || true
cleanup_dir "plasma" "$HOME/.cache/plasma" || true
cleanup_dir "mesa_shader" "$HOME/.cache/mesa_shader_cache" || true
cleanup_dir "kwinsession" "$HOME/.cache/kwinsession.kcache" || true
cleanup_dir "qtshader" "$HOME/.cache/qtshadercache-x86_64-little_endian-lp64" || true
cleanup_dir "opencode" "$HOME/.cache/opencode" || true
cleanup_dir "vicinae" "$HOME/.cache/vicinae" || true
cleanup_dir "codex-runtimes" "$HOME/.cache/codex-runtimes" || true
cleanup_dir "flatpak" "$HOME/.cache/flatpak" || true
sec_end "~/.cache" || true

sec_mark

# Trash
cleanup_dir "Trash" "$HOME/.local/share/Trash" || true
sec_end "Trash" || true

sec_mark

# /tmp selective
cleanup_tmp_selective || true
sec_end "/tmp (selectivo)" || true

sec_mark

# Editors
echo -e "\n${BLUE}Editores...${NC}"
cleanup_dir "Cursor Cache" "$HOME/.config/Cursor/Cache" || true
cleanup_dir "Cursor Code Cache" "$HOME/.config/Cursor/Code Cache" || true
cleanup_dir "Cursor GPUCache" "$HOME/.config/Cursor/GPUCache" || true
cleanup_dir "Cursor logs" "$HOME/.config/Cursor/logs" || true
cleanup_dir "Antigravity Cache" "$HOME/.config/Antigravity IDE/Cache" || true
cleanup_dir "Antigravity CachedData" "$HOME/.config/Antigravity IDE/CachedData" || true
cleanup_dir "Antigravity GPUCache" "$HOME/.config/Antigravity IDE/GPUCache" || true
cleanup_dir "Vicinae cache" "$HOME/.cache/vicinae" || true
sec_end "Editores + Vicinae" || true

sec_mark

# Steam (no juegos)
cleanup_dir "Steam compat tools" "$HOME/.local/share/Steam/compatibilitytools.d" || true
cleanup_dir "Steam runtime.old" "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime.old" || true
cleanup_dir "Steam htmlcache" "$HOME/.local/share/Steam/config/htmlcache" || true
cleanup_steam_shaders "$HOME/.local/share/Steam/steamapps/shadercache"
# Conserva Steam/package: el cliente guarda ahi el manifiesto de instalacion.
sec_end "Steam (caches)" || true

sec_mark

# Bottles
cleanup_dir "Bottles temp" "$HOME/.var/app/com.usebottles.bottles/data/bottles/temp" || true
cleanup_dir "Bottles templates" "$HOME/.var/app/com.usebottles.bottles/data/bottles/templates" || true
cleanup_dir "Bottles cache" "$HOME/.var/app/com.usebottles.bottles/cache" || true
cleanup_dir "Bottles bottle cache" "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/gaming/cache" || true
sec_end "Bottles (caches)" || true

sec_mark

# Wine
cleanup_dir "Wine windows temp" "$HOME/.wine/drive_c/windows/temp" || true
cleanup_dir "Wine shadercache" "$HOME/.wine/shadercache" || true
for u in "$HOME"/.wine/drive_c/users/*/; do [ -d "$u" ] && cleanup_dir "Wine ${u##*/}Temp" "${u}Temp" || true; done
sec_end "Wine caches" || true

sec_mark

# Dev tools
echo -e "\n${BLUE}Dev tools...${NC}"
command -v npm >/dev/null && { npm cache clean --force &>/dev/null && echo -e "  ${GREEN}✓ npm${NC}" || true; }
command -v pip3 >/dev/null && { pip3 cache purge &>/dev/null && echo -e " ${GREEN}✓ pip${NC}" || true; }
cleanup_rust_caches "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/avante.nvim" "${CARGO_HOME:-$HOME/.cargo}/registry/src"
command -v bun >/dev/null && { bun pm cache rm &>/dev/null && echo -e " ${GREEN}✓ bun${NC}" || true; }
sec_end "Dev tools" || true

sec_mark

# OpenCode VACUUM
prune_opencode || true
sec_end "OpenCode" || true

sec_mark

# Bottles runners + reports
cleanup_bottles_runners || true
sec_end "Bottles runners" || true

sec_mark
report_bottles_space || true
sec_end "Bottles space report" || true

sec_mark
report_var_space || true
sec_end "~/.var/app report" || true

sec_mark
cleanup_flatpak_pinned || true
sec_end "Flatpak pinned" || true

sec_mark
cleanup_stale_symlinks || true
sec_end "Symlinks rotos" || true

sec_mark

# Docker
if command -v docker >/dev/null && docker info &>/dev/null; then
  docker system prune -a --volumes -f &>/dev/null || true
  echo -e "  ${GREEN}✓ Docker pruned${NC}"
  sec_end "Docker" || true
  sec_mark
fi

# rpm-ostree rollback
cleanup_rpm_ostree_rollback || true
sec_end "rpm-ostree rollback" || true

sec_mark

# Ujust clean-system
if command -v ujust >/dev/null && ujust clean-system 2>&1; then
  sec_end "ujust clean-system" || true
else
  echo -e "\n${BLUE}ujust clean-system...${NC}"
  ujust clean-system 2>&1 || true
  sec_end "ujust clean-system" || true
fi
sec_mark

# rpm-ostree cleanup -r + df
if [ -e /run/ostree-booted ] || command -v rpm-ostree >/dev/null 2>&1; then
  sec_mark
  echo -e "\n${BLUE}rpm-ostree cleanup -r (rollback deployment)...${NC}"
  current=$(rpm-ostree status --json 2>/dev/null | python3 -c "
import json,sys; d=json.load(sys.stdin); [print(x.get('version')) for x in d.get('deployments',[]) if x.get('booted')]"
  ) || current=""
  rollback=$(rpm-ostree status --json 2>/dev/null | python3 -c "
import json,sys; d=json.load(sys.stdin); [print(x.get('version')) for x in d.get('deployments',[]) if not x.get('booted') and not x.get('staged')]"
  ) || rollback=""
  if [ -z "$rollback" ]; then
    echo -e "  ${GREEN}✓ sin rollback deployment${NC}"
  else
    echo -e "  Actual: ${GREEN}$current${NC} | Rollback: ${YELLOW}$rollback${NC}"
    printf "  ¿Eliminar rollback? [s/N] "
    if [ -r /dev/tty ]; then read -r ans < /dev/tty || ans=N; else ans=N; fi
    case "${ans:-N}" in s|S) sudo rpm-ostree cleanup -r; echo -e "  ${GREEN}✓ rollback eliminado${NC}" ;; *) echo -e "  ${YELLOW}conservado${NC}" ;; esac
  fi
  df -h /var/home 2>/dev/null || true
  sec_end "rpm-ostree rollback + df" || true
  sec_mark
fi

# Boot
offer_clean_boot || true

# Summary
print_summary || true

echo -e "\n${GREEN}✓ Limpieza completada${NC}"