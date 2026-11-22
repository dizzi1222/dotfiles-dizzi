# Handoff Termux — MCPs + skills de Claude Code (paridad con Hermes/OpenCode)

> Origen: Bazzite (rama `main`), 2026-11-22. Destino: agente en Termux (rama `termux`).
> Objetivo: traer la config de Claude Code, cargar tokens y hacer healthcheck.
> **No hagas push sin confirmar con Diego.**

## Commit a traer

Es **un solo commit** squasheado en `main` (también existe en `nixos` y `cachyos` con rutas `/home/diego`).
Su SHA cambió varias veces por amend → **búscalo por mensaje, no por SHA**:

```bash
cd ~/dotfiles-dizzi && git fetch origin
SHA=$(git log origin/main -1 --format=%H --grep='paridad de MCPs y skills entre Claude Code, OpenCode y Hermes')
git show --stat "$SHA" | head -20
```

## Qué trae

| Archivo | Cambio |
| --- | --- |
| `home/.claude/mcp-servers.json` | Manifiesto de **19** MCPs para Claude (sin secretos: `${VAR}` + `$HOME`) |
| `local/.local/bin/claude-mcp-sync` | Registra el manifiesto con `claude mcp add-json -s user`; omite stdio sin binario |
| `home/.claude/skills/*` | 90 symlinks **relativos**: 38 de OpenCode + 52 de `~/.hermes/skills` (sin `apple/*`) |
| `opencode/.config/opencode/opencode.json` | + notion, canva, cloudflare, atlassian, vercel, **webshare** (`https://mcp.webshare.io/`) remotos OAuth; − webshare local (wrapper); **sin slack** |
| `hermes/config.yaml` | Solo el bloque `webshare` → `url: https://mcp.webshare.io/`, `enabled: true`, `auth: oauth`. **No toca `model:`** |
| `home/.claude/HANDOFF-TERMUX-CLAUDE-MCP.md` | Este archivo |

Por qué: `webshare-proxy-wrapper` **no es servidor MCP** (imprime `Usage` y sale con exit 1). Slack no
soporta dynamic client registration ("Incompatible auth server") y OpenCode v2 **ignora `disabled: true`**,
por eso se elimina la entrada en vez de desactivarla.

## Pasos en Termux

1. **Cherry-pick** (Termux tiene rutas `$PREFIX`; resolver conflictos **a favor de termux**):

   ```bash
   git status --short            # si hay cambios: commit WIP antes
   git checkout termux && git cherry-pick "$SHA"
   python3 -c "import json;json.load(open('opencode/.config/opencode/opencode.json'))" && echo json_ok
   grep -n -E '/var/home|/home/diego' opencode/.config/opencode/opencode.json hermes/config.yaml   # no debe salir nada
   ```

   - `opencode.json`: conserva tus rutas; añade los 6 bloques remotos (son URLs, sin rutas);
     elimina `slack` y el `webshare` local.
   - `hermes/config.yaml`: el bloque `webshare` queda solo con `url`/`enabled`/`auth`; conserva tu `model:`.

2. **Tokens** (exportados desde Bazzite a Google Drive, remote rclone `gd-musica:`). **No imprimas valores.**

   ```bash
   rclone copy gd-musica:_secrets-dotfiles/ ~/secrets-import/ -P
   tar -xzf ~/secrets-import/agent-secrets-*.tar.gz -C ~/secrets-import/
   cat ~/secrets-import/LEEME.txt
   # Comparar con lo local ANTES de pisar (solo nombres de variables):
   diff <(grep -o '^export [A-Z0-9_]*' ~/.api-keys.sh | sort) <(grep -o '^export [A-Z0-9_]*' ~/secrets-import/.api-keys.sh | sort)
   install -m 600 ~/secrets-import/.api-keys.sh ~/.api-keys.sh
   install -m 600 ~/secrets-import/hermes.env ~/.hermes/.env              # solo si Termux no tiene uno más nuevo
   install -m 600 ~/secrets-import/opencode.env ~/.config/opencode/.env   # idem
   cp -n ~/secrets-import/mcp-tokens/* ~/.hermes/mcp-tokens/              # OAuth de Hermes (no pisar existentes)
   rm -rf ~/secrets-import    # y avisar a Diego para borrar gd-musica:_secrets-dotfiles/
   ```

   `~/.api-keys.sh` debe cargarse en `~/.zshenv` (o `~/.bashrc`) para que Claude expanda `${VAR}`.

3. **Claude Code**:

   ```bash
   ln -sfn ../../dotfiles-dizzi/local/.local/bin/claude-mcp-sync ~/.local/bin/claude-mcp-sync
   claude-mcp-sync --dry-run   # ver qué se registra (stdio sin binario se omite)
   claude-mcp-sync
   ```

   Skills: si `~/.claude` apunta a `dotfiles-dizzi/home/.claude`, los symlinks ya resuelven
   (relativos a `~/dotfiles-dizzi` y `~/.hermes/skills`). Si no, enlázalos igual.

## Healthcheck (devolver tabla OK/FALLA)

```bash
claude mcp list                               # esperado: stdio ✔, remotos ✔ o "Needs authentication"
cd ~/dotfiles-dizzi && opencode mcp list      # si dice "No MCP servers configured": reintentar a los ~5 s
                                              # (pasa justo tras arrancar el servicio o fuera de un repo git)
# Hermes: estado de engram, n8n, shopify, webshare (url), rentahuman
find -L ~/.claude/skills -maxdepth 2 -name SKILL.md | wc -l   # ~90
find ~/.claude/skills -maxdepth 1 -xtype l                     # symlinks rotos = skills de Hermes ausentes en Termux
webshare whoami                               # falla sin WEBSHARE_API_KEY: esperado, solo reportarlo
```

Reportar también: servidores stdio omitidos (sin binario en Termux), conflictos resueltos y cómo,
y el SHA final en `termux`.

## Conocido / pendiente

- **todoist, gitlab, prisma**: los Bearer de `~/.api-keys.sh` estaban **caducados** (401). En Claude
  van por OAuth (`/mcp` → Authenticate). En OpenCode siguen con Bearer → renovar tokens.
- **composio-connect** en Claude pide autenticación: revisar `COMPOSIO_API_KEY`.
- **slack**: solo vía conector claude.ai, Hermes (administrado, token no local) o Composio.
- **webshare MCP**: autenticar OAuth (`/mcp` en Claude, `opencode mcp auth webshare`; Hermes reutiliza
  `mcp-tokens/webshare.json`). La skill `proxy-manager` (CLI) necesita aparte `WEBSHARE_API_KEY`
  (la línea `WS_API_TOKEN` está comentada en `~/.api-keys.sh`): crear key en
  <https://dashboard.webshare.io/userapi/keys>. Los `WS_PROXY_*` (proxies estáticos) sí están.
- `cua_repl` / `node_repl` en Hermes fallan: son de Codex/ChatGPT, no portables a Termux.
