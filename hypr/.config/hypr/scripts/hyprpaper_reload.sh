# WAYBAR START
#
# by Abuku (2024)

# Kill all hyprpaper instance
pkill hyprpaper
pkill swww-daemon
pkill -f swww-daemon
# Reload hyprpaper
hyprpaper
eww reload && eww reload # dale 2 veces Windows+A para que se actualice
exit 0                   # <- opcional, solo deja claro que terminó
