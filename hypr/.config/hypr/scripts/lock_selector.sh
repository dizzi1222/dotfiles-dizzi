#!/bin/bash

# Intentar ejecutar Caelestia
caelestia shell lock lock

# Comprobar el estado de salida del comando anterior
# Si el comando de Caelestia falló (status 255 es diferente de 0), entonces ejecutar el siguiente
if [ $? -ne 0 ]; then
        # El comando de Caelestia falló, ahora probamos Hyprlock
        pidof hyprlock || hyprlock
fi
