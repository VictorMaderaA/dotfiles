#!/bin/bash

# Verifica si NVM está instalado
if [ -d "$HOME/.nvm" ]; then
    echo "NVM ya está instalado. Buscando actualizaciones..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install node # Esto actualizará a la última versión de Node
else
    echo "Instalando NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install node # Esto instalará la última versión de Node
fi

# Verifica la instalación de NVM
if command -v nvm &> /dev/null; then
    echo "NVM ha sido instalado/actualizado correctamente."
else
    echo "Hubo un problema instalando NVM."
fi

# Instrucciones para usar NVM (comentadas)
: '
Para usar NVM y administrar versiones de Node.js:
- Lista todas las versiones de Node disponibles para instalación: nvm ls-remote
- Instala una versión específica de Node: nvm install <version>
- Usa una versión específica de Node en una sesión: nvm use <version>
- Establece una versión predeterminada de Node: nvm alias default <version>
- Lista las versiones de Node instaladas: nvm ls
'
