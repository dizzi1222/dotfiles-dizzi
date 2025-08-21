return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({ flavour = "frappe", transparent_background = true })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "morhetz/gruvbox",
    lazy = false,
  },

  vim.keymap.set("n", "<leader>ct", function()
    require("telescope.builtin").colorscheme({ enable_preview = true })
  end, { desc = "Cambiar colorscheme" }),
}
