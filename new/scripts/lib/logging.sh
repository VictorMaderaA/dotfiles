#!/bin/bash

# scripts/lib/logging.sh
# Sistema de logging consistente para todos los scripts

# Colores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Verbosity levels
VERBOSE=${VERBOSE:-0}
DEBUG=${DEBUG:-0}

log_info() {
    echo -e "${BLUE}ℹ${NC} ${1}"
}

log_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

log_error() {
    echo -e "${RED}✗${NC} ${1}" >&2
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

log_debug() {
    if [[ "$DEBUG" == "1" ]] || [[ "$VERBOSE" == "1" ]]; then
        echo -e "${MAGENTA}🐛${NC} ${1}"
    fi
}

log_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  ${1}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_command() {
    if [[ "$DEBUG" == "1" ]]; then
        echo -e "${MAGENTA}→ ${1}${NC}"
    fi
}

# Exportar funciones
export -f log_info
export -f log_success
export -f log_error
export -f log_warn
export -f log_debug
export -f log_section
export -f log_command
