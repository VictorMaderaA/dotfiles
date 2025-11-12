#!/bin/bash

# install.sh - Script principal de instalación de dotfiles
# Uso: ./install.sh [OPTIONS]
# Opciones:
#   --verbose        Mostrar información detallada
#   --debug          Modo debug (muestra todos los comandos)
#   --no-backup      No hacer backup de archivos existentes
#   --env <env>      Especificar entorno (wsl|desktop|server)

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
ENVIRONMENTS_DIR="$SCRIPT_DIR/environments"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
VERBOSE=0
DEBUG=0
NO_BACKUP=0
FORCE_ENV=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=1
            shift
            ;;
        --debug)
            DEBUG=1
            VERBOSE=1
            shift
            ;;
        --no-backup)
            NO_BACKUP=1
            shift
            ;;
        --env)
            FORCE_ENV="$2"
            shift 2
            ;;
        *)
            echo "Opción desconocida: $1"
            exit 1
            ;;
    esac
done

# Exportar variables
export VERBOSE DEBUG NO_BACKUP

# ============================================================================
# Sourcing librerías
# ============================================================================

source "$SCRIPT_DIR/scripts/lib/logging.sh"
source "$SCRIPT_DIR/scripts/lib/detect_environment.sh"
source "$SCRIPT_DIR/scripts/lib/package_manager.sh"
source "$SCRIPT_DIR/scripts/lib/backup.sh"
source "$SCRIPT_DIR/scripts/lib/utils.sh"

# Cargar el archivo de configuración
source "$ENVIRONMENTS_DIR/env.conf"

# ============================================================================
# Funciones principales
# ============================================================================

check_prerequisites() {
    log_section "Verificando requisitos previos"
    
    # Verificar que somos Linux
    if [[ ! "$OSTYPE" =~ "linux" ]]; then
        log_error "Este script solo funciona en Linux"
        exit 1
    fi
    
    # Verificar git
    if ! command -v git &> /dev/null; then
        log_error "Git no está instalado"
        exit 1
    fi
    
    log_success "Requisitos cumplidos"
}

detect_env() {
    log_section "Detectando entorno"
    
    if ! detect_environment; then
        log_error "Error detectando entorno"
        exit 1
    fi
    
    # Permitir override manual
    if [[ -n "$FORCE_ENV" ]]; then
        log_warn "Entorno forzado a: $FORCE_ENV"
        case "$FORCE_ENV" in
            wsl)
                export IS_WSL=true
                export IS_DESKTOP=false
                export IS_SERVER=false
                ;;
            desktop)
                export IS_WSL=false
                export IS_DESKTOP=true
                export IS_SERVER=false
                ;;
            server)
                export IS_WSL=false
                export IS_DESKTOP=false
                export IS_SERVER=true
                ;;
            *)
                log_error "Entorno no válido: $FORCE_ENV"
                exit 1
                ;;
        esac
    fi
    
    show_environment_info
}

install_base_packages() {
    log_section "Instalando paquetes base"

    # Obtener paquetes directamente como array
    local packages=($(get_packages "BASE_PACKAGES"))

    for pkg in "${packages[@]}"; do
        pkg_install_if_needed "$pkg"
    done
    
    log_success "Paquetes base instalados"
}

install_shell_tools() {
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
    
    log_success "Herramientas de shell instaladas"
}

install_development_tools() {
    log_section "Instalando herramientas de desarrollo"

    # Obtener paquetes directamente como array
    local packages=($(get_packages "DEV_PACKAGES"))

    for pkg in "${packages[@]}"; do
        pkg_install_if_needed "$pkg"
    done

    install_bitwarden_cli
    
    log_success "Herramientas de desarrollo instaladas"
}

install_docker() {
    log_section "Instalando Docker"
    
    # Saltear si estamos en WSL (Docker Desktop se instala en Windows)
    if [[ "$IS_WSL" == true ]]; then
        log_warn "WSL detectado - saltando Docker (instala Docker Desktop en Windows)"
        return 0
    fi
    
    if ! command -v docker &> /dev/null; then
        log_info "Instalando Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        
        # Añadir usuario al grupo docker
        sudo usermod -aG docker "$(whoami)"
        log_warn "Usuario añadido al grupo docker - reinicia sesión o usa: newgrp docker"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_info "Instalando Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    log_success "Docker instalado"
}

install_desktop_apps() {
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

    log_success "Aplicaciones de escritorio instaladas"
}

install_server_tools() {
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

install_bitwarden_cli() {
    log_section "Instalando Bitwarden CLI"

    if ! command -v bw &> /dev/null; then
        log_info "Descargando e instalando Bitwarden CLI..."
        # Descargar la última versión estable para Linux
        BW_URL=$(curl -s https://api.github.com/repos/bitwarden/cli/releases/latest | grep "browser_download_url.*bw-linux.*\.zip" | cut -d '"' -f 4)

        if [ -z "$BW_URL" ]; then
            log_error "No se pudo obtener la URL de descarga de Bitwarden CLI"
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

link_dotfiles() {
    log_section "Creando symlinks de dotfiles"
    
    if [[ "$NO_BACKUP" != "1" ]]; then
        init_backup_dir
    fi
    
    # Función auxiliar para crear symlink
    link_dotfile() {
        local source=$1
        local target=$2

        if [[ -z "$source" ]] || [[ -z "$target" ]]; then
            log_error "Parámetros inválidos: $source -> $target"
            return 1
        fi

        # Ruta absoluta y elimina trailing slashes
        source="${DOTFILES_DIR}/${source%/}"
        target="${HOME}/${target%/}"

        if [[ ! -e "$source" ]]; then
            log_warn "Archivo de configuración no existe: $source"
            return 0
        fi

        # Función interna para crear symlinks recursivamente
        link_recursive() {
            local src=$1
            local tgt=$2

            if [[ -d "$src" ]]; then
                mkdir -p "$tgt"
                # Usa shopt -s dotglob para incluir archivos ocultos
                shopt -s dotglob
                for item in "$src"/*; do
                    [[ -e "$item" ]] || continue
                    local base_item=$(basename "$item")
                    link_recursive "$item" "$tgt/$base_item"
                done
                shopt -u dotglob
            else
                # Backup si existe
                if [[ "$NO_BACKUP" != "1" ]] && [[ -e "$tgt" ]]; then
                    backup_if_exists "$tgt"
                fi
                mkdir -p "$(dirname "$tgt")"
                ln -sf "$src" "$tgt"
                log_debug "Symlink creado: $src -> $tgt"
            fi
        }

        link_recursive "$source" "$target"
    }

    # Symlinks de shell
    link_dotfile "shell/.zshrc" ".zshrc"
    link_dotfile "shell/.bashrc" ".bashrc"
    link_dotfile "shell/.profile" ".profile"
    link_dotfile "shell/aliases/" ".aliases/"
    
    # Symlinks de git
    link_dotfile "git/.gitconfig" ".gitconfig"
    link_dotfile "git/.gitignore_global" ".gitignore_global"
    link_dotfile "git/gitConfig/" ".gitConfig/"
    
    # Symlinks de SSH (si existen)
    if [[ -f "$DOTFILES_DIR/ssh/config" ]]; then
        mkdir -p "$HOME/.ssh"
        link_dotfile "ssh/config" ".ssh/config"
        chmod 600 "$HOME/.ssh/config"
    fi
    
    # Symlinks de editors
    link_dotfile "editors/.vimrc" ".vimrc"
    link_dotfile "editors/.editorconfig" ".editorconfig"
    
    # Symlinks de tools
    link_dotfile "tools/.tmux.conf" ".tmux.conf"
    link_dotfile "tools/.inputrc" ".inputrc"
    
    log_success "Symlinks de dotfiles creados"
}

configure_shell() {
    log_section "Configurando shell"
    
    # Cambiar shell a zsh si no es el actual
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        log_info "Cambiando shell a zsh..."
        chsh -s "$(which zsh)"
        log_warn "Shell cambió - necesitarás reiniciar la sesión"
    fi
    
    log_success "Shell configurado"
}

run_post_install() {
    log_section "Ejecutando hooks post-instalación"
    
    if [[ -f "$SCRIPT_DIR/scripts/hooks/post-install.sh" ]]; then
        bash "$SCRIPT_DIR/scripts/hooks/post-install.sh"
    fi
    
    log_success "Hooks post-instalación ejecutados"
}

validate_installation() {
    log_section "Validando instalación"
    
    # Validar symlinks
    [[ -L "$HOME/.zshrc" ]] && log_success ".zshrc symlink OK" || log_warn ".zshrc no está linkedado"
    [[ -L "$HOME/.gitconfig" ]] && log_success ".gitconfig symlink OK" || log_warn ".gitconfig no está linkedado"
    [[ -L "$HOME/.tmux.conf" ]] && log_success ".tmux.conf symlink OK" || log_warn ".tmux.conf no está linkedado"
    
    # Validar comandos importantes
    command -v git &> /dev/null && log_success "Git: OK" || log_warn "Git: NO encontrado"
    command -v zsh &> /dev/null && log_success "Zsh: OK" || log_warn "Zsh: NO encontrado"
    command -v curl &> /dev/null && log_success "Curl: OK" || log_warn "Curl: NO encontrado"
    
    if is_desktop; then
        log_info "Ambiente Desktop detectado"
    elif is_server; then
        log_info "Ambiente Server detectado"
    elif is_wsl; then
        log_info "Ambiente WSL detectado"
    fi
}

# ============================================================================
# Main Flow
# ============================================================================

main() {
    clear
    
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         INSTALADOR DE DOTFILES - VICTOR MADERA              ║"
    echo "║          Auto-detección de entorno (Desktop/WSL/Server)     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    check_prerequisites
    detect_env

    detect_package_manager
    pkg_update
    
    # Instalar en orden
    install_base_packages
    install_shell_tools
    install_development_tools
    install_docker
    install_desktop_apps
    install_server_tools
    
    # Configurar
    link_dotfiles
    configure_shell
    run_post_install
    
    # Validar
    validate_installation
    
    # Resumen final
    log_section "¡Instalación Completada!"
    echo -e "${GREEN}"
    echo "Próximos pasos:"
    echo "  1. Reinicia tu sesión para cargar la nueva shell (zsh)"
    echo "  2. Personaliza tu configuración editando: $DOTFILES_DIR"
    echo "  3. Los backups están en: .dotfiles_backup"
    echo -e "${NC}"
    echo ""
}

# Ejecutar
main "$@"
