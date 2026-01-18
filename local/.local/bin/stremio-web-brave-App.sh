#!/bin/bash
# Abrir el servicio de Stremio
stremio-service &
com.stremio.Service &
# Abrir Stremio Web en Brave
brave --app="https://web.stremio.com/"
# firefox --new-window "https://web.stremio.com/"
