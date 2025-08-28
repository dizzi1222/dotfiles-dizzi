-- 🐐🗣️🔥️✍️ NO REQUIERE API  USA : Copilot auth
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
--
return {
  "zbirenbaum/copilot.lua",
  optional = true,
  opts = function()
    require("copilot").setup({
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = "<Tab>", -- acepta sugerencia
          next = "<C-]>",
          prev = "<C-[>",
          dismiss = "<ESC",
        },
      },
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        -- poner true para filetypes donde quieras AI
        lua = true,
        python = true,
        javascript = true,
        typescript = true,
      },
    })
  end,
}
