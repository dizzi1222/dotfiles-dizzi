# Migración a Bazzite

Usar este plan cuando Diego pida «migracion» sobre dotfiles-dizzi.
Consolidar los cambios revisados en un solo commit de migración.

## Identidad del commit

- Repositorio `/var/home/diego/dotfiles-dizzi`.
- Título exacto `@Migration to Bazzite con ascii de fedora no puede faltar`.
- Autor `nobody <nobody@localhost>`.
- El hash cambia con cada amend. Buscar el título exacto en la historia
  de la rama actual.

## Procedimiento

1. Revisar la rama, el estado, el índice y la historia reciente. Encontrar
   el commit con el título exacto en la rama de trabajo.
2. Comparar el árbol con la migración y revisar los cambios por archivo.
   Distinguir lo que ya está en el índice, lo que queda sin stage y los
   commits temporales encima de la migración.
3. Preparar solo los cambios de alcance confirmado. Si la migración ya
   es HEAD, usar el índice revisado directamente. Si hay commits
   temporales encima y todos pertenecen a la migración, registrar el
   hash anterior antes de usar `git reset --soft <commit-migración>`.
   Volver a comprobar el índice antes del amend.
4. Mantener el título y el autor. Actualizar el cuerpo con lo que el
   árbol realmente hace. Cada punto explica el cambio y su efecto.
   Los nombres de archivo sirven como referencia cuando aportan
   información. El cuerpo de abajo es un ejemplo para actualizar en
   cada migración.
5. Validar el índice con `git diff --cached --check` y las pruebas
   pertinentes. Guardar el mensaje en un archivo y ejecutar
   `git commit --amend --author='nobody <nobody@localhost>' -F <mensaje>`.
6. Comprobar el nuevo hash, el título, el autor, el padre y que el árbol
   del nuevo commit coincide con el índice que se revisó.
7. Publicar solo cuando Diego lo pida. Si el remoto ya contiene una
   versión anterior de la migración, revisar qué commits se
   reemplazarían antes de usar un lease explícito.

## Ejemplo de descripción consolidada

Completa la migración a Bazzite Desktop con Plasma y conserva los
ajustes compartidos con Hyprland y Niri.

Sistema y arranque

- Instala Discord nativo desde RPM Fusion y recrea la entrada de GRUB
  «Bazzite Desktop (Plasma)» tras finalizar el despliegue con Discord
  (bde475ce durante la migración).
- Mantiene Espanso nativo en Wayland con teclado US, expansión por
  portapapeles y secuencias para los acentos. Documenta el ajuste
  global del mouse zurdo Compx 2.4G mediante udev.
- Instala una sola fuente del script de arranque hacia Windows.
  El servicio usa la copia instalada para preparar Windows como
  próximo arranque al apagar o reiniciar Bazzite.
- Incorpora Loupe, ncdu, du-dust, antimicrox y playerctl a la capa
  nativa. Playerctl permite que Eww lea los metadatos de reproducción
  que publica el reproductor.
- Ofrece Antigravity CLI (agy), OpenCommit por npm y PostgreSQL con
  psql, pg_dump y pg_restore. El instalador TUI de Homebrew permite
  buscar paquetes con gum y conserva la lista en caché durante 24 h.

Plasma, notificaciones y apariencia

- Fija SwayNC en 0.11.0 para que consultar los botones del panel no
  ejecute sus acciones de Wi-Fi y Bluetooth. Construye el daemon y
  el cliente juntos y vincula el servicio a Plasma Wayland.
- Genera un perfil exclusivo para Bazzite con brillo de teclado y
  acciones de Plasma para Bluetooth, bloqueo, salida y luz nocturna.
  El perfil original y los scripts de Eww de Hyprland y Niri se
  conservan.
- Retira el servicio y el drop-in que sobrescribían los atajos de
  Plasma. Respalda archivos en conflicto antes de enlazar los atajos
  y lanzadores mantenidos en el repo.
- Mantiene Meta+N para SwayNC y Meta+Mayús+Punto para Glyphs. Añade
  Meta+Coma para enfocar el siguiente monitor y llevar el puntero
  a la ventana enfocada allí, y Meta+Ctrl+Coma para mover la ventana
  activa a la pantalla anterior.
- Configura Colloid-Pink-Dark para GTK e iconos, Noto Sans 11 y el
  cursor Kafka del repo. Conserva los enlaces de GTK al escribir
  ajustes y añade xcur2png para las vistas previas de nwg-look.
- Abre Satty desde Cinnamon para capturas de pantalla completa o
  de una región. Añade iconos de Spotify y YouTube Music a hicolor.
- Conserva los archivos de actualización y el manifiesto instalado
  de Steam al ejecutar la limpieza de Fedora.

Wine y lanzadores

- Mantiene Soda 11.0-10 para WoW64 y .NET 4.8, y GE-Proton8-26 para
  los sockets AF_UNIX del puente IPC de Discord. Incluye los wrappers
  de Wine, bridge.exe y winediscordipcbridge.exe, junto con el ajuste
  del registro para Windows 10 y la receta de Winetricks.
- Conserva los lanzadores que inician el puente antes de CustomRP
  para Wine y Bottles y sus iconos propios. El acceso directo de
  CustomRP usa Soda con el prefijo de Wine del usuario.
- Oculta los accesos duplicados de Discord y el lanzador de Brave
  de Lutris en el menú. System Control abre el historial de Zsh.
- Actualiza la referencia de Neovim al commit que abre copy.md en
  una ventana flotante con <leader>sz.
