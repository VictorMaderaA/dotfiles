#!/bin/bash

# Actualiza la lista de paquetes e instala los paquetes necesarios
echo "Actualizando la lista de paquetes e instalando ca-certificates, curl y gnupg..."
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg -y

# Elimina paquetes relacionados con Docker que podrían estar instalados
echo "Eliminando paquetes existentes relacionados con Docker..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg
done

# Configura el repositorio de Docker
echo "Configurando el repositorio de Docker..."

# Añade la clave GPG de Docker
echo "Añadiendo la clave GPG de Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Añade el repositorio de Docker a las fuentes de Apt
echo "Añadiendo el repositorio de Docker a las fuentes de Apt..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualiza la lista de paquetes para incluir el repositorio de Docker
sudo apt-get update -y

# Instala el motor de Docker
echo "Instalando Docker Engine..."
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Configura el grupo docker
echo "Configurando el grupo docker..."
if getent group docker > /dev/null 2>&1; then
  echo "El grupo docker ya existe."
else
  echo "Creando el grupo docker..."
  sudo groupadd docker
fi

# Añade el usuario actual al grupo docker
echo "Añadiendo el usuario $USER al grupo docker..."
sudo usermod -aG docker $USER

# Mensaje final
echo "La instalación de Docker se ha completado."

# Aplicar cambios en la sesión actual
if [ "$(id -gn)" != "docker" ]; then
  echo "Aplicando cambios del grupo en la sesión actual..."
  exec sg docker newgrp $(id -gn) "$SHELL"
else
  echo "El usuario ya pertenece al grupo docker."
fi

echo "Docker está instalado y el usuario está en el grupo docker."