#!/bin/bash

# Instalar dependencias necesarias para añadir un nuevo repositorio de WineHQ
sudo apt install -y software-properties-common wget

# Habilitar la arquitectura de 32 bits
sudo dpkg --add-architecture i386

# Añadir el repositorio de WineHQ
wget -O- -nc https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main' -y

# Actualizar la lista de paquetes después de añadir el repositorio de WineHQ
sudo apt update -y

# Intentar instalar una versión de Wine disponible directamente desde los repositorios de Ubuntu
sudo apt install -y --install-recommends wine-stable wine32 wine64 libwine libwine:i386 fonts-wine

# Configuración inicial de Wine (opcional, solo si es necesario)
# winecfg

# Eliminar el fichero de la clave pública de WineHQ
rm -f winehq.key