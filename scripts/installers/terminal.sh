#!/bin/bash
# scripts/installers/terminal.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/package_manager.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/utils.sh"

df_install_shell() {
    log_section "Instalando herramientas de shell"

    # Obtener paquetes directamente como array
    local packages=($(get_packages "SHELL_PACKAGES"))

    for pkg in "${packages[@]}"; do
        pkg_install_if_needed "$pkg"
    done

    # Instalar starship (cross-platform prompt)
    if ! command -v starship &> /dev/null; then
        log_info "Instalando starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # Instalar Nerd Fonts
    install_nerd_fonts

    log_success "Herramientas de shell instaladas"
}

install_nerd_fonts() {
    log_section "Instalando Nerd Fonts"

    FONTS_DIR="$HOME/.local/share/fonts"
    TEMP_DIR="/tmp/nerd_fonts_$$"

    mkdir -p "$FONTS_DIR"
    mkdir -p "$TEMP_DIR"

    # Array de fuentes disponibles en v3.4.0
    local fonts=(
        "Meslo"
        "FiraCode"
        "JetBrainsMono"
        "SourceCodePro"
    )

    local installed=0
    local skipped=0
    local failed=0

    for font in "${fonts[@]}"; do
        local zip_file="$TEMP_DIR/${font}.zip"

        log_info "Procesando ${font}..."

        # Verificar si la fuente ya está instalada
        # Busca archivos .ttf o .otf que contengan el nombre de la fuente (case-insensitive)
        if find "$FONTS_DIR" -type f \( -iname "*${font}*.ttf" -o -iname "*${font}*.otf" \) | grep -q .; then
            log_info "  ⊙ ${font} ya instalada (omitiendo)"
            skipped=$((skipped + 1))
            continue
        fi

        # Descargar solo si no existe en temp
        if [[ ! -f "$zip_file" ]]; then
            log_info "  Descargando ${font}.zip..."

            if ! curl -fL -o "$zip_file" \
                "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/${font}.zip"; then
                log_error "  ✗ Error descargando ${font}"
                failed=$((failed + 1))
                continue
            fi
        else
            log_info "  ${font}.zip ya descargado (usando cache local)"
        fi

        # Validar archivo ZIP
        if ! unzip -t "$zip_file" &>/dev/null; then
            log_error "  ✗ ${font}.zip corrupto o inválido"
            rm -f "$zip_file"
            failed=$((failed + 1))
            continue
        fi

        # Extraer sin prompts (sobrescribir automáticamente)
        if unzip -q -o "$zip_file" -d "$FONTS_DIR"; then
            log_success "  ✓ ${font} instalada"
            installed=$((installed + 1))
            rm -f "$zip_file"
        else
            log_error "  ✗ Error extrayendo ${font}"
            failed=$((failed + 1))
        fi
    done

    # Actualizar caché de fuentes solo si se instalaron nuevas
    if [[ $installed -gt 0 ]]; then
        log_info "Actualizando caché de fuentes..."
        if fc-cache -fv "$FONTS_DIR" > /dev/null 2>&1; then
            log_success "Caché actualizado"
        else
            log_warn "Advertencia: No se pudo actualizar el caché de fuentes"
        fi
    fi

    # Limpiar
    rm -rf "$TEMP_DIR"

    # Resumen
    if [[ $skipped -gt 0 ]]; then
        log_info "⊙ $skipped fuentes ya instaladas"
    fi

    if [[ $installed -gt 0 ]]; then
        log_success "✓ $installed fuentes nuevas instaladas en $FONTS_DIR"
    fi

    if [[ $failed -gt 0 ]]; then
        log_error "✗ $failed fuentes fallaron"
        return 1
    fi

    if [[ $installed -eq 0 && $failed -eq 0 ]]; then
        log_success "✓ Todas las fuentes ya están instaladas"
    fi
}
