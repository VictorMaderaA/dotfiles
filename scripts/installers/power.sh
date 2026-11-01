#!/bin/bash
# scripts/installers/power.sh
# Servicio systemd que aplica ajustes extra de ahorro con el perfil power-saver

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/detect_environment.sh"

POWERSAVE_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../dotfiles/system/power-saver-extras"
POWERSAVE_BIN=/usr/local/sbin/power-saver-extras
POWERSAVE_UNIT=/etc/systemd/system/power-saver-extras.service
POWERSAVE_CONF=/etc/default/power-saver-extras

df_install_powersave() {
    log_section "Instalando servicio power-saver-extras"

    if ! is_desktop; then
        log_warn "Desktop no detectado - saltando power-saver-extras"
        return 0
    fi

    local missing=0
    for cmd in systemctl gdbus busctl; do
        command -v "$cmd" &>/dev/null || { log_error "Falta '$cmd'"; missing=1; }
    done
    systemctl cat power-profiles-daemon &>/dev/null \
        || { log_error "power-profiles-daemon no está instalado"; missing=1; }
    [[ $missing -eq 0 ]] || return 1

    sudo install -m 755 "$POWERSAVE_SRC/power-saver-extras" "$POWERSAVE_BIN" || return 1
    sudo install -m 644 "$POWERSAVE_SRC/power-saver-extras.service" "$POWERSAVE_UNIT" || return 1
    # No pisar la configuración si el usuario ya la ha editado
    if [[ ! -f "$POWERSAVE_CONF" ]]; then
        sudo install -m 644 "$POWERSAVE_SRC/power-saver-extras.default" "$POWERSAVE_CONF" || return 1
    fi

    sudo systemctl daemon-reload || return 1
    sudo systemctl enable power-saver-extras.service || return 1
    sudo systemctl restart power-saver-extras.service || return 1

    log_success "Servicio activo. Edita $POWERSAVE_CONF para ajustar valores"
}

df_uninstall_powersave() {
    log_section "Desinstalando servicio power-saver-extras"

    # 'disable --now' para el servicio y ExecStopPost revierte los ajustes
    sudo systemctl disable --now power-saver-extras.service 2>/dev/null || true
    sudo rm -f "$POWERSAVE_BIN" "$POWERSAVE_UNIT"
    sudo systemctl daemon-reload

    log_success "Servicio eliminado (configuración conservada en $POWERSAVE_CONF)"
}
