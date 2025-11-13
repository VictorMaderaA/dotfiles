#!/bin/bash

# keyboard_shortcuts.sh - Automatizar configuración de atajos de teclado en GNOME

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

# Función auxiliar para trim whitespace
trim() {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# ============================================================================
# FUNCIONES DE CONFIGURACIÓN
# ============================================================================

# Función para crear un atajo personalizado
create_custom_shortcut() {
    local index=$1
    local name=$2
    local command=$3
    local binding=$4

    local path="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${index}/"

    # Establecer los parámetros del atajo
    if ! gsettings set "$path" name "$name" 2>/dev/null; then
        log_error "Error al establecer nombre del atajo: $name"
        return 1
    fi

    if ! gsettings set "$path" command "$command" 2>/dev/null; then
        log_error "Error al establecer comando: $command"
        return 1
    fi

    if ! gsettings set "$path" binding "$binding" 2>/dev/null; then
        log_error "Error al establecer binding: $binding"
        return 1
    fi

    return 0
}

# Función para actualizar la lista de atajos personalizados
update_custom_shortcuts_list() {
    local count=$1
    local shortcuts_list="["

    local i=0
    while [[ $i -lt $count ]]; do
        shortcuts_list+="'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${i}/'"
        i=$((i + 1))
        if [[ $i -lt $count ]]; then
            shortcuts_list+=", "
        fi
    done

    shortcuts_list+="]"

    if gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$shortcuts_list" 2>/dev/null; then
        return 0
    else
        log_error "Error al actualizar lista de atajos"
        return 1
    fi
}

# ============================================================================
# FUNCIÓN PRINCIPAL
# ============================================================================

configure_keyboard_shortcuts() {
    log_section "Configurando atajos de teclado personalizados"

    # Solo en desktop
    if ! is_desktop; then
        log_warn "Desktop no detectado - saltando atajos de teclado"
        return 0
    fi

    # Verificar que gsettings está disponible
    if ! command -v gsettings &> /dev/null; then
        log_warn "gsettings no disponible - saltando configuración de atajos"
        return 0
    fi

    local shortcuts_file="$DOTFILES_DIR/desktop/keyboard-shortcuts.conf"

    if [[ ! -f "$shortcuts_file" ]]; then
        log_warn "Archivo de atajos no encontrado: $shortcuts_file"
        return 0
    fi

    log_info "Leyendo archivo: $shortcuts_file"

    local index=0
    local errors=0

    # LEE EL ARCHIVO EN MAPFILE (no en while con redirección)
    local -a lines
    mapfile -t lines < "$shortcuts_file"

    # ITERA SOBRE EL ARRAY
    for line in "${lines[@]}"; do
        # Trim la línea completa
        line=$(trim "$line")

        # Saltar comentarios y líneas vacías
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue

        # Parsear línea con separador |
        local name command binding
        IFS='|' read -r name command binding <<< "$line"

        # Trim cada campo
        name=$(trim "$name")
        command=$(trim "$command")
        binding=$(trim "$binding")

        # Validación
        if [[ -z "$name" ]] || [[ -z "$command" ]] || [[ -z "$binding" ]]; then
            log_warn "Línea inválida (faltan campos): $line"
            errors=$((errors + 1))
            continue
        fi

        # Validar que el comando existe
        local cmd_name="${command%% *}"
        if ! command -v "$cmd_name" &> /dev/null; then
            log_warn "Comando no encontrado: $cmd_name"
            errors=$((errors + 1))
            continue
        fi

        log_info "[$index] $name ($binding)"

        if create_custom_shortcut "$index" "$name" "$command" "$binding"; then
            index=$((index + 1))
        else
            log_error "Error al crear atajo: $name"
            errors=$((errors + 1))
        fi
    done

    # Validar resultado
    if [[ $index -eq 0 ]]; then
        log_error "No se crearon atajos"
        return 1
    fi

    # Actualizar la lista global de atajos
    if update_custom_shortcuts_list "$index"; then
        log_success "Atajos de teclado configurados ($index atajos creados)"
        if [[ $errors -gt 0 ]]; then
            log_warn "Se ignoraron $errors errores"
        fi
        return 0
    else
        return 1
    fi
}
