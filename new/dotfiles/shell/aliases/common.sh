#Navigation and listing:
alias ll='ls -alF' # (Long detailed listing with file type indicators)
alias la='ls -A' # (List all except . and ..)
alias l='ls -CF' # (Classify and columnate list)
alias ..='cd ..' # (Go up one directory)
alias ...='cd ../..' # (Go up two directories)


#Command shortcuts:
alias c='clear' # (Clear the terminal)
alias r='source ~/.zshrc' # (Reload Zsh config)
alias h='history 10' # (Show last 10 commands)
alias hg='history | grep' # (Search command history)


#Git helpers:
alias gs='git status'
alias gf='git fetch'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'


#Package management (apt example):
alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias remove='sudo apt purge'
alias clean='sudo apt autoremove'


#npm/yarn shortcuts (if using Node.js):
alias ni='npm install'
alias nis='npm install --save'
alias nrb='npm run build'
alias nrs='npm run start'


#Global aliases for easier piping (Zsh-specific):
alias -g G='| grep' # (For quick grep in commands)
alias -g L='| less'
alias -g H='| head'

aws-switch() {
  # aws configure --profile nombre-del-perfil

    if [[ -z "$1" ]]; then
        echo "No se especificó un perfil. Perfiles disponibles:"
        aws configure list-profiles
        return 1
    fi

    export AWS_PROFILE="$1"
    echo "Perfil AWS cambiado a: $AWS_PROFILE"
}

