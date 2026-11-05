# Plan: amend de commit migración Bazzite + autor nobody

## Disparador
Cuando el usuario diga "migracion" sobre el repositorio de dotfiles.

## Repositorio
/var/home/diego/dotfiles-dizzi

## Plantillas inmutables (NO CAMBIAN entre ejecuciones)

### Título inmutable
```
@Migration to Bazzite con ascii de fedora no puede faltar
```

### Autor inmutable
```
nobody <nobody@localhost>
```

### Body template (se usa tal cual en cada amend)
```
@Migration to Bazzite con ascii de fedora no puede faltar

Bazzite migration completa:

- Discord nativo (RPM Fusion) en deployment bde475ce
- GRUB 'Bazzite Desktop (Plasma)' entry apuntando a deployment con Discord
- Espanso Wayland nativo (layout us, backend Clipboard, acentos ''a/a)
- Mouse zurdo global udev (Compx 2.4G, input-remapper deshabilitado)
- Wine cross-system:
  - Runner soda-11.0-10 para WoW64 .NET 4.8 (CustomRP instalado en ~/.wine)
  - GE-Proton8-26 (wine-staging 8.0) para AF_UNIX sockets (Discord IPC bridge)
  - Wrapper wine-staging + wine-soda + customrp-discord.sh
  - bridge.exe (enderice2/rpc-bridge) + winediscordipcbridge.exe (0e4ef622)
  - winetricks dotnet40 + fix registro Windows 10 (10.0/19041)
- loupe, ncdu, dust (du-dust), antimicrox en capa nativa
- opencommit (oco) via npm
- PostgreSQL opcional (psql, pg_dump, pg_restore)
- Iconos hicolor propios para wine-discord-ipc-bridge (wine + bottles)
- .desktop unificados customrp-discord.sh (wine + bottles) lanzan bridge ANTES
- CustomRP instalado en ~/.wine Y funcionando en Bottles gaming
- GRUB entry recreada tras finalize-staged apuntando a deployment con Discord

Cambios del tree incluidos en este commit:
- home/scripts/brew-pkg-install — instalador TUI de paquetes Homebrew (gum filter, caché 24h)
- home/scripts/cinnamon-satty-fullscreen.sh — captura pantalla completa grim+slurp+satty
- home/scripts/cinnamon-satty-region.sh — captura región grim+slurp+satty
- home/scripts/glyphs.sh — mapeo atajo Meta+Shift+Period para glyphs
- home/scripts/toggle-monitor.sh — toggle monitor externo on/off
- local/.local/share/applications/net.local.glyphs.desktop — launcher glyphs (Meta+Shift+Period)
- local/.local/share/icons/hicolor/scalable/apps/spotify.svg — icono SVG Spotify
- local/.local/share/icons/hicolor/scalable/apps/youtube-music.svg — icono SVG YouTube Music

Subject inmutable: @Migration to Bazzite con ascii de fedora no puede faltar.
```

## Qué hacer (en orden) — USANDO AMEND (NO hay base fija)

1. **Verificar estado actual** y localizar el commit migración actual (HEAD o commit con título `@Migration to Bazzite...`):
   - `git status --short --branch`
   - `git log --oneline -5` (identificar commit migración actual)

2. **Verificar cambios del tree** (staged/unstaged) que deben incluirse:
   - `git status --short`
   - Si hay cambios staged (A/M) o unstaged (??) que pertenecen a la migración, proceder.

3. **Add solo los archivos deseados** (NUNCA `git add .`):
   - `git add home/scripts/brew-pkg-install home/scripts/cinnamon-satty-fullscreen.sh home/scripts/cinnamon-satty-region.sh home/scripts/glyphs.sh home/scripts/toggle-monitor.sh local/.local/share/applications/net.local.glyphs.desktop local/.local/share/icons/hicolor/scalable/apps/spotify.svg local/.local/share/icons/hicolor/scalable/apps/youtube-music.svg`
   - + cualquier archivo nuevo/unstaged que pertenezca a la migración

4. **Amend del commit migración actual** (REEMPLAZA el commit actual, NO crea nuevo):
   - `git commit --amend --author="nobody <nobody@localhost>" -m "@Migration to Bazzite con ascii de fedora no puede faltar" -m "<BODY_TEMPLATE_DEL_PLAN>"`
   - Usar el body template guardado en este plan (ver arriba).

6. **Push forzado** (reescribe historial, destructivo):
   - `git push --force-with-lease origin main`

## Reglas clave
- **NO HAY BASE FIJA**: El commit migración *es* el HEAD que se amenda. Cada `amend` cambia el hash.
- `git commit --amend` REEMPLAZA el commit actual — NUNCA crea commit nuevo encima.
- Título inmutable: `@Migration to Bazzite con ascii de fedora no puede faltar`.
- Author: `nobody <nobody@localhost>`.
- Body: usar **exactamente el template guardado en este plan**.
- Add solo archivos específicos (NUNCA `git add .`).
- `git push --force-with-lease origin main` (reescribe historial remoto).

## Estado objetivo (siempre)
```
<commit-actual> @Migration to Bazzite con ascii de fedora no puede faltar   (autor: nobody)
<commit-anterior> ...
```
(Solo UN commit con ese título. Cada "migracion" lo amenda y cambia su hash).