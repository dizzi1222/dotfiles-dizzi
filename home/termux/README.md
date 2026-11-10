# Herramientas para Termux

## Atajos de OpenCode y Neovim

El paso **22c** de `../termux-basic-setup.sh` instala los scripts `opencode` y
`nvim` en `~/.termux/widget/dynamic_shortcuts/`. Ejecutan el comando tal cual.
Los íconos se instalan en `~/.shortcuts/icons/<nombre-del-script>.png`.

Abrí **Termux:Widget → CREATE SHORTCUTS**. Luego mantené presionado el ícono de
Termux:Widget en el launcher y añadí `nvim` al inicio. Si ya había un atajo con
el ícono viejo, quitá ese acceso del inicio y agregalo otra vez.

`dynamic_shortcuts/icons/nvim.png` usa la [marca oficial de Neovim](https://github.com/neovim/neovim.github.io/blob/6568b9011ddb2965dc5118d28f17d5b7ce7dd8da/static/logos/neovim-mark.png),
reducida proporcionalmente y centrada en un PNG transparente de 192×192.
Licencia del recurso: [MIT](dynamic_shortcuts/icons/LICENSE.neovim).

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

En la pantalla que se abre, activar el ajuste de sonido multimedia en varias
aplicaciones. El script abre los ajustes; los interruptores se manejan en la
interfaz de Xiaomi.

Ver [la guía completa](AUDIO-APLICACIONES.md) para los pasos de uso, cómo se
encontró la solución y las comprobaciones realizadas en esta ROM.
