~ > Aquí está la recapitulación completa en el orden cronológico que debes seguir si archinstall falla.

---------------------------
////////////////////////
---------------------------
Paso 0: El sistema no arranca (arreglar GRUB)
Después de que archinstall falla, el primer problema es que el ordenador no arranca y te quedas en la terminal del USB de Arch. Esto se debe a un error con el gestor de arranque GRUB.

Solución: Reinstala GRUB desde el entorno arch-chroot.

mount /dev/sda4 /mnt
mount /dev/sda1 /mnt/boot/efi
arch-chroot /mnt
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

---------------------------
////////////////////////
---------------------------

Paso 1: Configurar el entorno gráfico
Finalmente, si el sistema sigue arrancando en una terminal (TTY) y no aparece GDM, es porque el entorno gráfico no está bien configurado.

Solución: Instala y habilita el gestor de pantalla gdm y el compositor hyprland.

sudo pacman -S gdm hyprland
sudo systemctl enable gdm
sudo systemctl start gdm

exit
reboot
Una vez hecho esto, el ordenador ya debería arrancar en tu nueva instalación, y deberias de poder ver tu internet.
---------------------------
////////////////////////
---------------------------

Paso 2: Arreglar los permisos de usuario
Al iniciar sesión, puedes encontrar problemas con los permisos, como errores al intentar crear archivos o clonar repositorios.

Solución: Asegúrate de que el usuario tiene la propiedad de su directorio personal.

sudo chown -R diego:diego /home/diego
Si tu usuario no existe o tiene permisos incompletos, créalo de nuevo con los grupos correctos:

~ O puedes forzar con sudo su 
			[pero no es recomendable]

useradd -m -g users -G wheel,audio,video,storage,power -s /bin/zsh diego
passwd diego

---------------------------
////////////////////////
---------------------------

Paso 3: Conectarse a internet
El siguiente obstáculo es la falta de conexión, que hace que pacman y git clone fallen con errores de "Could not resolve host".

Solución: Instala y habilita el gestor de red+bluetooth (si no está ya).

sudo pacman -S networkmanager bluez bluez-utils blueman
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
Paso 4: Instalar programas y clonar repositorios
Ahora que tienes internet y los permisos correctos, puedes instalar programas.


─❯ Luego, para activar el bluetooth:

sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service

---------------------------
////////////////////////
---------------------------

─❯ Paso 5: Corregir la zona horaria. 
sudo timedatectl set-ntp true

timedatectl status

sudo timedatectl set-timezone 'America/Santo_Domingo'

---------------------------
////////////////////////
---------------------------

─❯ [Opcional] Paso 6: Configurar Huion Tablet
yay -Ss huion

y elige el 1:
yay -S huiontablet 15.0.0.162-1


---------------------------
////////////////////////
---------------------------

─❯ Paso 7: Corregir Fuente del sistema, iconos. + Gruv theme icons para nwg look {no es lo mismo)
~ > 1- Corregir fuente del sistema[NerdFont]

~ instala [700MB] fuentes de letras globales:

sudo pacman -S --needed \
  ttf-nerd-fonts-symbols \
  ttf-nerd-fonts-symbols-mono \
  noto-fonts \
  noto-fonts-emoji \
  ttf-dejavu \
  ttf-jetbrains-mono-nerd \
  ttf-firacode-nerd \
  ttf-font-awesome 
  
~ Y opcional los caracteres chinos, japoneses:
sudo pacman -S --needed \
  noto-fonts-cjk \
  adobe-source-han-sans-otc-fonts \
  adobe-source-han-serif-otc-fonts

~ Después de instalar las fuentes, refresca la caché de fontconfig:

fc-cache -fv

---------------------------
////////////////////////
---------------------------

Paso 8: Gruv theme icons para nwg look {no es lo mismo que lo anterior)

~ > 1- Clonar Gruv Icons
Si quieres los iconos más recientes tienes que clonar todo el repositorio:

git clone https://github.com/SylEleuth/gruvbox-plus-icon-pack.git
yay -Ss 

~ > 2- instalacion de gruv:
cd gruvbox-plus-icon-pack

ls -a 
[elige el tema que quieras, y luego:]

~ Descomprímalo y copie el contenido de la carpeta en su directorio home/.local/share/icons:

cp -rv Gruvbox-Plus-Dark ~/.local/share/icons

~ Y git pull

para descargar archivos agregados desde la última extracción.

---------------------------
////////////////////////
---------------------------

1️⃣ Cambiar idioma del sistema a español (Arch Linux)

Editar locales:

sudo nvim /etc/locale.gen


✅ Descomenta la línea:

es_ES.UTF-8 UTF-8


(y si quieres mantener inglés también, deja en_US.UTF-8 UTF-8 descomentado).

Regenerar locales:

sudo locale-gen


Definir idioma por defecto:

echo "LANG=es_ES.UTF-8" | sudo tee /etc/locale.conf


(Opcional) Aplicar al usuario actual:

export LANG=es_ES.UTF-8

2️⃣ Cambiar el teclado
Teclado temporal (solo sesión actual)
setxkbmap es

Teclado permanente (Xorg)

Crear archivo:

sudo nvim /etc/X11/xorg.conf.d/00-keyboard.conf


Contenido:

Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "es"
    Option "XkbModel" "pc105"
EndSection

Teclado permanente (Wayland / systemd)
sudo localectl set-x11-keymap es


(Esto también funciona para Xorg y es más rápido que editar a mano)

