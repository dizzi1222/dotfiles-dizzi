#!/usr/bin/env bash
set -euo pipefail

PROTECTED=(zsh fish nixconf)
BRANCH=cachyos

cd "$(dirname "$0")/.." || exit 1

git fetch origin
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

if ! git merge --no-commit --no-ff origin/main; then
  conflicted=$(git diff --name-only --diff-filter=U || true)
  for p in "${PROTECTED[@]}"; do
    conflicted=$(printf '%s\n' "$conflicted" | grep -v "^$p/" || true)
  done
  if [ -n "$conflicted" ]; then
    echo "Conflictos en rutas NO protegidas, abortando:"
    echo "$conflicted"
    git merge --abort
    exit 1
  fi
fi

git restore --source=HEAD --staged --worktree -- "${PROTECTED[@]}"
git add -A

if git diff --cached --quiet; then
  echo "Sin cambios de origin/main para sync; cachyos ya está al día."
  exit 0
fi

git commit -m "chore(cachyos): sync desde origin/main ($(date +%Y-%m-%d))"
git push origin "$BRANCH"

echo "Sync completado: cachyos actualizada desde origin/main (zsh/ fish/ nixconf/ preservados)."