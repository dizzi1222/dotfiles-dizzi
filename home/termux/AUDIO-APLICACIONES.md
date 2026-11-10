# Volumen por aplicación en Xiaomi desde Termux

**Funcionamiento confirmado por el propietario en su Redmi Note 9 Pro.**
Se abrió el Asistente de sonido nativo desde Termux y el usuario confirmó
que el control de audio funciona correctamente en este dispositivo.

## Dispositivo verificado

Datos consultados directamente mediante `getprop`:

| Dato | Valor |
| --- | --- |
| Fabricante / modelo | Xiaomi Redmi Note 9 Pro |
| Nombre de dispositivo | `joyeuse` |
| Plataforma | `atoll` |
| ROM | MIUI Global `V14.0.3.0.SJZMIXM` (MIUI 14) |
| Android | 12 |
| API / SDK | 31 |
| Parche de seguridad | `2023-02-01` |

## Uso

Desde Termux:

```bash
bash ~/termux/audio-aplicaciones.sh
```

O ejecutar directamente el comando comprobado:

```bash
am start -n com.miui.misound/com.miui.misound.playervolume.SoundAssistActivity
```

1. En **Asistente de sonido**, activar **Ajustar sonido multimedia en varias
   aplicaciones** (el texto puede variar según el idioma).
2. Para reproducir varias aplicaciones a la vez, activar también la opción
   **Varias fuentes de audio**, si se necesita.
3. Reproducir audio y pulsar una tecla de volumen. Tocar el botón adicional
   de audio por aplicación para acceder a los controles individuales.

El script abre la pantalla; los interruptores se controlan desde la interfaz
de Xiaomi. No requiere root, conexión ADB ni Shizuku. El comando `am` lo
proporciona el paquete `termux-am` (`pkg install termux-am`).

## Cómo se encontró y comprobó

- Se inspeccionó la app instalada `/system/app/MiSound/MiSound.apk`.
- Su manifiesto declara la actividad exportada
  `com.miui.misound.playervolume.SoundAssistActivity` y la acción
  `miui.intent.action.SOUND_ASSIST`.
- Incluye `res/xml/sound_assist_settings_preference.xml`, con las opciones
  `sound_assist_key` y `multi_music_coexistence`.
- El comando anterior abrió la actividad y el propietario confirmó que
  funciona en el dispositivo con las especificaciones indicadas.
- La primera ejecución superó un límite de 10 segundos; una ejecución con
  margen de 60 segundos terminó correctamente. Dar tiempo al primer arranque.

Se instalaron `aapt` y `android-tools` para el diagnóstico; no son dependencias
del script. La comprobación corresponde a esta ROM y dispositivo, no a todos
los modelos Xiaomi.

Referencia de la función:
[documentación de Xiaomi sobre Sound Assistant](https://www.mi.com/global/support/article/KA-08490/).
