#!/bin/bash

# === narobial initialization ===
_NAROBIAL_INITIALIZED=false

# Script para detectar si estamos en ~/narobial y ejecutar acciones específicas
# Agregarlo a ~/.bashrc o ~/.zshrc

# Detectar si estamos en ~/narobial o subdirectorios
_init_narobial() {
    local narobial_path="$HOME/narobial"
    local current_pwd="$PWD"
    local in_narobial=false

    if [[ "$current_pwd" == "$narobial_path" ]] || [[ "$current_pwd" == "$narobial_path"/* ]]; then
        in_narobial=true
    fi

    if [[ "$in_narobial" == true ]] && [[ "$_NAROBIAL_INITIALIZED" == false ]]; then
        aws-switch narobial
        echo "🚀 Entorno narobial iniciado"
        echo "   SSH Agent: $(ssh-add -l | wc -l) claves cargadas"
        echo ""
        _NAROBIAL_INITIALIZED=true
    elif [[ "$in_narobial" == false ]] && [[ "$_NAROBIAL_INITIALIZED" == true ]]; then
        _NAROBIAL_INITIALIZED=false
    fi
}

# Ejecutar al iniciar la terminal
_init_narobial

# También ejecutar cada vez que cambies de directorio
# Agregar esto al final de tu .bashrc o .zshrc
cd() {
    builtin cd "$@"
    _init_narobial
}