#!/bin/bash

sudo apt-get update -y > /dev/null
sudo apt-get install ca-certificates curl gnupg -y > /dev/null

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

# https://docs.docker.com/engine/install/ubuntu/

# 1 Set up Docker's Apt repository
# Add Docker's official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

# 2 Install Docker Engine
echo "-- Install Docker Engine --"
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# https://docs.docker.com/engine/install/linux-postinstall/
# 3 Create the docker group if it does not exist
if [ $(getent group docker) ]; then
  echo "-- Group docker exists --"
else
  echo "-- Group docker does not exist --"
  sudo groupadd docker
fi

# 3 Add default user to docker group
echo "-- Adding user to docker group -- $USER"
sudo usermod -aG docker $USER

figlet "Docker Installed" | lolcat
