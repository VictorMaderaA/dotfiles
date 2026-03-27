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

        # Verificar si existe .nvmrc y nvm está disponible
        if [[ -f "$narobial_path/.nvmrc" ]]; then
            # nvm se cargará bajo demanda por 0_nvm.sh
            if command -v nvm &> /dev/null; then
               nvm use
            fi
        fi

        echo "🚀 Entorno narobial iniciado"
        _NAROBIAL_INITIALIZED=true
    elif [[ "$in_narobial" == false ]] && [[ "$_NAROBIAL_INITIALIZED" == true ]]; then
        _NAROBIAL_INITIALIZED=false
    fi
}

# Usar hook de Zsh para detectar cambios de directorio
autoload -U add-zsh-hook
add-zsh-hook chpwd _init_narobial

# Ejecutar al iniciar la terminal
_init_narobial