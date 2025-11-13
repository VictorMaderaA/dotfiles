#!/bin/bash

# scripts/lib/backup.sh
# Utilidades para backup de archivos existentes

BACKUP_DIR="${BACKUP_DIR:-.dotfiles_backup}"
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Crear directorio de backup si no existe
init_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Directorio de backup creado: $BACKUP_DIR"
    fi
}

# Hacer backup de un archivo si existe
backup_if_exists() {
    local file=$1
    
    if [[ ! -e "$file" ]]; then
        log_debug "No existe: $file (no se hace backup)"
        return 0
    fi
    
    init_backup_dir
    
    local filename=$(basename "$file")
    local backup_file="$BACKUP_DIR/${filename}.${BACKUP_TIMESTAMP}"
    
    if [[ -d "$file" ]]; then
        cp -r "$file" "$backup_file"
        log_info "Backup de directorio: $file → $backup_file"
    else
        cp "$file" "$backup_file"
        log_info "Backup de archivo: $file → $backup_file"
    fi
}

# Restaurar archivo desde backup
restore_backup() {
    local original_file=$1
    local filename=$(basename "$original_file")
    
    # Buscar el backup más reciente
    local latest_backup=$(ls -t "$BACKUP_DIR"/${filename}.* 2>/dev/null | head -1)
    
    if [[ -z "$latest_backup" ]]; then
        log_error "No se encontró backup para: $original_file"
        return 1
    fi
    
    if [[ -d "$latest_backup" ]]; then
        rm -rf "$original_file"
        cp -r "$latest_backup" "$original_file"
    else
        cp "$latest_backup" "$original_file"
    fi
    
    log_success "Restaurado: $original_file desde $latest_backup"
}

# Listar backups disponibles
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warn "Directorio de backup no existe: $BACKUP_DIR"
        return 1
    fi
    
    echo "Backups disponibles en: $BACKUP_DIR"
    ls -lh "$BACKUP_DIR"
}

# Limpiar backups antiguos (por defecto los más de 7 días)
cleanup_old_backups() {
    local days=${1:-7}
    
    init_backup_dir
    
    log_info "Limpiando backups más antiguos de $days días..."
    find "$BACKUP_DIR" -type f -mtime +$days -delete
}

# Exportar funciones
export -f init_backup_dir
export -f backup_if_exists
export -f restore_backup
export -f list_backups
export -f cleanup_old_backups
