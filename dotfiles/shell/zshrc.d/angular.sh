# Angular completion (Lazy load with cache)
_load_angular_completion() {
  local cache="$HOME/.zsh/cache/ng_completion.zsh"
  local ng_bin=""

  # Priorizar ng local sobre global
  if [[ -f ./node_modules/.bin/ng ]]; then
    ng_bin="./node_modules/.bin/ng"
  elif [[ -f ./web/node_modules/.bin/ng ]]; then
    ng_bin="./web/node_modules/.bin/ng"
  elif command -v ng >/dev/null 2>&1; then
    ng_bin="ng"
  fi

  if [[ -n "$ng_bin" ]]; then
    # Regenerar caché solo si ng es más nuevo que el caché o no existe
    if [[ ! -f "$cache" || "$ng_bin" -nt "$cache" ]]; then
      mkdir -p "${cache:h}"
      "$ng_bin" completion script > "$cache" 2>/dev/null
    fi
    [[ -f "$cache" ]] && source "$cache"
  fi
}

ng() {
  unset -f ng
  _load_angular_completion
  ng "$@"
}
