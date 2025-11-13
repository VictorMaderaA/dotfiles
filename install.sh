#!/bin/bash

# install.sh - Script principal de instalación de dotfiles
# Uso: ./install.sh [OPTIONS]
# Opciones:
#   --verbose        Mostrar información detallada
#   --debug          Modo debug (muestra todos los comandos)
#   --no-backup      No hacer backup de archivos existentes
#   --env <env>      Especificar entorno (wsl|desktop|server)


#find . -type f \( \
#    -name "*.sh" -o \
#    -name "*.conf" -o \
#    -name "*.md" -o \
#    -name ".zshrc" -o \
#    -name ".bashrc" -o \
#    -name ".profile" -o \
#    -name ".gitconfig" -o \
#    -name "*.yaml" -o \
#    -name "*.yml" \
#    \) -not -path "*.git/*" -exec dos2unix {} \;

#find . -type f -name "*.sh" -exec dos2unix {} \;


find . -type f -name "*.sh" -exec chmod +x {} \;

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
source "$SCRIPT_DIR/scripts/lib/keyboard_shortcuts.sh"
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

    install_tailscale

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
    install_nvm
    install_pyenv
    install_aws_cli

    log_success "Herramientas de desarrollo instaladas"
}

install_docker() {
    log_section "Instalando Docker"

    # Saltear si estamos en WSL (Docker Desktop se instala en Windows)
    if [[ "$IS_WSL" == true ]]; then
        log_warn "WSL detectado - configurando permisos de Docker..."

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

    configure_keyboard_shortcuts

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

install_jetbrains_toolbox() {
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

install_nvm() {
    log_section "Instalando nvm (Node Version Manager)"

    local NVM_DIR="$HOME/.nvm"
    local NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"

    if [[ -d "$NVM_DIR" ]]; then
        log_info "nvm ya está instalado"
        return 0
    fi

    log_info "Descargando e instalando la última versión de nvm..."
    if curl -o- "$NVM_INSTALL_URL" | bash; then
        log_success "nvm instalado correctamente"
    else
        log_error "Error instalando nvm"
        return 1
    fi
}

install_pyenv() {
    log_section "Instalando pyenv (Python Version Manager)"

    local PYENV_ROOT="$HOME/.pyenv"
    local PYENV_INSTALL_URL="https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer"

    if [[ -d "$PYENV_ROOT" ]]; then
        log_info "pyenv ya está instalado"
        return 0
    fi

    log_info "Descargando e instalando pyenv..."
    if curl -L "$PYENV_INSTALL_URL" | bash; then
        log_success "pyenv instalado correctamente"
    else
        log_error "Error instalando pyenv"
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

install_aws_cli() {
    log_section "Instalando AWS CLI"

    if command -v aws &> /dev/null; then
        log_info "AWS CLI ya está instalado"
        return 0
    fi

    log_info "Descargando e instalando AWS CLI..."

    # Directorio temporal
    local TMP_DIR=$(mktemp -d)
    local AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
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
    link_dotfile "shell/.bashrc.d/" ".bashrc.d/"
    link_dotfile "shell/.profile" ".profile"
    link_dotfile "shell/aliases/" ".aliases/"

    # Symlinks de git
    link_dotfile "git/.gitconfig" ".gitconfig"
    link_dotfile "git/.gitignore_global" ".gitignore_global"
    link_dotfile "git/gitConfig/" ".gitConfig/"

    # Symlinks de AWS
    link_dotfile "aws/config" ".aws/config"

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

    local ZSH_PATH=$(which zsh)

    if [[ -z "$ZSH_PATH" ]]; then
        log_error "zsh no está instalado"
        return 1
    fi

    log_info "Ruta de zsh: $ZSH_PATH"

    # Cambiar shell a zsh
    local CURRENT_SHELL=$(grep "^$(whoami):" /etc/passwd | cut -d: -f7)

    if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
        log_info "Cambiando shell a zsh..."

        if sudo chsh -s "$ZSH_PATH" "$(whoami)"; then
            if grep -q "$(whoami).*zsh" /etc/passwd; then
                log_success "Shell cambiado a zsh en /etc/passwd"
            else
                log_error "No se pudo verificar el cambio"
                return 1
            fi
        else
            log_error "Error ejecutando chsh"
            return 1
        fi
    else
        log_success "zsh ya es el shell por defecto"
    fi

    log_success "Shell configurado"
}

configure_gnome_terminal() {
    log_section "Configurando GNOME Terminal para usar zsh"

    # Solo aplicar si estamos en desktop
    if ! is_desktop; then
        log_warn "Desktop no detectado - saltando configuración de GNOME Terminal"
        return 0
    fi

    if ! command -v gsettings &> /dev/null; then
        log_warn "gsettings no disponible - saltando configuración de GNOME Terminal"
        return 0
    fi

    # Obtener el ID del perfil por defecto
    local PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" )

    if [[ -z "$PROFILE_ID" ]]; then
        log_warn "No se pudo obtener el ID del perfil de GNOME Terminal"
        return 0
    fi

    local PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"

    log_info "Configurando perfil de GNOME Terminal: $PROFILE_ID"

    # SOLUCIÓN CORRECTA: Forzar custom-command en true
    # Esto funciona en todas las versiones recientes de GNOME Terminal
    log_info "Estableciendo custom-command a '/usr/bin/zsh -l'..."

    if gsettings set "$PROFILE_PATH" custom-command "/usr/bin/zsh -l" 2>&1; then
        log_debug "custom-command establecido"
    else
        log_warn "No se pudo establecer custom-command"
        return 1
    fi

    if gsettings set "$PROFILE_PATH" use-custom-command true 2>&1; then
        log_success "GNOME Terminal configurado para usar zsh"
    else
        log_warn "No se pudo activar use-custom-command"
        return 1
    fi

    # Fallback: Crear ~/.bash_profile para compatibilidad con otros terminales
    if [[ ! -f "$HOME/.bash_profile" ]]; then
        log_info "Creando ~/.bash_profile como fallback para otros terminales..."
        cat > "$HOME/.bash_profile" << 'EOF'
# ~/.bash_profile - Fallback para terminales que respetan /etc/passwd
# Si no estamos en una terminal de GNOME, esto redirige a zsh
if [[ -z "$GNOME_TERMINAL_SERVICE" ]]; then
    if [[ -x /usr/bin/zsh ]] || [[ -x /bin/zsh ]]; then
        export SHELL=$(which zsh)
        exec $(which zsh) -l
    fi
fi
EOF
        chmod 644 "$HOME/.bash_profile"
        log_success "~/.bash_profile creado"
    fi

    log_success "Configuración de GNOME Terminal completada"
}

run_post_install() {
    log_section "Ejecutando hooks post-instalación"

    if [[ -f "$SCRIPT_DIR/scripts/hooks/post-install.sh" ]]; then
        bash "$SCRIPT_DIR/scripts/hooks/post-install.sh"
    fi

    log_success "Hooks post-instalación ejecutados"
}

validate_keyboard_shortcuts() {
    log_section "Validando atajos de teclado"

    # Verificar si hay atajos personalizados configurados
    local shortcuts=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null)

    if [[ "$shortcuts" != "[]" ]]; then
        log_success "Atajos personalizados configurados: $shortcuts"
    else
        log_warn "No se encontraron atajos personalizados"
    fi
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

    validate_keyboard_shortcuts

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
    install_jetbrains_toolbox
    install_docker
    install_desktop_apps
    install_server_tools

    # Configurar
    link_dotfiles
    configure_shell
    configure_gnome_terminal
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
