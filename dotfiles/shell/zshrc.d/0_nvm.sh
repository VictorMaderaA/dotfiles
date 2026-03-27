# NVM configuration (Lazy load)
export NVM_DIR="$HOME/.nvm"

_load_nvm() {
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# Lazy load NVM
nvm()      { unset -f nvm;      _load_nvm; nvm      "$@"; }
node()     { unset -f node;     _load_nvm; node     "$@"; }
npm()      { unset -f npm;      _load_nvm; npm      "$@"; }
npx()      { unset -f npx;      _load_nvm; npx      "$@"; }
yarn()     { unset -f yarn;     _load_nvm; yarn     "$@"; }
pnpm()     { unset -f pnpm;     _load_nvm; pnpm     "$@"; }
corepack() { unset -f corepack; _load_nvm; corepack "$@"; }

# Cambia automáticamente la versión de Node con nvm al entrar en un proyecto.
nvm_use_project_node() {
  # No disparar si estamos en $HOME directamente
  [[ "$PWD" == "$HOME" ]] && return

  local node_version=""

  if [[ -f ".nvmrc" ]]; then
    node_version="$(< .nvmrc)"
  elif [[ -f "package.json" ]] && command -v node >/dev/null 2>&1; then
    # Solo intentamos leer package.json si node ya está cargado para evitar disparar lazy load innecesariamente
    node_version="$(node -e 'const pkg=require("./package.json"); process.stdout.write((pkg.engines && pkg.engines.node) || "")' 2>/dev/null)"
  fi

  if [[ -n "$node_version" ]]; then
     # Si necesitamos nvm, aseguramos que esté cargado
     if ! command -v nvm >/dev/null 2>&1; then
       _load_nvm
     fi
     nvm use "$node_version" >/dev/null 2>&1
  fi
}

# Ejecutar al entrar en un directorio (Zsh hook)
autoload -U add-zsh-hook
add-zsh-hook chpwd nvm_use_project_node

# Ejecutar una vez al inicio
nvm_use_project_node