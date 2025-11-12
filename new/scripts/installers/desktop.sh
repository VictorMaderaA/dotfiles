
#!/bin/bash

# Template para instaladores que usan archivos .conf
# Uso: Copiar este template y modificar las variables según necesidad

# Obtener el directorio del script actual
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Importar librerías comunes
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/package_manager.sh"

# Nombre del instalador (modificar según el caso)
INSTALLER_NAME="template"

install_packages() {
    local config_file="$1"
    local packages_var="$2"

    # Verificar que el archivo de configuración existe
    if [[ ! -f "$config_file" ]]; then
        log_error "Archivo de configuración no encontrado: $config_file"
        return 1
    }

    # Cargar el archivo de configuración
    source "$config_file"

    # Obtener la variable dinámica usando eval
    local packages
    eval "packages=\$$packages_var"

    # Verificar que se obtuvieron los paquetes
    if [[ -z "$packages" ]]; then
        log_warn "No hay paquetes definidos en $packages_var"
        return 0
    }

    # Convertir la string en un array
    IFS=' ' read -r -a package_array <<< "$packages"

    # Instalar cada paquete
    for pkg in "${package_array[@]}"; do
        # Ignorar líneas vacías
        [[ -z "$pkg" ]] && continue
        pkg_install_if_needed "$pkg"
    done
}

main() {
    log_section "Iniciando instalación: $INSTALLER_NAME"

    # Detectar el package manager
    detect_package_manager
    pkg_update

    # Definir rutas (modificar según el caso)
    local config_file="$SCRIPT_DIR/../../environments/common/packages.conf"
    local packages_var="PACKAGES_${INSTALLER_NAME^^}"  # Convierte a mayúsculas

    # Instalar paquetes
    install_packages "$config_file" "$packages_var"

    log_success "Instalación completada: $INSTALLER_NAME"
}

# Ejecutar solo si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi