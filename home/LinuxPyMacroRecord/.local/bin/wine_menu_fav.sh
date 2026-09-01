#!/usr/bin/env zsh

# Archivo: /home/diego/dotfiles-dizzi/local/.local/bin/Wine Commands - Comandos fav.sh
# Título: 🍷 Wine Commands 🍷 󰖳

# Variables para colores ANSI
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Definición del WINEPREFIX personalizado
readonly WINE_PREFIX="/home/diego/.wine-11"

# Función para ejecutar comandos con el prefijo wine-11
run_wine_command() {
    local cmd="$1"
    shift
    # Usamos $cmd para ejecutar el comando principal (ej. wine, winecfg, winetricks)
    echo -e "\n${YELLOW}Ejecutando en $WINE_PREFIX: ${cmd} $@...${NC}"
    WINEPREFIX="$WINE_PREFIX" "$cmd" "$@"
}

# Función principal para mostrar el menú
show_menu() {
    clear
    
    # Encabezado
    echo -e "${MAGENTA}╔═════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${CYAN}🍷 Wine Commands 🍷 󰖳${NC}       ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC} ${BLUE}PREFIX:${NC} ${YELLOW}${WINE_PREFIX:20}...${NC}  ${MAGENTA}║${NC}" # Muestra el prefijo
    echo -e "${MAGENTA}╚═════════════════════════════════════╝${NC}"
    echo

    # Opciones del menú (Generales, usando el prefijo por defecto o sin prefijo)
    echo -e "${GREEN}1)${NC} ${YELLOW}wineboot${NC}:  󰜉 Ejecutar o reiniciar el entorno Wine (prefijo por defecto). 󰨡 "
    echo -e "${GREEN}2)${NC} ${YELLOW}winecfg${NC}:  Configurar Wine (prefijo por defecto). "  
    echo -e "${GREEN}3)${NC} ${YELLOW}winefile${NC}:  📂Abrir el explorador de archivos de Wine (prefijo por defecto).󰈞"  
    echo -e "${GREEN}4)${NC} ${YELLOW}winepath${NC}:  Convertir ruta de Windows 󰖳 a Linux  (o viceversa). "
    echo -e "${GREEN}5)${NC} ${YELLOW}winemine${NC}: 󰍳 Ejecutar Buscaminas 󰷚 󰍳."
    echo -e "${GREEN}6)${NC} ${YELLOW}wineconsole${NC}: Abrir una consola de Wine (cmd.exe - prefijo por defecto)."
    echo
    echo -e "${CYAN}--- Comandos en prefijo ${WINE_PREFIX} ---${NC}"
    # Opciones del menú (Prefijo wine-11)
    echo -e "${GREEN}8)${NC} ${YELLOW}wine11cfg${NC}: ⚙️ Abrir la Configuración del prefijo. "
    echo -e "${GREEN}9)${NC} ${YELLOW}wine11tricks${NC}: 📦 Ejecutar Winetricks (con argumentos opcionales). 󰐒"
    echo -e "${GREEN}10)${NC} ${YELLOW}wine11 run${NC}: 🚀 Ejecutar un .exe (con argumentos opcionales). 󰍛"
    echo -e "${GREEN}11)${NC} ${YELLOW}wine11uninstaller${NC}: 🗑️ Desinstalar Apps del prefijo específico (${WINE_PREFIX:20}...)${NC}."
    
    echo
    echo -e "${CYAN}--- Otros Comandos de Mantenimiento ---${NC}"
    echo -e "${GREEN}12)${NC} ${YELLOW}wineuninstaller${NC}: 🗑️ Desinstalar Apps del prefijo por defecto (~/.wine).${NC}"
    echo -e "${GREEN}13)${NC} ${YELLOW}wine11file${NC}:  📂Abrir el explorador de archivos de Wine (prefijo por defecto).󰈞"
    echo -e "${RED}7)${NC} ${RED}Salir${NC} 󰩈"
    echo -e "${CYAN}-------------------------------------${NC}"
    echo -n "Selecciona una opción: "
}

# Función para ejecutar la acción seleccionada
run_command() {
    case $1 in
        1)
            echo -e "\n${YELLOW}Ejecutando: wineboot (reiniciar entorno)...${NC}"
            wineboot
            ;;
        2)
            echo -e "\n${YELLOW}Ejecutando: winecfg (configurador - por defecto)...${NC}"
            winecfg
            ;;
        3)
            echo -e "\n${YELLOW}Ejecutando: winefile (explorador de archivos - por defecto)...${NC}"
            winefile
            ;;
        4)
            echo -e "\n${YELLOW}Ejecutando: winepath (conversor de rutas)...${NC}"
            echo -n "Introduce la ruta de Windows (Ej: C:\\Windows): "
            read -r win_path
            echo -e "Resultado en Linux: $(winepath -u "$win_path")"
            ;;
        5)
            echo -e "\n${YELLOW}Ejecutando: winemine (Buscaminas)...${NC}"
            winemine
            ;;
        6)
            echo -e "\n${YELLOW}Ejecutando: wineconsole (cmd.exe - por defecto)...${NC}"
            wineconsole cmd
            ;;
        # --- PREFIJO WINE-11 ---
        8)
            # wine11cfg: Abrir winecfg en el prefijo wine-11
            run_wine_command winecfg
            ;;
        9)
            # wine11tricks: Ejecutar winetricks con argumentos opcionales
            echo -n "Introduce verbos de winetricks (Ej: corefonts d3dx9): "
            read -r tricks_args
            run_wine_command winetricks $tricks_args
            ;;
        10)
            # wine11 run: Ejecutar un .exe en el prefijo wine-11
            echo -n "Introduce la ruta del .exe (Ej: 'C:\\Program Files\\app.exe'): "
            read -r exe_path
            run_wine_command wine "$exe_path"
            ;;
        11)
            # wine11uninstaller: Desinstalador para el prefijo wine-11
            run_wine_command wine uninstaller
            ;;
        # --- OTROS COMANDOS DE MANTENIMIENTO ---
        12)
            # wineuninstaller: Desinstalador para el prefijo por defecto
            echo -e "\n${YELLOW}Ejecutando: wine uninstaller (prefijo por defecto)...${NC}"
            wine uninstaller
            ;;
                    # --- OTROS COMANDOS DE MANTENIMIENTO ---
        13)
            # wineuninstaller: Archivos para el prefijo por defecto
                echo -e "\n${YELLOW}⚙️ Abriendo winefile para el prefijo: /home/diego/.wine-11)...${NC}"
                WINEPREFIX=/home/diego/.wine-11 winefile

            ;;

        # --- SALIR ---
        7)
            echo -e "\n${RED}Saliendo... ¡Hasta pronto!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Opción inválida. Inténtalo de nuevo.${NC}"
            ;;
    esac
    echo -e "\n${CYAN}Presiona Enter para continuar...${NC}"
    read -r
}

# Bucle principal del menú
while true; do
    show_menu
    read -r choice
    run_command "$choice"
done
