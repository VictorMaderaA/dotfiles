#!/bin/bash
source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../lib/package_manager.sh"

log_section "Instalando paquetes base"
detect_package_manager
pkg_update

base_packages=(
    git curl wget build-essential
    software-properties-common ca-certificates
)

for pkg in "${base_packages[@]}"; do
    pkg_install_if_needed "$pkg"
done

log_success "Paquetes base instalados"