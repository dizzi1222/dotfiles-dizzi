-- ~/.config/nvim/lua/plugins/lsp-progress.lua
-- DESCATIVAR NOTIFICACIONES DE LOADING
return {
  "linrongbin16/lsp-progress.nvim",
  config = function()
    require("lsp-progress").setup({
      max_time = 10000, -- mensajes desaparecen tras 10s
    })

    -- Evitar mostrar cualquier mensaje de LSP en la cmdline
    vim.lsp.handlers["$/progress"] = function() end

    -- Refrescar statusline automáticamente
    vim.api.nvim_create_augroup("LspProgressAU", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = "LspProgressAU",
      pattern = "LspProgressStatusUpdated",
      callback = function()
        vim.cmd("redrawstatus")
      end,
    })
  end,
}
