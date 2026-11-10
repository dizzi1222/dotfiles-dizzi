# Herramientas para Termux

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
