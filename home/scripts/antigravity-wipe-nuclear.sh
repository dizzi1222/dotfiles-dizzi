#!/bin/bash
# antigravity-wipe-nuclear.sh — Reset TOTAL del perfil de Antigravity IDE
# (Fix "There was an unexpected issue setting up your account" / loginError).
#
# ⚠️  Borra TODOS los datos locales del IDE (cuenta, settings, cache, extensiones
#      locales). El onboarding arranca de cero la próxima apertura.
#      Requiere: cerrar el IDE antes de correrlo.
#
# ⚠️  NUESTRO CASO (thinkpad-x1e2, NixOS):
#      El wipe limpia; pero el login SOLO entró combinado con:
#        (1) wipe nuclear  +  (2) Proton VPN activo  +  (3) tethering datos móviles.
#      Ver README-antigravity-wipe.md en este directorio para el procedimiento completo.
set -euo pipefail

PROFILE="${1:-/home/diego/dotfiles-dizzi/Antigravity/.config/Antigravity IDE}"
MARKER="$HOME/.antigravity/runtime/.store-path"

echo "⚠️  Esto borra TODO el perfil del IDE (no hay vuelta atrás, sin backup)."
printf 'Perfil objetivo: %s\n¿Continuar? [y/N] ' "$PROFILE"
read -r ok
[ "$ok" = "y" ] || [ "$ok" = "Y" ] || { echo "abortado"; exit 1; }

# 1) cerrar procesos
pkill -f "$HOME/.antigravity/runtime" 2>/dev/null || true
pkill -f "antigravity-ide" 2>/dev/null || true
sleep 2

# 2) wipe del contenido (NOTA: aquí `find` es alias de `fd` → uso python)
if [ -d "$PROFILE" ]; then
  python3 - "$PROFILE" <<'PY'
import os, shutil, sys
P = sys.argv[1]
n = len(os.listdir(P))
for e in os.listdir(P):
    p = os.path.join(P, e)
    try:
        if os.path.islink(p) or os.path.isfile(p):
            os.unlink(p)
        else:
            shutil.rmtree(p)
    except Exception as ex:
        print("skip", e, ex)
print("perfil: %d entradas -> 0" % n)
PY
else
  echo "perfil no existe (nada que borrar): $PROFILE"
fi

# 3) forzar re-sync del runtime (recopia el store la próxima vez)
rm -f "$MARKER"

echo
echo "✅ Wipe listo. Para la PRÓXIMA apertura sigue estas instrucciones:"
echo
echo "  SÍNDROME: 'There was an unexpected issue setting up your account.'"
echo "  Causa: rate-limit/geo de Google por IP (incidente server-side, no NixOS)."
echo
echo "  ORDEN QUE FUNCIONÓ (combinar los 3):"
echo "  1) PROTON VPN  → conéctate a un país DISTINTO. Ejemplo que funcionó:"
echo "       SINGAPUR (SG)  — protonvpn-app → servidor 'SG'  (fix #5 de la comunidad)"
echo "       (servidor rápido:  protonvpncli? no: usa la app o `protonvpn-cli c -f`)"
echo "     Verificá salida distinta:  curl -s ifconfig.me"
echo "  2) TETHERING MÓVIL → activá 'Anclaje/Hotspot' en el celular y conectá la"
echo "     laptop a esa red (Igual que conectar la PC a datos móviles del teléfono)."
echo "     (Cambiar de red/IP es lo que destraba el login.)"
echo "  3) ABRÍ EL IDE UNA SOLA VEZ y logueate:"
echo "       antigravity-ide"
echo "     → onboarding limpio → Login con Google → SIN cambiar de cuenta a mitad."
echo
echo "  SI SIGUE FALLANDO: esperá unas horas SIN reintentar (cooldown de Google)."
echo "  Último recurso: borrar datos google.com/antigravity.google del navegador."
echo