# Keep Ubuntu up to date
sudo apt-get update -y
sudo apt-get upgrade -y

# Install or Update Common Packages
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  build-essential \
  libssl-dev \
  libffi-dev

sudo apt-get install python-dev python-pip python3-dev python3-pip -y

sudo apt-get install -y figlet lolcat