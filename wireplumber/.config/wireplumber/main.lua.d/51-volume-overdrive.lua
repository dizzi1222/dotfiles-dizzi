-- Permitir volumen hasta 200% en WirePlumber

rule = {
  matches = {
    {
      { "node.name", "matches", "alsa_output.*" },
    },
    {
      { "node.name", "matches", "alsa_input.*" },
    },
  },
  apply_properties = {
    ["audio.volume"] = 1.0,        -- Volumen por defecto 100%
    ["audio.max-volume"] = 2.0,    -- Máximo 200%
  },
}

table.insert(alsa_monitor.rules, rule)
