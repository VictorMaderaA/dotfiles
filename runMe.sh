#!/bin/bash

# Ask for the administrator password upfront
sudo -v

# Set appropriate permissions for the repository files
echo "Setting permissions for the repository files..."

# Define the directories
directories=("dotfiles" "other" "scripts" "steps")

# Set executable permissions for all .sh files in the 'scripts' and 'steps' directories
for dir in "${directories[@]}"; do
  if [ -d "$dir" ]; then
    echo "Setting permissions for directory: $dir"
    # Set permissions for directories
    find "$dir" -type d -exec chmod 755 {} \;
    # Set permissions for files
    find "$dir" -type f -exec chmod 644 {} \;
    # Set executable permissions for .sh files
    find "$dir" -type f -name "*.sh" -exec chmod +x {} \;
  else
    echo "Directory $dir does not exist."
  fi
done

# Set permissions for the main script
chmod +x ./runMe.sh

# Verify that the 'steps' directory exists
if [ ! -d "./steps" ]; then
  echo "Error: The 'steps' directory does not exist."
  exit 1
fi

# Function to print styled messages
function figlol() {
  figlet "//////////"
  figlet "$1" | lolcat
}

# Show error message and wait for enter to continue
function showError() {
  figlol "Error"
  echo "Error: $1"
  echo "$1"
  read -p "Press Enter to continue..."
}

# Function to execute a step script
function executeStep() {
  local step_name=$1
  local script_path="./steps/${step_name}.sh"

  if [ -f "$script_path" ]; then
    source ~/.bashrc
    echo "Running ${step_name}.sh..."
    figlol "$step_name"
    # Execute the script and show the output
    (./steps/${step_name}.sh || showError "Error en ${step_name}.sh")
    source ~/.bashrc
  else
    figlol "Error"
    echo "The script ${script_path}.sh does not exist."
    exit 1
  fi
}

# Execute the startup script
(./steps/startup.sh || echo "Error en startup.sh")

figlol "Startup Complete"

# Execute each step
for step in symLink aptInstall node python docker snap vsc flatpak other; do
  executeStep $step
done

figlol "Cleaning up"
sudo apt-get autoremove -y
sudo apt-get autoclean -y

figlol "Setup Complete"
