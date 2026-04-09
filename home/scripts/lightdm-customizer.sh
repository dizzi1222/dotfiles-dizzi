#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# LIGHTDM CUSTOMIZER - Fondo y avatar para LightDM Greeter
# ══════════════════════════════════════════════════════════════════════════════

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[96m'
GREEN='\033[92m'
YELLOW='\033[93m'
RED='\033[91m'
BLUE='\033[94m'
MAGENTA='\033[95m'

LIGHTDM_DIR="/usr/share/lightdm-webkit/themes/glorious"
BACKGROUNDS_DIR="/usr/share/backgrounds"
AVATAR_DIR="/var/lib/AccountsService/icons"

# ─── Verificar permisos ───────────────────────────────────────────────────
check_root() {
	if [ "$EUID" -ne 0 ]; then
		echo -e "${RED}❌ Necesitas permisos de root (sudo)${RESET}"
		return 1
	fi
	return 0
}

# ─── Cambiar fondo ──────────────────────────────────────────────────────
change_background() {
	echo -e "\n${CYAN}${BOLD}🖼️  CAMBIAR FONDO DE LIGHTDM${RESET}\n"

	# Buscar wallpapers desde dotfiles o home
	local wall_dir="$HOME/wallpapers/wallpapers"
	[ ! -d "$wall_dir" ] && wall_dir="$HOME/dotfiles-dizzi/wallpapers/wallpapers/wallpapers"
	[ ! -d "$wall_dir" ] && wall_dir="$HOME/dotfiles-dizzi/wallpapers/wallpapers"

	if [ ! -d "$wall_dir" ]; then
		echo -e "${YELLOW}⚠️  No existe $wall_dir${RESET}"
		echo -e "${DIM}Usando fondo por defecto...${RESET}"
	fi

	# Listar opciones
	echo -e "${DIM}Opciones disponibles:${RESET}"
	echo -e "${CYAN}1)${RESET} Wallpapers locales"
	echo -e "${CYAN}2)${RESET} Usar imagen personalizada"
	echo -e "${CYAN}3)${RESET} Quitar fondo (oscuro)"
	echo -e "${CYAN}0)${RESET} Volver"
	echo ""
	printf "Selecciona: "
	read -r opt

	case "$opt" in
	1)
		# Listar wallpapers
		local walls=$(find "$wall_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | head -10)
		if [ -z "$walls" ]; then
			echo -e "${RED}No hay wallpapers en $wall_dir${RESET}"
			return 1
		fi

		echo -e "${DIM}Wallpapers disponibles:${RESET}"
		local i=1
		local files=()
		for w in $walls; do
			echo -e "${CYAN}$i)${RESET} $(basename "$w")"
			files+=("$w")
			((i++))
		done

		printf "Selecciona número: "
		read -r sel
		sel=$((sel - 1))

		if [ "$sel" -ge 0 ] && [ "$sel" -lt "${#files[@]}" ]; then
			local src="${files[$sel]}"
			local dest="$BACKGROUNDS_DIR/lightdm.jpg"

			echo -e "${YELLOW}📋 Copiando $src...${RESET}"
			cp "$src" "$dest"
			chmod 644 "$dest"

			# Configurar en lightdm
			if ! grep -q "background_images" /etc/lightdm/lightdm-webkit2-greeter.conf 2>/dev/null; then
				echo "background_images = $BACKGROUNDS_DIR" | sudo tee -a /etc/lightdm/lightdm-webkit2-greeter.conf >/dev/null
			fi

			echo -e "${GREEN}✅ Fondo actualizado${RESET}"
		fi
		;;
	2)
		printf "Ruta de imagen: "
		read -r src
		if [ -f "$src" ]; then
			cp "$src" "$BACKGROUNDS_DIR/lightdm.jpg"
			chmod 644 "$BACKGROUNDS_DIR/lightdm.jpg"
			echo -e "${GREEN}✅ Fondo actualizado${RESET}"
		else
			echo -e "${RED}❌ Archivo no existe${RESET}"
		fi
		;;
	3)
		sudo rm -f "$BACKGROUNDS_DIR/lightdm.jpg"
		echo -e "${GREEN}✅ Fondo eliminado${RESET}"
		;;
	*)
		return 0
		;;
	esac
}

# ─── Cambiar avatar ──────────────────────────────────────────────────────
change_avatar() {
	echo -e "\n${CYAN}${BOLD}👤 CAMBIAR AVATAR DE USUARIO${RESET}\n"

	# Buscar avatar
	local avatars=$(find "$HOME/Pictures" "$HOME/.face" -type f \( -iname "*.png" -o -iname "*.jpg" \) 2>/dev/null | head -10)

	echo -e "${DIM}Opciones:${RESET}"
	echo -e "${CYAN}1)${RESET} Usar imagen existente"
	echo -e "${CYAN}2)${RESET} Ingresar ruta personalizada"
	echo -e "${CYAN}0)${RESET} Volver"
	echo ""
	printf "Selecciona: "
	read -r opt

	case "$opt" in
	1)
		if [ -n "$avatars" ]; then
			echo -e "${DIM}Imágenes encontradas:${RESET}"
			local i=1
			local files=()
			for a in $avatars; do
				echo -e "${CYAN}$i)${RESET} $(basename "$a")"
				files+=("$a")
				((i++))
			done

			printf "Selecciona: "
			read -r sel
			sel=$((sel - 1))

			if [ "$sel" -ge 0 ] && [ "$sel" -lt "${#files[@]}" ]; then
				local src="${files[$sel]}"
				copy_avatar "$src"
			fi
		else
			echo -e "${YELLOW}⚠️  No se encontraron imágenes${RESET}"
		fi
		;;
	2)
		printf "Ruta de imagen: "
		read -r src
		if [ -f "$src" ]; then
			copy_avatar "$src"
		else
			echo -e "${RED}❌ Archivo no existe${RESET}"
		fi
		;;
	*)
		return 0
		;;
	esac
}

copy_avatar() {
	local src="$1"
	local user="$USER"

	# Usar .face del usuario directamente
	local face_src="$HOME/.face"

	if [ -f "$face_src" ]; then
		sudo ln -sf "$face_src" "$AVATAR_DIR/$user"
		sudo chmod 644 "$AVATAR_DIR/$user" 2>/dev/null || true
		echo -e "${GREEN}✅ Avatar enlazado desde .face${RESET}"
	else
		echo -e "${YELLOW}⚠️  No existe $face_src${RESET}"
	fi
}

# ─── Instalar tema Glorious ──────────────────────────────────────────────
install_glorious() {
	echo -e "\n${CYAN}${BOLD}📦 INSTALAR TEMA GLORIOUS${RESET}\n"

	if [ -d "$LIGHTDM_DIR" ]; then
		echo -e "${GREEN}✅ Tema ya instalado${RESET}"
		return 0
	fi

	echo -e "${YELLOW}📥 Descargando tema...${RESET}"
	wget -q git.io/webkit2 -O /tmp/theme.tar.gz

	sudo mkdir -p /usr/share/lightdm-webkit/themes
	sudo tar -xzf /tmp/theme.tar.gz -C /usr/share/lightdm-webkit/themes/
	sudo mv /usr/share/lightdm-webkit/themes/glorious /tmp/glorious 2>/dev/null || true

	echo -e "${GREEN}✅ Tema instalado${RESET}"
}

# ─── Menú principal ──────────────────────────────────────────────────────
main_menu() {
	clear
	echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
	echo -e "${CYAN}${BOLD}║        🖥️  LIGHTDM CUSTOMIZER                            ║${RESET}"
	echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}\n"

	echo -e "${DIM}─────────────────────────────────────────────────────────${RESET}"
	echo -e "${YELLOW}1)${RESET} 🖼️  Cambiar fondo"
	echo -e "${YELLOW}2)${RESET} 👤 Cambiar avatar"
	echo -e "${YELLOW}3)${RESET} 📦 Instalar tema Glorious"
	echo -e "${YELLOW}4)${RESET} 🔄 Reiniciar LightDM"
	echo -e "${RED}0)${RESET} ❌ Volver"
	echo -e "${DIM}─────────────────────────────────────────────────────────${RESET}\n"
}

# ─── MAIN ───────────────────────────────────────────────────────────────
main() {
	check_root || {
		echo -e "${YELLOW}⚠️  Ejecuta con sudo${RESET}"
		echo -e "${DIM}sudo $0${RESET}"
		exit 1
	}

	while true; do
		main_menu
		printf "Selecciona opción: "
		read -r opt
		echo ""

		case "$opt" in
		1) change_background ;;
		2) change_avatar ;;
		3) install_glorious ;;
		4)
			echo -e "${YELLOW}🔄 Reiniciando LightDM...${RESET}"
			sudo systemctl restart lightdm
			echo -e "${GREEN}✅ LightDM reiniciado${RESET}"
			;;
		0) exit 0 ;;
		*) echo -e "${RED}Opción inválida${RESET}" ;;
		esac

		echo ""
		printf "Presiona Enter..."
		read -r
	done
}

main "$@"
