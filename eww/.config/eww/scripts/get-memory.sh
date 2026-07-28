#!/bin/bash

# Forzar salida consistente en inglés
export LC_ALL=C
export LANG=C

printf "%.0f\n" $(free -m | grep Mem | awk '{print ($3/$2)*100}')
