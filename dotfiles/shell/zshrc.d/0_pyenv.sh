# Pyenv configuration (Lazy load)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

_load_pyenv() {
  eval "$(pyenv init - zsh)"
  # También cargar virtualenv si está disponible
  if pyenv help virtualenv-init >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
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
