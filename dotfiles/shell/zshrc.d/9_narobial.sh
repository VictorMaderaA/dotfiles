# === narobial initialization ===
_NAROBIAL_INITIALIZED=false

# Detectar si estamos en ~/narobial o subdirectorios
_init_narobial() {
    local narobial_path="$HOME/narobial"
    local current_pwd="$PWD"
    local in_narobial=false

    if [[ "$current_pwd" == "$narobial_path" ]] || [[ "$current_pwd" == "$narobial_path"/* ]]; then
        in_narobial=true
    fi

    if [[ "$in_narobial" == true ]] && [[ "$_NAROBIAL_INITIALIZED" == false ]]; then
        if command -v aws-switch &> /dev/null; then
            aws-switch narobial
        fi

        # El nvm use ya lo gestiona 0_nvm.sh vía el hook chpwd
        # que se ejecutará también al entrar aquí.

        echo "🚀 Entorno narobial iniciado"
        _NAROBIAL_INITIALIZED=true
    elif [[ "$in_narobial" == false ]] && [[ "$_NAROBIAL_INITIALIZED" == true ]]; then
        # Reset de perfil AWS al salir si existe aws-switch
        if command -v aws-switch &>/dev/null; then
            aws-switch default
        fi
        _NAROBIAL_INITIALIZED=false
    fi
}

# Usar hook de Zsh para detectar cambios de directorio (con guardia anti-duplicación)
if (( ! ${chpwd_functions[(Ie)_init_narobial]} )); then
  autoload -U add-zsh-hook
  add-zsh-hook chpwd _init_narobial
fi

# Ejecutar al iniciar la terminal
_init_narobial