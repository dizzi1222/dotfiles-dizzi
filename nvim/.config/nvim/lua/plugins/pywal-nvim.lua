return {
  {
    "AlphaTechnolog/pywal.nvim",
    name = "pywal",
    config = function()
      -- Guardamos tu colorscheme original
      local original_colorscheme = vim.g.colors_name or "default"
      local wal_active = false -- Pywal inicia activado
      -- # ESTO DE TERMINA SI ARRANCA FALSE O TU TEMA
      -- # CON SPACE + PW o SPACE + P = Alternas entre Pywal / colorscheme

      -- Activamos Pywal al inicio si wal_active es true
      if wal_active then
        require("pywal").setup()
      else
        vim.cmd("colorscheme " .. original_colorscheme)
      end

      -- Función toggle de Pywal
      local function toggle_pywal()
        if wal_active then
          vim.cmd("colorscheme " .. original_colorscheme) -- vuelve a tu tema original
          wal_active = false
        else
          require("pywal").setup() -- activa Pywal
          wal_active = true
        end
      end

      -- Mapear <leader>p para toggle
      vim.keymap.set("n", "<leader>p", toggle_pywal, { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>pw", toggle_pywal, { noremap = true, silent = true })
    end,
  },
}
