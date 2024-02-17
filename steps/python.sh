#!/bin/bash

# Actualiza la lista de paquetes e instala dependencias necesarias para compilar Python
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git

# Instala pyenv
curl https://pyenv.run | bash

# Configura el entorno para pyenv y pyenv-virtualenv
echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc

# Reinicia la shell
exec "$SHELL"

# Instala pyenv-virtualenv como un plugin de pyenv
git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv

# Reinicia la shell nuevamente para aplicar los cambios
exec "$SHELL"

# Instala una versión específica de Python usando pyenv
pyenv install 3.10.0

# Crea un entorno virtual para la versión instalada
# pyenv virtualenv 3.10 my-virtual-env-3.8.10

# Activar el entorno virtual
# Nota: Para activar el entorno virtual, deberás ejecutar este comando manualmente después de la instalación,
# ya que este script no puede cambiar el entorno de la shell actual.
# echo "Para activar el entorno virtual, ejecuta: pyenv activate my-virtual-env-3.8.10"

# Nota sobre la desactivación del entorno virtual
# echo "Para desactivar el entorno virtual, usa: pyenv deactivate"
