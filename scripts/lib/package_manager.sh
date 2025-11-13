#!/bin/bash

# scripts/lib/package_manager.sh
# Abstracción para diferentes package managers

# Detectar package manager disponible
detect_package_manager() {
    if command -v apt &> /dev/null; then
        export PKG_MANAGER="apt"
        export PKG_UPDATE_CMD="sudo apt update"
        export PKG_INSTALL_CMD="sudo apt install -y"
        export PKG_SEARCH_CMD="apt search"
        export PKG_REMOVE_CMD="sudo apt remove -y"
    elif command -v pacman &> /dev/null; then
        export PKG_MANAGER="pacman"
        export PKG_UPDATE_CMD="sudo pacman -Sy"
        export PKG_INSTALL_CMD="sudo pacman -S --noconfirm"
        export PKG_SEARCH_CMD="pacman -Ss"
        export PKG_REMOVE_CMD="sudo pacman -R --noconfirm"
    elif command -v yum &> /dev/null; then
        export PKG_MANAGER="yum"
        export PKG_UPDATE_CMD="sudo yum check-update"
        export PKG_INSTALL_CMD="sudo yum install -y"
        export PKG_SEARCH_CMD="yum search"
        export PKG_REMOVE_CMD="sudo yum remove -y"
    else
        log_error "No se encontró package manager soportado"
        return 1
    fi
    
    log_debug "Package manager detectado: $PKG_MANAGER"
    return 0
}

# Instalar paquete(s)
pkg_install() {
    local packages=("$@")
    
    log_debug "Instalando: ${packages[*]}"
    eval "$PKG_INSTALL_CMD ${packages[*]}"
}

# Buscar paquete
pkg_search() {
    local package=$1
    eval "$PKG_SEARCH_CMD $package"
}

# Remover paquete(s)
pkg_remove() {
    local packages=("$@")
    eval "$PKG_REMOVE_CMD ${packages[*]}"
}

# Actualizar cache de paquetes
pkg_update() {
    log_info "Actualizando cache de paquetes..."
    eval "$PKG_UPDATE_CMD"
}

# Verificar si paquete está instalado
pkg_is_installed() {
    local package=$1
    
    case "$PKG_MANAGER" in
        apt)
            dpkg -l | grep -q "^ii  $package" && return 0 || return 1
            ;;
        pacman)
            pacman -Q "$package" &> /dev/null && return 0 || return 1
            ;;
        yum)
            yum list installed "$package" &> /dev/null && return 0 || return 1
            ;;
    esac
    
    return 1
}

# Instalar si no existe
pkg_install_if_needed() {
    local package=$1
    
    if pkg_is_installed "$package"; then
        log_debug "Paquete ya instalado: $package"
        return 0
    fi

    log_info "Instalando: $package"
    pkg_install "$package"
}

# Exportar funciones
export -f detect_package_manager
export -f pkg_install
export -f pkg_search
export -f pkg_remove
export -f pkg_update
export -f pkg_is_installed
export -f pkg_install_if_needed
