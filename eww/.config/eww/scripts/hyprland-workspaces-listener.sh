
#!/bin/bash

get_data() {
  local workspaces active
  workspaces=$(hyprctl workspaces -j | jq -c 'sort_by(.id) | map(select(.windows > 0)) | [.[] | {id: .id}]')
  active=$(hyprctl activeworkspace -j | jq -r '.id')
  echo "{\"workspaces\": $workspaces, \"active\": \"$active\"}"
}

# Estado inicial
get_data

# Escuchar eventos y actualizar
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | \
while read -r line; do
  case "$line" in
    workspace>>*|focusedmon>>*|createworkspace>>*|destroyworkspace>>*|movewindow>>*|activewindow>>*)
      get_data
      ;;
  esac
done
