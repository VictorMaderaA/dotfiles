#!/bin/bash

# Instala herramientas de compilación y Git si no están presentes
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null || ! command -v git &> /dev/null; then
    echo "Herramientas de compilación o Git no encontrados. Instalando..."
    sudo apt update
    sudo apt install build-essential git -y
else
    echo "Herramientas de compilación y Git ya están instalados."
fi

# Directorio temporal para la compilación
TEMP_DIR="/tmp/wrk"
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi
mkdir "$TEMP_DIR"

# Clona el repositorio de wrk
echo "Clonando el repositorio de wrk..."
git clone https://github.com/wg/wrk.git "$TEMP_DIR"
if [ $? -ne 0 ]; then
    echo "Error clonando el repositorio de wrk."
    exit 1
fi

# Compila wrk
echo "Compilando wrk..."
cd "$TEMP_DIR"
make
if [ $? -ne 0 ]; then
    echo "Error compilando wrk."
    exit 1
fi

# Instala wrk
echo "Instalando wrk..."
sudo cp wrk /usr/local/bin
if [ $? -eq 0 ]; then
    echo "wrk instalado correctamente."
else
    echo "Error instalando wrk."
    exit 1
fi

# Limpieza
rm -rf "$TEMP_DIR"
