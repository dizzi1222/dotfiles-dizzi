return {
  {
    "andweeb/presence.nvim",
    lazy = false,
    config = function()
      require("presence"):setup({
        auto_update = true, -- Actualiza automáticamente tu estado
        neovim_image_text = "Editando en Neovim",
        main_image = "neovim",
        client_id = "793271441293967371", -- ID oficial de Neovim RPC
        buttons = true, -- Botones para mostrar en Discord
        enable_line_number = true, -- Muestra línea actual
      })
    end,
  },
}
