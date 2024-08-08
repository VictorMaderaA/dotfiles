#!/bin/bash

# Instala snapd si no está instalado
if ! command -v snap &> /dev/null; then
    echo "Instalando snapd..."
    sudo apt-get install -y snapd
else
    echo "Snapd ya está instalado."
fi

# Actualiza snap y sus paquetes
echo "Actualizando snap y sus paquetes..."
sudo snap refresh --list
sudo snap refresh

# Función para instalar paquetes usando snap
function install {
  # Verifica si el paquete está instalado
  if ! snap list | grep -q "^$1 "; then
    echo "Instalando: ${1}..."
    if [ -n "$2" ]; then
      sudo snap install $1 $2
    else
      sudo snap install $1
    fi
  else
    echo "Ya está instalado: ${1}"
  fi
}

# IDEs
install webstorm --classic
install phpstorm --classic
install datagrip --classic
install pycharm-professional --classic

# Entretenimiento
install spotify
install vlc
install obs-studio
install plexmediaserver
install snap-store

# Desarrollo
install insomnia
install postman
install ngrok
install notepad-plus-plus

# Utilidades
install libreoffice
install bw # bitwarden cli
install doctl # digital ocean cli
install notion-snap-reborn
install notion-calendar-snap
install bitwarden
install audacity
install gnome-system-monitor

# Comunicación
install slack --classic
install discord
install telegram-desktop

# Navegadores
install chromium
install firefox
install brave

# Juegos
install steam

echo "Proceso de instalación completado."
