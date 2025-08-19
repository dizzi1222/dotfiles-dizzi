--.. al finar Empeze a probar otro autosave XD de mc-gap
return {
  "m-gac/auto-save.nvim",

  config = function()
    require("auto-save").setup({
      events = { "BufLeave", "InsertLeave" },
    })
  end,
}
