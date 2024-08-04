#!/bin/bash

function figlol() {
  figlet "$1" | lolcat
}

cd ./other

figlol "OpenVPN"
./openvpn3.sh

figlol "Whissper"
./whisper.sh

figlol "wrk"
./wrk.sh

figlol "Wine"
./wine.sh

figlol "Tor"
./tor.sh
