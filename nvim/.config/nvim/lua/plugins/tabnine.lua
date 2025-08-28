-- 🐐🗣️🔥️✍️  NO REQUIERE API. [lo usa gil] Pero no me gusta tanto como copilot, o supermaven como IAS gratuitas para sugerencias]
--
-- PARA QUE FUNCIONE DEBES DE ELIMINAR CMP.lua
--
-- PARA ACTIVAR CIERTAS IAS NECESITAS MODIFICAR CIERTOS ARCHIVOS
--
-- Entre ellos:
--   - plugins/init.lua
--   - plugins/disabled.lua
--   - .config/lazy.lua
-- Y LOS RESPECTOS ARCHIVOS DE CONFIGURACION dE IA [copilot, claude-code.lua etc]
--   - .config/nvim/lua/plugins/copilot.lua [opcional usa copilot-chat.lua]
--   - .config/nvim/lua/plugins/supermaven.lua {etc..}
--
-- OBVIAMENTE REVISA LOS KEYMAPS: config/keymaps.lua--
--
return {
  -- // Esta extension es la que da problemas al usar Ctrl+O, pero da sugerencias AI
  "codota/tabnine-nvim",
  build = "./dl_binaries.sh",
  config = function()
    require("tabnine").setup({
      disable_auto_comment = true,
      accept_keymap = "<Tab-//>",
      dismiss_keymap = "<C-c]>",
      debounce_ms = 800,
      suggestion_color = { gui = "#808080", cterm = 244 },
      exclude_filetypes = { "TelescopePrompt", "NvimTree" },
      log_file_path = nil, -- absolute path to Tabnine log file
      ignore_certificate_errors = false,
      -- workspace_folders = {
      --   paths = { "/your/project" },
      --   get_paths = function()
      --       return { "/your/project" }
      --   end,
      -- },
    })
  end,
}
