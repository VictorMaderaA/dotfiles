#!/bin/bash

# Check if figlet is installed
if ! command -v figlet &> /dev/null; then
  echo "figlet not found. Please install it to use this script."
  exit 1
fi

# Up from scripts dir
if [ ! -d "./dotfiles" ]; then
  echo "Directory './dotfiles' does not exist."
  exit 1
fi

cd ./dotfiles || exit
dotfilesDir=$(pwd)

function linkDotfile {
  local dest="${HOME}/${1}"
  local dateStr=$(date +%Y-%m-%d-%H%M)

  if [ -h "${dest}" ]; then
    # Existing symlink 
    echo "Removing existing symlink: ${dest}"
    rm "${dest}" 

  elif [ -f "${dest}" ]; then
    # Existing file
    echo "Backing up existing file: ${dest}"
    mv "${dest}" "backup_${dest}.${dateStr}"

  elif [ -d "${dest}" ]; then
    # Existing dir
    echo "Backing up existing dir: ${dest}"
    mv "${dest}" "backup_${dest}.${dateStr}"
  fi

  echo "Creating new symlink: ${dest}"
  ln -s "${dotfilesDir}/${1}" "${dest}"

  figlet "__________"
}

linkDotfile .bash_aliases
linkDotfile .bash_profile
linkDotfile .bashrc
linkDotfile .gitconfig
linkDotfile .gitmessage
