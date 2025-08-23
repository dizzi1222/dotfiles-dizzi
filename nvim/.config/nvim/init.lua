-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.keymaps")

--.. al finar Empeze a probar otro autosave XD de ookuva

-- Autosave nativo sin plugins,Pero empeze a usar autommands - NO FUNCIONA EN WINDOWS
-- vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave", "FocusLost" }, {
--   callback = function()
--     if vim.bo.modified and vim.bo.buftype == "" then
--       vim.cmd("silent write")
--     end
--   end,
-- })

-- después de lazy.nvim, al final de init.lua

require("lsp-progress").setup()
