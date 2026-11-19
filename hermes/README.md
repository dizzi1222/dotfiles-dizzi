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

## Datos locales y secretos

`config.yaml` se basa en la configuración activa de Bazzite y añade únicamente `fallback_providers` del perfil Termux. Las credenciales siguen en `~/.hermes/.env` y `~/.hermes/auth.json`; sesiones, memoria, historial, cachés y demás estado local siguen fuera del repo. El instalador de agentes comparte la autenticación del perfil `default`, igual que `hermes profile create --clone-from default`.

`~/Mi negocio/` queda sin crear. Los datos inventados y plantillas permanecen en `workspace/Tu equipo en Hermes/ejemplo/` para que la Configuradora los copie solo cuando Diego elija esa opción.
