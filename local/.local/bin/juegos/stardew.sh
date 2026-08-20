#!/bin/bash
export WINEDEBUG=-all
export LUTRIS_SKIP_INIT=1
antimicrox --profile "$HOME/.config/antimicrox/profiles/8bitdo-stardew.amgp" --tray &
ANTI_PID=$!
sleep 1
script -e -q -c "wine '/home/diego/.wine/drive_c/Games/Stardew Valley/StardewModdingAPI.exe'" /dev/null
kill $ANTI_PID 2>/dev/null
