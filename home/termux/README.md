# Herramientas para Termux

## Atajos de Termux:Widget

El paso **22b** de `../termux-basic-setup.sh` instala Hermes Agent y Grok Build
con sus instaladores oficiales Linux dentro de Ubuntu/proot, separados del
entorno nativo de Termux. Hermes conserva sus datos en `/root/hermes-user`; Grok
Build en `/root/.grok`. Consulta la [guía de Hermes para Termux](https://hermes-agent.nousresearch.com/docs/getting-started/termux)
y la [documentación oficial de Grok Build](https://docs.x.ai/build/overview).

El paso **22c** instala ocho scripts (`opencode`,
`nvim`, `agy`, `codex`, `claude-code`, `openclaw`, `hermes` y `grokbot`) en
`~/.termux/widget/dynamic_shortcuts/` y `~/.shortcuts/`. Ejecutan el comando
correspondiente; `grokbot` inicia Grok Build, el agente oficial de terminal de
xAI, y `hermes` inicia Hermes Agent dentro de Ubuntu/proot. Ninguno abre una app
Android. Los íconos se instalan en
`~/.shortcuts/icons/<nombre-del-script>.png`.

El instalador ejecuta `am start -a android.intent.action.CREATE_SHORTCUT -n
com.termux.widget/.TermuxCreateShortcutActivity` una vez por agente: ocho veces en
total, esperando entre cada invocación. En el selector, elegí el script indicado
y confirmá el acceso de inicio antes de continuar con el siguiente.

Para crear otro acceso después de la instalación, usá el alias `widget`
(definido en `~/.termux_aliases`), que ejecuta ese mismo comando.

Los atajos reanudan la sesión anterior, igual que los `.desktop` de la rama
`main`: `claude --resume`, `codex resume`, `opencode --continue`, Hermes con
`--tui --continue` y `agy` vía [`agy-resume`](agy-resume), que inyecta
`Escape` + `/resume` en un pty porque Termux no tiene kitty.

El instalador de Hermes deja pendiente el primer setup si no hay una terminal
interactiva. Para completarlo manualmente, ejecutá:

```bash
proot-distro login ubuntu -- /usr/bin/env \
  HOME=/root/hermes-user \
  HERMES_HOME=/root/hermes-user/.hermes \
  PATH=/root/hermes-user/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /root/hermes-user/.local/bin/hermes setup
```

Para iniciar sesión en Grok Build desde Termux, ejecutá:

```bash
proot-distro login ubuntu -- /root/.grok/bin/grok login --device-auth
```

`dynamic_shortcuts/icons/nvim.png` usa la [marca oficial de Neovim](https://github.com/neovim/neovim.github.io/blob/6568b9011ddb2965dc5118d28f17d5b7ce7dd8da/static/logos/neovim-mark.png),
reducida proporcionalmente y centrada en un PNG transparente de 192×192.

`dynamic_shortcuts/icons/agy.png` usa el [logo oficial de Google Antigravity](https://antigravity.google/assets/image/antigravity-logo.png),
recortado, reducido proporcionalmente y centrado en un PNG transparente de 192×192.

`dynamic_shortcuts/icons/codex.png` usa el [isotipo oficial de OpenAI](https://chatgpt.com/cdn/assets/favicon-c80e01a96037.svg)
(blanco) centrado en una tarjeta negra redondeada de 192×192.

`dynamic_shortcuts/icons/claude-code.png` usa el [icono oficial de Claude Code de LobeHub](https://cdn.jsdelivr.net/npm/@lobehub/icons-static-png@latest/light/claudecode-color.png),
reducido a un PNG transparente de 192×192.

`dynamic_shortcuts/icons/openclaw.png` usa el [icono oficial de OpenClaw de LobeHub](https://cdn.jsdelivr.net/npm/@lobehub/icons-static-png@latest/light/openclaw-color.png),
reducido a un PNG transparente de 192×192.

`dynamic_shortcuts/icons/hermes.png` usa el [icono Hermes de Homarr Dashboard Icons](https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/hermes.webp),
convertido de WebP y reducido a PNG de 192×192.

`dynamic_shortcuts/icons/grokbot.png` usa el [icono oscuro de Grok Bot de LobeHub](https://cdn.jsdelivr.net/npm/@lobehub/icons-static-png@latest/dark/grokbot.png),
reducido a PNG de 192×192. Termux:Widget requiere que el archivo se llame `<script_name>.png`.

Licencia de los recursos de Neovim: [MIT](dynamic_shortcuts/icons/LICENSE.neovim).

## Hermes Agent: dotfiles, workspace y estado privado

- La carpeta completa `HERMES AI/` vive en este directorio de Termux y `~/HERMES AI` apunta a ella mediante un symlink.
  El atajo crea el enlace si falta, pero no reemplaza una carpeta existente que apunte a otra ubicación. Inicia
  el agente en ese workspace y, sin argumentos, abre el TUI con `--continue`: retoma la sesión de ese terminal
  cuando existe y, si no, la sesión reciente del TUI o de CLI.
- La configuración versionada está en `hermes/`: `config.yaml`, `SOUL.md` y `profiles/*/config.yaml`.
  `hermes/link-configs.sh` enlaza esos archivos dentro de `/root/hermes-user/.hermes`; cualquier configuración
  previa que no estuviera enlazada se conserva con el sufijo `.pre-dotfiles-*`.
- `hermes/patch-gateway-startup.sh` corrige el timeout fijo del TUI: inicio y recuperación usan la espera
  adaptativa del gateway (60 s iniciales, hasta 300 s mientras el proceso progresa) y el proceso Node espera
  hasta 360 s. El atajo solo recompila si faltan los artefactos corregidos y revierte los cambios de fuentes
  al salir para no dejar Hermes permanentemente modificado ni frenar futuras actualizaciones.
- Las credenciales y los datos mutables permanecen fuera del repositorio en `/root/hermes-user/.hermes`:
  `.env`, `auth.json`, sesiones/base de datos y memoria dinámica. No copiar ni commitear esos archivos.
- El setup de Termux copia el atajo `dynamic_shortcuts/hermes` desde dotfiles a Termux:Widget y `~/.shortcuts`.

## Control de volumen por aplicación en Xiaomi

**Probado en el dispositivo del propietario, quien confirmó que funciona:**

- **Modelo:** Xiaomi Redmi Note 9 Pro (`joyeuse`), plataforma `atoll`.
- **ROM:** MIUI Global `V14.0.3.0.SJZMIXM` (MIUI 14).
- **Sistema:** Android 12, API 31; parche de seguridad `2023-02-01`.

Se hizo funcionar abriendo directamente el **Asistente de sonido nativo de
Xiaomi** desde Termux, sin necesitar root, ADB ni Shizuku:

```bash
bash ~/termux/audio-aplicaciones.sh
```

El script ejecuta el comando comprobado:

```bash
am start -n com.miui.misound/com.miui.misound.playervolume.SoundAssistActivity
```

También está disponible como el alias `sonido` en `~/.termux_aliases`.

En la pantalla que se abre, activar el ajuste de sonido multimedia en varias
aplicaciones. El script abre los ajustes; los interruptores se manejan en la
interfaz de Xiaomi.

Ver [la guía completa](AUDIO-APLICACIONES.md) para los pasos de uso, cómo se
encontró la solución y las comprobaciones realizadas en esta ROM.

## Alias de Termux

`../termux-basic-setup.sh` (paso 15) los agrega a `~/.termux_aliases`:

| Alias    | Qué hace                                                                                   |
| -------- | ------------------------------------------------------------------------------------------ |
| `widget` | Abre el selector de Termux:Widget para crear un acceso de inicio (`TermuxCreateShortcutActivity`) |
| `sonido` | Abre el Asistente de sonido de MIUI (volumen por aplicación)                               |
| `home`   | [`miui-home.sh`](miui-home.sh): Home real de MIUI con el Ultra Ahorro activo (ADB + Lawnchair) |
