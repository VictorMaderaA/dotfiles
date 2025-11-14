## Bash completion configuration
#if ! shopt -oq posix; then
#  if [ -f /usr/share/bash-completion/bash_completion ]; then
#    . /usr/share/bash-completion/bash_completion
#  elif [ -f /etc/bash_completion ]; then
#    . /etc/bash_completion
#  fi
#fi

# Bash completion configuration (para Zsh)
if [[ -f /usr/share/zsh/completion/_bash_completion ]]; then
  . /usr/share/zsh/completion/_bash_completion
elif [[ -f /etc/zsh_completion ]]; then
  . /etc/zsh_completion
fi
