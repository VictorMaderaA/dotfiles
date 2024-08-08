#!/bin/bash

# Función para instalar paquetes
install() {
  package=$1
  # Verifica si el paquete está instalado
  if ! which $package &> /dev/null; then
    echo "Instalando: ${package}..."
    # Intenta instalar el paquete
    if sudo apt install -y $package > /dev/null; then
      echo "Instalación completada: ${package}"
      figlet "__________"
    else
      echo "Error al instalar: ${package}"
    fi
  else
    echo "Ya está instalado: ${package}"
  fi
}

# Lista de paquetes a instalar
packages=(
  git          # control de versiones
  curl         # transferencia de datos de o a un servidor
  htop         # monitor del sistema
  tmux         # multiplexor de terminal
  nmap         # escáner de red
  vim          # editor de texto
  neovim       # editor de texto
  tree         # listar contenidos del directorio
  file         # identificación del tipo de archivo
  gimp         # editor de imágenes
  jpegoptim    # optimización de imágenes
  optipng      # optimización de imágenes
  chromium-browser # navegador web
  awscli       # CLI de servicios web de amazon
  neofetch     # muestra información del sistema
)

echo "Iniciando la instalación de paquetes..."

# Instalación de todos los paquetes
for package in "${packages[@]}"; do
  install $package
done

echo "Instalación de todos los paquetes completada."
