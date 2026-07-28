# NixOS + Home Manager Configuration

This configuration is for the **ThinkPad X1 Extreme Gen 2** (GTX 1650 hybrid).

> **Kernel:** Use default (latest stable), not LTS. NVIDIA hybrid drivers work better with recent kernels.
>
> **Windows 11 dual boot:** No formatear la partición EFI existente. El instalador NixOS la comparte con GRUB.

## Installation (from NixOS ISO)

### Option A: GUI Installer (Recommended)

El instalador gráfico de NixOS maneja particionado, formateo, instalación y GRUB.

#### Step 1: Boot from NixOS ISO USB

Selecciona "Install" en el menú de arranque.

#### Step 2: Partitioning

En el instalador GUI:

1. Selecciona tu disco NVMe
2. **Manual partitioning** (no "Erase disk")
3. Selecciona la partición EFI existente → **no formatear** → mount en `/boot`
4. Crea partición root (ext4, ~80GB+) → mount en `/`
5. Crea partition swap (~8GB)
6. Aplica cambios

> ⚠️ **Dual boot:** NO tocar la partición EFI de Windows. Solo crear nuevas particiones en espacio libre.

#### Step 3: Install & Reboot

1. Configura usuario (diego) y contraseña
2. Instala
3. Reboot

#### Step 4: Apply Custom Config (after reboot)

```bash
# 0. Instalar git temporal (no viene por defecto en NixOS)
nix-shell -p git

# 1. Clone tu repo
git clone https://github.com/dizzi1222/dotfiles-dizzi.git ~/dotfiles-dizzi

# 2. Aplicar config del sistema (flakes no habilitado aún, usar --extra-experimental-features)
cd ~/dotfiles-dizzi/nixconf
sudo nix --extra-experimental-features "nix-command flakes" os-rebuild switch --flake .#thinkpad-x1e2

# 3. Aplicar home manager (nix run, NO home-manager)
nix --extra-experimental-features "nix-command flakes" run github:nix-community/home-manager -- switch --flake .#diego@thinkpad-x1e2
```

---

### Option B: CLI Installer (Advanced)

Instalación manual completa desde terminal.

#### Step 1: Boot & Network

```bash
# Boot from NixOS ISO USB

# Ethernet (auto)
sudo systemctl start dhcpcd

# WiFi
sudo iwctl
station wlan0 connect "YOUR_WIFI"
exit
```

#### Step 2: Partition Disk

```bash
# Identify your disk
lsblk

# Partition (NVMe example)
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart root ext4 512MB -8GB
sudo parted /dev/nvme0n1 -- mkpart swap linux-swap -8GB 100%
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MB 512MB
sudo parted /dev/nvme0n1 -- set 3 esp on
```

#### Step 3: Format & Mount

```bash
sudo mkfs.ext4 -L nixos /dev/nvme0n1p1
sudo mkswap -L swap /dev/nvme0n1p2
sudo mkfs.fat -F32 -L boot /dev/nvme0n1p3

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
sudo swapon /dev/nvme0n1p2
```

#### Step 4: Clone Repo

```bash
nix-shell -p git
git clone https://github.com/dizzi1222/dotfiles-dizzi.git /mnt/home/diego/dotfiles-dizzi
sudo chown -R diego:users /mnt/home/diego/dotfiles-dizzi
```

#### Step 5: Generate Hardware Config

```bash
sudo nixos-generate-config --root /mnt
```

#### Step 6: Install NixOS

```bash
# Copy your configuration
sudo cp /mnt/home/diego/dotfiles-dizzi/nixconf/hosts/thinkpad-x1e2/configuration.nix /mnt/etc/nixos/configuration.nix

# Install
sudo nixos-install --flake /mnt/etc/nixos#thinkpad-x1e2

# When prompted, set password for diego user
sudo reboot
```

#### Step 7: Home Manager (after reboot)

```bash
# Login as diego

# Instalar git temporal
nix-shell -p git

# Clone repo
git clone https://github.com/dizzi1222/dotfiles-dizzi.git ~/dotfiles-dizzi

# Aplicar config del sistema
cd ~/dotfiles-dizzi/nixconf
sudo nixos-rebuild switch --flake .#thinkpad-x1e2

# Aplicar home manager (nix run, NO home-manager)
nix run github:nix-community/home-manager -- switch --flake .#diego@thinkpad-x1e2
```

## Daily Usage

### Rebuild System

```bash
# After editing any .nix file in nixconf/
cd ~/dotfiles-dizzi/nixconf
sudo nixos-rebuild switch --flake .#thinkpad-x1e2
```

### Rebuild Home Manager

```bash
# After editing home-manager/*.nix
cd ~/dotfiles-dizzi/nixconf
nix run github:nix-community/home-manager -- switch --flake .#diego@thinkpad-x1e2
```

### Update Inputs

```bash
cd ~/dotfiles-dizzi/nixconf
nix flake update
sudo nixos-rebuild switch --flake .#thinkpad-x1e2
nix run github:nix-community/home-manager -- switch --flake .#diego@thinkpad-x1e2
```

### Garbage Collect

```bash
sudo nix-collect-garbage -d
```

## Structure

```
nixconf/
├── flake.nix                          # Flake with all inputs
├── hosts/
│   └── thinkpad-x1e2/
│       ├── configuration.nix          # NixOS host config
│       ├── home-manager.nix           # Home Manager imports
│       └── features/
│           └── nvidia.nix             # NVIDIA hybrid graphics
├── home-manager/
│   ├── home.nix                       # Core Home Manager (symlinks)
│   └── features/
│       ├── desktop.nix                # GUI apps, Spicetify
│       ├── shell.nix                  # Fish, Zsh, Starship, tools
│       ├── wayland.nix                # Hyprland, SwayNC, etc
│       ├── services.nix               # Background services
│       ├── stylix.nix                 # Theming (Catppuccin Mocha)
│       └── work.nix                   # Dev tools, Nix helpers
├── nixos/
│   ├── base-configuration.nix         # Shared NixOS config
│   └── features/
│       ├── hyprland.nix
│       ├── pipewire.nix
│       ├── battery.nix
│       ├── steam.nix
│       └── bluetooth.nix
└── home-manager/scripts/
    ├── brightness.sh
    ├── volume.sh
    ├── screenshot.sh
    └── wayland-session.sh
```

## Key Features

- **Flake-based**: Reproducible, declarative system configuration
- **Symlinked dotfiles**: All configs in `~/dotfiles-dizzi/` are symlinked via Home Manager
- **NVIDIA Optimus**: Hybrid Intel + GTX 1650 with offload mode
- **Stylix**: System-wide theming with Catppuccin Mocha
- **Same experience**: Uses the same dotfiles as CachyOS (fase2 script)

## Commands

| Command | Description |
|---------|-------------|
| `nixrb` | Rebuild NixOS system |
| `hm` | Switch Home Manager config |
| `nixup` | Update flake inputs |
| `nixgc` | Garbage collect old generations |

## Customization

1. Edit `hosts/thinkpad-x1e2/configuration.nix` for system-level changes
2. Edit `home-manager/features/*.nix` for user-level changes
3. Add new features in `nixos/features/` and import in host config
4. All app configs live in `~/dotfiles-dizzi/` (shared with CachyOS)

### SDDM Themes

El theme actual es `sddm-astronaut` (package custom en `nixos/pkgs/sddm-astronaut-theme/`).

**Cambiar theme existente:** editá `services.displayManager.sddm.theme` en `base-configuration.nix` con el nombre del theme deseado.

**Agregar theme nuevo:**
1. Agregá el package a `environment.systemPackages` o a `services.displayManager.sddm.extraPackages` en `base-configuration.nix`
2. Cambiá `theme` al nombre del nuevo theme
3. Reconstruí: `sudo nixos-rebuild switch --flake .#thinkpad-x1e2`

**Crear theme custom:** agregá un derivation en `nixos/pkgs/` (ej: `sddm-astronaut-theme/default.nix`) e importalo via `pkgs.callPackage`.

---

## Post-Install (Manual Steps)

Estos pasos son **post-reboot** y están fuera del alcance de nixconf.

### SDDM Astronaut Theme (NixOS)

No requiere instalación manual — el tema `sddm-astronaut` es un package custom en `nixconf/nixos/pkgs/sddm-astronaut-theme/`.

Para cambiar de tema: editá `services.displayManager.sddm.theme` en `base-configuration.nix`.

Para temas adicionales: agregá el package a `environment.systemPackages` y cambiá el nombre del theme.

Si querés forzar un tema específico sin que SDDM detecte otros:

```nix
services.displayManager.sddm.settings.Theme.Current = "sddm-astronaut-theme";
```

### Flatpak Apps (automáticos)

GeForce NOW, Podman Desktop y Bottles se instalan automáticamente en el primer `home-manager switch` via activation scripts en `home.nix`. No requiere comandos manuales.

Para verificar estado:

```bash
flatpak info com.nvidia.geforcenow 2>/dev/null && echo "✅ GeForce NOW" || echo "❌ GeForce NOW"
flatpak info io.podman_desktop.PodmanDesktop 2>/dev/null && echo "✅ Podman Desktop" || echo "❌ Podman Desktop"
flatpak info com.usebottles.bottles 2>/dev/null && echo "✅ Bottles" || echo "❌ Bottles"
flatpak info io.mrarm.mcpelauncher 2>/dev/null && echo "✅ MCPE Launcher (Minecraft Bedrock)" || echo "❌ MCPE Launcher"
```

Si fallaron en el primer `home-manager switch` (los activation scripts tienen `|| true` y tragan errores), instalá manual:

```bash
# GeForce NOW (remote especial)
flatpak remote-add --user --if-not-exists GeForceNOW \
  https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo
flatpak install -y --user GeForceNOW com.nvidia.geforcenow

# Bottles
flatpak install -y --user flathub com.usebottles.bottles

# Podman Desktop
flatpak install -y --user flathub io.podman_desktop.PodmanDesktop

# Minecraft Bedrock (MCPE Launcher)
flatpak install -y --user flathub io.mrarm.mcpelauncher
```

O corré de nuevo el rebuild (los scripts chequean `flatpak info` primero, no re-intentan si ya está):

```bash
home-manager switch -b backup --flake ~/dotfiles-dizzi/nixconf#diego@thinkpad-x1e2
```

> ### Nota: Xbox / Game Pass en Linux
>
> **No existe una app nativa "Xbox Experience" en Flathub.** Xbox Game Pass en Linux
> se usa vía **Xbox Cloud Gaming** (jugar desde la nube) con el navegador en
> `https://www.xbox.com/play`, o con el cliente **Greenlight**
> (`flatpak install flathub io.github.unknownskl.greenlight`). No hay app oficial de
> Microsoft en Linux.
>
> ### Nota: Minecraft Bedrock (mcpelauncher)
>
> `io.mrarm.mcpelauncher` es **la única versión flatpak** del launcher de Bedrock.
> El login con cuenta Microsoft puede fallar con error `"drowned"`/código `13089`:
> es un **bug upstream de mcpelauncher**, no de esta config ni del flatpak. Si el
> login no avanza, probá cambiar la zona horaria del sistema o usá el
> [troubleshooting oficial](https://minecraft-linux.github.io/troubleshooting).

### Lutris (biblioteca de juegos)

El config de Lutris vive en `~/.local/share/lutris/` (symlink → `local/.local/share/lutris`).

> ⚠️ La biblioteca de juegos se sincroniza desde tu cuenta de Lutris al iniciar sesión.
> Si `pga.db` y los YAML en `games/` aparecen vacíos, solo hay que abrir Lutris y loguearse
> con la cuenta que tiene la biblioteca. No hay que importar nada manualmente.

```bash
lutris                      # login con tu cuenta → sincroniza la biblioteca
```

### npm Global Packages (mcp-hub, etc.)

Home-manager no maneja el `~/.npmrc`. Run once after install:

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
set -x PATH ~/.npm-global/bin $PATH   # fish
npm install -g mcp-hub@latest
```

El path `~/.npm-global/bin` ya está en `$PATH` via `programs.zsh.initContent` (shell.nix) y `programs.fish.interactiveShellInit`.

### GTK Theme (Colloid-Pink-Dark)

El theme `colloid-gtk-theme` se instala via `home.packages` y las variantes Pink se symlinkean a `~/.themes/` automáticamente.

Para activarlo visualmente:

```bash
# Abrir nwg-look y seleccionar Colloid-Pink-Dark como GTK theme
nwg-look
# Aplicar los cambios en el menú
```

> ⚠️ Home Manager sobreescribe `~/.config/gtk-3.0/settings.ini` en cada rebuild. Si querés persistir el theme, setéalo en `stylix.nix`:
> ```nix
> gtk.theme.name = "Colloid-Pink-Dark";
> ```
> O volvé a correr `nwg-look` después de cada `home-manager switch`.

### VSCode / Cursor / Antigravity Extensions (primera vez)

Las extensiones de VSCode/Cursor/Antigravity se instalan una sola vez con el script en el repo:

```bash
# Navegar al directorio del script
cd ~/dotfiles-dizzi/home/Antigravity\ Setup/install\ extensions

# Ejecutar (detecta automáticamente antigravity → code → codium)
bash install-vscode-extensions.sh
```

El script lee `extensions.txt` (66 extensiones: Neovim, Tailwind, GitLens, Copilot, etc.) y las instala una por una.

### Secure Boot (para Vanguard / Windows 11 dualboot)

Secure Boot es requisito de Vanguard (Riot anticheat).

> ⚠️ **IMPORTANTE — por qué el core mínimo no sirve:**  
> GRUB >= 2.06 (parches boothole) **bloquea el sideloading de `.mod`** cuando Secure Boot está
> activo. Los `.mod` son ELF (`0x457f`), no PE, así que `sbctl` **jamás puede firmarlos**.
> El `grubx64.efi` de NixOS es un core mínimo (~141KB) que carga `normal.mod` etc en runtime
> -> Secure Boot lo bloquea -> **GRUB rescue** (`verification requested but nobody cares: normal.mod`).
>
> La única solución fiable: imagen **standalone con todos los módulos embebidos**, firmar SOLO ese
> binario. Lo hace `boot.loader.grub.extraInstallCommands` (`base-configuration.nix`) con
> `grub-mkstandalone --disable-shim-lock`.
> Ref: https://github.com/Foxboron/sbctl/issues/91 · https://wejn.org/2021/09/

**Cada `nixos-rebuild switch` automáticamente:**
1. Construye `grubx64.efi` standalone (todos los módulos embebidos) con `grub-mkstandalone --disable-shim-lock`.
2. Lo copia a `BOOTX64.EFI` (fallback removible).
3. Firma ambos con `sbctl sign -s`.

**Setup inicial (una sola vez, con Secure Boot OFF en BIOS):**

```bash
# 1. Rebuild para instalar sbctl + grub2_efi y generar el standalone firmado
sudo nixos-rebuild switch --flake .#thinkpad-x1e2
#    Debe mostrar: "✓ Standalone GRUB signed for Secure Boot."

# 2. Entrar BIOS, poner Secure Boot en Setup Mode
#    ("Clear Secure Boot Keys" / "Reset to Setup Mode")

# 3. Boot NixOS, crear y enrolar keys (con Microsoft keys para Windows)
sudo sbctl status                          # debe decir "Setup Mode: Enabled"
sudo sbctl create-keys
sudo sbctl enroll-keys -m                  # incluye KEK/Ub de Microsoft

# 4. Firmar el standalone (solo los 2 binarios EFI)
sudo sbctl sign -s /boot/EFI/NixOS-boot/grubx64.efi
sudo sbctl sign -s /boot/EFI/Boot/bootx64.efi

# 5. Rebuild para que extraInstallCommands reconstruya + re-firme el standalone
sudo nixos-rebuild switch --flake .#thinkpad-x1e2

# 6. Entrar BIOS, ENABLE Secure Boot (User Mode)

# 7. Doble verificación
sudo sbctl status                          # "Secure Boot: Enabled"
sudo sbctl verify | rg '(✓|✗)'
```

Cada `nixos-rebuild switch` re-construye y re-firma el standalone automáticamente. Windows arranca porque las keys de Microsoft ya están enroladas.

> 🛡️ **Recuperación si cae en GRUB rescue**: desactiva Secure Boot en BIOS, boot normal,
> y corre `sudo nixos-rebuild switch` para reconstruir el standalone firmado.

### Pywal Cache (required for rofi themes + walset-menu)

```bash
wal -i ~/wallpapers/wallpapers/wallhaven-76edpv-Cyberpunk-Futuristic.jpg
```

### Waydroid (after first boot)

```bash
sudo waydroid init -s GAPPS -f
sudo systemctl start waydroid-container
waydroid session start
sudo waydroid_script install libhoudini
```

### Waydroid Network Fix

```bash
sudo bash /nix/store/*/waydroid-*/lib/waydroid/data/scripts/waydroid-net.sh start
```

### Partición EFI

Si `/boot` se llena (300MB con dual boot Windows), usar GParted Live USB para expandir a 1GB. `configurationLimit = 3` en GRUB limita kernels guardados.

### Known Issues (CachyOS dotfiles en NixOS)

- ~~`keybinds-zenities.conf:19` — `togglesplit` eliminado en Hyprland 0.56.0~~ ✅ Fixed: `layoutmsg, togglesplit`
- ~~`looknfeel.conf:97` — `dwindle:pseudotile` removido en 0.55 (no hacía nada)~~ ✅ Fixed: línea eliminada
- ~~`killall` not found on NixOS~~ ✅ Fixed: added `psmisc` to system packages
- ~~`/bin/bash` not found on NixOS~~ ✅ Fixed: activation script creates symlink
- ~~`/usr/bin/swaync-client` not found~~ ✅ Fixed: activation script creates symlink
- ~~waybar JSON parse error (literal tabs)~~ ✅ Fixed: tabs replaced with `\t` escape sequences
- ~~wallpapers path mismatch~~ ✅ Fixed: symlink `~/wallpapers` now points to images dir
- ~~walset-menu compositor detection~~ ✅ Fixed: `pgrep Hyprland` (without -x)
- `powerprofilesctl` not found — conflicta con TLP, no se puede agregar. Usar `tlp-stat` en su lugar
- `exec-autostart.conf` — `/usr/lib/polkit-gnome/...` no existe en NixOS (NixOS lo maneja via systemd)
- `get-wallpapers.sh` — busca en `~/wallpapers/` pero archivos estaban en `~/wallpapers/wallpapers/` ✅ Fixed via symlink
- `system_control.sh` — error `color5` es de SwayNC, no de EWW
- `exec-autostart.conf` — `/usr/lib/polkit-gnome/...` no existe en NixOS (NixOS lo maneja via systemd)
- `bindings.conf:93,95` — `/usr/bin/waybar` no existe en NixOS (usar `waybar` directo)
- `walset-menu` — `pgrep -x Hyprland` falla en NixOS (proceso es `.Hyprland-wrapp`)
- `get-wallpapers.sh` — busca en `~/wallpapers/` pero archivos están en `~/wallpapers/wallpapers/`
- `~/.local/share/fonts` no puede ser symlink a nix store (Steam bwrap falla). HM ahora crea dir real via activation script.
- `programs.nix-ld.enable = true` necesario para binarios dinámicos (tree-sitter CLI, etc.)
- npm global packages: `~/.npm-global` debe crearse manualmente + `npm config set prefix ~/.npm-global`

> Estos se resuelven editando los dotfiles para que sean compatibles con ambos sistemas, o creando overrides en nixconf.

---

## What's Included

Adaptado de [ghaerdi/dotfiles](https://github.com/ghaerdi/dotfiles) para ThinkPad X1E2.

### Desktop / Window Management
- **Hyprland** - Wayland compositor
- **Waybar** - Status bar
- **SwayNC** - Notifications
- **Wlogout** - Session manager
- **SWWW** - Wallpaper daemon

### Terminal & Shells
- **Ghostty** - Terminal emulator
- **Kitty** - Terminal emulator (backup)
- **Zellij** - Terminal multiplexer
- **Fish** - Primary shell
- **Zsh** - Secondary shell (oh-my-zsh + plugins)
- **Starship** - Prompt
- **Zoxide** - Smart cd

### Applications
- **Neovim** - Editor
- **Rofi** - App launcher
- **Espanso** - Text expansion
- **EasyEffects** - Audio effects
- **Dunst** - Notification daemon
- **QtScrcpy** - Android screen mirroring
- **Syncthing** - P2P file sync
- **RQuickShare** - Nearby Share (Android<->Linux)

### Input
- **Brightnessctl** - Display brightness
- **Playerctl** - Media player control
- **Pamixer** - Volume control

### Visual
- **Fastfetch** - System info display
- **Wal** - Color schemes (pywal)
- **Stylix** - System-wide theming (Catppuccin Mocha)

### AI Coding
- **Opencode** - AI coding assistant
- **Engram** - Persistent memory
- **Open WebUI** - Local LLM web interface (`pkgs.open-webui`)

### Work / Dev
- **Lazygit** - Git TUI
- **Podman Desktop** - Containers (reemplaza Docker Desktop)
- **Go / Rust / Python / Node.js / pnpm** - Languages & package managers
- **Wine / Winetricks** - Windows apps
