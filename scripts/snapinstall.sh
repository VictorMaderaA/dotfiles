#!/bin/bash

sudo apt update

function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    echo "Installing: ${1}..."
    sudo snap install $1 $2
  else
    echo "Already installed: ${1}"
  fi
}




#Productivity
install notion-snap
install bitwarden
install slack --classic
install libreoffice
install bw # bitwarden cli
# install mailspring
install audacity
install doctl # digital ocean cli
install gnome-system-monitor


#Development
install docker
sudo addgroup --system docker
sudo adduser $USER docker
newgrp docker
sudo snap disable docker
sudo snap enable docker

install notepad-plus-plus
install datagrip --classic
install phpstorm --classic
install webstorm --classic
# install insomnia
install ngrok
#install pycharm-community
install pycharm-professional --classic
install postman
install node --classic

#Entreteinment
install spotify
install vlc
install obs-studio
install plexmediaserver
install snap-store
install easy-disk-cleaner
install organize-my-files

