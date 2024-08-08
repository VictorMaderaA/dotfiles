#!/bin/bash

# Verifica si pyenv está instalado
if command -v pyenv &> /dev/null; then
    echo "pyenv ya está instalado."
    exit 0
else
    echo "pyenv no está instalado."
fi

# Actualiza la lista de paquetes e instala dependencias necesarias para compilar Python
echo "Actualizando lista de paquetes e instalando dependencias..."
sudo apt-get update -y
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git

# Instala pyenv
echo "Instalando pyenv..."
curl -fsSL https://pyenv.run | bash

# Configura el entorno para pyenv y pyenv-virtualenv
echo "Configurando pyenv en el archivo .bashrc..."
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# Verifica si la configuración de pyenv ya existe en el archivo .bashrc
if grep -q "pyenv" ~/.bashrc; then
    echo "La configuración de pyenv ya existe en el archivo .bashrc."
else
    echo "Añadiendo configuración de pyenv al archivo .bashrc..."
    echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
fi

# Recarga el entorno
source ~/.bashrc

# Instala pyenv-virtualenv como un plugin de pyenv
echo "Instalando pyenv-virtualenv..."
git clone https://github.com/pyenv/pyenv-virtualenv.git "$(pyenv root)/plugins/pyenv-virtualenv"

# Verifica la instalación de pyenv y pyenv-virtualenv
if command -v pyenv &> /dev/null && [ -d "$(pyenv root)/plugins/pyenv-virtualenv" ]; then
    echo "pyenv y pyenv-virtualenv han sido instalados correctamente."
else
    echo "Hubo un problema instalando pyenv o pyenv-virtualenv. Por favor, verifica manualmente."
    exit 1
fi

# Identificar la versión LTS de Python (última versión LTS en el momento de escribir este script)
LTS_VERSION="3.10.12"

# Verifica si la versión LTS está instalada
if pyenv versions --bare | grep -q "$LTS_VERSION"; then
    echo "La versión LTS de Python $LTS_VERSION ya está instalada."
else
    echo "Instalando la versión LTS de Python $LTS_VERSION..."
    pyenv install $LTS_VERSION
fi

# Establecer la versión LTS como la versión global de Python
pyenv global $LTS_VERSION
echo "La versión LTS de Python $LTS_VERSION ha sido configurada como la versión global."

# Mostrar instrucciones adicionales
figlol "Instalación Completa"
echo "Para verificar la versión actual de Python en uso, ejecuta: python --version"
echo "Para cambiar la versión global de Python, usa: pyenv global <version>"
echo "Para listar las versiones de Python instaladas, usa: pyenv versions"