#!/bin/bash

# scripts/lib/detect_environment.sh
# Detección inteligente del entorno de ejecución
# Usa: source detect_environment.sh && detect_environment

detect_environment() {
    local uname_s=$(uname -s)
    local uname_r=$(uname -r)
    local os_release=""
    
    # Inicializar todos los flags como false
    export IS_UBUNTU=false
    export IS_WSL=false
    export IS_DESKTOP=false
    export IS_SERVER=false
    export DISTRO="unknown"
    export IS_INTERACTIVE=true
    
    # 1. Detectar Sistema Operativo Base
    if [[ "$uname_s" == "Linux" ]]; then
        # Leer información de distribución
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            DISTRO="${ID}"
        fi
        
        # 2. Detectar WSL específicamente
        # WSL1 tiene "Microsoft" en uname -r
        # WSL2 tiene "microsoft" (lowercase) en uname -r
        if [[ "$uname_r" =~ [Mm]icrosoft ]] || [[ "$uname_r" =~ -WSL ]]; then
            export IS_WSL=true
            export IS_UBUNTU=true
        # 3. Detectar Ubuntu/Debian nativo
        elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            export IS_UBUNTU=true
            
            # 4. Detectar Desktop vs Server
            # Buscar display managers activos (indicador de GUI)
            if systemctl list-units --all 2>/dev/null | grep -qE "(display-manager|sddm|lightdm|gdm|xdm)"; then
                export IS_DESKTOP=true
            # Alternativa: buscar si X11 está disponible
            elif [[ -n "$DISPLAY" ]] || [[ -S /tmp/.X11-unix/* ]]; then
                export IS_DESKTOP=true
            # Alternativa: buscar procesos gráficos
            elif pgrep -x "gnome-session\|kwin\|xfce4-session\|lxsession" > /dev/null 2>&1; then
                export IS_DESKTOP=true
            else
                export IS_SERVER=true
            fi
        else
            export IS_UBUNTU=true  # Asumir Ubuntu si es Linux desconocido
            export IS_SERVER=true
        fi
    else
        echo "ERROR: Sistema no soportado: $uname_s"
        echo "Este script solo soporta Linux"
        return 1
    fi
    
    # Validación: WSL nunca debe tener Desktop
    if [[ "$IS_WSL" == true ]]; then
        export IS_DESKTOP=false
    fi
    
    # Detectar si es ejecución interactiva
    if [[ ! -t 0 ]]; then
        export IS_INTERACTIVE=false
    fi
    
    return 0
}

get_environment_name() {
    if [[ "$IS_WSL" == true ]]; then
        echo "wsl"
    elif [[ "$IS_DESKTOP" == true ]]; then
        echo "desktop"
    elif [[ "$IS_SERVER" == true ]]; then
        echo "server"
    else
        echo "unknown"
    fi
}

show_environment_info() {
    echo "╔════════════════════════════════════════╗"
    echo "║    INFORMACIÓN DEL ENTORNO DETECTADO   ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Sistema Operativo:  $DISTRO"
    echo "Ubuntu/Debian:      $([ "$IS_UBUNTU" = true ] && echo "✓" || echo "✗")"
    echo "WSL:                $([ "$IS_WSL" = true ] && echo "✓" || echo "✗")"
    echo "Desktop:            $([ "$IS_DESKTOP" = true ] && echo "✓" || echo "✗")"
    echo "Server:             $([ "$IS_SERVER" = true ] && echo "✓" || echo "✗")"
    echo ""
    echo "Entorno: $(get_environment_name)"
    echo ""
}

# Función auxiliar para condiciones
is_wsl() { [[ "$IS_WSL" == true ]]; }
is_desktop() { [[ "$IS_DESKTOP" == true ]]; }
is_server() { [[ "$IS_SERVER" == true ]]; }
is_ubuntu() { [[ "$IS_UBUNTU" == true ]]; }

# Exportar funciones para uso en scripts sourced
export -f get_environment_name
export -f is_wsl
export -f is_desktop
export -f is_server
export -f is_ubuntu
export -f show_environment_info
