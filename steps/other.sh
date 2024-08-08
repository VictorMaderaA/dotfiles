#!/bin/bash

function figlol() {
  figlet "$1" | lolcat
}

function executeOther() {
  local step_name=$1
  local script_path="./other/${step_name}.sh"

  if [ -f "$script_path" ]; then
    source ~/.bashrc
    echo "Running ${step_name}.sh..."
    figlol "$step_name"
    # Execute the script and show the output
    (./other/${step_name}.sh || showError "Error en ${step_name}.sh")
    source ~/.bashrc
  else
    figlol "Error"
    echo "The script ${script_path}.sh does not exist."
    exit 1
  fi
}

executeOther "openvpn3"
executeOther "whisper"
executeOther "wrk"
executeOther "wine"
executeOther "tor"
