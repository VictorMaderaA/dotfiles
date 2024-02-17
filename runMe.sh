#!/bin/bash

function figlol() {
  figlet "$1" | lolcat
}

# Ask for the administrator password upfront
sudo -v

#  ____  _             _               
# / ___|| |_ __ _ _ __| |_ _   _ _ __  
# \___ \| __/ _` | '__| __| | | | '_ \ 
#  ___) | || (_| | |  | |_| |_| | |_) |
# |____/ \__\__,_|_|   \__|\__,_| .__/ 
#                               |_|    
./steps/startup.sh
figlol "Startup Complete"

#  ____                  _     _       _        
# / ___| _   _ _ __ ___ | |   (_)_ __ | | __
# \___ \| | | | '_ ` _ \| |   | | '_ \| |/ /
#  ___) | |_| | | | | | | |___| | | | |   <
# |____/ \__, |_| |_| |_|_____|_|_| |_|_|\_\
#        |___/                                  
figlol "Installing Dotfiles"
./steps/symLink.sh

#              _     _           _        _ _ 
#   __ _ _ __ | |_  (_)_ __  ___| |_ __ _| | |
#  / _` | '_ \| __| | | '_ \/ __| __/ _` | | |
# | (_| | |_) | |_  | | | | \__ \ || (_| | | |
#  \__,_| .__/ \__| |_|_| |_|___/\__\__,_|_|_|
#       |_|                                   
figlol "Installing apt Packages"
./steps/aptInstall.sh

#  _   _           _      
# | \ | | ___   __| | ___ 
# |  \| |/ _ \ / _` |/ _ \
# | |\  | (_) | (_| |  __/
# |_| \_|\___/ \__,_|\___|
figlol "Installing NodeVM"
./steps/node.sh

#  ____             _             
# |  _ \  ___   ___| | _____ _ __ 
# | | | |/ _ \ / __| |/ / _ \ '__|
# | |_| | (_) | (__|   <  __/ |   
# |____/ \___/ \___|_|\_\___|_|   
figlol "Installing Docker"
./steps/docker.sh

#  ____                    
# / ___| _ __   __ _ _ __  
# \___ \| '_ \ / _` | '_ \ 
#  ___) | | | | (_| | |_) |
# |____/|_| |_|\__,_| .__/ 
#                   |_|    
figlol "Installing Snap & Packages"
./steps/snap.sh


# __     ______   ____          _      
# \ \   / / ___| / ___|___   __| | ___ 
#  \ \ / /\___ \| |   / _ \ / _` |/ _ \
#   \ V /  ___) | |__| (_) | (_| |  __/
#    \_/  |____/ \____\___/ \__,_|\___|
figlol "Installing VSCode & Extensions"
./steps/vsc.sh


#   ___  _   _               
#  / _ \| |_| |__   ___ _ __ 
# | | | | __| '_ \ / _ \ '__|
# | |_| | |_| | | |  __/ |   
#  \___/ \__|_| |_|\___|_|   
figlol "Installing Other Packages"
./steps/other.sh


figlol "Cleaning up"
sudo apt-get autoremove -y
sudo apt-get autoclean -y