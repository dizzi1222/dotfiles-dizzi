return {
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- web
          "html",
          "cssls",
          "emmet_ls",
          "tailwindcss",
          "ts_ls",
          "eslint",
          "svelte",
          "astro",

          -- others
          "rust_analyzer",
          "dockerls",
          "lua_ls",
          "jsonls",
          "yamlls",
          "bashls",
          "taplo",
          "pylsp",
          "zls",
        },
        automatic_installation = true,
      })
    end,
  },

  -- LSP config original comentado
  -- {
  --   "neovim/nvim-lspconfig",
  --   dependencies = {
  --     "joechrisellis/lsp-format-modifications.nvim",
  --     "hrsh7th/cmp-nvim-lsp",
  --   },
  --   config = function()
  --     -- Tu configuración de lspconfig aquí
  --   end,
  -- },

  {
    "nvimdev/lspsaga.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lspsaga").setup({
        lightbulb = {
          enable = false,
        },
      })
    end,
  },

  -- Mason + null-ls comentado
  -- {
  --   "jay-babu/mason-null-ls.nvim",
  --   event = { "BufReadPre", "BufNewFile" },
  --   dependencies = {
  --     "nvimtools/none-ls-extras.nvim",
  --     "williamboman/mason.nvim",
  --     "nvimtools/none-ls.nvim",
  --   },
  --   config = function()
  --     local null_ls = require("null-ls")
  --     require("mason-null-ls").setup({
  --       ensure_installed = { "stylua", "prettier", "black", "isort", "eslint_d" },
  --     })
  --     null_ls.setup({
  --       null_ls.builtins.formatting.stylua,
  --       null_ls.builtins.formatting.prettier,
  --       null_ls.builtins.formatting.black,
  --       null_ls.builtins.formatting.isort,
  --       null_ls.builtins.formatting.alejandra,
  --       require("none-ls.diagnostics.eslint"),
  --     })
  --     vim.keymap.set("n", "<A-S-f>", vim.lsp.buf.format)
  --   end,
  -- },
}

