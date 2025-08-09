-- ~/.config/nvim/lua/plugins/init.lua
return {
  -- 1) Primero los plugins/core de LazyVim (debe ir primero)
  { import = "lazyvim.plugins" },
  -- 2) Luego van los extras de LazyVim
  { import = "lazyvim.plugins.extras" },

  -- 3) Finalmente tus propios plugins
  { "pocco81/auto-save.nvim" },
  { "eandrju/cellular-automaton.nvim" },
  { "gen740/SmoothCursor.nvim" }, -- usa owner/nombre
  -- agrega aquí el resto de tus plugins...
}
