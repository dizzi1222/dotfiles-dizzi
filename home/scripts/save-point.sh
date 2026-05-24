#!/bin/bash
# ================================================================================
# ☠ SAVE POINT ☠ - TUI con gum
# ================================================================================

SAVE_BRANCH="main"
SAVE_COMMIT="20e1946"
SAVE_MSG="feat(dotfiles): add design-extract blueprint tool, arzopa vertical fix & hypr/niri sync.mejorar el cierre de waydroid y añadir soporte para HDMI-A-1 en rotación de monitores ✨ (input-remapper): añadir configuración para mouse Logitech G305 zurdo y actualizar mapeo de teclas ♻️ (hypr/niri): centralizar configuración de teclados en script setup-keyboard.sh y añadir rotación automática de monitores 📝 (nvim): actualizar subproyecto de configuración de Neovim ➕ (local): añadir lanzador de escritorio para Geforce Now Web"

# ── Verificar dependencia ────────────────────────────────────────────────────────
if ! command -v gum &>/dev/null; then
  echo "✗ 'gum' no está instalado."
  echo "  paru -S gum"
  exit 1
fi

# ── Banner ───────────────────────────────────────────────────────────────────────
print_banner() {
  clear
  printf '%s\n' \
    "███████╗ █████╗ ██╗   ██╗███████╗    ██████╗  ████████╗" \
    "██╔════╝██╔══██╗██║   ██║██╔════╝    ██╔══██╗ ╚══██╔══╝" \
    "███████╗███████║██║   ██║█████╗      ██████╔╝    ██║   " \
    "╚════██║██╔══██║╚██╗ ██╔╝██╔══╝      ██╔═══╝     ██║   " \
    "███████║██║  ██║ ╚████╔╝ ███████╗    ██║         ██║   " \
    "╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝    ╚═╝         ╚═╝   " |
    gum style --foreground="#FFD700" --align center --width 60
}

# ── Info del checkpoint ──────────────────────────────────────────────────────────
print_checkpoint_info() {
  echo ""
  printf "  %-10s %s\n" "Rama:" "$SAVE_BRANCH" \
    "Commit:" "$SAVE_COMMIT" \
    "Msg:" "$SAVE_MSG" |
    gum style --border rounded --border-foreground="#7C3AED" \
      --padding "0 2" --foreground="#AAAAAA"
}

# ── Git status ───────────────────────────────────────────────────────────────────
check_git_status() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    gum style --foreground="#FF4444" "  ✗ No estás en un repositorio git"
    return 1
  fi

  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
  gum style --foreground="#888888" "  Rama actual: $CURRENT_BRANCH"

  DIRTY=$(git status --porcelain)
  if [[ -n "$DIRTY" ]]; then
    gum style --foreground="#FF6B6B" \
      "  ⚠  Cambios sin commit — serán PERDIDOS al restaurar:" \
      "" \
      "$(git status --porcelain | sed 's/^/    /')"
    return 2
  else
    gum style --foreground="#00FF88" "  ✓ Working tree limpio"
    return 0
  fi
}

# ── Restaurar ────────────────────────────────────────────────────────────────────
restore_save_point() {
  if ! git show-ref --verify --quiet "refs/heads/$SAVE_BRANCH"; then
    gum style --foreground="#FF4444" \
      "  ✗ La rama '$SAVE_BRANCH' no existe localmente"
    return 1
  fi

  gum spin --spinner dot --title "Restaurando $SAVE_COMMIT..." -- \
    git checkout -f "$SAVE_BRANCH"

  if [[ $? -eq 0 ]]; then
    echo ""
    printf '%s\n' "  ✓  VICTORY  —  restaurado → $SAVE_COMMIT" |
      gum style --foreground="#00FF88" --border double \
        --border-foreground="#00FFFF" --align center \
        --padding "1 6"
  else
    gum style --foreground="#FF4444" "  ✗ Error al restaurar"
    return 1
  fi
}

# ── Menú ─────────────────────────────────────────────────────────────────────────
show_menu() {
  print_banner
  print_checkpoint_info
  echo ""
  check_git_status
  STATUS_CODE=$?
  echo ""

  local OPTIONS=()
  [[ $STATUS_CODE -eq 2 ]] && OPTIONS+=("⚠  RESTAURAR  (pierdo cambios)")
  [[ $STATUS_CODE -eq 2 ]] && OPTIONS+=("💾 BACKUP+RESTORE  (stash primero)")
  [[ $STATUS_CODE -ne 2 ]] && OPTIONS+=("✅ RESTAURAR  (sin riesgos)")
  OPTIONS+=("📋 STATUS")
  OPTIONS+=("🚪 SALIR")

  CHOICE=$(printf '%s\n' "${OPTIONS[@]}" |
    gum choose \
      --header "  ¿Qué deseas hacer?" \
      --header.foreground="#FFD700" \
      --cursor.foreground="#FFD700" \
      --selected.foreground="#00FFFF")

  [[ -z "$CHOICE" ]] && exit 0

  case "$CHOICE" in
  *RESTAURAR*)
    if [[ $STATUS_CODE -eq 2 ]]; then
      gum confirm "⚠  Los cambios locales serán PERDIDOS. ¿Continuar?" || exit 0
    fi
    restore_save_point
    ;;
  *BACKUP*)
    STASH_NAME="SAVEPOINT_BACKUP_$(date +%Y%m%d_%H%M%S)"
    gum spin --spinner dot --title "Creando stash..." -- \
      git stash push -m "$STASH_NAME"
    gum style --foreground="#00FF88" \
      "  ✓ Stash: $STASH_NAME" \
      "  Recuperar con: git stash pop"
    sleep 1
    restore_save_point
    ;;
  *STATUS*)
    echo ""
    git status
    echo ""
    gum input --placeholder "ENTER para continuar..." >/dev/null
    show_menu
    return
    ;;
  *)
    gum style --foreground="#888888" "  Cancelado."
    exit 0
    ;;
  esac

  echo ""
  gum input --placeholder "ENTER para cerrar..." >/dev/null
}

# ── Entry ────────────────────────────────────────────────────────────────────────
if [[ "$1" == "--force" ]]; then
  restore_save_point
else
  show_menu
fi
