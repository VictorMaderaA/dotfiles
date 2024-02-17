#!/bin/bash

# sudo chmod 600 .ssh/id_ed25519
# ssh-add

./symlink.sh
./aptinstall.sh
./snapinstall.sh
./programs.sh
./desktop.sh

# Get all upgrades
sudo apt upgrade -y

# See our bash changes
source ~/.bashrc

echo CONFIGURADOR FNMT-RCM https://www.sede.fnmt.gob.es/descargas/descarga-software/instalacion-software-generacion-de-claves
echo AUTOFIRMA https://firmaelectronica.gob.es/Home/Descargas.html
echo Distribuciones Linux https://www.dnielectronico.es/PortalDNIe/PRF1_Cons02.action?pag=REF_1112

# Fun hello
figlet "... and we're back!" | lolcat