#!/bin/bash
export WINEDEBUG=-all
export LUTRIS_SKIP_INIT=1
script -e -q -c "wine '/home/diego/.wine/drive_c/Games/Stardew Valley/StardewModdingAPI.exe'" /dev/null
