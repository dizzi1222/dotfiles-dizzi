#!/usr/bin/env bash
# nixconf-cleanup: limpieza de disco de un solo comando (ghaerdi)
# Versión .sh standalone (convertida desde writeShellScriptBin de Nix).

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting System Cleanup...${NC}"

# ── Contabilidad de espacio ────────────────────────────────────
# FOUND_TOTAL : suma de los "found <size>" (espacio POSIBLE a liberar)
# FREED_TOTAL : delta real de espacio libre del filesystem
# SEC_LABELS/_VALUES : desglose por sección para el resumen final
ROOT_FS="/"
# Raíz del flake: donde viven features/*.nix y home.nix. Override con NIXCONF_DIR=...
NIXCONF_DIR="${NIXCONF_DIR:-$HOME/dotfiles-dizzi/nixconf}"
# Cuántos paquetes residentes mostrar (override con RESIDENTS_TOP=N).
RESIDENTS_TOP="${RESIDENTS_TOP:-60}"
FOUND_TOTAL=0
FREED_TOTAL=0
FREED_TOTAL_START=$(df -B1 --output=avail "$ROOT_FS" 2>/dev/null | sed -n '$p' | tr -d ' ')
SEC_MARK=$FREED_TOTAL_START
SEC_LABELS=()
SEC_VALUES=()

# Convierte bytes a legible (1.2G, 782M, 4.0K)
human() { numfmt --to=iec --suffix=B "${1:-0}" 2>/dev/null || echo "${1:-0}B"; }

# Borra los coredumps de systemd. Necesita sudo.
cleanup_coredumps() {
  local dir="/var/lib/systemd/coredump"
  [ -d "$dir" ] || return
  local size bytes
  size=$(sudo du -sh "$dir" 2>/dev/null | cut -f1)
  [ -z "$size" ] && size="0B"
  bytes=$(sudo du -sb "$dir" 2>/dev/null | cut -f1)
  [ -z "$bytes" ] && bytes=0
  if [ "$bytes" -gt 0 ] 2>/dev/null; then
    FOUND_TOTAL=$(( FOUND_TOTAL + bytes ))
  fi
  echo -ne "Cleaning coredumps... found ${RED}$size${NC}"
  # `coredumpctl delete/purge` NO existe en este systemd-coredump: se borra a mano.
  sudo rm -f "$dir"/* &> /dev/null
  echo -e " ${GREEN}✓${NC}"
}

# Al final: ofrece el limpiador de /boot (vive en ~/.local/bin).
offer_clean_boot() {
  local reply
  echo -e "\n${BLUE}═══════════ /boot ═══════════${NC}"
  echo -e "  Kernels viejos en EFI, generaciones Nix y ncdu manual"
  if [ ! -x "$HOME/.local/bin/clean-boot" ]; then
    echo -e "  ${YELLOW}clean-boot no encontrado — omitido${NC}"
    return
  fi
  read -r -p "  ¿Limpiar manualmente Boot? [y/N] " reply
  case "$reply" in
    y|Y) echo; sudo "$HOME/.local/bin/clean-boot" ;;
    *) echo -e "  ${YELLOW}Boot: omitido${NC}" ;;
  esac
}

disk_free() { df -B1 --output=avail "$ROOT_FS" 2>/dev/null | sed -n '$p' | tr -d ' '; }

# Marca el inicio de una sección de limpieza
sec_mark() { SEC_MARK=$(disk_free); }

# Cierra la sección: acumula el delta real y lo imprime
sec_end() {
  local label="$1"
  local after; after=$(disk_free)
  # Al BORRAR el espacio libre AUMENTA: delta = after - SEC_MARK
  local freed=$(( after - SEC_MARK ))
  [ "$freed" -lt 0 ] && freed=0
  SEC_MARK=$after
  FREED_TOTAL=$(( FREED_TOTAL + freed ))
  SEC_LABELS+=("$label")
  SEC_VALUES+=("$freed")
  if [ "$freed" -gt 0 ]; then
    printf "   %-36s %10b\n" "$label" "${GREEN}$(human "$freed")${NC}"
  else
    printf "   %-36s %10s\n" "$label" "0B"
  fi
}

# Resumen final: posible a liberar vs realmente liberado
print_summary() {
  local now; now=$(disk_free)
  local delta=$(( now - FREED_TOTAL_START ))
  [ "$delta" -lt 0 ] && delta=0

  echo -e "\n${BLUE}═══════════ ESPACIO ═══════════${NC}"
  echo -e "${YELLOW}  Recuento por sección:${NC}"
  for i in "${!SEC_LABELS[@]}"; do
    printf "    %-38s %10s\n" "${SEC_LABELS[$i]}" "$(human "${SEC_VALUES[$i]}")"
  done

  echo -e "${YELLOW}  Totales:${NC}"
  printf "    %-38s %10s\n" "Espacio POSIBLE a liberar (found)" "$(human "$FOUND_TOTAL")"
  printf "    %-38s %10s\n" "Liberado por secciones (suma)"      "$(human "$FREED_TOTAL")"
  printf "    %-38s %10s  ${GREEN}← este es el real${NC}\n" \
         "LIBERADO TOTAL (delta disco)"               "$(human "$delta")"
  echo
  printf "    %-38s %10s\n" "Disco libre ANTES" "$(human "$FREED_TOTAL_START")"
  printf "    %-38s %10s\n" "Disco libre AHORA" "$(human "$now")"
  echo
  df -h "$ROOT_FS" | sed -n '1,2p'
}

# Helper: limpia el contenido de un directorio (conserva el directorio)
cleanup_dir() {
  name=$1
  path=$2

  if [ -d "$path" ]; then
    size=$(du -sh "$path" 2>/dev/null | cut -f1)
    bytes=$(du -sb "$path" 2>/dev/null | cut -f1)
    if [ -z "$size" ]; then size="0B"; fi
    if [ -z "$bytes" ]; then bytes=0; fi

    if [ "$bytes" -gt 0 ] 2>/dev/null; then
      FOUND_TOTAL=$(( FOUND_TOTAL + bytes ))
    fi

    echo -ne "Cleaning $name cache... found ${RED}$size${NC}"
    find "$path" -mindepth 1 -delete 2>/dev/null
    echo -e " ${GREEN}✓${NC}"
  fi
}

# ── Prune OpenCode ────────────────────────────────────────────
# Reporta cuánto ocupa OpenCode y ofrece:
#   [v] VACUUM -> compacta la BD (recupera el freelist)
#   [w] WIPE   -> borra TODAS las sesiones + eventos, luego VACUUM
#   [n] nada
# VACUUM necesita lock EXCLUSIVO: si opencode corre, falla.
prune_opencode() {
  local oc_share="$HOME/.local/share/opencode"
  local oc_cache="$HOME/.cache/opencode"
  [ -d "$oc_share" ] || return

  local total=0
  total=$(( total + $(du -sb "$oc_share" 2>/dev/null | cut -f1 || echo 0) ))
  [ -d "$oc_cache" ] && total=$(( total + $(du -sb "$oc_cache" 2>/dev/null | cut -f1 || echo 0) ))

  echo -e "\n${BLUE}OpenCode${NC}"
  echo -e "  ${YELLOW}OpenCode ocupa:${NC} ${RED}$(human "$total")${NC}"

  local p
  for p in "$oc_share" "$oc_cache"; do
    [ -d "$p" ] || continue
    printf "    %-28s %8s\n" "${p/#$HOME\//}" "$(du -sh "$p" 2>/dev/null | cut -f1)"
  done

  local dbs db sz free_bytes
  dbs=$(find "$oc_share" -maxdepth 1 -name '*.db' 2>/dev/null)
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
    printf "    %-28s %8s   (freelist recuperable: %b)\n" \
           "$(basename "$db")" "$(human "$sz")" "${YELLOW}$(human "$free_bytes")${NC}"
  done

  if pgrep -u "$USER" -f 'opencode' &> /dev/null; then
    echo -e "  ${RED}⚠  opencode está CORRIENDO.${NC} VACUUM necesita lock exclusivo y fallará."
  fi

  local mode
  echo -e "\n  ${YELLOW}Opciones:${NC}"
  echo -e "    ${GREEN}[v]${NC} VACUUM  — compacta la BD (conserva el historial)"
  echo -e "    ${RED}[w]${NC} WIPE   — borra TODAS las sesiones + eventos, luego compacta"
  echo -e "    ${NC}[n]${NC} nada   — saltar OpenCode"
  read -r -p "  Elige [v/w/n]: " mode

  case "$mode" in
    v|V|w|W) ;;
    *) echo -e "  ${YELLOW}OpenCode: omitido${NC}"; return ;;
  esac

  local wipe=0
  case "$mode" in w|W) wipe=1 ;; esac

  for db in $dbs; do
    echo -ne "  Processing $(basename "$db")..."
    python3 -c "
import sqlite3, sys
db = sys.argv[1]; wipe = int(sys.argv[2])
try:
    con = sqlite3.connect(db)
    cur = con.cursor()
    if wipe:
        # Las FKs están desactivadas en esta DB: hay que activarlas para el CASCADE.
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
" "$db" "$wipe" 2>&1 | sed "s/^/${GREEN}${NC}/;s/ERROR:/${RED}${NC}/"
  done

  cleanup_dir "OpenCode log"          "$oc_share/log"
  cleanup_dir "OpenCode snapshot"     "$oc_share/snapshot"
  cleanup_dir "OpenCode session_diff" "$oc_share/storage/session_diff"
  [ -d "$oc_cache/packages" ] && cleanup_dir "OpenCode cache packages" "$oc_cache/packages"

  if [ "$wipe" -eq 1 ]; then
    echo -e "  ${RED}✓ sesiones y eventos borrados${NC}"
  else
    echo -e "  ${GREEN}✓ BD compactada (historial conservado)${NC}"
  fi
}

# ── Paquetes residentes ────────────────────────────────────────
# Reporta qué ocupa espacio en el closure de home-manager y NO es parte del
# system profile de NixOS. SOLO LECTURA: no borra nada.
# Flujo para sacar algo: comentar en el .nix -> home-manager switch -> nix-collect-garbage -d
# Trampa que detecta: comentar un paquete de home.packages NO lo saca del store
# si sigue referenciado como pkgs.X en otro sitio (sessionVariables, aliases...).

# Paquetes que JAMÁS deben quedar residentes -> alerta roja si reaparecen.
NEVER_RESIDENT="
cypress
chromedriver
geckodriver
pgadmin4
postman
libreoffice
mongodb-compass
mongodb-tools
google-cloud-sdk
google-cloud-sql-proxy
playwright-chromium
playwright-firefox
playwright-webkit
playwright-chromium-headless
playwright-browsers
kate
"

# Índice de la config: paquete -> "archivo:linea:ESTADO:tipo"
#   REF   = referencia pkgs.X fuera de la lista (invisible)
#   LISTA = línea suelta de una lista de paquetes
# ESTADO = LIVE (sin comentar) o COMMENT (comentada)
_residents_build_index() {
  local idx="$1" f line ln name st base
  : > "$idx"
  for f in "$NIXCONF_DIR"/home-manager/features/*.nix \
           "$NIXCONF_DIR"/home-manager/home.nix; do
    [ -f "$f" ] || continue
    base="${f#$NIXCONF_DIR/}"
    ln=0
    while IFS= read -r line; do
      ln=$(( ln + 1 ))
      st=LIVE
      case "$line" in
        \#*) st=COMMENT ;;
      esac
      # referencias pkgs.NOMBRE (pueden ser varias por línea)
      for name in $(printf '%s' "$line" \
                     | grep -oE '\$\{?pkgs\.[A-Za-z0-9_.-]+' \
                     | sed 's/.*pkgs\.//' | sort -u); do
        printf '%s\t%s\t%s\t%s\tREF\n' \
               "$name" "$base" "$ln" "$st" >> "$idx"
      done
      # líneas "sueltas" de listas de paquetes (sangría 4+ espacios, un token),
      # incluidas las ya comentadas (estado COMMENT).
      for name in $(printf '%s' "$line" \
                     | sed -n -e 's/^[[:space:]]\{4,\}\([a-zA-Z0-9_][a-zA-Z0-9_.-]*\)[[:space:]]*\(#.*\)\{0,1\}$/\1/p' \
                            -e 's/^[[:space:]]\{4,\}#[[:space:]]*\([a-zA-Z0-9_][a-zA-Z0-9_.-]*\).*/\1/p'); do
        printf '%s\t%s\t%s\t%s\tLISTA\n' \
               "$name" "$base" "$ln" "$st" >> "$idx"
      done
    done < "$f"
  done
  sort -u -o "$idx" "$idx"
}

# Reporte de residentes. Solo lectura.
residents_report() {
  local gen sysd tmp idx top helper n_only
  top="${RESIDENTS_TOP:-12}"
  gen=$(readlink -f "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null)
  sysd="/nix/var/nix/profiles/system"
  helper="$NIXCONF_DIR/scripts/nixconf-residents.py"

  if [ -z "$gen" ] || [ ! -e "$gen" ]; then
    echo -e "  ${YELLOW}✗ home-manager profile no encontrado — reporte omitido${NC}"
    return
  fi
  if [ ! -d "$NIXCONF_DIR" ]; then
    echo -e "  ${YELLOW}✗ NIXCONF_DIR ausente ($NIXCONF_DIR) — sin mapeo a la config${NC}"
    return
  fi
  if [ ! -f "$helper" ]; then
    echo -e "  ${RED}✗ falta el helper $helper${NC}"
    return
  fi
  if ! command -v nix-store &> /dev/null; then
    echo -e "  ${YELLOW}✗ nix-store no disponible — reporte omitido${NC}"
    return
  fi

  tmp=$(mktemp -d)
  idx="$tmp/index"

  echo -ne "  Calculando closure(gen) - closure(system)..."
  sudo nix-store -qR "$sysd" 2>/dev/null | sort -u > "$tmp/sys"
  sudo nix-store -qR "$gen"  2>/dev/null | sort -u > "$tmp/hm"
  comm -13 "$tmp/sys" "$tmp/hm" > "$tmp/only"
  n_only=$(wc -l < "$tmp/only")
  if [ "$n_only" -eq 0 ]; then
    echo -e " ${GREEN}✓${NC}"
    rm -rf "$tmp"
    return
  fi
  echo -e " ${GREEN}✓${NC} ${YELLOW}($n_only paths solo-home)${NC}"

  _residents_build_index "$idx"
  echo -e "  ${YELLOW}Índice de la config:${NC} $(wc -l < "$idx") referencias mapeadas"

  # El parser de Python vive en un archivo real del repo (nixconf-residents.py).
  sudo nix path-info --json $(cat "$tmp/only") 2>/dev/null > "$tmp/s.json"
  chmod 644 "$tmp/s.json" 2>/dev/null || true

  python3 "$helper" \
          "$tmp/s.json" "$idx" "$top" \
          "$NEVER_RESIDENT" 2>&1 | while IFS= read -r l; do
    case "$l" in
      __ALERT*) echo -e "  ${RED}${l#__ALERT}${NC}" ;;
      __WARN*)  echo -e "  ${YELLOW}${l#__WARN}${NC}" ;;
      __OK*)    echo -e "  ${GREEN}${l#__OK}${NC}" ;;
      *)        echo "  $l" ;;
    esac
  done

  rm -rf "$tmp"
}

# ── Flatpak: refs huérfanas y runtimes viejos ────────────────
# `flatpak uninstall --unused` solo quita lo que ninguna app referencia.
# Los runtimes PINNED se ignoran en silencio: se avisa y se des-pinean.
cleanup_flatpak_unused() {
  if ! command -v flatpak &> /dev/null; then return; fi

  echo -e "\n${BLUE}Flatpak: refs sin usar y runtimes viejos...${NC}"

  local fp_repo before_b
  fp_repo="$HOME/.local/share/flatpak"
  [ -d "$fp_repo" ] && before_b=$(du -sb "$fp_repo" 2>/dev/null | cut -f1)

  echo -ne "  Cleaning Flatpak unused (runtimes viejos, refs huérfanas)..."
  local out
  out=$(flatpak uninstall --unused -y 2>&1)
  if [ $? -eq 0 ]; then
    echo -e " ${GREEN}✓${NC}"
  else
    echo -e " ${RED}✗ fallo${NC}"
  fi

  # "pinned" = hay runtimes viejos que --unused no toca
  # (el original tenía un sed roto aquí; se reemplazó por un case)
  case "$out" in
    *pinned*)
      echo -e "  ${YELLOW}⚠  hay runtimes PINNED que no se pueden quitar:${NC}"
      echo "$out" | sed -n '/runtime\//p' | while IFS= read -r r; do
        [ -z "$r" ] && continue
        printf "      %-48s " "$(basename "$r")"
        if flatpak unpin "$r" &> /dev/null; then
          echo -e "${GREEN}despinned${NC}"
        else
          echo -e "${YELLOW}(no se pudo)${NC}"
        fi
      done
      echo -e "  ${YELLOW}   des-pineados ahora; corré el script de nuevo para liberarlos${NC}"
      ;;
  esac

  echo -ne "  Cleaning Flatpak integrity (repair)..."
  if flatpak repair --user &> /dev/null; then
    echo -e " ${GREEN}✓${NC}"
  else
    echo -e " ${YELLOW}(omitido)${NC}"
  fi

  if [ -n "$before_b" ] && [ -d "$fp_repo" ]; then
    local after_b
    after_b=$(du -sb "$fp_repo" 2>/dev/null | cut -f1)
    if [ -n "$after_b" ] && [ "$after_b" -lt "$before_b" ] 2>/dev/null; then
      echo -e "  ${GREEN}✓ repo flatpak: $(human $(( before_b - after_b ))) liberados${NC}"
    fi
  fi
}

# ── Symlinks rotos en $HOME (GC roots que impiden borrar paquetes) ──
cleanup_stale_symlinks() {
  echo -e "\n${BLUE}Symlinks rotos en \$HOME (trash de builds)...${NC}"
  local lnp count=0
  for lnp in "$HOME/result" "$HOME/.nix-defexpr" "$NIXCONF_DIR/result"; do
    if [ -L "$lnp" ] && [ ! -e "$lnp" ]; then
      echo -ne "  Cleaning $(basename "$(dirname "$lnp")")/$(basename "$lnp") (symlink roto)..."
      rm -f "$lnp" 2>/dev/null
      echo -e " ${GREEN}✓${NC}"
      count=$(( count + 1 ))
    fi
  done
  if [ "$count" -eq 0 ]; then
    echo -e "  ${GREEN}✓ ninguno${NC}"
  fi
}

# Juegos de Bottles que NO se tocan nunca (nombres EXACTOS de drive_c/Games).
PROTECTED_GAMES="Hollow Knight Hollow Knight Silksong"

# Apps flatpak en ~/.var/app marcadas como intocables.
PROTECTED_VAR_APPS="com.usebottles.bottles"

# ── Reporte de espacio de Bottles (solo informe) ────────────────
report_bottles_space() {
  local bbase total free_prot used y r name sz g gsz gn
  bbase="$HOME/.var/app/com.usebottles.bottles/data/bottles"
  [ -d "$bbase" ] || return

  total=$(du -sb "$bbase" 2>/dev/null | cut -f1)
  [ -z "$total" ] && return

  echo -e "\n${BLUE}═══════════ BOTTLES: espacio a liberar ═══════════${NC}"
  printf "    %-42s %10s\n" "Bottles total" "$(human "$total")"

  # runners en uso vs huérfanos
  used=""
  for y in "$bbase"/bottles/*/bottle.yml; do
    [ -f "$y" ] || continue
    r=$(sed -n 's/^Runner:[[:space:]]*//p' "$y" 2>/dev/null)
    [ -n "$r" ] && used="$used $r"
  done
  free_prot=0
  for r in "$bbase"/runners/*; do
    [ -d "$r" ] || continue
    name=$(basename "$r")
    case " $used " in
      *" $name "*) continue ;;
    esac
    sz=$(du -sb "$r" 2>/dev/null | cut -f1)
    [ -n "$sz" ] && free_prot=$(( free_prot + sz ))
  done
  if [ "$free_prot" -gt 0 ] 2>/dev/null; then
    printf "    %-42s %10b\n" "  runners huérfanos (se limpian ya)" "${GREEN}$(human "$free_prot")${NC}"
  fi

  local games_prot=0
  for y in "$bbase"/bottles/*/; do
    [ -d "$y" ] || continue
    name=$(basename "$y")
    [ "$name" = "bottles" ] && continue
    sz=$(du -sb "$y" 2>/dev/null | cut -f1)
    printf "    %-42s %10s\n" "  botella: $name" "$(human "$sz")"
    if [ -d "$y/drive_c/Games" ]; then
      for g in "$y/drive_c/Games"/*/; do
        [ -d "$g" ] || continue
        gsz=$(du -sb "$g" 2>/dev/null | cut -f1)
        gn=$(basename "$g")
        case " $PROTECTED_GAMES" in
          *" $gn"*)
            games_prot=$(( games_prot + gsz ))
            printf "      %-40s %8s  %b\n" "$gn" "$(human "$gsz")" "${GREEN}[PROTEGIDO]${NC}"
            ;;
          *)
            printf "      %-40s %8s  %b\n" "$gn" "$(human "$gsz")" "${YELLOW}(borrable a mano)${NC}"
            ;;
        esac
      done
    fi
  done

  echo
  printf "    %-42s %10b\n" "LIBERABLE SIN TOCAR JUEGOS" "${GREEN}$(human "$free_prot")${NC}"
  printf "    %-42s %10s\n" "JUEGOS PROTEGIDOS (intocables)" "$(human "$games_prot")"
  echo -e "    ${YELLOW}Para liberar más: borra el juego desde Bottles o rm -rf${NC}"
  echo -e "    ${YELLOW}  la carpeta dentro de drive_c/Games. Requiere que Bottles esté cerrado.${NC}"
}

# ── Reporte de ~/.var/app (datos de apps flatpak) ───────────────
report_var_space() {
  local vard total p sz name
  vard="$HOME/.var/app"
  [ -d "$vard" ] || return

  total=$(du -sb "$vard" 2>/dev/null | cut -f1)
  [ -z "$total" ] && return

  echo -e "\n${BLUE}═══════════ ~/.var/app: ocupación ═══════════${NC}"
  printf "    %-42s %10s\n" "Apps flatpak (datos, no el repo)" "$(human "$total")"
  echo

  for p in "$vard"/*/; do
    [ -d "$p" ] || continue
    name=$(basename "$p")
    sz=$(du -sb "$p" 2>/dev/null | cut -f1)
    # menos de 1 MB = stubs vacíos de flatpak
    [ -n "$sz" ] && [ "$sz" -lt 1048576 ] 2>/dev/null && continue
    case " $PROTECTED_VAR_APPS " in
      *" $name "*)
        printf "    %-42s %10b\n" "  $name" "${GREEN}$(human "$sz")${NC} [PROTEGIDO]"
        ;;
      *)
        printf "    %-42s %10s\n" "  $name" "$(human "$sz")"
        ;;
    esac
  done
  echo
  echo -e "  ${YELLOW}Bottles se detalla aparte (ver sección BOTTLES).${NC}"
  echo -e "  ${YELLOW}El repo flatpak real: ~/.local/share/flatpak (lo limpia cleanup_flatpak_unused).${NC}"
}

# ── Runners de Bottles no usados ───────────────────────────────
# Un runner es HUÉRFANO si ninguna botella lo declara en bottle.yml (`Runner:`).
# Borrarlo NO toca los juegos (viven en bottles/bottles/<nombre>/drive_c/).
cleanup_bottles_runners() {
  local bbase runners y used r name size bytes total=0
  bbase="$HOME/.var/app/com.usebottles.bottles/data/bottles"
  runners="$bbase/runners"
  [ -d "$runners" ] || return

  used=""
  for y in "$bbase"/bottles/*/bottle.yml; do
    [ -f "$y" ] || continue
    r=$(sed -n 's/^Runner:[[:space:]]*//p' "$y" 2>/dev/null)
    [ -n "$r" ] && used="$used $r"
  done

  [ -z "$used" ] && used="(ninguna)"
  echo -e "  ${YELLOW}Runners en uso por alguna botella:${NC} $used"

  for r in "$runners"/*; do
    [ -d "$r" ] || continue
    name=$(basename "$r")
    [ "$name" = "LICENSE" ] && continue

    case " $used " in
      *" $name "*)
        echo -ne "Cleaning Bottles runner $name... (EN USO) "
        echo -e "${YELLOW}conservado${NC}"
        continue
        ;;
    esac

    size=$(du -sh "$r" 2>/dev/null | cut -f1)
    bytes=$(du -sb "$r" 2>/dev/null | cut -f1)
    [ -z "$bytes" ] && bytes=0
    total=$(( total + bytes ))
    if [ "$bytes" -gt 0 ] 2>/dev/null; then
      FOUND_TOTAL=$(( FOUND_TOTAL + bytes ))
    fi
    echo -ne "Cleaning Bottles runner $name... found ${RED}$size${NC}"
    rm -rf "$r" 2>/dev/null
    echo -e " ${GREEN}✓${NC}"
  done

  if [ "$total" -gt 0 ] 2>/dev/null; then
    echo -e "  ${GREEN}✓ runners huérfanos eliminados: $(human "$total")${NC}"
  fi
}

# ── /tmp wipe completo ─────────────────────────────────────────
# ⚠  PELIGRO: /tmp contiene sockets VIVOS (kitty-*, .X11-unix, systemd-private-*,
#    sddm-auth-*). Esto ROMPE la sesión actual. Se pide confirmación (10s).
cleanup_tmp() {
  local size reply
  size=$(sudo du -sh /tmp 2>/dev/null | cut -f1)
  if [ -z "$size" ]; then size="0B"; fi

  echo -e "\n${RED}${YELLOW}⚠  /tmp contiene sockets VIVOS: kitty-*, .X11-unix, systemd-private-*, sddm-auth-*${NC}"
  echo -e "${YELLOW}   Esto matará tu sesión de terminal y las apps gráficas abiertas.${NC}"

  if ! read -r -t 10 -p "   Enter para continuar, Ctrl-C para abortar (10s)... " reply; then
    echo -e " ${YELLOW}Abortado — /tmp intacto${NC}"
    return
  fi

  echo -ne "Cleaning /tmp (wipe completo)... found ${RED}$size${NC}"

  sudo rm -rf /tmp
  sudo mkdir -p /tmp
  sudo chmod 1777 /tmp

  echo -e " ${GREEN}✓${NC}"
}

# ═══════════════════════ EJECUCIÓN ═══════════════════════

sec_mark

# Browsers
cleanup_dir "Brave Browser" "$HOME/.cache/BraveSoftware/Brave-Browser/Default/Cache"
cleanup_dir "Brave Code" "$HOME/.cache/BraveSoftware/Brave-Browser/Default/Code Cache"
cleanup_dir "Brave Service Worker" "$HOME/.cache/BraveSoftware/Brave-Browser/Default/Service Worker/CacheStorage"

# Communication
cleanup_dir "Slack" "$HOME/.config/Slack/Cache"
cleanup_dir "Slack Service Worker" "$HOME/.config/Slack/Service Worker/CacheStorage"
cleanup_dir "Telegram" "$HOME/.local/share/TelegramDesktop/tdata/user_data/cache"
cleanup_dir "Telegram Media" "$HOME/.local/share/TelegramDesktop/tdata/user_data/media_cache"

# Vesktop (Discord)
cleanup_dir "Vesktop" "$HOME/.config/vesktop/sessionData/Cache"
cleanup_dir "Vesktop Code" "$HOME/.config/vesktop/sessionData/Code Cache"
cleanup_dir "Vesktop GPU" "$HOME/.config/vesktop/sessionData/GPUCache"

sec_end "Browsers + Comunicación"

sec_mark

# Development
echo -e "\n${YELLOW}Cleaning Development Tools...${NC}"

if command -v npm &> /dev/null; then
  echo -ne "Running npm cache clean..."
  npm cache clean --force &> /dev/null
  echo -e " ${GREEN}✓${NC}"
fi

if command -v pip &> /dev/null; then
  echo -ne "Running pip cache purge..."
  pip cache purge &> /dev/null
  echo -e " ${GREEN}✓${NC}"
elif command -v pip3 &> /dev/null; then
  echo -ne "Running pip3 cache purge..."
  pip3 cache purge &> /dev/null
  echo -e " ${GREEN}✓${NC}"
fi

if command -v go &> /dev/null; then
  echo -ne "Running go clean..."
  go clean -cache -modcache &> /dev/null
  echo -e " ${GREEN}✓${NC}"
fi

if command -v bun &> /dev/null; then
  echo -ne "Running bun cache rm..."
  bun pm cache rm &> /dev/null
  echo -e " ${GREEN}✓${NC}"
fi

sec_end "Dev tools (npm/pip/go/bun)"

sec_mark

# System
cleanup_dir "Thumbnails" "$HOME/.cache/thumbnails"
cleanup_dir "Trash" "$HOME/.local/share/Trash"

# Wipe total de /tmp (pide confirmación; rompe sockets vivos)
cleanup_tmp

# Media
cleanup_dir "YouTube Music" "$HOME/.config/YouTube Music/Cache"
cleanup_dir "YouTube Music Code" "$HOME/.config/YouTube Music/Code Cache"

# Steam (runtime/cache/no-juegos — los juegos NO se tocan)
cleanup_dir "Steam compat tools" "$HOME/.local/share/Steam/compatibilitytools.d"
cleanup_dir "Steam runtime.old" "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime.old"
cleanup_dir "Steam htmlcache" "$HOME/.local/share/Steam/config/htmlcache"
cleanup_dir "Steam package/depot" "$HOME/.local/share/Steam/package"

# Bottles (solo temp/cache/templates — las bottles INTACTAS)
cleanup_dir "Bottles temp" "$HOME/.var/app/com.usebottles.bottles/data/bottles/temp"
cleanup_dir "Bottles templates" "$HOME/.var/app/com.usebottles.bottles/data/bottles/templates"
cleanup_dir "Bottles data cache" "$HOME/.var/app/com.usebottles.bottles/cache"
cleanup_dir "Bottles bottle cache" "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/gaming/cache"

sec_end "Sistema + /tmp + Steam + Bottles"

sec_mark

# Antigravity IDE (perfil mkOutOfStoreSymlink — caches VOLÁTILES)
cleanup_dir "Antigravity profile Cache" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/Cache"
cleanup_dir "Antigravity profile CachedData" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/CachedData"
cleanup_dir "Antigravity profile GPUCache" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/GPUCache"
cleanup_dir "Antigravity profile Code Cache" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/Code Cache"
cleanup_dir "Antigravity profile Service Worker" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/Service Worker"
cleanup_dir "Antigravity profile VSIXs" "$HOME/dotfiles-dizzi/Antigravity/.config/Antigravity IDE/CachedExtensionVSIXs"
# segundo config-root posible según cómo se lance el binario
cleanup_dir "Antigravity Cache" "$HOME/.config/Antigravity IDE/Cache"
cleanup_dir "Antigravity CachedData" "$HOME/.config/Antigravity IDE/CachedData"
cleanup_dir "Antigravity GPUCache" "$HOME/.config/Antigravity IDE/GPUCache"

# Cursor
cleanup_dir "Cursor Cache" "$HOME/.config/Cursor/Cache"
cleanup_dir "Cursor CachedData" "$HOME/.config/Cursor/CachedData"
cleanup_dir "Cursor Code Cache" "$HOME/.config/Cursor/Code Cache"
cleanup_dir "Cursor GPUCache" "$HOME/.config/Cursor/GPUCache"
cleanup_dir "Cursor Service Worker" "$HOME/.config/Cursor/Service Worker"
cleanup_dir "Cursor workspaceStorage" "$HOME/.config/Cursor/User/workspaceStorage"
cleanup_dir "Cursor logs" "$HOME/.config/Cursor/logs"

# Antigravity (perfil real, no el del symlink de dotfiles)
cleanup_dir "Antigravity Cache" "$HOME/.antigravity/Cache"
cleanup_dir "Antigravity CachedData" "$HOME/.antigravity/CachedData"
cleanup_dir "Antigravity Code Cache" "$HOME/.antigravity/Code Cache"
cleanup_dir "Antigravity Service Worker" "$HOME/.antigravity/Service Worker"
cleanup_dir "Antigravity logs" "$HOME/.antigravity/logs"
cleanup_dir "Antigravity-IDE Cache" "$HOME/.antigravity-ide/Cache"
cleanup_dir "Antigravity-IDE CachedData" "$HOME/.antigravity-ide/CachedData"
cleanup_dir "Antigravity-IDE Code Cache" "$HOME/.antigravity-ide/Code Cache"
cleanup_dir "Antigravity-IDE logs" "$HOME/.antigravity-ide/logs"

# Vicinae
cleanup_dir "Vicinae cache" "$HOME/.cache/vicinae"

sec_end "Editores (Cursor/Antigravity) + Vicinae"

sec_mark

# Wine windows temp (solo temp/cache — el prefix INTACTO)
cleanup_dir "Wine windows temp" "$HOME/.wine/drive_c/windows/temp"
cleanup_dir "Wine shadercache" "$HOME/.wine/shadercache"
cleanup_dir "Wine runtime cache" "$HOME/.cache/wine"
cleanup_dir "Wine mesa shader cache" "$HOME/.cache/mesa_shader_cache"
cleanup_dir "Wine mesa shader cache (rx)" "$HOME/.cache/mesa_shader_cache_rx"
# %TEMP% real de cada usuario Windows dentro del prefix
for u in "$HOME"/.wine/drive_c/users/*/; do
  [ -d "$u" ] || continue
  cleanup_dir "Wine ${u##*/}Temp" "${u}Temp"
  cleanup_dir "Wine ${u##*/}AppData/Local/Temp" "${u}AppData/Local/Temp"
  cleanup_dir "Wine ${u##*/}INetCache" "${u}AppData/Local/Microsoft/Windows/INetCache"
done

# Flatpak (caches por app)
if command -v flatpak &> /dev/null; then
  echo -e "\n${BLUE}Cleaning Flatpak...${NC}"
  for appdir in "$HOME"/.var/app/*/; do
    [ -d "$appdir" ] || continue
    cleanup_dir "Flatpak ${appdir##*/} root cache" "${appdir}cache"
    for cdir in "${appdir}"config/*/Cache* "${appdir}"config/*/*/Cache*; do
      cleanup_dir "Flatpak ${appdir##*/} ${cdir##*/}" "$cdir"
    done
  done
fi

sec_end "Wine + Flatpak (caches)"

sec_mark

# Runners de Bottles huérfanos: verifica bottle.yml de TODAS las botellas
# antes de borrar; nunca toca drive_c/Games.
cleanup_bottles_runners

sec_end "Bottles runners huérfanos"

sec_mark

report_bottles_space

sec_end "Bottles (reporte de espacio)"

sec_mark

report_var_space

sec_end "~/.var (reporte de ocupación)"

sec_mark

cleanup_flatpak_unused

sec_end "Flatpak runtimes viejos"

sec_mark

cleanup_stale_symlinks

sec_end "Symlinks rotos"

sec_mark

# Docker Cleanup
if command -v docker &> /dev/null; then
  if docker info &> /dev/null; then
    echo -e "\n${BLUE}Cleaning Docker...${NC}"
    docker system prune -a --volumes -f
    echo -e "${GREEN}✓ Docker pruned${NC}"
  else
    echo -e "\n${RED}Skipping Docker: Daemon not running${NC}"
  fi
fi

sec_end "Docker"

sec_mark

# OpenCode (BD SQLite + sesiones)
prune_opencode

sec_end "OpenCode"

sec_mark

# Nix Cleanup
if command -v nix-collect-garbage &> /dev/null; then
  echo -e "\n${BLUE}Collecting Nix garbage (ALL unreferenced)...${NC}"
  # "-d" borra todo lo no referenciado Y las generaciones viejas (sin rollback).
  nix-collect-garbage -d
  echo -e "${GREEN}✓ Nix garbage collected${NC}"
fi

sec_end "Nix GC (paths no referenciados)"

sec_mark

if command -v nix-store &> /dev/null; then
  echo -e "\n${BLUE}Optimizing Nix store (deduplicating files)...${NC}"
  nix-store --optimise
  echo -e "${GREEN}✓ Nix store optimized${NC}"
fi

sec_end "Nix store optimise (dedup)"

sec_mark

# Reporte de paquetes residentes (solo lectura). Va DESPUÉS del GC.
echo -e "\n${BLUE}Paquetes residentes...${NC}"
residents_report

sec_end "Paquetes residentes (reporte)"

sec_mark

# Coredumps (systemd)
cleanup_coredumps

sec_end "Coredumps (systemd)"

sec_mark

# Home Manager: borra TODAS las generaciones salvo la (current).
# Fail-safe: si no se detecta la (current), no se borra NADA.
# Va DESPUÉS del GC: borrar una generación crea paths huérfanos.
if command -v home-manager &> /dev/null; then
  echo -e "\n${BLUE}Home Manager generations...${NC}"

  hm_gens=$(home-manager generations 2>/dev/null)
  hm_current=$(echo "$hm_gens" | sed -n 's/.*id \([0-9][0-9]*\).*(current).*/\1/p')
  hm_old=$(echo "$hm_gens" | sed -n 's/.*id \([0-9][0-9]*\).*/\1/p' | sed "\|^${hm_current}\$|d")

  if [ -z "$hm_current" ]; then
    echo -e " ${RED}✗ no se pudo detectar la generación current — no se borra nada${NC}"
  elif [ -z "$hm_old" ]; then
    echo -e " ${GREEN}✓ solo existe la current (id $hm_current)${NC}"
  else
    hm_count=$(echo "$hm_old" | wc -l | tr -d ' ')
    echo -ne "Borrando $hm_count generación(es) no-current (current id $hm_current)..."
    if home-manager remove-generations $hm_old &> /dev/null; then
      echo -e " ${GREEN}✓${NC}"
    else
      echo -e " ${RED}✗ remove-generations falló${NC}"
    fi
    # segunda pasada: los paths de las generaciones borradas quedan huérfanos
    if command -v nix-collect-garbage &> /dev/null; then
      echo -e "  ${YELLOW}Recogiendo los paths de las generaciones borradas...${NC}"
      sudo nix-collect-garbage -d &> /dev/null
      echo -e "  ${GREEN}✓ paths huérfanos recogidos${NC}"
    fi
  fi
fi

sec_end "Home Manager (generaciones)"

# Reinicia el medidor para no contar dos veces lo que acaba de liberar el GC.
sec_mark

# ── Resumen final ──
print_summary

# Oferta final: limpieza manual de /boot
offer_clean_boot

echo -e "\n${GREEN}Cleanup Complete!${NC}"
