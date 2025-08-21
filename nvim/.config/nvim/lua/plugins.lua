-- ~/.config/nvim/lua/plugins/init.lua
return {
  -- 1) Primero los plugins/core de LazyVim (debe ir primero)
  { import = "lazyvim.plugins" },
  -- 2) Luego van los extras de LazyVim
  { import = "lazyvim.plugins.extras" },

  -- 3) Finalmente tus propios plugins

  -- Pero empeze a usar autommands autosave en mi init.lua, no me da tantos problemas.

  -- ... al finar Empeze a probar otro autosave XD de okuuva un chad.
  -- { "pocco81/auto-save.nvim" },
  { "eandrju/cellular-automaton.nvim" },
  { "gen740/SmoothCursor.nvim" }, -- usa owner/nombre

  -- agrega aquí el resto de tus plugins...
  {
    -- elegir colores de HEXH - RGB
    -- Lo abres con Space + C + P = Cole Palmer 🗣️
    "uga-rosa/ccc.nvim",
    config = function()
      local ccc = require("ccc")
      ccc.setup({
        highlighter = {
          auto_enable = true, -- Resalta colores automáticamente
          lsp = true, -- Usa LSP para detección extra
        },
      })
      -- Lo abres con Space + C + P = Cole Palmer 🗣️
      -- Atajos estilo VSCode
      vim.keymap.set("n", "<leader>cp", "<cmd>CccPick<cr>", { desc = "Color Picker" })
      vim.keymap.set("n", "<leader>cc", "<cmd>CccConvert<cr>", { desc = "Convertir color" })

      --LO ABRES CON SPACE + V + Colorpicker con Mouse GOD 🗣️🙏️✍️ -- unicamente con MOUSE.
      -- setup de oklch-color-picker dentro del mismo config
      require("oklch-color-picker").setup({
        highlight = {
          enabled = true,
          style = "foreground+virtual_left",
          virtual_text = "■ ",
          emphasis = { threshold = { 0.1, 0.17 }, amount = { 45, -80 } },
        },
        patterns = {
          hex = { priority = -1, "()#%x%x%x+%f[%W]()" },
          numbers_in_brackets = false,
        },
        auto_download = true,
        wsl_use_windows_app = true,
      })
    end,
  },
}
