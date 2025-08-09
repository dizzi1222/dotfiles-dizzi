local hl = function(thing, opts)
  vim.api.nvim_set_hl(0, thing, opts)
end

return {
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      vim.g.neovide_transparency = 0.98

      require("tokyonight").setup({
        style = "night", -- "storm", "night", "moon", "day"
        transparent = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      })

      vim.o.background = "dark"
      vim.cmd.colorscheme("tokyonight")

      -- Enlazar SmoothCursor a un color de Tokyonight
      hl("SCCursorHead", { link = "Identifier" })
      hl("SCCursor", { link = "Identifier" })
    end,
  },
  {
    "xiyaowong/transparent.nvim",
    priority = 1000,
    config = function()
      require("transparent").setup({
        extra_groups = {
          "NormalFloat",
          "NvimTreeNormal",
        },
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup()
    end,
  },
  {
    "gen740/SmoothCursor.nvim",
    config = function()
      require("smoothcursor").setup({
        cursor = "",
        texthl = "SCCursorHead",
        linehl = nil,
        type = "exp",
        fancy = {
          enable = true,
          head = { cursor = "", texthl = "SCCursorHead" },
          body = {
            { cursor = "●", texthl = "SCCursor" },
            { cursor = "●", texthl = "SCCursor" },
            { cursor = "•", texthl = "SCCursor" },
            { cursor = "•", texthl = "SCCursor" },
            { cursor = "∙", texthl = "SCCursor" },
            { cursor = "∙", texthl = "SCCursor" },
          },
        },
        speed = 20,
        intervals = 15,
        threshold = 1,
        disable_float_win = true,
      })
    end,
  },
}
