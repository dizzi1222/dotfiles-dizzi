---
description: Lleva la vista de Neovim a una línea exacta (oc-open / mecanismo lazygit)
agent: build
---

Ejecuta `oc-open` con los objetivos indicados y confirma en una línea dónde quedó el cursor.

Objetivos: $ARGUMENTS

```bash
oc-open $ARGUMENTS
```

Notas:

- Si `$ARGUMENTS` está vacío, pídele la ruta y la línea antes de ejecutar.
- Acepta `ruta:línea[:columna]`, varios objetivos, o `-` para leer de stdin.
- Si el archivo ya está abierto en el Neovim de Diego, `oc-open` reutiliza ese buffer y
  sólo mueve el cursor (no crea tabs nuevas).
- No edites nada: este comando sólo navega.