#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# WAYDROID SCRIPTS LAUNCHER - Gestión completa de Waydroid
# Con fix para CachyOS/EndeavourOS y opción de reset ID
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$HOME/waydroid_script/"
VENV_DIR="$SCRIPT_DIR/venv"

WAYDROID_NET="/usr/lib/waydroid/data/scripts/waydroid-net.sh"

# ─── Colores ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ─── Fix nftables para CachyOS/EndeavourOS ───────────────────────────
apply_net_fix() {
	echo -e "${YELLOW}🔧 Aplicando fix de red para nftables...${RESET}"
	sudo sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' "$WAYDROID_NET" 2>/dev/null &&
		echo -e "${GREEN}✅ Fix aplicado.${RESET}" ||
		echo -e "${YELLOW}⚠️  Fix ya estaba aplicado o falló.${RESET}"
}

if [ -f "$WAYDROID_NET" ]; then
	if grep -qiE "endeavouros|cachyos" /etc/os-release 2>/dev/null; then
		echo -e "${CYAN}🐧 Sistema detectado: $(grep '^NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '\"')${RESET}"
		apply_net_fix
	elif command -v nft &>/dev/null && ! command -v iptables-legacy &>/dev/null; then
		echo -e "${CYAN}🐧 Sistema con nftables detectado${RESET}"
		apply_net_fix
	else
		echo -e "${GREEN}✅ Sistema compatible, no se necesita fix.${RESET}"
	fi
else
	echo -e "${RED}⚠️  No se encontró waydroid-net.sh — ¿Waydroid instalado?${RESET}"
fi

echo ""

# ─── Menú Principal ──────────────────────────────────────────────────
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║         📱 WAYDROID SCRIPTS LAUNCHER              ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${YELLOW}1)${RESET} 🚀 Ejecutar waydroid_script (gestión GApps)"
echo -e "  ${YELLOW}2)${RESET} 🔄  Reiniciar container"
echo -e "  ${YELLOW}3)${RESET} 🆔 Obtener Android ID"
echo -e "  ${YELLOW}4)${RESET} 💥 RESET COMPLETO - Borrar datos y generar nuevo ID"
echo -e "  ${YELLOW}5)${RESET} ❌ Salir"
echo ""

printf "Selecciona opción: "
read -r option
echo ""

case "$option" in
1)
	# ── Ejecutar waydroid_script ───────────────────────────────
	if [ ! -d "$SCRIPT_DIR" ]; then
		echo -e "${CYAN}Clonando repositorio...${RESET}"
		git clone https://github.com/casualsnek/waydroid_script.git "$SCRIPT_DIR" || {
			echo -e "${RED}Error al clonar.${RESET}"
			exit 1
		}
	fi

	cd "$SCRIPT_DIR" || exit 1

	if [ ! -d "$VENV_DIR" ]; then
		echo -e "${CYAN}Creando entorno virtual...${RESET}"
		python -m venv venv
		source venv/bin/activate
		pip install --upgrade pip
		pip install inquirerpy requests tqdm
		[ -f "requirements.txt" ] && pip install -r requirements.txt
	else
		source venv/bin/activate
	fi

	echo -e "${CYAN}Ejecutando waydroid_script...${RESET}"
	echo "=========================================="
	sudo venv/bin/python main.py
	deactivate
	;;

2)
	# ── Reiniciar container ───────────────────────────────────
	echo -e "${YELLOW}Reiniciando Waydroid...${RESET}"
	waydroid session stop 2>/dev/null
	sudo systemctl restart waydroid-container
	waydroid session start &
	echo -e "${CYAN}⏳ Esperando 15 segundos...${RESET}"
	sleep 15
	echo -e "${GREEN}✅ Waydroid reiniciado${RESET}"
	;;

3)
	# ── Obtener Android ID ───────────────────────────────────
	echo -e "${CYAN}Obteniendo Android ID...${RESET}"
	if ! systemctl is-active waydroid-container &>/dev/null; then
		echo -e "${YELLOW}Container detenido, iniciándolo...${RESET}"
		sudo systemctl start waydroid-container
		waydroid session start &
		sleep 20
	fi

	ANDROID_ID=$(sudo waydroid shell settings get secure android_id 2>/dev/null)

	if [ -n "$ANDROID_ID" ]; then
		echo ""
		echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
		echo -e "${GREEN}║              🆔 TU ANDROID ID                        ║${RESET}"
		echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
		echo ""
		echo -e "  ${CYAN}ID:${RESET} ${YELLOW}$ANDROID_ID${RESET}"
		echo ""
		echo -e "${CYAN}Registra en: ${YELLOW}https://www.google.com/android/uncertified/${RESET}"
		echo ""
		# Copiar al clipboard
		echo "$ANDROID_ID" | xclip -selection clipboard 2>/dev/null && echo -e "${GREEN}✓ Copiado al portapapeles${RESET}"
	else
		echo -e "${RED}✗ No se pudo obtener el ID. ¿Waydroid está corriendo?${RESET}"
	fi
	;;

4)
	# ── RESET COMPLETO ────────────────────────────────────────
	echo -e "${RED}╔══════════════════════════════════════════════════════╗${RESET}"
	echo -e "${RED}║           ⚠️  RESET COMPLETO DE WAYDROID           ║${RESET}"
	echo -e "${RED}║  Esto borrará TODOS los datos y generará nuevo ID  ║${RESET}"
	echo -e "${RED}╚══════════════════════════════════════════════════════╝${RESET}"
	echo ""
	printf "¿Estás seguro? Escribe 'SI' para confirmar: "
	read -r confirm

	if [ "$confirm" != "SI" ]; then
		echo -e "${YELLOW}Cancelado.${RESET}"
		exit 0
	fi

	echo ""
	echo -e "${YELLOW}[1/5]${RESET} Deteniendo servicios..."
	waydroid session stop 2>/dev/null
	sudo systemctl stop waydroid-container 2>/dev/null
	sudo systemctl disable waydroid-container 2>/dev/null
	echo -e "${GREEN}✓ Servicios detenidos${RESET}"

	echo ""
	echo -e "${YELLOW}[2/5]${RESET} Respaldando datos..."
	BACKUP_DIR=~/waydroid-backup-$(date +%Y%m%d_%H%M%S)
	mkdir -p "$BACKUP_DIR"
	[ -d /var/lib/waydroid ] && sudo cp -r /var/lib/waydroid "$BACKUP_DIR/"
	echo -e "${GREEN}✓ Backup en: $BACKUP_DIR${RESET}"

	echo ""
	echo -e "${YELLOW}[3/5]${RESET} Eliminando datos..."
	sudo rm -rf /var/lib/waydroid
	rm -rf ~/.local/share/waydroid
	rm -rf ~/.cache/waydroid
	echo -e "${GREEN}✓ Datos eliminados${RESET}"

	echo ""
	echo -e "${YELLOW}[4/5]${RESET} Iniciando container..."
	sudo systemctl enable --now waydroid-container
	waydroid session start &
	echo -e "${CYAN}⏳ Esperando 30 segundos para generación de nuevo ID...${RESET}"
	sleep 30

	echo ""
	echo -e "${YELLOW}[5/5]${RESET} Obteniendo nuevo Android ID..."
	NEW_ID=$(sudo waydroid shell settings get secure android_id 2>/dev/null)

	if [ -n "$NEW_ID" ]; then
		echo ""
		echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
		echo -e "${GREEN}║          ✅ NUEVO ANDROID ID GENERADO              ║${RESET}"
		echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
		echo ""
		echo -e "  ${CYAN}ANTIGUO ID:${RESET} $ANDROID_ID"
		echo -e "  ${GREEN}NUEVO ID:${RESET}   ${YELLOW}$NEW_ID${RESET}"
		echo ""
		echo -e "${CYAN}Registra el NUEVO ID en:${RESET}"
		echo -e "${YELLOW}   https://www.google.com/android/uncertified/${RESET}"
		echo ""
		echo -e "${CYAN}Espera 10-30 minutos, luego:${RESET}"
		echo -e "${YELLOW}   waydroid session stop${RESET}"
		echo -e "${YELLOW}   sudo systemctl restart waydroid-container${RESET}"
		echo -e "${YELLOW}   waydroid session start${RESET}"

		# Copiar al clipboard
		echo "$NEW_ID" | xclip -selection clipboard 2>/dev/null && echo -e "${GREEN}✓ Nuevo ID copiado al portapapeles${RESET}"
	else
		echo -e "${RED}✗ No se pudo obtener el ID. Espera más o verifica logs.${RESET}"
	fi
	;;

*)
	echo -e "${CYAN}👋 ¡Hasta luego!${RESET}"
	exit 0
	;;
esac

echo ""
echo -e "${CYAN}Presiona Enter para salir...${RESET}"
read
