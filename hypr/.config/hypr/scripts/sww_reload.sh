# WAYBAR START
#
# by Abuku (2024)

# Kill all hyprpaper instance
pkill swww-daemon
pkill -f hyprpaper
# Reload SWW
swww-daemon
eww reload && sleep 1 && eww reload ## # dale 2 veces Windows+Shift+A para que se actualice
exit 0                              # <- opcional, solo deja claro que terminó
