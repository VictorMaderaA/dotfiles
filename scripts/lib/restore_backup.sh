#!/bin/bash
# scripts/lib/restore_backup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

BACKUP_DIR="$HOME/.dotfiles_backup"

restore_backup() {
    log_section "Restauración de Backups"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "No se encontró el directorio de backups: $BACKUP_DIR"
        return 1
    fi

    # Listar subdirectorios de backup (fechas)
    local backups=($(ls -d "$BACKUP_DIR"/*/ 2>/dev/null | sort -r))

    if [[ ${#backups[@]} -eq 0 ]]; then
        log_warn "No hay backups disponibles para restaurar."
        return 0
    fi

    echo "Backups disponibles (el más reciente primero):"
    for i in "${!backups[@]}"; do
        echo "$((i+1))) $(basename "${backups[$i]}")"
    done

    echo ""
    read -p "Selecciona el número del backup a restaurar (o 'q' para salir): " choice

    if [[ "$choice" == "q" ]]; then
        return 0
    fi

    if [[ "$choice" -lt 1 || "$choice" -gt ${#backups[@]} ]]; then
        log_error "Selección inválida."
        return 1
    fi

    local selected_backup="${backups[$((choice-1))]}"
    log_info "Restaurando desde: $selected_backup"

    # Encontrar todos los archivos en el backup seleccionado
    # El backup mantiene la estructura del home
    cd "$selected_backup"
    find . -type f | while read -r file; do
        local target="$HOME/${file#./}"
        log_info "Restaurando $target..."
        mkdir -p "$(dirname "$target")"
        cp -p "$file" "$target"
    done

    log_success "Restauración completada."
}

# Si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    restore_backup
fi
