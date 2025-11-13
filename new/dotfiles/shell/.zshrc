# Configuration for Zsh
export ZSH_CUSTOM="$HOME/.config/zsh"

# Source common aliases
[[ -f ~/.shell_aliases ]] && source ~/.shell_aliases
[[ -f ~/.aliases/common.sh ]] && source ~/.aliases/common.sh

# Source starship prompt
eval "$(starship init zsh)"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Keybindings (vim-like)
bindkey -v

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
