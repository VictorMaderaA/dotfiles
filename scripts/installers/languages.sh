#!/bin/bash
# scripts/installers/languages.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/logging.sh"

install_nvm() {
    log_section "Instalando nvm (Node Version Manager)"

    local NVM_DIR="$HOME/.nvm"
    local NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"

    if [[ -d "$NVM_DIR" ]]; then
        log_info "nvm ya está instalado"
        return 0
    fi

    log_info "Descargando e instalando la última versión de nvm..."
    if curl -o- "$NVM_INSTALL_URL" | bash; then
        log_success "nvm instalado correctamente"
    else
        log_error "Error instalando nvm"
        return 1
    fi
}

install_pyenv() {
    log_section "Instalando pyenv (Python Version Manager)"

    local PYENV_ROOT="$HOME/.pyenv"
    local PYENV_INSTALL_URL="https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer"

    if [[ -d "$PYENV_ROOT" ]]; then
        log_info "pyenv ya está instalado"
        return 0
    fi

    log_info "Descargando e instalando pyenv..."
    if curl -L "$PYENV_INSTALL_URL" | bash; then
        log_success "pyenv instalado correctamente"
    else
        log_error "Error instalando pyenv"
        return 1
    fi
}
