-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.keymaps")

-- Autosave nativo sin plugins,Pero usando autommands
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufLeave", "FocusLost" }, {
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" then
      vim.cmd("silent write")
    end
  end,
})
