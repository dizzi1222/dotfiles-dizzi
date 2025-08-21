-- ~/.config/nvim/lua/plugins/minty.lua
-- ~/.config/nvim/lua/plugins/minty.lua
return {
  "nvzone/minty",
  cmd = { "Shades", "Huefy" },
  keys = {
    -- Mapeo para 'Shades'
    { "<leader>ms", "<cmd>Shades<CR>", desc = "Toggle Shades" },
    -- Mapeo para 'Huefy'
    { "<leader>mh", "<cmd>Huefy<CR>", desc = "Toggle Huefy" },
  },
}
