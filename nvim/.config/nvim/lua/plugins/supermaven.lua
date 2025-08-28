return {
  "supermaven-nvim",
  opts = {
    keymaps = {
      accept_suggestion = "<Tab>",
      clear_suggestion = "<C-]>",
      accept_word = "<C-j>",
    },
    ignore_filetypes = { cpp = true },
    color = {
      suggestion_color = "#595959b6",
      cterm = 244,
    },
    log_level = "info",
    disable_inline_completion = false,
    disable_keymaps = false,
    condition = function()
      return false
    end,
  },
}
