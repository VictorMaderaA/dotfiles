# Pyenv configuration (Lazy load)
export PYENV_ROOT="$HOME/.pyenv"
# El PATH se gestiona en 0_paths.sh

_load_pyenv() {
  eval "$(pyenv init - zsh)"
  # virtualenv-init solo si existe el plugin
  if pyenv commands 2>/dev/null | grep -q virtualenv-init; then
    eval "$(pyenv virtualenv-init - zsh)"
  fi
}

pyenv() {
  unset -f pyenv
  _load_pyenv
  pyenv "$@"
}

python() {
  unset -f python
  _load_pyenv
  python "$@"
}

python3() {
  unset -f python3
  _load_pyenv
  python3 "$@"
}

pip() {
  unset -f pip
  _load_pyenv
  pip "$@"
}

pip3() {
  unset -f pip3
  _load_pyenv
  pip3 "$@"
}
