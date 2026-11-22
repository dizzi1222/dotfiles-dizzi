# Perfil — Diego Samuel Härdi Santana (memoria de usuario)

## Identidad y reglas de interacción

- **Rol:** Programador.
- **Idioma:** Responder **SIEMPRE en español**, incluso si el input viene en inglés (o es extenso).
- **Estilo:** Respuestas breves, concisas, documentadas y correctas. Explicar secuencialmente, sin dejar atrás lo que ya está hecho.
- **Restricciones:** **NO dibujar Canvas** para explicaciones. Investigación objetiva (FPS reales, Frame Generation en Linux).

## Ecosistema de aprendizaje "Developer Pro" (3 niveles)

1. **Núcleo / Estrategia — JSCAMP (Midu):** Fullstack React + TypeScript, proyectos reales, estructura profesional.
2. **Músculo / Técnica — Exercism:** Rust, POO y lógica; editor propio + terminal + tests reales; dominar Rust.
3. **Hábito / Constancia — Mimo:** Python / Web Basics; mantener el cerebro en "modo código" y repasar sintaxis mientras viajo o descanso.

- **Objetivo:** MERN-Stack. Experiencia básica con Docker.

## Agentes (coding agéntico / autonomía)

- **OpenCode:** Orquestador principal (Webshare IPs, Engram).
- **Hermes:** 4 agentes (líder + 3 workers), plugin Agy ACP, memoria persistente; perfiles aislados por entorno recomendado.
- **Otros agentes:** Agy (ACP -> Hermes), Codex, Claude Code (pago).
- **Roadmap:** Hostinger VPS + `n8n` + Claude ACP + Agy ACP + OpenRouter (Nemotron).

## IAs de chat convencionales (NO agentes)

- **Chat web:** Deepseek o Gemini, para conversar en tiempo real.
- **Terminal:** `tgpt`.
- **Descartadas / no uso:** `gemini-cli`, Warp.

## Neovim — IA integrada

- **Autocompletado (ghost text):** `neocursor.nvim`, con backend de Cursor y de Antigravity (`sidecar_antigravity.py`). Cursor y Antigravity **NO** se usan como chat ni como agente: solo como backend de autocompletado vía `neocursor`.
- **Generación de código:** Avante en **modo visual** -> `<leader>ae` (**Edit**). Verificado en `lua/plugins/avante-cursor.lua`: grupo which-key `"<leader>ae", mode = "x"` = `avante: edit` (también `<leader>aa` ask y `<leader>an` new ask en visual).
- **Editor:** Neovim LazyVim + Gentleman config (`oil`, manejo principal de `.lua`), `oc-open` para saltar a archivos desde el agente.

## Workspace `~/workspace` — proyectos (29)

`AGENT-records`, `codex-discord-presence`, `dataimpulse-mcp`, `dbtui.nvim`, `dhardi-laravel`, `dhardi.dev`, `dizzi1222`, `FCTicService.github.6c-Diego-05`, `GLAZE-WM-make-windows-pretty-main-dizzi`, `jscamp`, `kimu-underground`, `lenso-api`, `Librezam`, `mongodb`, `MultiPresence`, `neocursor.nvim`, `opencode-discord-rpc`, `opencode.nvim`, `PCE-Agencia`, `portafolio-eric-godtier`, `portfolio-terminal-dhardi`, `proyeccion-astral`, `Proyecto-App-MCSD`, `ptd-talento-back`, `ptd-talento-front`, `REACT-Diego-Dizzi-Dashboard`, `retro-portfolio`, `rsv-travelermap-force`, `tmp-testing`.

## Workspace `~/workspace` — documentación propia

- **Raíz:** `AGENT.md`, `PLAN.md`, `README.md`, `learning-roadmap.md`, `motivational.md`, `setup.sh`, `theme-neonforge.css`, `ENTREVISTA-MCTEKK.md`, `.gitmodules`, `.gitignore`.
- **`AGENT-records/`:** `AGENT-records.md`, `vim-basics.md`, `vim-dap-debug.md`, `vim-mason.md`, `vim-motions.md`, `vim-ui.md` (documentación personal de Neovim). Subcarpetas: `PCE-Agencia`, `ptd-talento-back`, `ptd-talento-front`.

## Hardware y sistema

- **Laptop:** Lenovo ThinkPad X1 Extreme Gen 2 (MTM `20QV0008US`): Intel Core i7-9850H, 32 GB RAM, NVIDIA GTX 1650 Mobile/Max-Q 4 GB + Intel UHD 630.
- **Almacenamiento:** SSD Samsung PM981 512 GB NVMe en 2.º slot M.2.
- **Triple-boot GRUB:** Bazzite (Fedora rpm/Flatpak, SDDM, KDE/KWin) + Windows 11 FSE + Arch (KDE Plasma y Hyprland).
- **Historial OS:** NixOS 3 meses (inestable, rompe fácil, programación difícil) -> Bazzite elegido por inmutabilidad por encima de Fedora/CachyOS. Gaming AAA/RDR2 OK.
- **eGPU:** PowerColor Red Dragon RX Vega 56 8 GB HBM2 (entregada) + dock Thunderbolt 3/4 abierto (comprado; prueba pendiente).
- **Otros hardware:** RTX 4060 Ti 8 GB (~$270): evaluada, no comprada. Legion Go: robado/perdido.

## Periféricos y energía

- **Monitor externo:** ASUS 144Hz.
- **Teclado:** Royal Kludge RK61 Plus 60% (lubricado con Krytox 205g0 + GPL 105).
- **Energía:** Power banks 20,000 mAh / 140 W USB-C PD 3.1 para contingencia eléctrica.

## Entorno Linux (Arch/Hyprland) y Dotfiles

- **Dotfiles:** `~/dotfiles-dizzi` con `home-manager` (NO Stow), symlinks, `ydotool` (F7/F9), `system_control.sh` (`rofi`), plantillas `.github` (`daily`, `investigation`, `spike`, `comentarios-seccionales`).
- **Arch/Hyprland:** `Pywal` (fondos), `eww` widgets, `waybar`, `kitty`, `zsh`, `QUICKSHELL`, `Nemo` Desktop tipo Windows, `Lutris`, Hyprland como tile manager.
- **Nota sobre temas antiguos:** Raleigh/Adwaita, `JetBrainsMono Nerd Font` (mono), `Adwaita Sans` (UI), NWGLook / Mac Theme / LxAppearance — dato del perfil antiguo, NO verificado en la partición Arch actual.

## Entorno Windows

- **Sistema:** Windows 11 FSE para juegos con anticheat (LoL) y apps propias (`FS Multi Monitor`).
- **Utilidades:** PowerToys, GlazeWM (tile manager), Wallpaper Engine (`VSTHEMES.org`, anime/aesthetic cinema), Zebra Top Bar, Git Bash/WSL.

## Herramientas creativas, capturas y sync

- **Diseño y Arte:** Figma (mockups), Canva/Photopea, Krita + DeviantArt.
- **Video y Grabación:** Filmora, OBS.
- **Capturas:** Greenshot + Imgur (Windows); Gyazo + Slurp + QUICKSHELL (Linux).
- **Sync y Remoto:** Syncthing, `floccus`, Moonlight/Sunshine, ComfyUI (localhost si se requiere).
- **VCS, Contenedores y Otros:** Git Bash + GitHub (`gh`), Podman Desktop + Docker, Composio.

## Proyecto PTD-Talento (completado)

- **Alcance:** Epics E1–E8, 107 tests backend + 23 frontend (Jest), post-QA Spike #195.
- **Convenciones:** Ramas `feat/m3-cat-usXXXX`, commits `fix|feat|chore`, plantilla PR QA.
- **Base de Datos:** pgAdmin4 (`talento-dev`) vía proxy Cloud SQL en `127.0.0.1:5433` (credenciales en 1Password).
- **CVs:** `/home/diego/mi_gdrive/Mi unidad/[Clase]/- Curriculum copium [+Certificados]/` (`cv.pdf`, `Unisys Cover Letter`).

## Contexto personal

- **Ubicación y Viajes:** Jarabacoa / Santiago, República Dominicana (planes de viaje a Zúrich, Suiza).
- **Idiomas:** Español nativo, inglés técnico, alemán en estudio.
- **Trabajo y Carrera:** Grupo Olé (desde oct 2026); búsqueda activa de roles remotos junior/entry-level en SWE, DevOps e IA.
- **Movilidad:** Motocicleta Honda Wave 110; interés en enduro/motocross (Yamaha WR450F).

## OBSOLETO (no usar)

- **Hardware antiguo:** PC "Windows 10 Pro, i7 @2.20GHz Skylake, 16 GB single-channel, Intel Iris 540, Dell 00F6D3, SSD SK hynix 476 GB".
- **Theming antiguo:** "Raleigh/Adwaita, NotwaitaBlack, NWGLook, Mac Theme Gnome, Zenities Theme, Vanzuh" como estado actual.
- **Estado real actual:** ThinkPad X1E2 con Bazzite/KDE (`Colloid-Pink-Dark` GTK, iconos `Kafka`, `Noto Sans` 11pt) + Win11 FSE + Arch/Hyprland. Tampoco se usan `gemini-cli` ni Warp.
