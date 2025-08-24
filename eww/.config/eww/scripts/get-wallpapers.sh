#!/bin/bash

DIRECTORY=~/wallpapers/
DIRECTORY=$(eval echo $DIRECTORY)

if [ -d "$DIRECTORY" ]; then
  # Listar archivos preview-* y devolver el nombre SIN "preview-" y sin extensión
  find "$DIRECTORY" -type f \( -name "preview-*.jpg" -o -name "preview-*.png" \) \
    -exec basename {} \; |
    sed -E 's/^preview-//' |
    sed -E 's/\.[a-zA-Z0-9]+$//' |
    jq -R . | jq -s .
else
  echo "[]"
  exit 1
fi
