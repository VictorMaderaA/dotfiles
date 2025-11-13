# scripts/installers/development.sh
#!/bin/bash
source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../lib/package_manager.sh"

log_section "Instalando herramientas de desarrollo"
detect_package_manager

dev_packages=(
    git git-flow neovim python3 python3-pip nodejs npm
)

for pkg in "${dev_packages[@]}"; do
    pkg_install_if_needed "$pkg"
done

log_success "Dev tools instalados"