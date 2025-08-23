ls ~/wallpapers/wallpapers/ | rofi -dmenu | xargs -I _ sh -c 'swww img -t wipe ~/wallpapers/wallpapers/_ && sleep 2 && wal -i ~/wallpapers/wallpapers/_'
