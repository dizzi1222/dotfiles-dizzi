"""Plugin ``limpieza``: comando ``/limpieza`` para limpieza acotada de Bazzite/Fedora."""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


def register(ctx) -> None:
    from . import slash
    ctx.register_command(
        "limpieza",
        slash.make_handler(ctx),
        description="Ejecuta la rutina de limpieza acotada de Bazzite/Fedora (cachés, journal, rpm-ostree, Hermes, Codex)",
        args_hint="[--dry-run | --quick]",
    )
    logger.info("Plugin 'limpieza' registrado: comando /limpieza disponible")