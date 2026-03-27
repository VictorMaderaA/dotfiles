#!/bin/bash
# scripts/installers/base.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/package_manager.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/utils.sh"

df_install_base() {
    log_section "Instalando paquetes base"

    # Obtener paquetes directamente como array
    local packages=($(get_packages "BASE_PACKAGES"))

    for pkg in "${packages[@]}"; do
        pkg_install_if_needed "$pkg"
    done

    install_tailscale

    log_success "Paquetes base instalados"
}
