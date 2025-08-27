return {
  "zbirenbaum/copilot.lua",
  optional = true,
  opts = function()
    require("copilot").setup({
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = "<C-Tab>", -- acepta sugerencia
          next = "<C-]>",
          prev = "<C-[>",
          dismiss = "<C-",
        },
      },
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        -- poner true para filetypes donde quieras AI
        lua = true,
        python = true,
        javascript = true,
        typescript = true,
      },
    })
  end,
}
