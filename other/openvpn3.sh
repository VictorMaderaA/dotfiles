#!/bin/bash

# Añade el repositorio de OpenVPN 3
echo "Añadiendo el repositorio de OpenVPN 3 Linux..."
wget -qO - https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://build.openvpn.net/debian/openvpn3/repos focal main" | sudo tee /etc/apt/sources.list.d/openvpn3.list

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
