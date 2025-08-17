# 💤 🔮 🗿 In Love 💜 With Arch Hypr My✨Inspiration 🔮 🔥 🚀 
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/29ba01b1-da5b-4b39-a612-360d69cb697a" />

## 💤 LazyVim 🦥
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/60c80cc3-98d7-4af0-a5bd-8842a9c8c80d" />

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Wallpapers
Wallpapers for desktop
https://github.com/dylanaraps/wal

## Fastfetch 

<h3 align="left">
Welcome to my fastfetch config presets repo :3
</h3>

[Fastfetch](https://github.com/fastfetch-cli/fastfetch) is a tool for fetching system information and displaying them in a pretty way. 
In this repo, I collect my config files that I designed for my [Arch Linux](https://archlinux.org/) [Hyprland](https://github.com/hyprwm/Hyprland) rice. 
Feel free to copy files and modify them or clone the complete repository.

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/4e5c4c97-a852-49a9-9718-acecfa6bfd00" />

Usage

Clone the repository into ``~/.local/share``

```sh
cd ~/.local/share
git clone https://github.com/LierB/fastfetch
```
and execute your preferred files (e.g. ``groups.jsonc`` or ``minimal.jsonc``) with 

```sh
fastfetch --config groups
fastfetch --config minimal
```
OR

Copy your preferred config file (if necessary images/ascii-art files), rename it to ``config.jsonc``, move it to ``~/.config/fastfetch`` and execute it with 

```sh
fastfetch
# or with additional options e.g.
fastfetch --colors-block-range-start 9 --colors-block-width 3
```

#!/bin/bash
# ────────────────────────────────────────────
# Guia/Script de reparación y post-instalación Arch Linux si archinstall falla
─❯  Incluye: GRUB, entorno gráfico, permisos, internet, programas, idioma, teclado y más.
# ────────────────────────────────────────────
### How set Network - Poner internet
[https://www.youtube.com/watch?v=x2euFpcv7hw&t=426s
](https://www.youtube.com/watch?v=x2euFpcv7hw&t=426s)
─────────────
<img width="401" height="84" alt="image" src="https://github.com/user-attachments/assets/ea9630b6-84a9-4709-a7b7-b3dff93b6de8" />
─────────────

### How install dualboot - Instalar particion
[https://www.youtube.com/watch?v=tPYCd4w65-0&t=180s
](https://www.youtube.com/watch?v=tPYCd4w65-0&t=180s)
─────────────
<img width="523" height="136" alt="image" src="https://github.com/user-attachments/assets/721c7cad-31d9-4a93-af7a-fac83ea057e7" />


## Paso 0: Arreglar GRUB si el sistema no arranca

 ─❯ Al haber formateado el boot efi, y elegido tu particion para linux, asumo que ya sabes identificar tu sda.. mira el video coño.
```
echo ">> Paso 0: Reparando GRUB..."
mount /dev/sda4 /mnt
mount /dev/sda1 /mnt/boot/efi
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
```

## Paso 1: Configurar entorno gráfico
echo ">> Paso 1: Instalando y habilitando GDM + Hyprland..."
```
sudo pacman -S --needed gdm hyprland
sudo systemctl enable gdm
sudo systemctl start gdm
```

## Paso 2: Arreglar permisos de usuario
echo ">> Paso 2: Arreglando permisos de usuario..."
```
sudo chown -R diego:diego /home/diego
```
Si el usuario no existe o permisos incompletos:
```
sudo useradd -m -g users -G wheel,audio,video,storage,power -s /bin/zsh diego
```
## Para cambiar de password:
```
 sudo passwd diego
```
## 🌐💻Paso 3: Conectarse a internet
echo ">> Paso 3: Instalando NetworkManager y Bluetooth..."
```
sudo pacman -S --needed networkmanager bluez bluez-utils blueman
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

─❯ Luego, para activar el bluetooth:
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
```

##  🌍💻Paso 4: Instalar programas y clonar repositorios
echo ">> Paso 4: Clona tus repositorios [dotifles] o instala programas adicionales..."

## ⌛Paso 5: Corregir zona horaria
echo ">> Paso 5: Configurando zona horaria..."
```
sudo timedatectl set-ntp true
sudo timedatectl set-timezone 'America/Santo_Domingo'
timedatectl status
```

## Paso 6 [Opcional]: Configurar Huion Tablet
echo ">> Paso 6: Instalando Huion Tablet (opcional)..."
```
yay -S huiontablet
```

## 🔠Paso 7: Corregir fuentes del sistema
## ~ instala [700MB] fuentes de letras globales:
echo ">> Paso 7: Instalando fuentes NerdFont y Noto..."
```
sudo pacman -S --needed \
  ttf-nerd-fonts-symbols \
  ttf-nerd-fonts-symbols-mono \
  noto-fonts \
  noto-fonts-emoji \
  ttf-dejavu \
  ttf-jetbrains-mono-nerd \
  ttf-firacode-nerd \
  ttf-font-awesome
```

## 🍜🇨🇳Opcional caracteres CJK - China, Japon etc..
```
sudo pacman -S --needed noto-fonts-cjk \
  adobe-source-han-sans-otc-fonts \
  adobe-source-han-serif-otc-fonts
# ─❯ Después de instalar las fuentes, refresca la caché de fontconfig:
fc-cache -fv
```

## Paso 8: Instalar Gruv theme icons para nwg-look✅
Me gustra mas Dracula🧛🏻 theme, pero gruv icons es god🦥💤
echo ">> Paso 8: Instalando iconos Gruv..."

```
git clone https://github.com/SylEleuth/gruvbox-plus-icon-pack.git
yay -Ss 
cd gruvbox-plus-icon-pack
# ─❯ [elige el tema que quieras, y luego:]
cp -rv Gruvbox-Plus-Dark ~/.local/share/icons
git pull
```

## 🚨Paso 9: Cambiar idioma del sistema a ingles+español 1️⃣st
echo ">> Paso 9: Configurando idioma español..."

Editar locales [/etc/locale.gen]:
```
sudo sed -i 's/^#es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' /etc/locale.gen
sudo sed -i 's/^#es_US.UTF-8 UTF-8/es_US.UTF-8 UTF-8/' /etc/locale.gen
sudo sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
```
## O manualmente:
```
sudo nvim /etc/locale.gen

# ~> Descomenta las líneas:

es_ES.UTF-8 UTF-8
es_US.UTF-8 UTF-8
en_EN.UTF-8 UTF-8
```
## ─❯ 🚨Regenerar locales:
```
sudo locale-gen
```
---------------------------
////////////////////////
---------------------------

## Paso 10: Definir idioma por defecto en conf [etc/local.conf]:
```
echo "LANG=es_ES.UTF-8" | sudo tee /etc/locale.conf
echo "LC_COLLATE=C" | sudo tee -a /etc/locale.conf
```
## O manualmente:
```
sudo nvim /etc/locale.conf
1- ~> {Y Agregas}:
LANG="es_ES.UTF-8"
LC_COLLATE=C
```
---------------------------
////////////////////////
---------------------------

## 📌 Para cambiar el lenguaje en un app en especifico.. [del idioma default] a ingles [idioma favorito de devs]...
Algunas aplicaciones como eww van a requerer que exportes, porque muchas de sus funciones, estan pensadas en inglés..

## Forzar salida consistente en inglés
```
export LC_ALL=C
export LANG=C
```
---------------------------
////////////////////////
---------------------------

## 📌Forzar [idioma default].. en apps específicas (ejemplo: rofi)  ya que rofi hace lo contrario, no respeta tu config y la remplaza...
```
LANG="es_ES.UTF-8" LC_COLLATE=C LC_ALL=es_ES.UTF-8 rofi
```
rofimoji no es compatible con todo esto ya que NO ES TEXTO. 
# ~ >Configuralo tu, LaZY.🦥💤

---------------------------
////////////////////////
---------------------------

## 📌 Paso 11: [Opcional] Cambiar teclado a EN
echo ">> Paso 10: Configurando teclado..."
## Temporal (solo sesión actual)
```
setxkbmap en
```
## Permanente (Xorg)
```
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf > /dev/null <<EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "en"
    Option "XkbModel" "pc105"
EndSection
EOF
```

## Permanente (Wayland / systemd)
```
sudo localectl set-x11-keymap en
```
echo ">> Script finalizado. Reinicia para aplicar cambios."

# 📌TOTALMENTe OPCIONAL [intel UHD 600 drivers]
## Para instalarlo en mi patata.. 🥔💻🧨
```
sudo pacman -S vulkan-headers vulkan-icd-loader
```
# 🌄🦥🗿 EL INICIO DE UN VIAJE POR EL COSMOS.. 🤓🚀🌌
