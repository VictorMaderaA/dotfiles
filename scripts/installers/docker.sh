#!/bin/bash
# scripts/installers/docker.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/detect_environment.sh"

df_install_docker() {
    log_section "Instalando Docker"

    # Saltear si estamos en WSL (Docker Desktop se instala en Windows)
    if [[ "$IS_WSL" == true ]]; then
        log_warn "WSL detectado - configurando permisos de Docker..."

        if ! getent group docker > /dev/null; then
            log_info "Creando grupo docker..."
            sudo groupadd docker
            log_success "Grupo docker creado"
        fi

        # Añadir usuario al grupo docker
        if ! groups "$(whoami)" | grep -q docker; then
            log_info "Añadiendo usuario al grupo docker..."
            sudo usermod -aG docker "$(whoami)"
            log_success "Usuario añadido al grupo docker"
        fi

        # Cambiar permisos del socket si es necesario
        if [[ -S /var/run/docker.sock ]]; then
            sudo chmod 666 /var/run/docker.sock
            log_info "Permisos del socket Docker ajustados"
        fi

        log_warn "Para que los cambios surtan efecto, ejecuta: newgrp docker"
        return 0
    fi

    if ! command -v docker &> /dev/null; then
        log_info "Instalando Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh

        # Añadir usuario al grupo docker
        if ! groups "$(whoami)" | grep -q docker; then
            log_info "Añadiendo usuario al grupo docker..."
            sudo usermod -aG docker "$(whoami)"
            log_warn "Usuario añadido al grupo docker - reinicia sesión o usa: newgrp docker"
        fi
    else
        log_info "Docker ya está instalado"
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_info "Instalando Docker Compose..."
        DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
        curl -L "$DOCKER_COMPOSE_URL" -o /tmp/docker-compose
        sudo mv /tmp/docker-compose /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        log_info "Docker Compose ya está instalado"
    fi

    log_success "Docker instalado"
}
