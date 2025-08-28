-- 💸💳💰REQUIERE API. USA : claude auth o consigue tu key en https://claude.ai
--
-- PARA QUE FUNCIONE DEBES DE ELIMINAR CMP.lua
--
-- PARA ACTIVAR CIERTAS IAS NECESITAS MODIFICAR CIERTOS ARCHIVOS
-- Entre ellos:
--   - plugins/init.lua
--   - plugins/disabled.lua
--   - .config/lazy.lua
-- Y LOS RESPECTOS ARCHIVOS DE CONFIGURACION dE IA [copilot, claude-code.lua etc]
--   - .config/nvim/lua/ia.lua
return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for git operations
  },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>ar", "<cmd>ClaudeCodeResume<cr>", desc = "Resume conversation (picker)" },
    { "<leader>at", "<cmd>ClaudeCodeContinue<cr>", desc = "Continue recent conversation" },
    { "<leader>av", "<cmd>ClaudeCodeVerbose<cr>", desc = "Verbose logging" },
  },
  config = function()
    require("claude-code").setup()
  end,
}
