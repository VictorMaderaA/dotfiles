#!/bin/bash

function install {
  which $1 &> /dev/null

  if [ $? -ne 0 ]; then
    echo "Installing: ${1}..."
    sudo apt install -y $1 > /dev/null
    figlet "Installed: ${1}" | lolcat
  else
    echo "Already installed: ${1}"
  fi
}

install git # version control
install curl # transfer data from or to a server
install htop # system monitor
install tmux # terminal multiplexer
install nmap # network scanner
install vim # text editor
install neovim # text editor
install exfat-utils # exfat file system support
install tree # list directory contents
install file # file type identification
install gimp # image editor
install jpegoptim # image optimization
install optipng # image optimization
install chromium-browser # web browser
install awscli # amazon web services cli
install neofetch # displays system info