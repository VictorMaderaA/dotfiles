#!/bin/bash

sudo apt update

function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    echo "Installing: ${1}..."
    sudo snap install $1
  else
    echo "Already installed: ${1}"
  fi
}

#Productivity
install notion-snap
install bitwarden

#Development
install datagrip
install phpstorm
install webstorm
#install pycharm-community
install pycharm-professional
install postman
install node

#Entreteinment
install spotify

