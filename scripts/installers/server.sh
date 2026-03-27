#!/bin/bash
# scripts/installers/server.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/package_manager.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/detect_environment.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/utils.sh"

df_install_server() {
    log_section "Instalando herramientas de servidor"

    if ! is_server; then
        log_warn "Server no detectado - saltando herramientas de servidor"
        return 0
    fi

    # Obtener paquetes directamente como array
    local packages=($(get_packages "SERVER_PACKAGES"))

    for pkg in "${packages[@]}"; do
        pkg_install_if_needed "$pkg"
    done

    log_success "Herramientas de servidor instaladas"
}
