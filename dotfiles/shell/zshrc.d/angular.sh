# Angular completion (Lazy load)
_load_angular_completion() {
  # ng instalado globalmente
  if command -v ng >/dev/null 2>&1; then
    source <(ng completion script)
  fi

  # Caso instalado en proyecto
  if [ -f ./node_modules/.bin/ng ]; then
    source <(./node_modules/.bin/ng completion script)
  elif [ -f ./web/node_modules/.bin/ng ]; then
    source <(./web/node_modules/.bin/ng completion script)
  fi
}

ng() {
  unset -f ng
  _load_angular_completion
  ng "$@"
}
