#!/bin/bash

function figlol() {
  figlet "$1" | lolcat
}

cd ./other

figlol "Installing OpenVPN"
./openvpn3.sh

figlol "Installing Whissper"
./whissper.sh

figlol "Installing wrk"
./wrk.sh
