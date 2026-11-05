#!/usr/bin/env bash
# Mod+Comma: enfocar la siguiente pantalla y centrar el puntero, incluso si está vacía.
set -euo pipefail

kwin_shortcut=(
  qdbus-qt6 org.kde.kglobalaccel /component/kwin
  org.kde.kglobalaccel.Component.invokeShortcut
)

"${kwin_shortcut[@]}" 'Switch to Next Screen'
"${kwin_shortcut[@]}" 'MoveMouseToCenter'
