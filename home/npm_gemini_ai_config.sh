# ~ > Ubicado en: /home/diego/dotfiles/home/npm_gemini_ai_config.sh

#!/bin/bash

# 1. Crea el directorio para paquetes globales si no existe
mkdir -p ~/.npm-global

# 2. Configura npm para usar ese directorio
npm config set prefix '~/.npm-global'

# 3. Añade la ruta al PATH si no está ya
# ~ Añade el directorio bin/ a la variable de entorno PATH.
# Esto asegura que los comandos instalados globalmente (como 'gemini')
# sean reconocidos por el sistema.
#
# La condición 'grep -q' verifica si la línea ya existe para evitar duplicados.
if ! grep -q 'NPM_GLOBAL' ~/.zshrc; then
  echo '# Añade el directorio global de npm al PATH. NPM_GLOBAL' >>~/.zshrc
  echo 'export PATH=~/.npm-global/bin:$PATH' >>~/.zshrc
fi

#instalar sin sudo, sudo lo USAS si instalas desde la raiz ~/
npm install -g @google/gemini-cli
