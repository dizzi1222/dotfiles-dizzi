#!/bin/bash
echo "Quick Termux Setup..."
termux-setup-storage
pkg update && pkg upgrade -y
pkg install -y git curl wget android-tools
curl -sS https://starship.rs/install.sh | sh -s -- -y
echo 'eval "$(starship init bash)"' >> ~/.bashrc
mkdir -p ~/.termux/boot
source ~/.bashrc
echo "Listo!"
