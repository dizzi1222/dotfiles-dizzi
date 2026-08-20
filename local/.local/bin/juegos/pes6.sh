#!/bin/bash
export WINEDEBUG=-all
export LUTRIS_SKIP_INIT=1
cd "/home/diego/.wine/drive_c/Games/KONAMI/Pro Evolution Soccer 6" || exit 1
wine "PES6.exe"
