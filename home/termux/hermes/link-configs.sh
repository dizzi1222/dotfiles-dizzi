#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-${HOME:?}/.hermes}"
DOTFILES_HERMES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_SUFFIX="$(date -u +%Y%m%dT%H%M%SZ)-$$"

link_hermes_config() {
  local source_path="$1"
  local target_path="$2"
  local target_dir
  local backup_path

  if [[ ! -f "$source_path" ]]; then
    printf 'Hermes dotfile no encontrado: %s\n' "$source_path" >&2
    return 1
  fi

  target_dir="$(dirname -- "$target_path")"
  mkdir -p -- "$target_dir"

  if [[ -L "$target_path" ]] && \
    [[ "$(readlink -f -- "$target_path" 2>/dev/null || true)" == "$(readlink -f -- "$source_path")" ]]; then
    return 0
  fi

  if [[ -d "$target_path" && ! -L "$target_path" ]]; then
    printf 'Se esperaba un archivo de configuración, no un directorio: %s\n' "$target_path" >&2
    return 1
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    backup_path="${target_path}.pre-dotfiles-${BACKUP_SUFFIX}"
    mv -- "$target_path" "$backup_path"
    printf 'Configuración anterior preservada en: %s\n' "$backup_path"
  fi

  ln -s -- "$source_path" "$target_path"
  printf 'Configuración enlazada: %s -> %s\n' "$target_path" "$source_path"
}

link_hermes_config "$DOTFILES_HERMES_DIR/config.yaml" "$HERMES_HOME/config.yaml"
link_hermes_config "$DOTFILES_HERMES_DIR/SOUL.md" "$HERMES_HOME/SOUL.md"
link_hermes_config "$DOTFILES_HERMES_DIR/skills/agent/SKILL.md" "$HERMES_HOME/skills/agent/SKILL.md"

for profile_config in "$DOTFILES_HERMES_DIR"/profiles/*/config.yaml; do
  [[ -f "$profile_config" ]] || continue
  profile_name="$(basename -- "$(dirname -- "$profile_config")")"
  profile_dir="$HERMES_HOME/profiles/$profile_name"
  pack_agent="$DOTFILES_HERMES_DIR/../HERMES AI/Tu equipo en Hermes/agentes/$profile_name"
  link_hermes_config "$profile_config" "$profile_dir/config.yaml"
  if [[ -f "$pack_agent/SOUL.md" ]]; then
    link_hermes_config "$pack_agent/SOUL.md" "$profile_dir/SOUL.md"
    for skill in "$pack_agent"/skills/*/SKILL.md; do
      [[ -f "$skill" ]] || continue
      relative_skill="${skill#"$pack_agent/skills/"}"
      link_hermes_config "$skill" "$profile_dir/skills/negocio/$relative_skill"
    done
  fi
done
