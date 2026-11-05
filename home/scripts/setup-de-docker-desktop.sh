#!/bin/bash
# fase2-HyprInstall-full.sh
# Script OPTIMIZADO SIN COMPILACIONES LARGAS
# Ejecutar como usuario normal después de archinstall
# Version ULTRA-FAST: Solo paquetes -bin precompilado

# +++- anotaciones
# Script perfeccionado con todas las mejoras solicitadas
# - Caelestia/Quickshell/Eww: Instalación interactiva (s/n)
# - Stremio: Instalación interactiva opcional
# - Editor: Selección interactiva VSCode/Cursor/Antigravity
# - Ollama + opencommit (oco) con modelo qwen2.5:0.5b
# - Kafka cursor: Búsqueda en múltiples rutas + config Hyprland
# - 35 pasos totales con todas las features esenciales

set -e

# ═══════════════════════════════════════════════════════════
# COLORES Y FUNCIONES
# ═══════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

function print_header() {
  echo
  echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║ $1${NC}"
  echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
  echo
}

function print_step() {
  echo
  echo -e "${BOLD}${BLUE}▶ PASO $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

function print_package() { echo -e "  ${MAGENTA}📦${NC} $1"; }
function print_status() { echo -e "${BLUE}[⚡]${NC} $1"; }
function print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
function print_error() { echo -e "${RED}[✗]${NC} $1"; }
function print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
function print_installing() { echo -e "${CYAN}[↓]${NC} Instalando: ${BOLD}$1${NC}"; }

# ═══════════════════════════════════════════════════════════
# VERIFICACIONES
# ═══════════════════════════════════════════════════════════
if [[ $EUID -eq 0 ]]; then
  print_error "NO ejecutar como root. Ejecuta como usuario normal."
  exit 1
fi

if ! command -v sudo &>/dev/null; then
  print_error "Sudo no está instalado. Configúralo primero."
  exit 1
fi

if ! ping -c 1 archlinux.org &>/dev/null; then
  print_error "Sin internet. Conecta con: sudo systemctl start NetworkManager && nmtui"
  exit 1
fi

# ═══════════════════════════════════════════════════════════
# INTRO
# ═══════════════════════════════════════════════════════════
clear
cat <<"EOF"

██╗░░██╗██╗░░░██╗██████╗░██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██║░░██║╚██╗░██╔╝██╔══██╗██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
███████║░╚████╔╝░██████╔╝██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██╔══██║░░╚██╔╝░░██╔═══╝░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██║░░██║░░░██║░░░██║░░░░░██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

╔══════════════════════════════════════════════════════════════════════╗
║        🚀 INSTALACIÓN ULTRA-FAST HYPRLAND 🚀                         ║
║            VERSIÓN OPTIMIZADA SIN COMPILACIONES                      ║
╚══════════════════════════════════════════════════════════════════════╝

EOF

echo -e "${GREEN}${BOLD}Esta instalación incluye:${NC}"
echo "  • Configuraciones de Grub Mine-Craft"
echo "  • Algunos scripts de Omarchy [webpack, arch install]"
echo "  • Hyprland + Waybar + Rofi + Dunst + Swaync"
echo "  • Audio: PipeWire + EasyEffects"
echo "  • Gaming: Steam, Lutris, Wine (INTERACTIVO)"
echo "  • Apps: Brave, Spotify, OBS, Discord, YouTube Music"
echo "  • Editor: VSCode/Cursor/Antigravity (INTERACTIVO)"
echo "  • Dev: Docker, Node.js, Rust, Python, Neovim, Ollama + IA"
echo "  • Utilidades: zsh, tmux, fastfetch, yazi, btop, pywal"
echo "  • Widgets: Eww (esencial), Quickshell + Caelestia (OPCIONAL)"
echo "  • Iconos/Glyphs: Nerd Fonts, Rofimoji || Launchers: Fuzzel [rofi], Vicinae (Raycast para Hyprland)"
echo "  • Extras: Input Remapper, Wine Dark Theme, Kafka Cursor"
echo "  • Temas: Oh-My-Posh, Rofimoji, Qt/GTK automático"
echo "  • Servicios: Gemini, Espanso, Kanata, GDrive mounts, ydotool"
echo "  • Dotfiles dizzi1222"
echo
echo -e "${RED}${BOLD}OPTIMIZACIONES:${NC}"
echo "  • Solo paquetes -bin (precompilados)"
echo "  • Caelestia/Quickshell: OPCIONAL (compilación ~30min)"
echo "  • Stremio: OPCIONAL (compilación ~10-15min)"
echo "  • Gemini CLI: OPCIONAL (omitir si ya configurado)"
echo "  • Eww: ESENCIAL (instalación rápida)"
echo "  • Bottles: OMITIDO (compila 1+ hora)"
echo "  • Stremio, discord-rpc (redundante si uso customRP en wine), qt5-webengine: OMITIDOS (compilan mucho)"
echo
echo -e "${YELLOW}${BOLD}Duración estimada: 25-35 minutos${NC}"
echo
read -p "¿Continuar? [S/n]: " confirm
[[ "$confirm" =~ ^[Nn]$ ]] && exit 0

# ═══════════════════════════════════════════════════════════
# SUDO KEEPALIVE
# ═══════════════════════════════════════════════════════════
sudo -v
(while true; do
  sudo -n true
  sleep 50
done 2>/dev/null) &
SUDO_PID=$!
trap "kill $SUDO_PID 2>/dev/null" EXIT

# ═══════════════════════════════════════════════════════════
# DOCKER SETUP (FUNCIONAL Y ROBUSTO)
# ═══════════════════════════════════════════════════════════
print_header "Configurando Docker"

# 1. Habilitar Docker service
print_status "Habilitando servicios de Docker..."
sudo systemctl daemon-reload
sudo systemctl enable docker.socket 2>/dev/null || true
sudo systemctl enable docker 2>/dev/null || true
sudo systemctl start docker.socket 2>/dev/null || true
sudo systemctl start docker 2>/dev/null || true

# 2. Agregar usuario a grupo docker
sudo usermod -aG docker $USER 2>/dev/null || true
print_success "Docker CLI configurado"

# 3. Verificar instalación básica
if command -v docker &>/dev/null; then
  print_success "Docker disponible: $(docker --version)"
else
  print_warning "Docker CLI no disponible en PATH"
fi

# ═══════════════════════════════════════════════════════════
# DOCKER DESKTOP (OPCIONAL - FALLBACK INTELIGENTE)
# ═══════════════════════════════════════════════════════════
echo
echo -e "${CYAN}Opciones de Docker:${NC}"
echo -e "  ${MAGENTA}1.${NC} (OMITIR) Docker CLI (ya instalado - suficiente)"
echo -e "  ${MAGENTA}2.${NC} Docker Desktop (binarios estáticos+GUI - recomendado si necesitas GUI)"
echo -e "  ${MAGENTA}BTW.${NC} La realidad es que docker-compose entraba en conflicto con docker-desktop"
echo
read -p "Selecciona [1=(OMITIR) CLI solamente, 2=Agregar Desktop]: " docker_choice

if [[ "$docker_choice" == "2" ]]; then
  print_header "Instalando Docker Desktop (Binarios Estáticos)"

  # Crear directorio temporal
  DOCKER_TEMP="/tmp/docker-desktop-install-$$"
  mkdir -p "$DOCKER_TEMP"
  cd "$DOCKER_TEMP"

  # DESCARGA CORRECTA
  print_status "Descargando Docker binarios estáticos v29.1.4..."
  if wget -q --show-progress https://download.docker.com/linux/static/stable/x86_64/docker-29.1.4.tgz 2>/dev/null; then
    wget -q --show-progress https://desktop.docker.com/linux/main/amd64/214940/docker-desktop-x86_64.pkg.tar.zst
    sudo pacman -U ./docker-desktop-x86_64.pkg.tar.zst
    print_success "GUI => Descarga completada [Pacman -U para instalaciones Locales] + Binario Estático"

    # EXTRACCIÓN CORRECTA (sin errores de sintaxis)
    print_status "Extrayendo archivos..."
    if tar -xzf docker-29.1.4.tgz 2>/dev/null; then
      print_success "Extracción completada"

      # INSTALACIÓN CORRECTA
      print_installing "Instalando binarios en /usr/local/bin/"
      if sudo cp -rp docker/* /usr/local/bin/ && rm -rf docker; then
        print_success "Binarios instalados"

        # CREAR SERVICIO SYSTEMD (para docker daemon)
        print_status "Creando servicio Docker daemon..."
        sudo tee /etc/systemd/system/docker.service >/dev/null <<'DOCKERSVC'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP $MAINPID
RestartSec=5
Restart=on-failure

[Install]
WantedBy=multi-user.target
DOCKERSVC

        # Habilitar servicios
        sudo systemctl daemon-reload
        sudo systemctl enable docker docker.socket 2>/dev/null || true
        sudo systemctl restart docker 2>/dev/null || true

        print_success "Docker daemon configurado"

        # Verificación
        sleep 2
        if docker --version &>/dev/null; then
          print_success "✅ Docker funcional: $(docker --version)"

          # Prueba rápida (sin descargar imagen)
          print_status "Verificando conectividad..."
          if docker ps &>/dev/null; then
            print_success "✅ Docker listo para usar"
          fi
        else
          print_warning "⚠️  Docker instalado pero no disponible en PATH"
          print_status "Intenta: /usr/local/bin/docker --version"
        fi
      else
        print_error "❌ Error al copiar binarios"
      fi
    else
      print_error "❌ Error al extraer archivo tar"
    fi
  else
    print_error "❌ Error descargando Docker (sin internet o servidor caído)"
    print_status "Descarga manual: https://download.docker.com/linux/static/stable/x86_64/docker-29.1.4.tgz"
  fi

  # Limpiar
  cd ~
  rm -rf "$DOCKER_TEMP"

  # ── GPG / pass para Docker Desktop Login ──────────────────────────
  echo
  echo -e "${CYAN}Docker Desktop requiere GPG + pass para iniciar sesión.${NC}"
  read -p "¿Configurar GPG/pass ahora? [s/N]: " gpg_choice
  if [[ "$gpg_choice" =~ ^[sS]$ ]]; then
    print_header "Configurando GPG + pass para Docker Desktop"

    # Instalar dependencias si faltan
    for pkg in gnupg pass; do
      if ! command -v "$pkg" &>/dev/null; then
        print_status "Instalando $pkg..."
        sudo pacman -S --noconfirm "$pkg"
      fi
    done

    echo
    print_status "Generando clave GPG (sigue las instrucciones en pantalla)..."
    gpg --generate-key

    echo
    echo -e "${CYAN}Busca la línea 'pub' en la salida anterior y copia el ID (ej: 3ABCD1234EF56G78)${NC}"
    read -p "Pega tu GPG ID aquí: " gpg_id

    if [[ -n "$gpg_id" ]]; then
      pass init "$gpg_id"
      print_success "✅ pass inicializado con GPG ID: $gpg_id"
      echo -e "${CYAN}Ahora puedes iniciar sesión en Docker Desktop desde la GUI.${NC}"
    else
      print_warning "⚠️  GPG ID vacío — omitiendo pass init. Puedes hacerlo manualmente: pass init <TU_GPG_ID>"
    fi
  else
    print_warning "GPG/pass omitido — necesario para iniciar sesión en Docker Desktop"
    print_status "Manual: gpg --generate-key && pass init <GPG_ID>"
  fi

elif [[ "$docker_choice" == "1" ]]; then
  print_success "Usando Docker CLI (suficiente para la mayoría)"
else
  print_warning "Docker Desktop omitido"
fi

print_success "Docker configurado"

# ═══════════════════════════════════════════════════════════
# PYTHON + NODE SUPPORT
# ═══════════════════════════════════════════════════════════
print_installing "Python LSP + Neovim support"
python -m pip install --user --break-system-packages pynvim 'python-lsp-server[all]' 2>/dev/null || true

print_installing "Node packages (neovim)"
npm install -g neovim 2>/dev/null || true

# ═══════════════════════════════════════════════════════════
# PASO ???: INSTALACION DE Docker
# ═══════════════════════════════════════════════════════════
print_step "35/35: Limpieza Final"
print_status "Eliminando paquetes huérfanos..."
sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
yay -Rns $(yay -Qdtq) --noconfirm 2>/dev/null || true

print_status "Limpiando caché..."
yay -Sc --noconfirm 2>/dev/null || true
sudo pacman -Sc --noconfirm 2>/dev/null || true
rm -rf ~/.cache/yay 2>/dev/null || true
rm -rf /tmp/sddm-astronaut-theme 2>/dev/null || true
hyprctl reload # o niri reload

# Reiniciar Waybar desacoplado de la terminal
print_status "Reiniciando Waybar..."
killall waybar 2>/dev/null || true
nohup waybar >/dev/null 2>&1 & # NOHUP LA SOLUCION PARA QUE NO SE CIERRE AL CERRAR TERMINAL
sleep 1

print_success "Limpieza completada"
# ═══════════════════════════════════════════════════════════
# RESUMEN
# ═══════════════════════════════════════════════════════════
kill $SUDO_PID 2>/dev/null || true
clear
cat <<"EOF"
╔══════════════════════════════════════════════════════════════════════╗
║              🎉 INSTALACIÓN ULTRA-FAST COMPLETADA 🎉                 ║
╠══════════════════════════════════════════════════════════════════════╣
║ ✅ 󰡨   Apps, DevOps (Docker), Ollama + opencommit (si seleccionado) ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
echo
