#!/bin/bash
# scripts/installers/development.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/package_manager.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/utils.sh"

df_install_dev() {
    log_section "Instalando herramientas de desarrollo"

    # Obtener paquetes directamente como array
    local packages=($(get_packages "DEV_PACKAGES"))

    for pkg in "${packages[@]}"; do
        pkg_install_if_needed "$pkg"
    done

    install_bitwarden_cli
    install_nvm
    install_pyenv
    install_aws_cli
    df_install_pipx

    log_success "Herramientas de desarrollo instaladas"
}

df_install_pipx() {
  # Instala git-remote-codecommit
  pipx install git-remote-codecommit
}
