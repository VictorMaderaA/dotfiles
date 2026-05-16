# Configuration for Zsh
export ZSH_CUSTOM="$HOME/.config/zsh"

# Load shared terminal defaults before other shell-specific setup so locale and
# TERM behavior stays consistent across machines, SSH sessions and tmux.
if [[ -f ~/.terminal-env ]]; then
    source ~/.terminal-env
fi

# Source common aliases
[[ -f ~/.shell_aliases ]] && source ~/.shell_aliases

# ============================================================================
# Load local environment variables (~/.env.local)
# This file is ignored by git and can contain sensitive information
# ============================================================================

if [[ -f ~/.env.local ]]; then
    source ~/.env.local
fi

# Source starship prompt
eval "$(starship init zsh)"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Keybindings (vim-like)
# bindkey -v

# ============================================================================
# Load aliases from ~/.aliases/*.sh directory
# ============================================================================

ALIASES_DIR="$HOME/.aliases"

if [[ -d "$ALIASES_DIR" ]]; then
    for config_file in "$ALIASES_DIR"/*.sh; do
        if [[ -f "$config_file" ]]; then
            source "$config_file"
        fi
    done
    unset config_file
fi

unset ALIASES_DIR

# ============================================================================
# Load custom configurations from ~/.bashrc.d/
# ============================================================================

BASHRC_D_DIR="$HOME/.zshrc.d"

if [[ -d "$BASHRC_D_DIR" ]]; then
    for config_file in "$BASHRC_D_DIR"/*.sh; do
        if [[ -f "$config_file" ]]; then
            source "$config_file"
        fi
    done
    unset config_file
fi

unset BASHRC_D_DIR


# Mostrar neofetch solo si la terminal se abre en home
if [[ "$PWD" == "$HOME" ]]; then
    neofetch
fi
