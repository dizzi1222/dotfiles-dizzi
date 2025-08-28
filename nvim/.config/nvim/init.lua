-- PARA Configurar IAS, revisa:
-- config/lazy.lua
-- plugins/disabled
-- OBVIAMENTE REVISA LOS KEYMAPS: config/keymaps.lua
--
-- KEYMAPS DE CHAT por IA FUNCIONAN AL SELECCIONAR TEXTO [v]
--
-- # Primero, arreglar PATH para binarios globales
vim.env.PATH = os.getenv("HOME") .. "/.npm-global/bin:" .. vim.env.PATH

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.keymaps")

-- # PARA HACER FUNCIONAR GENTLEMAN AIS
require("config.nodejs").setup({ silent = true })

-- [MUY OPCIONAL] LSP Progress - NO RECOMIENDO DESACTIVARLO, eso tiene que ver con tu PC y CPU que sea tan lento.. por sobrecargar la config
-- Aparte LSP progress solo se jecuta al modificar cosas de NVIM...
-- vim.lsp.handlers["$/progress"] = function() end -- si quieres desactivar LSP PROGRESS:

-- Configuracion del cursor - smear
require("smear_cursor").setup({
  cursor_color = "#49A3EC",
  stiffness = 0.3,
  trailing_stiffness = 0.1,
  trailing_exponent = 5,
  hide_target_hack = true,
  gamma = 1,
})
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
-- bootstrap lazy.nvim, LazyVim and your plugins
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
