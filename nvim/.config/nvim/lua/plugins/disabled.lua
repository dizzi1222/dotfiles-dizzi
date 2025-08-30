-- 💸💳💰 DONDE ESTA CHATGPT? COMO IA ES TREMENDA.. PERO NO ES GRATIS PARA INTEGRARLO EN NVIM DIRECTAMENTE. Al igual que Avante [avane/cursor es mejor]
--
-- PARA QUE FUNCIONE DEBES DE ELIMINAR CMP.lua
--
-- PARA ACTIVAR CIERTAS IAS NECESITAS MODIFICAR CIERTOS ARCHIVOS
-- Entre ellos:
--   - plugins/init.lua
--   - plugins/disabled.lua
--   - .config/lazy.lua
-- Y LOS RESPECTOS ARCHIVOS DE CONFIGURACION dE IA [copilot, claude-code.lua etc]
--   - .config/nvim/lua/plugins/copilot.lua [opcional usa copilot-chat.lua]
--   - .config/nvim/lua/plugins/supermaven.lua {etc..}
--
-- OBVIAMENTE REVISA LOS KEYMAPS: config/keymaps.lua--

-- This file contains the configuration for disabling specific Neovim plugins.{desactivar plugins
return {
  {
    -- Plugin: bufferline.nvim
    -- URL: https://github.com/akinsho/bufferline.nvim
    -- Description: A snazzy buffer line (with tabpage integration) for Neovim.
    "akinsho/bufferline.nvim",
    enabled = true, -- Disable this plugin
  },
  {
    -- Plugin para mejorar la experiencia de edición en Neovim
    -- URL: https://github.com/yetone/avante.nvim
    -- Description: Este plugin ofrece una serie de mejoras y herramientas para optimizar la edición de texto en Neovim.
    "yetone/avante.nvim",
    enabled = false,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = true,
  },
  { "supermaven-nvim", enabled = false },
  {
    "codota/tabnine-nvim",
    enabled = false,
  },
  "folke/snacks.nvim",
  enabled = false,
  {
    "sudo-tee/opencode.nvim",
    enabled = false,
  },
  {
    "olimorris/codecompanion.nvim",
    enabled = true,
  },
  {
    "tris203/precognition.nvim",
    enabled = false,
  },
  {
    -- Plugin: claude-code.nvim
    -- URL: https://github.com/greggh/claude-code.nvim
    -- Description: Neovim integration for Claude Code AI assistant
    "greggh/claude-code.nvim",
    enabled = false,
  },
}
