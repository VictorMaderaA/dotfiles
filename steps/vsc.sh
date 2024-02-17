#!/bin/bash

# Verifica si Visual Studio Code está instalado
if ! command -v code &> /dev/null
then
    echo "Visual Studio Code no está instalado. Instalando..."
    # Importa la clave de Microsoft GPG
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    # Añade el repositorio de Visual Studio Code
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm microsoft.gpg
    # Actualiza paquetes e instala Visual Studio Code
    sudo apt update -y 
    sudo apt install code -y
fi

# Lista de extensiones a instalar/actualizar
# Puedes modificar esta lista según tus necesidades
# code --list-extensions
extensions=(
    aaron-bond.better-comments
    christian-kohler.path-intellisense
    dbaeumer.vscode-eslint
    eamodio.gitlens
    github.copilot
    github.copilot-chat
    kamikillerto.vscode-colorize
    ms-azuretools.vscode-docker
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    ms-vscode.remote-explorer
    vscode-icons-team.vscode-icons
    waderyan.gitblame
    xabikos.javascriptsnippets
    hookyqr.beautify
)

# Instala o actualiza las extensiones
for extension in "${extensions[@]}"
do
    code --install-extension $extension --force
done

echo "Visual Studio Code y las extensiones han sido actualizados."s