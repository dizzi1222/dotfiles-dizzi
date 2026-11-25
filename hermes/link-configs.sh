#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
HERMES_DIR="$DOTFILES_ROOT/hermes"
HERMES_HOME="${HERMES_HOME:-${HOME:?}/.hermes}"
WORKSPACE_TARGET="$HOME/HERMES AI"
BACKUP_SUFFIX="$(date -u +%Y%m%dT%H%M%SZ)-$$"

link_path() {
  local source_path="$1"
  local target_path="$2"
  local parent backup

  if [[ ! -e "$source_path" ]]; then
    printf 'No existe el origen Hermes: %s\n' "$source_path" >&2
    return 1
  fi
  parent="$(dirname -- "$target_path")"
  mkdir -p -- "$parent"

  if [[ -L "$target_path" ]] && \
    [[ "$(readlink -f -- "$target_path" 2>/dev/null || true)" == "$(readlink -f -- "$source_path")" ]]; then
    return 0
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    backup="${target_path}.pre-dotfiles-${BACKUP_SUFFIX}"
    mv -- "$target_path" "$backup"
    printf 'Respaldo preservado en: %s\n' "$backup"
  fi

  ln -s -- "$source_path" "$target_path"
  printf 'Enlace creado: %s -> %s\n' "$target_path" "$source_path"
}

agents=(presupuestos cobros agenda contenido)
for agent in "${agents[@]}"; do
  if [[ ! -d "$HERMES_HOME/profiles/$agent" ]]; then
    printf 'Falta el perfil Hermes %s. Ejecuta primero instalar-equipo.sh.\n' "$agent" >&2
    exit 1
  fi
done

link_path "$HERMES_DIR/config.yaml" "$HERMES_HOME/config.yaml"
link_path "$HERMES_DIR/SOUL.md" "$HERMES_HOME/SOUL.md"
link_path "$HERMES_DIR/workspace" "$WORKSPACE_TARGET"
link_path "$DOTFILES_ROOT/local/.local/bin/webshare-proxy-wrapper" "$HOME/.local/bin/webshare-proxy-wrapper"

for agent in "${agents[@]}"; do
  profile_dir="$HERMES_HOME/profiles/$agent"
  pack_agent="$HERMES_DIR/workspace/Tu equipo en Hermes/agentes/$agent"
  link_path "$HERMES_DIR/profiles/$agent/config.yaml" "$profile_dir/config.yaml"
  link_path "$pack_agent/SOUL.md" "$profile_dir/SOUL.md"
  link_path "$pack_agent/skills" "$profile_dir/skills/negocio"
done

# Parches al código de Hermes: Desktop los aparca en un stash al actualizar (--keep-stash).
bash "$HERMES_DIR/apply-patches.sh" --install ||
  printf 'Aviso: revisa hermes/patches (mensaje anterior de apply-patches.sh).\n' >&2

printf 'Enlaces Hermes listos. No se enlazaron .env, auth, sesiones, memoria ni historial.\n'
