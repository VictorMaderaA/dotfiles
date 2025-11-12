#!/bin/bash

# Obtiene un array de paquetes desde una variable de configuración
# Uso: get_packages "BASIC_PACKAGES" o local packages=($(get_packages "BASIC_PACKAGES"))
get_packages() {
    local var_name="$1"

    if [[ -z "$var_name" ]]; then
        log_error "get_packages: se requiere el nombre de la variable"
        return 1
    fi

    # Obtener el valor de la variable indirectamente
    local packages_string="${!var_name}"

    if [[ -z "$packages_string" ]]; then
        log_warn "get_packages: variable '$var_name' vacía o no definida"
        return 0
    fi

    # Normalizar: eliminar saltos de línea y espacios extra, devolver lista separada por espacios
    echo "$packages_string" | tr '\n' ' ' | tr -s ' ' | xargs
}

# Alternativa que devuelve directamente un array (para usar con mapfile/readarray)
get_packages_array() {
    local var_name="$1"
    local -n result_array="$2"  # nameref para modificar el array pasado por referencia

    if [[ -z "$var_name" ]]; then
        log_error "get_packages_array: se requiere el nombre de la variable"
        return 1
    fi

    local packages_string="${!var_name}"

    if [[ -z "$packages_string" ]]; then
        log_warn "get_packages_array: variable '$var_name' vacía o no definida"
        return 0
    fi

    # Leer en el array, eliminando líneas vacías
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && result_array+=("$pkg")
    done < <(echo "$packages_string" | xargs -n1)
}
