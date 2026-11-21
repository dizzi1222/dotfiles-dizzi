---
description: Libera espacio con la rutina acotada de Bazzite (cachés, rclone, Hermes)
agent: build
---

Ejecuta la rutina oficial de limpieza y reporta cuánto espacio se liberó. El script
vive en `~/scripts/fedora-cleanup.sh` (symlink a
`dotfiles-dizzi/home/scripts/fedora-cleanup.sh`).

Modos disponibles:

| Uso                       | Efecto                                                              |
| ------------------------- | ------------------------------------------------------------------- |
| `/limpieza`               | Pasada completa (cachés, journal, rpm-ostree -bm, Hermes, Codex)     |
| `/limpieza --dry-run`     | Solo muestra qué borraría, no toca nada                              |
| `/limpieza --quick`       | Pasada mínima de cachés (la del timer de cada minuto)                |

```bash
~/scripts/fedora-cleanup.sh $ARGUMENTS
```

Si `$ARGUMENTS` está vacío, ejecuta la pasada completa. Después resume en una tabla
breve: libre antes, libre ahora, liberado real y secciones que aportaron espacio.

Reglas que el comando NO puede romper (ni con argumentos):

- Nada de juegos: Steam (`common`, `compatdata`, `shadercache`, `workshop`), Lutris,
  Bottles, Waydroid, `/var/mnt/games-swap`.
- Nada de datos personales: `~/Descargas`, `~/Documentos`, `~/Vídeo*`, `~/Escritorio`,
  workspace, repos, dotfiles ni papelera.
- Nada de Zen Browser (perfil, sesión ni caché).
- `rpm-ostree` solo con `cleanup -bm`; nunca `-p`, `-r` ni `ujust clean-system`.
- `sudo` solo en modo no interactivo (`sudo -n`) para no colgar el comando.
