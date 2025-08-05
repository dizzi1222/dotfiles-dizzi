#!/usr/bin/env bash
# CLIPHIST o7 copyq
# executes same behaviour as below but with support for images
#
# cliphist list | wofi --dmenu | cliphist decode
#
# produces thumbnails and stores them in XDG_CACHE_HOME
# note: does NOT put in clipboard, call wl-copy yourself!  <-- ESTO CAMBIA, AHORA LO PEGAREMOS NOSOTROS

# set up thumbnail directory
thumb_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
mkdir -p "$thumb_dir"

cliphist_list="$(cliphist list)"

# delete thumbnails in cache but not in cliphist
for thumb in "$thumb_dir"/*; do
  clip_id="${thumb##*/}"
  clip_id="${clip_id%.*}"
  check=$(rg <<<"$cliphist_list" "^$clip_id\s")
  if [ -z "$check" ]; then
    >&2 rm -v "$thumb"
  fi
done

# remove unnecessary image tags
# create thumbnail if image not processed already
# print escape sequence
read -r -d '' prog <<EOF
/^[0-9]+\\s<meta http-equiv=/ { next }
match(\$0, /^([0-9]+)\\s(\\[\\[\\s)?binary.*(jpg|jpeg|png|bmp)/, grp) {
    image = grp[1]"."grp[3] # Construye el nombre de archivo de la imagen (ID.ext)
    
    # ESTA ES LA LÍNEA DE CÓDIGO CLAVE CORREGIDA
    # Genera la miniatura:
    # 1. 'printf' pasa el ID sin salto de línea a 'cliphist decode'.
    # 2. 'cliphist decode' pone la imagen en el portapapeles de Wayland.
    # 3. 'wl-paste -n' lee el contenido binario de la imagen del portapapeles y lo manda a 'magick'.
    # 4. 'magick -' lee de stdin, redimensiona y guarda en el archivo temporal.
    system("test -f " ENVIRON["THUMB_DIR_AWK"] "/" image " || (printf \"%s\" " grp[1] " | cliphist decode && wl-paste -n | magick - -resize '256x256>' " ENVIRON["THUMB_DIR_AWK"] "/" image ")")
    
    # Imprime la línea para Wofi con la ruta de la imagen
    # Agregamos "IMG_PREFIX:" para distinguir fácilmente en el post-procesamiento
    print "IMG_PREFIX:" \$0 "img:" ENVIRON["THUMB_DIR_AWK"] "/" image
    next
}
1
EOF

# Pasar la variable 'thumb_dir' de bash a gawk usando -v
export THUMB_DIR_AWK="$thumb_dir" # Exportar para que ENVIRON la vea
# La salida de gawk se procesa para Rofi/Wofi.
# Los elementos de imagen tendrán el prefijo "IMG_PREFIX:"
wofi_output=$(gawk "$prog" <<<$cliphist_list)

# Usar wofi para mostrar el historial y capturar la selección
selected_line=$(echo -e "$wofi_output" | wofi -I --dmenu -Dimage_size=100 -Dynamic_lines=true)

# stop execution if nothing selected in wofi menu
[ -z "$selected_line" ] && exit 1

# Extraer el ID de cliphist de la línea seleccionada
clip_id=$(echo "$selected_line" | awk '{print $1}')

# Validar que el ID es un número antes de intentar decodificarlo
if [[ "$clip_id" =~ ^[0-9]+$ ]]; then
  # --- INICIO DE LA LÓGICA DE "MATAR Y REINICIAR" EL OBSERVADOR DE CLIPHIST ---
  # Encontrar el PID del proceso wl-paste --watch cliphist store
  CLIPHIST_WATCH_PID=$(pgrep -f "wl-paste --watch cliphist store")

  # Si se encontró el proceso, matarlo temporalmente
  if [ -n "$CLIPHIST_WATCH_PID" ]; then
    kill "$CLIPHIST_WATCH_PID"
    sleep 0.1 # Pequeño retraso para asegurar que el proceso se detenga
  fi

  # Decodificar el elemento seleccionado y copiarlo al portapapeles
  printf "%s" "$clip_id" | cliphist decode | wl-copy

  # Re-iniciar el proceso wl-paste --watch cliphist store si estaba corriendo antes
  if [ -n "$CLIPHIST_WATCH_PID" ]; then
    wl-paste --watch cliphist store &
    disown
  fi
  # --- FIN DE LA LÓGICA DE "MATAR Y REINICIAR" ---

else
  # Si por alguna razón no se pudo extraer un ID válido, salir con un error
  >&2 echo "Error: No se pudo extraer un ID numérico de la selección."
  exit 1
fi
