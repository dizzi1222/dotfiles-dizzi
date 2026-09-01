#!/bin/bash
sudo rfkill unblock bluetooth
sudo systemctl restart bluetooth
notify-send "󰂯  Bluetooth" "Bluetooth reiniciado correctamente"
