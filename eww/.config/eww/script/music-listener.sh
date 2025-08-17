#!/bin/bash

# Este script maneja la escucha de playerctl para eww.

# Bucle infinito para asegurar la escucha continua.
while true; do
  playerctl --follow metadata --format '{{ title }}'

  # Si playerctl falla, espera un momento y vuelve a intentarlo.
  # Esto evita el consumo excesivo de CPU en caso de errores.
  sleep 1
done
