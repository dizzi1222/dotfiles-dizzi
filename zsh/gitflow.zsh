# Git workflow shared by Termux and the desktop Zsh configuration.

gitcommit() {
  local template_file="$HOME/commit-template.txt"

  if [[ ! -f "$template_file" ]]; then
    mkdir -p "$HOME/.config/git"
    cat > "$template_file" <<'TEMPLATE'
feat(arch 󰣇): 󰊢 Best Linux 🐧 Setup

# Agrega contexto adicional aquí:
# -
# -
# -

# Recuerda usar 'gitflow' para commits más complejos
TEMPLATE
    echo "✅ Plantilla creada en: $template_file"
  fi

  git add .
  git commit -t "$template_file"

  echo -n "¿Pushear cambios? (y/n): "
  read -r push_answer
  if [[ "$push_answer" == "y" || "$push_answer" == "Y" ]]; then
    git push
    echo "✅ Cambios pusheados"
  else
    echo "⚠️ Commit realizado sin push"
  fi
}

gitquick() {
  local default_msg="feat(arch 󰣇): 󰊢 Best Linux 🐧 Setup"

  if [[ $# -gt 0 ]]; then
    git add . && git commit -m "$default_msg

- $*" && git push
  else
    git add . && git commit -m "$default_msg" && git push
  fi

  echo "✅ Commit rápido realizado"
}

gitconv() {
  local type scope msg full_msg

  echo "📝 Tipo de commit (feat/fix/docs/style/refactor/test/chore):"
  read -r type

  echo "📦 Scope (opcional, ej: hyprland, waybar, scripts):"
  read -r scope

  echo "💬 Mensaje del commit:"
  read -r msg

  if [[ -n "$scope" ]]; then
    full_msg="${type}(${scope}): ${msg}"
  else
    full_msg="${type}: ${msg}"
  fi

  git add .
  git commit -m "$full_msg"
  git push

  echo "✅ Commit: $full_msg"
}

gitflow() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "     🚀 GIT WORKFLOW INTERACTIVO"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  📝 COMMITS"
  echo "  0. ✏️  Editar último commit"
  echo "  1. 📋 Commit con editor (plantilla)"
  echo "  2. ⚡ Commit rápido"
  echo "  3. 🤖 Commit con IA (opencommit)"
  echo "  4. 📦 Commit convencional (feat/fix/etc)"
  echo ""
  echo "  📊 VER INFORMACIÓN"
  echo "  5. 📈 Estado actual"
  echo "  6. 📜 Log (últimos 10)"
  echo "  7. 🌳 Historial visual (tig)"
  echo ""
  echo "  🔧 EDITAR"
  echo "  8. 📝 Editar plantilla de commit"
  echo "  9. 🔄 Editar commits históricos"
  echo ""
  echo "  ⏮️  DESHACER"
  echo "  10. ↩️  Deshacer último commit (sin perder cambios)"
  echo "  11. 🔁 Descartar cambios locales (pull remoto)"
  echo "  12. 🛑 Abortar merge en curso"
  echo "  13. 💾 Savepoint (amend al commit raíz)"
  echo "  14. 🌐 Sincronizar ~/workspace (dual push dizzi1222 + dhardi007)"
  echo "  15. 🗣️ Commit (Head) Actual"
  echo "  16. ❌ Cancelar"
  echo ""
  echo -n "Elige opción: "
  read -r option

  case "$option" in
    0) git commit --amend ;;
    1) gitcommit ;;
    2)
      echo -n "💬 Contexto (Enter para saltar): "
      read -r context
      if [[ -n "$context" ]]; then
        gitquick "$context"
      else
        gitquick
      fi
      ;;
    3)
      if (( $+functions[aicommit] )); then
        aicommit
      elif (( $+commands[oco] )); then
        command oco
      else
        echo "❌ No se encontró aicommit ni oco"
      fi
      ;;
    4) gitconv ;;
    5) git status -sb ;;
    6) git log --oneline --graph --decorate --all -10 ;;
    7)
      if (( $+commands[tig] )); then
        tig
      else
        git log --oneline --graph --decorate --all -10
      fi
      ;;
    8)
      local template_file="$HOME/commit-template.txt"
      mkdir -p "$HOME/.config/git"
      ${EDITOR:-nano} "$template_file"
      echo "✅ Plantilla actualizada"
      ;;
    9) git rebase -i HEAD~5 ;;
    10)
      echo "↩️  Deshaciendo último commit..."
      git reset --soft HEAD~1
      echo "✅ Cambios preservados en staging"
      ;;
    11)
      echo "🔁 Sincronizando con remoto..."
      local branch
      branch=$(git rev-parse --abbrev-ref HEAD) || return 1
      git reset --hard "origin/$branch" && git pull
      ;;
    12)
      echo "❌ Abortando merge..."
      git merge --abort
      echo "✅ Merge cancelado"
      ;;
    13)
      echo "💾 Savepoint: aplastando al commit raíz..."
      local root_commit
      root_commit=$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -n 1)
      if [[ -z "$root_commit" ]]; then
        echo "❌ No se pudo encontrar el commit raíz"
        return 1
      fi
      git reset --soft "$root_commit" || return 1
      git add -A
      git commit --amend --no-edit
      echo "✅ Savepoint creado: $(git rev-parse --short HEAD) ($(git rev-list --count HEAD) commits)"
      ;;
    14)
      echo "🌐 Sincronizando ~/workspace (dual push)..."
      if [[ -d "$HOME/workspace/.git" ]]; then
        (
          cd "$HOME/workspace" || exit 1
          echo "📤 Push a origin (dizzi1222)..."
          git push origin main
          echo "🔄 Cambiando a cuenta dhardi007..."
          gh auth switch --user dhardi007
          echo "📤 Push a dhardi007..."
          git push dhardi007 main
          echo "🔄 Volviendo a dizzi1222..."
          gh auth switch --user dizzi1222
          echo "✅ Sincronización dual completada"
        )
      else
        echo "❌ ~/workspace no es un repo git"
      fi
      ;;
    15)
      echo "🔍 Estado del HEAD"
      git rev-list --count HEAD
      git status --short
      ;;
    16) echo "❌ Cancelado" ;;
    *) echo "❌ Opción inválida" ;;
  esac
}
