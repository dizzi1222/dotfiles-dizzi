#!/usr/bin/env bash
# arzopa-tui.sh — menú Arzopa en terminal (gum/fzf) para SteamOS Game Mode
# Uso: arzopa-tui.sh  (se abre en kitty desde Lutris/Steam)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Forzar TTY (necesario para gum/fzf/read)
# En Steam/Lutris Game Mode, stdin no es TTY; /dev/tty sí lo es si kitty lo abre bien
if [ ! -t 0 ]; then
  { exec < /dev/tty; } 2>/dev/null || { exec < /dev/console; } 2>/dev/null || true
fi

has_gum() { command -v gum >/dev/null 2>&1 && [ -t 0 ]; }
has_fzf() { command -v fzf >/dev/null 2>&1 && [ -t 0 ]; }

# Detectar estado del teclado
if loginctl seat-status seat-arzopa 2>/dev/null | grep -q 'AT Translated Set 2 keyboard'; then
  KB_LABEL="Teclado → Laptop (está en Arzopa)"
  KB_ACTION="laptop"
else
  KB_LABEL="Teclado → Arzopa (está en Laptop)"
  KB_ACTION="arzopa"
fi

choose_with_gum() {
  gum choose --cursor="▸ " --selected="✓" --height=10 \
    "󰍹 Abrir app en Arzopa" \
    "󰍹 Zen en Arzopa (Game Mode)" \
    "󰕮 Zen → Arzopa (Desktop Mode)" \
    "󰌌 $KB_LABEL" \
    "󰗼 Salir"
}

choose_with_fzf() {
  printf '%s\n' \
    "󰍹 Abrir app en Arzopa" \
    "󰍹 Zen en Arzopa (Game Mode)" \
    "󰕮 Zen → Arzopa (Desktop Mode)" \
    "󰌌 $KB_LABEL" \
    "󰗼 Salir" | fzf --prompt="Arzopa ▸ " --height=10 --reverse --no-sort
}

if has_gum; then
  CHOICE=$(choose_with_gum)
elif has_fzf; then
  CHOICE=$(choose_with_fzf)
else
  # Fallback simple: menú numerado
  echo "=== Arzopa ==="
  echo "1) Abrir app en Arzopa"
  echo "2) Zen en Arzopa (Game Mode)"
  echo "3) Zen → Arzopa (Desktop Mode)"
  echo "4) $KB_LABEL"
  echo "5) Salir"
  read -rp "Elige [1-5]: " n
  case "$n" in
    1) CHOICE="󰍹 Abrir app en Arzopa" ;;
    2) CHOICE="󰍹 Zen en Arzopa (Game Mode)" ;;
    3) CHOICE="󰕮 Zen → Arzopa (Desktop Mode)" ;;
    4) CHOICE="󰌌 $KB_LABEL" ;;
    *) exit 0 ;;
  esac
fi

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
  *"Abrir app"*)
    exec "$SCRIPT_DIR/arzopa-launcher.sh"
    ;;
  *"Game Mode"*)
    echo "Instalando/configurando Arzopa para Game Mode..."
    env -u TERMINFO sudo "$SCRIPT_DIR/setup-via-a-arzopa.sh" &&
      env -u TERMINFO sudo /usr/local/bin/arzopa-attach --keyboard &&
      systemctl --user restart arzopa-gamemode.service
    echo "Listo. Presiona Enter para cerrar."
    read -r
    ;;
  *"Desktop"*)
    exec "$SCRIPT_DIR/zen-to-arzopa.sh"
    ;;
  *"Teclado → Laptop"*)
    env -u TERMINFO sudo -n /usr/local/bin/arzopa-detach --keyboard-only &&
      echo "Teclado devuelto a la laptop (seat0)"
    sleep 1
    ;;
  *"Teclado → Arzopa"*)
    env -u TERMINFO sudo -n /usr/local/bin/arzopa-attach --keyboard-only &&
      echo "Teclado movido a la Arzopa (seat-arzopa)"
    sleep 1
    ;;
  *) exit 0 ;;
esac