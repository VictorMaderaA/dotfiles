#!/bin/bash

# Nombre del entorno virtual para Whisper
ENV_NAME="whisper-env"

# Versión de Python para el entorno virtual
PYTHON_VERSION="3.9.7"

# Verifica si pyenv está instalado
if ! command -v pyenv &> /dev/null; then
    echo "pyenv no está instalado. Por favor, instálalo antes de ejecutar este guion."
    #Imprime un mensaje de error y termina el script
    figlet "ERROR"
    exit 1
else
    echo "pyenv encontrado."
fi

# Instala la versión de Python deseada si no está disponible
if ! pyenv versions | grep -q $PYTHON_VERSION; then
    echo "Instalando Python $PYTHON_VERSION con pyenv..."
    pyenv install $PYTHON_VERSION
else
    echo "Python $PYTHON_VERSION ya está instalado."
fi

# Crea un entorno virtual para Whisper si no existe
if ! pyenv versions | grep -q $ENV_NAME; then
    echo "Creando el entorno virtual $ENV_NAME con Python $PYTHON_VERSION..."
    pyenv virtualenv $PYTHON_VERSION $ENV_NAME
else
    echo "El entorno virtual $ENV_NAME ya existe."
fi

# Activa el entorno virtual
echo "Activando el entorno virtual $ENV_NAME..."
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
pyenv activate $ENV_NAME

# Instala Whisper
echo "Instalando Whisper..."
pip install git+https://github.com/openai/whisper.git

echo "Whisper ha sido instalado exitosamente en el entorno virtual $ENV_NAME."
