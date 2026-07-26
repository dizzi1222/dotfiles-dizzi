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

### Work / Dev
- **Lazygit** - Git TUI
- **Docker** - Containers
- **Go / Rust / Python / Node.js / pnpm** - Languages & package managers
- **Wine / Winetricks** - Windows apps
