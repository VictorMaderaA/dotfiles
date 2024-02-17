# Download the latest release of neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz

# Remove the existing nvim folder
rm -rf /opt/nvim

# Extract the tar file
tar -C /opt -xzf nvim-linux64.tar.gz

# Remove the tar file
rm nvim-linux64.tar.gz