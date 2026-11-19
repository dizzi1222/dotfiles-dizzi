# Hermes Agent · sala de agentes

Esta carpeta reúne la configuración versionada de Hermes y el pack «Tu equipo en Hermes», portado desde el commit Termux `7a125fd35fa9`.

## Perfiles

- `presupuestos`: prepara presupuestos y respuestas de precio.
- `cobros`: organiza facturas pendientes y borradores de recordatorio.
- `agenda`: resume fechas y tareas pendientes.
- `contenido`: redacta publicaciones y respuestas a reseñas.

Los cuatro perfiles comparten la configuración de Bazzite como base y las instrucciones del pack. Tienen desactivados los toolsets de terminal, navegador, ejecución de código, computer-use, delegación, generación de imágenes/vídeo y kanban.

## Instalación en Bazzite

Con Hermes ya instalado, crea primero los perfiles. Así la CLI registra cada agente antes de enlazar sus configuraciones:

```bash
bash "$HOME/dotfiles-dizzi/hermes/workspace/Tu equipo en Hermes/instalar-equipo.sh"
bash "$HOME/dotfiles-dizzi/hermes/link-configs.sh"
hermes profile list
```

El segundo comando crea enlaces puntuales en `~/.hermes/` y `~/HERMES AI`. Si encuentra archivos anteriores, los conserva con el sufijo `.pre-dotfiles-<fecha>-<pid>`.

## CachyOS y NixOS

Después de instalar Hermes y crear los cuatro perfiles con `instalar-equipo.sh`, aplica Home Manager:

```bash
home-manager switch -b backup --flake /home/diego/dotfiles-dizzi/nixconf#diego@thinkpad-x1e2
```

`nixconf/home-manager/home.nix` enlaza solamente `config.yaml`, `SOUL.md`, cada configuración/identidad/skills del equipo y el workspace. No enlaza el directorio completo `~/.hermes`.

## Lanzamiento

Los launchers existentes usan `local/.local/bin/juegos/hermes.sh`. Sin argumentos, abre Hermes TUI, reanuda la sesión más reciente y establece `~/HERMES AI` como workspace. Si se pasan argumentos, el wrapper los entrega intactos a Hermes.

## Trabajar con el equipo desde la TUI

- `default` coordina con GPT-6 Luna (`max`). Los apoyos habituales son `agenda` (`low`), `cobros` (`low`) y `presupuestos` (`medium`). `contenido` sigue disponible como especialista aparte.
- `hermes -p agenda --tui` abre ese perfil; añade `--resume latest` para retomar su último chat. `hermes -p agenda chat -Q --max-turns 3 -q 'Resume las citas pendientes, sin enviar ni modificar nada'` es la variante de un solo encargo. Para combinar los tres niveles de esfuerzo, envía a cada perfil su propio encargo y reúne las respuestas en `default`.
- `/agent <tarea>` encarga trabajo en paralelo a `agenda`, `cobros`, `presupuestos` y `contenido`; `default` lo coordina y sintetiza. Escribe el comando sin barra final: los clientes tratan `/agent/` como texto. Sin tarea pide el encargo, no inicia cuatro trabajos vacíos. Usa `/agents` para verlos una vez lanzados y `/usage` para consultar el uso. El límite sigue siendo de cinco hijos en total.
- El atajo utiliza la skill de este repositorio y las rutas por perfil del plugin oficial `advanced-delegation`; en un host nuevo instala el plugin desde el catálogo. Abre una sesión nueva si la sesión actual se inició con otro backend. Verifica las cuatro rutas con `hermes delegation config --show`.
- Usa `/title Mi sesión` para renombrar el chat actual. `↑` y `↓` recuperan prompts ya enviados desde el cuadro de entrada de una sola línea. Fuera del chat: `hermes sessions rename <session_id> <title>`.
- Nemotron `nvidia/nemotron-3-ultra-550b-a55b:free` de OpenRouter es el primer fallback. `hermes fallback check --live` verifica esa ruta con una petición real. Para usarlo directamente en un perfil sin cambiar sus ajustes: `hermes -p agenda --tui --provider openrouter -m nvidia/nemotron-3-ultra-550b-a55b:free`.

Este flujo funciona sin Hermes Desktop. Los perfiles y la delegación no crean un Group Chat de Bot Mode.

## Voz local en Bazzite

En un host nuevo, `hermes pm install --extra voice` instala captura de audio y Faster-Whisper. Este perfil usa Whisper `tiny` multilingüe en CPU (`int8`) para dictado en español; el modelo se descarga la primera vez. Para leer las respuestas usa `espeak-ng` local (`es-419`), que debe estar en `PATH`. Ninguno de esos dos pasos envía el audio ni el texto de síntesis a un servicio de voz; el prompt ya transcrito sí se envía al proveedor del modelo del chat.

Reabre `hermes --tui` después de instalar. En el chat ejecuta `/voice status`, `/voice on` y, si quieres respuestas habladas, `/voice tts`. `Ctrl+B` inicia la captura con el atajo por defecto. `/voice off` detiene la voz. La prueba local de instalación genera audio sintético y lo transcribe sin red; la prueba final del micrófono consiste en hablar tú desde la TUI.

## Goal de la sesión

Pega este bloque como un solo mensaje con `/goal` únicamente cuando quieras iniciar el bucle automático:

```text
/goal Dejar operativo un equipo Hermes ligero en CLI/TUI: Luna max como líder, agenda y cobros low, presupuestos medium; Nemotron gratis de OpenRouter como primer fallback y voz funcional en español.
verify: validar los cinco perfiles y sus enlaces a dotfiles, ejecutar hermes fallback check --live y probar una frase de dictado y una respuesta hablada sin usar datos reales.
constraints: sin Desktop ni paquetes pesados sin aprobación, sin credenciales ni historial en Git, sin publicar cambios ajenos y sin usar datos ficticios de negocio sin permiso.
boundaries: configuración local de Hermes y carpeta hermes/ de dotfiles; Rich Presence queda opcional y AGY/ACP fuera de esta fase.
stop when: la voz requiera aprobar una instalación, falte espacio, se agote la cuota sin fallback usable o sea necesario decidir los datos del negocio.
```

## Datos locales y secretos

`config.yaml` se basa en la configuración activa de Bazzite y añade únicamente `fallback_providers` del perfil Termux. Las credenciales siguen en `~/.hermes/.env` y `~/.hermes/auth.json`; sesiones, memoria, historial, cachés y demás estado local siguen fuera del repo. El instalador de agentes comparte la autenticación del perfil `default`, igual que `hermes profile create --clone-from default`.

`~/Mi negocio/` queda sin crear. Los datos inventados y plantillas permanecen en `workspace/Tu equipo en Hermes/ejemplo/` para que la Configuradora los copie solo cuando Diego elija esa opción.
