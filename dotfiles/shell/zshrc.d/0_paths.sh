# Consolidar todos los cambios al PATH aquí con guardias para evitar duplicados.

# Añadir .local/bin (común para pipx, aws-cli local, etc.)
if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$PATH:$HOME/.local/bin"
fi

# Pyenv bin si existe
if [[ -d "$HOME/.pyenv/bin" && ":$PATH:" != *":$HOME/.pyenv/bin:"* ]]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
fi
