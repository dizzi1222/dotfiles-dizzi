"""``/limpieza``: Ejecuta la rutina de limpieza acotada de Bazzite/Fedora.

``/limpieza``               Pasada completa (cachés, journal, rpm-ostree -bm, Hermes, Codex)
``/limpieza --dry-run``     Solo muestra qué borraría, no toca nada
``/limpieza --quick``       Pasada mínima de cachés (la del timer de cada minuto)

El script vive en ``~/scripts/fedora-cleanup.sh`` (symlink a
``dotfiles-dizzi/home/scripts/fedora-cleanup.sh``).
"""

from __future__ import annotations

import subprocess
from typing import Any, Callable, Optional

USAGE = "/limpieza [--dry-run | --quick]"


def make_handler(ctx) -> Callable[..., str]:
    """The registered handler: ``handle`` with the context."""
    def limpieza_command(raw_args: str = "", **_: Any) -> str:
        return handle(raw_args)
    return limpieza_command


def _parse(raw: str) -> tuple[bool, bool, str]:
    """``(dry_run, quick, unknown_arg)`` from the raw arguments."""
    words = raw.split()
    dry_run = "--dry-run" in words
    quick = "--quick" in words
    unknown = next((w for w in words if w not in ("--dry-run", "--quick")), "")
    return dry_run, quick, unknown


def handle(raw_args: str = "") -> str:
    dry_run, quick, unknown = _parse(raw_args or "")
    
    if unknown:
        return f"Argumento desconocido '{unknown}'. Uso: {USAGE}"
    
    if dry_run and quick:
        return "No se puede usar --dry-run y --quick a la vez. Uso: {USAGE}"
    
    script_path = "/home/diego/scripts/fedora-cleanup.sh"
    
    # Build command
    cmd = [script_path]
    if dry_run:
        cmd.append("--dry-run")
    if quick:
        cmd.append("--quick")
    
    try:
        # Run the script and capture output
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,  # 5 minute timeout
        )
        
        output = result.stdout
        if result.stderr:
            output += f"\n--- stderr ---\n{result.stderr}"
        
        if result.returncode == 0:
            return output.strip() if output.strip() else "✓ Limpieza completada sin salida visible"
        else:
            return f"✗ Error (código {result.returncode}):\n{output.strip()}"
            
    except subprocess.TimeoutExpired:
        return "✗ Timeout: la limpieza tardó más de 5 minutos"
    except FileNotFoundError:
        return f"✗ Script no encontrado en {script_path}. Verifica que exista el symlink ~/scripts/fedora-cleanup.sh"
    except Exception as e:
        return f"✗ Error ejecutando limpieza: {e}"