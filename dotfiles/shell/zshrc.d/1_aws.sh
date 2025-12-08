export PATH="$PATH:$HOME/.local/bin/git-remote-codecommit"

# Enable AWS CLI autocompletion
autoload -Uz compinit && compinit
autoload -Uz bashcompinit && bashcompinit
complete -C '/usr/local/bin/aws_completer' aws
