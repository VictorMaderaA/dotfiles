# NVM configuration (Lazy load)
export NVM_DIR="$HOME/.nvm"

_load_nvm() {
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

# Lazy load NVM
nvm()      { unset -f nvm;      _load_nvm; nvm      "$@"; }
node()     { unset -f node;     _load_nvm; node     "$@"; }
npm()      { unset -f npm;      _load_nvm; npm      "$@"; }
npx()      { unset -f npx;      _load_nvm; npx      "$@"; }
yarn()     { unset -f yarn;     _load_nvm; yarn     "$@"; }
pnpm()     { unset -f pnpm;     _load_nvm; pnpm     "$@"; }
corepack() { unset -f corepack; _load_nvm; corepack "$@"; }

nvm_use_project_node() {
  [[ "$PWD" == "$HOME" ]] && return

  local node_version=""
  local use_auto=false

  if [[ -f ".nvmrc" || -f ".node-version" ]]; then
    # nvm resuelve estos archivos de forma nativa
    use_auto=true

  elif [[ -f "package.json" ]]; then
    # Parsear engines.node con awk (sin node, sin python, sin jq)
    local raw
    raw=$(awk -F'"' '
      /"engines"/ { in_engines=1 }
      in_engines && /"node"/ { print $4; exit }
      /}/ && in_engines { in_engines=0 }
    ' package.json 2>/dev/null)

    # Extraer el número de versión mayor (maneja >=18, ^22, ~20, 22.x, 22.0.0, etc.)
    if [[ -n "$raw" ]]; then
      node_version=$(echo "$raw" | grep -oE '[0-9]+' | head -1)
    fi
  fi

  [[ -z "$node_version" && "$use_auto" == false ]] && return

  # Cargar nvm si aún es el wrapper (función, no binario)
  if (( $+functions[nvm] )); then
    _load_nvm
    unset -f node npm npx yarn pnpm corepack 2>/dev/null
  fi

  if [[ "$use_auto" == true ]]; then
    nvm use --silent 2>/dev/null
  else
    nvm use "$node_version" --silent 2>/dev/null
  fi
}

# Hook con guardia anti-duplicación
if (( ${chpwd_functions[(Ie)nvm_use_project_node]:-0} == 0 )); then
  autoload -U add-zsh-hook
  add-zsh-hook chpwd nvm_use_project_node
fi

nvm_use_project_node
