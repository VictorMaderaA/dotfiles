# Configuration for Zsh
export ZSH_CUSTOM="$HOME/.config/zsh"

# Source common aliases
[[ -f ~/.shell_aliases ]] && source ~/.shell_aliases

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

# ============================================================================
# Load aliases from ~/.aliases/*.sh directory
# ============================================================================

if [[ -d ~/.aliases ]]; then
    for alias_file in ~/.aliases/*.sh; do
        if [[ -f "$alias_file" ]]; then
            source "$alias_file"
        fi
    done
    unset alias_file
fi
