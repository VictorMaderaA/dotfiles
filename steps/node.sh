#!/bin/bash

# Verifica si NVM está instalado
if [ -d "$HOME/.nvm" ]; then
    echo "NVM ya está instalado. Buscando actualizaciones..."
    export NVM_DIR="$HOME/.nvm"
    # Carga NVM
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    # Instala la versión LTS de Node.js
    echo "Instalando la versión LTS de Node.js..."
    nvm install --lts
else
    echo "Instalando NVM..."
    # Descarga e instala NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    # Carga NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    # Instala la versión LTS de Node.js
    echo "Instalando la versión LTS de Node.js..."
    nvm install --lts
fi

# Verifica la instalación de NVM
if command -v nvm &> /dev/null; then
    echo "NVM ha sido instalado/actualizado correctamente."
    echo "La versión LTS de Node.js ha sido instalada."
else
    echo "Hubo un problema instalando NVM. Por favor, verifica manualmente."
    exit 1
fi

# Establece la versión LTS como predeterminada
nvm alias default lts/*
echo "La versión LTS de Node.js ha sido establecida como predeterminada."

# Mensaje final con instrucciones de uso
echo -e "\nInstrucciones para usar NVM y administrar versiones de Node.js:"
echo "- Lista todas las versiones de Node disponibles para instalación: nvm ls-remote"
echo "- Instala una versión específica de Node: nvm install <version>"
echo "- Usa una versión específica de Node en una sesión: nvm use <version>"
echo "- Establece una versión predeterminada de Node: nvm alias default <version>"
echo "- Lista las versiones de Node instaladas: nvm ls"
