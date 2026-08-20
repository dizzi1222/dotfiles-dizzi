# 🐧 Dotfiles-Dizzi — Rama `termux`

Configuración lista para **Termux (Android)**: zsh, opencommit, nvim, starship, tmux, yazi, fastfetch y más.

> Para la config de escritorio (Arch/Hyprland/NixOS) ver la rama `main`.

---

## ⚡ Instalación rápida

Desde Termux, una vez con `termux-setup-storage` hecho:

```bash
pkg update && pkg upgrade -y
pkg install -y git

git clone -b termux https://github.com/dizzi1222/dotfiles-dizzi.git ~/dotfiles-dizzi
cd ~/dotfiles-dizzi
```

### Opción A — Setup completo (recomendado)

Script interactivo de **22 pasos** (pregunta antes de instalar): sistema, git (con auto-push), desarrollo, editores, CLIs modernas, GitHub CLI, **zsh + plugins**, prompts, pokemon-colorscripts, tmux, yazi, fastfetch, Termux-API, aliases, IA tools (**tgpt + opencommit**), Fira Code, stow + dotfiles, parcheo de `.zshrc`, `.gitignore` seguro, rama termux:

```bash
bash ~/dotfiles-dizzi/home/termux-basic-setup.sh
```

### Opción B — Setup mínimo

```bash
bash ~/dotfiles-dizzi/home/termux/quick_termux-setup.sh
# storage + update + git/curl/wget/android-tools + starship
```

---

## 🔧 Scripts útiles (`home/termux/`)

| Script | Uso |
|---|---|
| `activar-todo.sh` | Configuración completa: ADB/Shizuku + PIN automático + activar servicios + install en **Termux:Boot** |
| `activar-servicios.sh` / `ver-servicios.sh` | Activar / verificar servicios de accesibilidad |
| `quick-connect.sh` | Conexión rápida ADB |
| `start_shizuku.sh` / `start_shizuku_enhanced.sh` | Iniciar Shizuku |
| `ejecutar_comando_PIN_sin_ok.sh` | Ejecutar comando PIN sin OK manual |

---

## 📝 Notas

- **Nunca commitear** `~/.opencommit` ni `*api-keys*` (el setup agrega `**/.opencommit` al `.gitignore`).
- Submódulo **nvim** apunta a la rama `termux` de `dizzi1222/nvim` (config adaptada a Android).
- Stow disponible para enlazar configs: `stow nvim starship --adopt`.

## 📦 Backup del sistema (Linux)

`setup-backup-system.sh` + `BACKUP-SYSTEM.md`: snapshots automáticos Timeshift (ext4) / Snapper (btrfs) antes de `pacman -Syu`.