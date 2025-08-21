--.. al finar Empeze a probar otro autosave XD de mc-gap
return {
  {
    "okuuva/auto-save.nvim",
    cmd = "ASToggle", -- carga bajo demanda
    event = { "InsertLeave", "TextChanged" }, -- gatilla eventos
    opts = {
      trigger_events = {
        immediate_save = { "BufLeave", "FocusLost" },
        defer_save = { "InsertLeave", "TextChanged" },
        cancel_deferred_save = { "InsertEnter" },
      },
      -- aquí puedes añadir más opciones según tu preferencia
    },
  },
}
