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
install mailspring


#Development
install datagrip --classic
install phpstorm --classic
install webstorm --classic
install insomnia
install ngrok
#install pycharm-community
install pycharm-professional --classic
install postman
install node --classic

#Entreteinment
install spotify

