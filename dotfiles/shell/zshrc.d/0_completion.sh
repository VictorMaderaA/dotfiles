# Bash completion configuration (para Zsh)
# Solo cargar si compinit está disponible
if (( $+functions[compinit] )); then
  if [[ -f /usr/share/zsh/completion/_bash_completion ]]; then
    source /usr/share/zsh/completion/_bash_completion
  elif [[ -f /etc/zsh_completion ]]; then
    source /etc/zsh_completion
  fi
else
  # Si compinit no se ha cargado aún, lo cargamos aquí para que funcionen las terminaciones básicas
  autoload -Uz compinit && compinit
  if [[ -f /usr/share/zsh/completion/_bash_completion ]]; then
    source /usr/share/zsh/completion/_bash_completion
  fi
fi
