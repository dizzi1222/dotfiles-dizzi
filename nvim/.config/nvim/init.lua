-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.keymaps")

-- [MUY OPCIONAL] LSP Progress - NO RECOMIENDO DESACTIVARLO, eso tiene que ver con tu PC y CPU que sea tan lento.. por sobrecargar la config
-- Aparte LSP progress solo se jecuta al modificar cosas de NVIM...
-- vim.lsp.handlers["$/progress"] = function() end -- si quieres desactivar LSP PROGRESS:

-- [OOKUVA AUTOSAVE ES MUCHO MEJOR UBICADO EN: lua/plugins/auto-save.lua]
-- al finar Empeze a probar otro autosave XD de ookuva
-- por cierto,hay que veces que ookuva se bugea o si sales muy rapido no guardara un carajo

-- [NO USO ESTE AUTOSAVE YA.]
-- Autosave nativo sin plugins,Pero empeze a usar autommands - NO FUNCIONA EN WINDOWS
-- vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave", "FocusLost" }, {
--   callback = function()
--     if vim.bo.modified and vim.bo.buftype == "" then
--       vim.cmd("silent write")
--     end
--   end,
-- })
