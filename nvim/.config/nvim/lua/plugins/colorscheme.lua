return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        flavour = "frappe",
        transparent_background = true,
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "morhetz/gruvbox",
    lazy = false,
  },

  -- # Si prefieres tener un fondo usa este y comenta lo otro de abajo
  -- vim.keymap.set("n", "<leader>ct", function()
  --   require("telescope.builtin").colorscheme({ enable_preview = true })
  -- end, { desc = "Cambiar colorscheme" }),

  -- temas con fondo transparente, temas retros tiene identaciones mas anchas.. lsp progress molesta en blanco btw
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>ct",
        function()
          require("telescope.builtin").colorscheme({ enable_preview = true })
        end,
        desc = "Cambiar colorscheme (sin fondo forzado)",
      },
    },
  },

  {
    "nvim-lua/plenary.nvim",
    config = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local groups = {
            "Normal",
            "NormalNC",
            "NormalFloat",
            "SignColumn",
            "MsgArea",
            "MsgSeparator",
            "FloatBorder",
            "TelescopeNormal",
            "TelescopeBorder",
            "Pmenu",
            "PmenuSel",
            "NonText",
            "Whitespace",
            "EndOfBuffer",
            -- 🔹 extra para temas viejos como morning
            "Identifier",
            "Statement",
            "PreProc",
            "Type",
            "Special",
            "Todo",
          }
          for _, g in ipairs(groups) do
            vim.api.nvim_set_hl(0, g, { bg = "none" })
          end
        end,
      })
    end,
  },
}
