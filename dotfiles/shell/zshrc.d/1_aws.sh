export PATH="$PATH:$HOME/.local/bin/git-remote-codecommit"

# Enable AWS CLI autocompletion (Lazy load)
_load_aws_completion() {
  # Solo cargar bashcompinit si no está ya cargado
  if [[ -z "$(builtin functions bashcompinit)" ]]; then
    autoload -Uz bashcompinit && bashcompinit
  fi
  complete -C '/usr/local/bin/aws_completer' aws
}

# Wrapper para cargar completado en el primer uso de aws
aws() {
  unset -f aws
  _load_aws_completion
  aws "$@"
}
