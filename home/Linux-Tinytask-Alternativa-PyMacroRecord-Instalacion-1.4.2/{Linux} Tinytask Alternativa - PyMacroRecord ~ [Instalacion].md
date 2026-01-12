─❯ 📦 ~ > 📷 Tinytask Alternativa - Resumen de tu instalación de PyMacroRecord.
╰─❯ ~ > Instala el paquete desde: https://www.pymacrorecord.com/download
	~ O simplemente copia PyMacroRecord a Descargas, para 
	configurarar el env.
	
	|
	╰─❯ Instalación inicial de dependencias del sistema:
    Bash

sudo pacman -S python python-pip git --needed
sudo pacman -S --needed zlib libjpeg-turbo libtiff
sudo pacman -S pyenv

Configuración de Pyenv:
Bash

# Añade estas líneas a tu archivo ~/.zshrc
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Reinicia la terminal o ejecuta
source ~/.zshrc

Instalación de Python 3.11.9:
Bash

cd ~/Descargas/PyMacroRecord-1.4.1
pyenv install 3.11.9
pyenv local 3.11.9

Creación y activación del entorno virtual:
Bash

python -m venv venv
source venv/bin/activate

Instalación de dependencias de PyMacroRecord:
Bash

# Antes de esto, edita el archivo requirements.txt para quitar 'win10toast'.
pip install -r requirements.txt

Ejecución del programa:
Bash

    cd src
    python main.py

Este resumen incluye los comandos principales que utilizaste para que el programa funcionara correctamente en tu sistema.
