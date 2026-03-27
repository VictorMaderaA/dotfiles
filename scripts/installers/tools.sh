#!/bin/bash
# scripts/installers/tools.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/logging.sh"

install_bitwarden_cli() {
    log_section "Instalando Bitwarden CLI"

    if ! command -v bw &> /dev/null; then
        log_info "Descargando e instalando Bitwarden CLI..."
        
        # Mapear arquitectura para Bitwarden
        local bw_arch="linux"
        [[ "$ARCH_TYPE" == "arm64" ]] && bw_arch="linux-arm64"

        # Descargar la última versión estable para la arquitectura detectada
        BW_URL=$(curl -s https://api.github.com/repos/bitwarden/cli/releases/latest | grep "browser_download_url.*bw-$bw_arch.*\.zip" | cut -d '"' -f 4)

        if [ -z "$BW_URL" ]; then
            log_error "No se pudo obtener la URL de descarga de Bitwarden CLI para $bw_arch"
            return 1
        fi

        echo "Descargando: $BW_URL"

        if curl -L "$BW_URL" -o /tmp/bw.zip; then
            unzip -o /tmp/bw.zip -d /tmp/
            sudo mv /tmp/bw /usr/local/bin/
            sudo chmod +x /usr/local/bin/bw
            rm /tmp/bw.zip
            log_success "Bitwarden CLI instalado"
        else
            log_error "Error al descargar Bitwarden CLI"
            return 1
        fi
    else
        log_info "Bitwarden CLI ya está instalado"
    fi
}

install_aws_cli() {
    log_section "Instalando AWS CLI"

    if command -v aws &> /dev/null; then
        log_info "AWS CLI ya está instalado"
        return 0
    fi

    log_info "Descargando e instalando AWS CLI..."

    # Mapear arquitectura para AWS
    local aws_arch="x86_64"
    [[ "$ARCH_TYPE" == "arm64" ]] && aws_arch="aarch64"

    # Directorio temporal
    local TMP_DIR=$(mktemp -d)
    local AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-$aws_arch.zip"
    local AWS_CLI_ZIP="$TMP_DIR/awscliv2.zip"

    # Descargar AWS CLI
    if curl -s -o "$AWS_CLI_ZIP" "$AWS_CLI_URL"; then
        # Descomprimir e instalar
        unzip -q "$AWS_CLI_ZIP" -d "$TMP_DIR"
        sudo "$TMP_DIR/aws/install" --update
        rm -rf "$TMP_DIR"
        log_success "AWS CLI instalado correctamente"
    else
        log_error "Error descargando AWS CLI"
        rm -rf "$TMP_DIR"
        return 1
    fi
}

install_tailscale() {
    log_section "Instalando Tailscale"

    if command -v tailscale &> /dev/null; then
        log_info "Tailscale ya está instalado"
        return 0
    fi

    log_info "Descargando e instalando Tailscale..."
    if curl -fsSL https://tailscale.com/install.sh | sh; then
        log_success "Tailscale instalado correctamente"
    else
        log_error "Error instalando Tailscale"
        return 1
    fi
}
