#!/bin/bash

# config/environments.conf
# Definición central de qué instalar en cada entorno
# Sourcing: source config/environments.conf

# ============================================================================
# ENTORNO: DESKTOP (Ubuntu con GUI)
# ============================================================================
[desktop]
# Herramientas de desarrollo
INSTALL_NODEJS=true
INSTALL_PYTHON=true
INSTALL_DOCKER=true
INSTALL_GIT=true

# Aplicaciones GUI
INSTALL_VSCODE=true
INSTALL_TERMINAL=true
INSTALL_FILE_MANAGER=true
INSTALL_MEDIA_TOOLS=false

# Configuraciones
ENABLE_SYSTEMD_USER=true
INSTALL_FONT_TOOLS=true
SETUP_THEMES=true

# ============================================================================
# ENTORNO: SERVER (Ubuntu sin GUI)
# ============================================================================
[server]
# Herramientas de desarrollo
INSTALL_NODEJS=true
INSTALL_PYTHON=true
INSTALL_DOCKER=true
INSTALL_GIT=true

# Aplicaciones GUI (NO)
INSTALL_VSCODE=false
INSTALL_TERMINAL=false
INSTALL_FILE_MANAGER=false

# Configuraciones
ENABLE_SYSTEMD_SERVICES=true
INSTALL_MONITORING_TOOLS=true
INSTALL_FIREWALL_TOOLS=true
SETUP_SSH_HARDENING=true

# ============================================================================
# ENTORNO: WSL (Windows Subsystem for Linux)
# ============================================================================
[wsl]
# Herramientas de desarrollo
INSTALL_NODEJS=true
INSTALL_PYTHON=true
INSTALL_DOCKER=false          # Docker Desktop en Windows
INSTALL_GIT=true

# Aplicaciones GUI (NO - usar Windows)
INSTALL_VSCODE=false          # Usar Remote WSL extension
INSTALL_TERMINAL=false
INSTALL_FILE_MANAGER=false

# Configuraciones
ENABLE_WINDOWS_INTEROP=true
SETUP_SSH_PASSTHROUGH=true
LIMIT_WSL_RAM=true
INSTALL_WINDOWS_LAUNCHER=true

# ============================================================================
# CONFIGURACIÓN COMÚN (Todos)
# ============================================================================
[common]
# Core tools
INSTALL_GIT=true
INSTALL_CURL=true
INSTALL_WGET=true
INSTALL_ZSH=true
INSTALL_TMUX=true

# Shell tools
INSTALL_BAT=true
INSTALL_EXA=true
INSTALL_RIPGREP=true
INSTALL_FZF=true
INSTALL_STARSHIP=true

# Configuración
SETUP_GIT_CONFIG=true
SETUP_SSH_CONFIG=true
LINK_DOTFILES=true
CREATE_ALIASES=true
