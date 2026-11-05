# Genera el perfil de Plasma a partir de la configuración compartida.
def action($name): ($home + "/scripts/swaync-bazzite-action.sh" | @sh) + " " + $name;

.["$schema"] = "https://raw.githubusercontent.com/ErikReider/SwayNotificationCenter/v0.11.0/src/configSchema.json"
| .widgets |= map(
    if . == "slider" then "backlight#keyboard"
    elif . == "slider#vanzuh" then empty
    else . end
  )
| .["widget-config"] |= (
    del(.slider, .["slider#vanzuh"])
    | .["backlight#keyboard"] = {label: "󰌌", device: "tpacpi::kbd_backlight", subsystem: "leds"}
    | .["buttons-grid"].actions |= map(
        if .command == "hyprctl dispatch exit" then .command = action("logout")
        elif .command == "hyprlock" then .command = action("lock")
        elif (.command | endswith("/bluetuith-swaync.sh")) then .command = action("bluetooth")
        elif (.command | endswith("/toggle-dnd.sh")) then
          .command = action("dnd") | .["update-command"] = action("dnd-status")
        elif (.command | endswith("/toggle-night-mode.sh")) then
          .command = action("night-mode") | .["update-command"] = action("night-status")
        else . end
      )
  )
