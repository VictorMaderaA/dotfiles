#!/bin/bash

# https://openvpn.net/cloud-docs/owner/connectors/connector-user-guides/openvpn-3-client-for-linux.html

# Añade el repositorio de OpenVPN 3
echo "Añadiendo el repositorio de OpenVPN 3 Linux..."
sudo mkdir -p /etc/apt/keyrings && curl -fsSL https://packages.openvpn.net/packages-repo.gpg | sudo tee /etc/apt/keyrings/openvpn.asc
DISTRO=$(lsb_release -c | awk '{print $2}')
echo "deb [signed-by=/etc/apt/keyrings/openvpn.asc] https://packages.openvpn.net/openvpn3/debian $DISTRO main" | sudo tee /etc/apt/sources.list.d/openvpn-packages.list

# Actualiza los paquetes e instala OpenVPN 3
echo "Actualizando paquetes e instalando OpenVPN 3 Linux..."
sudo apt-get update -y 
sudo apt-get install -y openvpn3

# Verifica si OpenVPN 3 está instalado
if command -v openvpn3 &> /dev/null
then
    echo "OpenVPN 3 ha sido instalado correctamente."
else
    echo "Hubo un problema instalando OpenVPN 3."
    exit 1
fi

echo "Instalación completada."

# Instrucciones de uso comentadas
: '
Para iniciar una conexión VPN con OpenVPN 3, sigue estos pasos:

1. Importa tu archivo de configuración (archivo .ovpn):
   openvpn3 config-import --config /ruta/a/tu/archivo.ovpn

2. Inicia la conexión VPN:
   openvpn3 session-start --config /ruta/a/tu/archivo.ovpn

Para verificar el estado de la sesión VPN:
   openvpn3 sessions-list

Para desconectar la VPN:
   openvpn3 session-manage --session-path /net/openvpn/v3/sessions/{tu-session-path} --disconnect

Reemplaza "/ruta/a/tu/archivo.ovpn" con la ruta real a tu archivo de configuración de OpenVPN.
'
