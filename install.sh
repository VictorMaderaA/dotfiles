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
NO_TUI=0

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
        --no-tui)
            NO_TUI=1
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

# Global variables
FAILED_TASKS=()
SELECTED_MODULES=()

# Exportar variables
export VERBOSE DEBUG NO_BACKUP FAILED_TASKS SELECTED_MODULES NO_TUI

# ============================================================================
# Sourcing librerías
# ============================================================================

source "$SCRIPT_DIR/scripts/lib/logging.sh"
source "$SCRIPT_DIR/scripts/lib/detect_environment.sh"
source "$SCRIPT_DIR/scripts/lib/keyboard_shortcuts.sh"
source "$SCRIPT_DIR/scripts/lib/package_manager.sh"
source "$SCRIPT_DIR/scripts/lib/backup.sh"
source "$SCRIPT_DIR/scripts/lib/utils.sh"

# Cargar instaladores modulares
source "$SCRIPT_DIR/scripts/installers/base.sh"
source "$SCRIPT_DIR/scripts/installers/terminal.sh"
source "$SCRIPT_DIR/scripts/installers/development.sh"
source "$SCRIPT_DIR/scripts/installers/languages.sh"
source "$SCRIPT_DIR/scripts/installers/tools.sh"
source "$SCRIPT_DIR/scripts/installers/docker.sh"
source "$SCRIPT_DIR/scripts/installers/desktop.sh"
source "$SCRIPT_DIR/scripts/installers/server.sh"

# Cargar el archivo de configuración
source "$ENVIRONMENTS_DIR/env.conf"

# ============================================================================
# Funciones principales
# ============================================================================

run_task() {
    local task_name=$1
    shift
    log_info "Iniciando tarea: $task_name"
    if "$@"; then
        log_success "Tarea completada: $task_name"
    else
        log_error "Tarea fallida: $task_name"
        FAILED_TASKS+=("$task_name")
    fi
}

df_check_prerequisites() {
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

df_env_detect() {
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














df_init_local_configs() {
    log_section "Inicializando configuraciones locales"

    # 1. Asegurar que existe .env.local
    if [[ ! -f "$DOTFILES_DIR/shell/.env.local" ]]; then
        if [[ -f "$DOTFILES_DIR/shell/env.example" ]]; then
            cp "$DOTFILES_DIR/shell/env.example" "$DOTFILES_DIR/shell/.env.local"
            log_success "Creado dotfiles/shell/.env.local desde env.example"
        else
            touch "$DOTFILES_DIR/shell/.env.local"
            log_success "Creado dotfiles/shell/.env.local (vacío)"
        fi
    fi

    # 2. Generar config.local desde plantilla si existe
    if [[ -f "$DOTFILES_DIR/ssh/config.local.template" ]]; then
        if command -v envsubst &> /dev/null; then
            log_info "Generando config.local desde plantilla..."
            # Usar subshell para exportar variables de .env.local sin afectar el script principal
            (
                # shellcheck disable=SC1091
                set -a
                [[ -f "$DOTFILES_DIR/shell/.env.local" ]] && source "$DOTFILES_DIR/shell/.env.local"
                set +a
                envsubst < "$DOTFILES_DIR/ssh/config.local.template" > "$DOTFILES_DIR/ssh/config.local"
            )
            log_success "Generado dotfiles/ssh/config.local correctamente"
        else
            log_warn "envsubst no encontrado. No se puede procesar la plantilla SSH."
            if [[ ! -f "$DOTFILES_DIR/ssh/config.local" ]]; then
                if [[ -f "$DOTFILES_DIR/ssh/config.local.example" ]]; then
                    cp "$DOTFILES_DIR/ssh/config.local.example" "$DOTFILES_DIR/ssh/config.local"
                    log_success "Fallback: Creado config.local desde ejemplo"
                fi
            fi
        fi
    else
        # Fallback para cuando no hay plantilla (comportamiento original)
        if [[ ! -f "$DOTFILES_DIR/ssh/config.local" ]]; then
            if [[ -f "$DOTFILES_DIR/ssh/config.local.example" ]]; then
                cp "$DOTFILES_DIR/ssh/config.local.example" "$DOTFILES_DIR/ssh/config.local"
                log_success "Creado dotfiles/ssh/config.local desde config.local.example"
            else
                touch "$DOTFILES_DIR/ssh/config.local"
                log_success "Creado dotfiles/ssh/config.local (vacío)"
            fi
        fi
    fi
}

df_dotfiles_link() {
    log_section "Procesando symlinks desde configuración"

    if [[ "$NO_BACKUP" != "1" ]]; then
        init_backup_dir
    fi

    local SYMLINKS_CONF="$SCRIPT_DIR/config/symlinks.conf"

    if [[ ! -f "$SYMLINKS_CONF" ]]; then
        log_error "Archivo de configuración de symlinks no encontrado: $SYMLINKS_CONF"
        return 1
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
                # Verificar si el symlink ya existe y apunta al origen correcto
                if [[ -L "$tgt" ]]; then
                    local current_source=$(readlink "$tgt")
                    if [[ "$current_source" == "$src" ]]; then
                        log_info "El archivo ya está correctamente ligado: $tgt -> $src"
                        return 0
                    fi
                fi

                # Backup si existe
                if [[ "$NO_BACKUP" != "1" ]] && [[ -e "$tgt" ]]; then
                    backup_if_exists "$tgt"
                fi
                mkdir -p "$(dirname "$tgt")"
                ln -sf "$src" "$tgt"
                log_success "Symlink creado: $src -> $tgt"
            fi
        }

        link_recursive "$source" "$target"
    }

    while IFS=: read -r src tgt; do
        # Saltar comentarios y líneas vacías
        [[ -z "$src" || "$src" =~ ^# ]] && continue

        # Trim whitespace
        src=$(echo "$src" | xargs)
        tgt=$(echo "$tgt" | xargs)

        # Caso especial para SSH config
        if [[ "$src" == "ssh/config" ]]; then
            mkdir -p "$HOME/.ssh"
            link_dotfile "$src" "$tgt"
            chmod 600 "$HOME/.ssh/config"
            continue
        fi

        link_dotfile "$src" "$tgt"
    done < "$SYMLINKS_CONF"

    log_success "Symlinks de dotfiles procesados"
}

df_shell_configure() {
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

df_terminal_configure() {
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



df_hooks_post_install() {
    log_section "Ejecutando hooks post-instalación"

    if [[ -f "$SCRIPT_DIR/scripts/hooks/post-install.sh" ]]; then
        bash "$SCRIPT_DIR/scripts/hooks/post-install.sh"
    fi

    log_success "Hooks post-instalación ejecutados"
}

df_show_tui() {
    if [[ "$NO_TUI" == "1" ]]; then
        SELECTED_MODULES=("BASE" "SHELL" "DEV" "DOCKER" "DESKTOP" "SERVER")
        return 0
    fi

    if ! command -v whiptail &> /dev/null; then
        log_warn "whiptail no está instalado. Saltando TUI."
        SELECTED_MODULES=("BASE" "SHELL" "DEV" "DOCKER" "DESKTOP" "SERVER")
        return 0
    fi

    local choices
    choices=$(whiptail --title "Instalador de Dotfiles - Victor Madera" --checklist \
        "Selecciona los módulos a instalar (Espacio para seleccionar, Enter para confirmar):" 20 75 10 \
        "BASE" "Paquetes esenciales del sistema" ON \
        "SHELL" "Configuración de Zsh y herramientas CLI" ON \
        "DEV" "Entornos de desarrollo (NVM, Pyenv, etc.)" ON \
        "DOCKER" "Docker y Docker Compose" ON \
        "DESKTOP" "Aplicaciones GUI y JetBrains Toolbox" OFF \
        "SERVER" "Herramientas de monitoreo y seguridad" OFF \
        3>&1 1>&2 2>&3)

    if [[ $? -ne 0 ]]; then
        log_info "Instalación cancelada por el usuario."
        exit 0
    fi

    # Limpiar comillas y convertir a array
    choices=$(echo "$choices" | tr -d '"')
    SELECTED_MODULES=($choices)

    if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
        log_warn "No has seleccionado ningún módulo. Saliendo."
        exit 0
    fi
}

df_run_hook() {
    local module=$1
    local type=$2 # pre o post
    local hook_file="$SCRIPT_DIR/dotfiles/$module/hooks/$type-install.sh"

    if [[ -f "$hook_file" ]]; then
        log_info "Ejecutando hook $type-install para $module..."
        bash "$hook_file"
    fi
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

validate_command() {
    local cmd=$1
    if command -v "$cmd" &> /dev/null; then
        log_success "Comando $cmd: OK"
        return 0
    fi

    # Manejo especial para nvm y pyenv que pueden ser funciones de shell o estar instalados en rutas fijas
    if [[ "$cmd" == "nvm" ]]; then
        if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
            log_success "nvm detectado en $HOME/.nvm: OK"
            return 0
        fi
    elif [[ "$cmd" == "pyenv" ]]; then
        if [[ -s "$HOME/.pyenv/bin/pyenv" ]]; then
            log_success "pyenv detectado en $HOME/.pyenv: OK"
            return 0
        fi
    fi

    log_warn "Comando $cmd: NO ENCONTRADO"
    return 1
}

df_validate() {
    log_section "Validando instalación completa"

    # Validar symlinks
    [[ -L "$HOME/.zshrc" ]] && log_success ".zshrc symlink OK" || log_warn ".zshrc no está linkeado"
    [[ -L "$HOME/.gitconfig" ]] && log_success ".gitconfig symlink OK" || log_warn ".gitconfig no está linkeado"
    [[ -L "$HOME/.tmux.conf" ]] && log_success ".tmux.conf symlink OK" || log_warn ".tmux.conf no está linkeado"

    # Comandos core
    validate_command "git"
    validate_command "zsh"
    validate_command "starship"
    validate_command "tmux"
    validate_command "curl"

    # Entornos y Herramientas
    validate_command "nvm"
    validate_command "pyenv"
    validate_command "aws"
    validate_command "bw"
    validate_command "docker"

    validate_keyboard_shortcuts

    if is_desktop; then
        log_info "Ambiente Desktop detectado"
        validate_command "jetbrains-toolbox"
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

    df_check_prerequisites
    df_env_detect

    # Mostrar menú TUI para seleccionar módulos
    df_show_tui

    detect_package_manager
    pkg_update

    # Instalar en orden según selección
    for module in "${SELECTED_MODULES[@]}"; do
        case "$module" in
            BASE)
                df_run_hook "system" "pre"
                run_task "Paquetes Base" df_install_base
                df_run_hook "system" "post"
                ;;
            SHELL)
                df_run_hook "shell" "pre"
                run_task "Herramientas Shell" df_install_shell
                df_run_hook "shell" "post"
                ;;
            DEV)
                df_run_hook "development" "pre"
                run_task "Herramientas Desarrollo" df_install_dev
                df_run_hook "development" "post"
                ;;
            DOCKER)
                df_run_hook "docker" "pre"
                run_task "Docker" df_install_docker
                df_run_hook "docker" "post"
                ;;
            DESKTOP)
                df_run_hook "desktop" "pre"
                run_task "JetBrains Toolbox" df_install_jetbrains
                run_task "Aplicaciones Escritorio" df_install_desktop
                df_run_hook "desktop" "post"
                ;;
            SERVER)
                df_run_hook "server" "pre"
                run_task "Herramientas Servidor" df_install_server
                df_run_hook "server" "post"
                ;;
        esac
    done

    # Configurar
    run_task "Configuraciones Locales" df_init_local_configs
    run_task "Symlinks" df_dotfiles_link
    run_task "Configuración Shell" df_shell_configure
    run_task "Configuración Terminal" df_terminal_configure
    run_task "Post-Instalación" df_hooks_post_install

    # Validar
    df_validate

    # Resumen final
    log_section "¡Proceso Finalizado!"

    if [[ ${#FAILED_TASKS[@]} -gt 0 ]]; then
        log_error "Las siguientes tareas fallaron:"
        for task in "${FAILED_TASKS[@]}"; do
            echo -e "  ${RED}- $task${NC}"
        done
        echo ""
    else
        log_success "¡Todas las tareas se completaron con éxito!"
    fi

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
