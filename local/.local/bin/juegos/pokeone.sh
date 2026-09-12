#!/bin/bash
export WINEDEBUG=-all
export WINEPREFIX="/home/diego/.var/app/com.usebottles.bottles/data/bottles/bottles/gaming"
export WINEDLLOVERRIDES="mscoree,mscoreei,mscoreeis=n"
export LUTRIS_SKIP_INIT=1
wine "C:\\Games\\PokeOne\\Launcher.exe"
