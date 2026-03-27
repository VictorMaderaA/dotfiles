#!/bin/bash
# scripts/installers/desktop.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/package_manager.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/detect_environment.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/utils.sh"

df_install_desktop() {
    log_section "Instalando aplicaciones de escritorio"

    if ! is_desktop; then
        log_warn "Desktop no detectado - saltando aplicaciones GUI"
        return 0
    fi

    # Obtener paquetes directamente como array
    local packages=($(get_packages "DESKTOP_PACKAGES"))

    for pkg in "${packages[@]}"; do
        pkg_install_if_needed "$pkg"
    done

    configure_keyboard_shortcuts

    log_success "Aplicaciones de escritorio instaladas"
}

df_install_jetbrains() {
    log_section "Instalando JetBrains Toolbox"

    if ! is_desktop; then
        log_warn "Desktop no detectado - saltando JetBrains Toolbox"
        return 0
    fi

    local INSTALL_DIR="$HOME/.local/share/JetBrains/Toolbox"
    local SYMLINK_DIR="$HOME/.local/bin"
    local TOOLBOX_BIN="$INSTALL_DIR/bin/jetbrains-toolbox"
    local TOOLBOX_SYMLINK="$SYMLINK_DIR/jetbrains-toolbox"

    # Verificar si ya está instalado correctamente
    if [[ -f "$TOOLBOX_BIN" && -x "$TOOLBOX_BIN" ]] && [[ -L "$TOOLBOX_SYMLINK" ]]; then
        log_info "JetBrains Toolbox ya está instalado"
        return 0
    fi

    # Instalar dependencias
    local deps=("libfuse2" "libxi6" "libxrender1" "libxtst6" "mesa-utils" "libfontconfig" "libgtk-3-bin")
    for dep in "${deps[@]}"; do
        pkg_install_if_needed "$dep"
    done

    log_info "Instalando JetBrains Toolbox..."

    export CI=1

    if curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash; then
        log_success "JetBrains Toolbox instalado correctamente"
        unset CI
    else
        log_error "Error instalando JetBrains Toolbox"
        unset CI
        return 1
    fi
}
