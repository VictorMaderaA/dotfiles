#!/bin/bash

sudo apt-get install -y snapd

sudo snap refresh --list
sudo snap refresh

function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    echo "Installing: ${1}..."
    sudo snap install $1 $2
  else
    echo "Already installed: ${1}"
  fi
}

# IDEs
install webstorm --classic
install phpstorm --classic
install datagrip --classic
install pycharm-professional --classic

# Entreteinment
install spotify
install vlc
install obs-studio
install plexmediaserver
install snap-store

# Development
install insomnia
install postman
install ngrok
install notepad-plus-plus

# Utilities
install libreoffice
install bw # bitwarden cli
install doctl # digital ocean cli
install notion-snap-reborn
install notion-calendar-snap
install bitwarden
install audacity
install gnome-system-monitor

# Communication
install slack --classic
install discord
install telegram-desktop

# Browsers
install chromium
install firefox
install brave

# Games
install steam
