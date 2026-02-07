#!/bin/bash
# wifihack.sh

sudo airmon-ng check kill
sudo airmon-ng start wlan0
kitty --title "Airodump" -e sudo airodump-ng wlan0mon &
echo "Modo monitor activado. BSSID y canal?"

# ~/.local/bin
