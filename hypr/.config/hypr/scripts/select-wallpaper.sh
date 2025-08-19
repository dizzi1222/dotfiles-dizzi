ls ~/Wallpapers/wallpapers/ | rofi -dmenu | xargs -I _ sh -c 'swww img -t wipe ~/Wallpapers/wallpapers/_ && sleep 2 && wal -i ~/Wallpapers/wallpapers/_'
