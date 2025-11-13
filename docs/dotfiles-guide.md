# Guía de Estructura Recomendada para tu Dotfiles

## 📋 Resumen Ejecutivo

Se propone una estructura modular y escalable que permite:
- ✅ Detectar automáticamente el entorno (Ubuntu Desktop, WSL, Server)
- ✅ Instalar solo lo relevante para cada ambiente
- ✅ Mantener configuraciones compartidas y específicas por entorno
- ✅ Fácil expansión y mantenimiento
- ✅ Simlinks de archivos de configuración para control de versiones

---

## 🏗️ Estructura Recomendada

```
dotfiles/
├── README.md
├── LICENSE
├── .gitignore
├── install.sh                    # Script principal (entry point)
├── uninstall.sh
│
├── scripts/
│   ├── lib/                      # Funciones compartidas reutilizables
│   │   ├── utils.sh
│   │   ├── detect_environment.sh  # CRÍTICO: Detección del entorno
│   │   ├── package_manager.sh    # Abstracción para apt/pacman/etc
│   │   ├── logging.sh
│   │   └── backup.sh
│   │
│   ├── core/                     # Configuraciones esenciales
│   │   ├── system.sh
│   │   ├── shell.sh
│   │   ├── git.sh
│   │   └── ssh.sh
│   │
│   ├── installers/               # Scripts de instalación modulares
│   │   ├── base.sh               # Herramientas base (todos los entornos)
│   │   ├── development.sh        # Dev tools
│   │   ├── desktop.sh            # GUI apps (SOLO desktop)
│   │   ├── terminal.sh           # Terminal tools
│   │   ├── docker.sh
│   │   ├── languages.sh
│   │   └── server.sh             # Config específica de servidores
│   │
│   └── hooks/
│       ├── post-install.sh
│       └── environment-specific.sh
│
├── dotfiles/                     # Archivos de configuración (symlinks)
│   ├── shell/
│   │   ├── .zshrc
│   │   ├── .bashrc
│   │   ├── aliases/
│   │   │   ├── common.sh
│   │   │   ├── development.sh
│   │   │   ├── git.sh
│   │   │   └── docker.sh
│   │   ├── functions/
│   │   │   ├── common.sh
│   │   │   └── utilities.sh
│   │   └── themes/
│   │       ├── p10k.zsh
│   │       └── starship.toml
│   │
│   ├── git/
│   │   ├── .gitconfig
│   │   ├── .gitignore_global
│   │   ├── gitmessage
│   │   └── git-templates/
│   │
│   ├── ssh/
│   │   ├── config
│   │   └── config.d/
│   │
│   ├── editors/
│   │   ├── .vimrc
│   │   ├── .editorconfig
│   │   └── vscode/settings.json
│   │
│   ├── tools/
│   │   ├── .tmux.conf
│   │   ├── .inputrc
│   │   └── lazygit/config.yml
│   │
│   └── system/
│       ├── ubuntu/
│       │   └── dconf/
│       └── wsl/
│           └── .wslconfig
│
├── environments/                 # Configuraciones específicas por entorno
│   ├── desktop/
│   │   ├── applications.conf
│   │   └── keybindings/
│   │
│   ├── server/
│   │   ├── services.conf
│   │   ├── monitoring.sh
│   │   └── firewall.sh
│   │
│   ├── wsl/
│   │   ├── wsl.conf
│   │   ├── interop.sh
│   │   └── ports.sh
│   │
│   └── common/
│       └── essential.conf
│
├── templates/
│   ├── .env.example
│   ├── ssh-config.template
│   └── hostname.template
│
├── docs/
│   ├── INSTALL.md
│   ├── ENVIRONMENTS.md
│   ├── CUSTOMIZATION.md
│   ├── TROUBLESHOOTING.md
│   └── ARCHITECTURE.md
│
├── tests/
│   ├── test_environment.sh
│   ├── test_symlinks.sh
│   └── test_packages.sh
│
└── config/
    ├── environments.conf
    ├── packages.conf
    └── versions.conf
```

---

## 🔍 Sistema de Detección de Entorno

### Script `scripts/lib/detect_environment.sh`

```bash
#!/bin/bash

# Detecta el entorno actual y define variables globales
detect_environment() {
    local uname_s=$(uname -s)
    local uname_r=$(uname -r)
    
    # Inicializar flags
    export IS_UBUNTU=false
    export IS_WSL=false
    export IS_DESKTOP=false
    export IS_SERVER=false
    
    # 1. Detectar si es Linux
    if [[ "$uname_s" == "Linux" ]]; then
        # 2. Detectar si es WSL (buscar "microsoft" o "wsl" en kernel)
        if [[ "$uname_r" =~ [Mm]icrosoft|[Ww][Ss][Ll] ]]; then
            export IS_WSL=true
            export IS_UBUNTU=true
        else
            export IS_UBUNTU=true
            
            # 3. Detectar si es Desktop o Server
            if systemctl list-units --all | grep -q "display-manager\|sddm\|lightdm\|gdm"; then
                export IS_DESKTOP=true
            else
                export IS_SERVER=true
            fi
        fi
    else
        echo "ERROR: Este script solo soporta Linux"
        exit 1
    fi
    
    # Validación: en WSL no puede ser desktop
    if [[ "$IS_WSL" == true && "$IS_DESKTOP" == true ]]; then
        export IS_DESKTOP=false
    fi
    
    # Mostrar información detectada
    if [[ "${VERBOSE:-false}" == true ]]; then
        echo "Entorno detectado:"
        echo "  Ubuntu: $IS_UBUNTU"
        echo "  WSL: $IS_WSL"
        echo "  Desktop: $IS_DESKTOP"
        echo "  Server: $IS_SERVER"
    fi
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
```

### Ejemplos de Detección:

| Entorno | IS_WSL | IS_DESKTOP | IS_SERVER | Acción |
|---------|--------|-----------|-----------|--------|
| Ubuntu Desktop | false | true | false | Instala GUI apps + dev tools |
| WSL2 Ubuntu | true | false | false | Solo tools CLI, NO GUI |
| Ubuntu Server | false | false | true | Server tools, monitoring |

---

## 📦 Sistema Modular de Instaladores

Cada archivo en `scripts/installers/` es independiente y controlado por flags:

### `install.sh` (Script Principal)

```bash
#!/bin/bash

# Sourcing librerías
source "$(dirname "$0")/scripts/lib/detect_environment.sh"
source "$(dirname "$0")/scripts/lib/utils.sh"
source "$(dirname "$0")/scripts/lib/package_manager.sh"
source "$(dirname "$0")/scripts/lib/logging.sh"
source "$(dirname "$0")/scripts/lib/backup.sh"

# Detectar ambiente
detect_environment
ENV=$(get_environment_name)

log_info "Instalando dotfiles para entorno: $ENV"

# Instalar categorías base (siempre)
bash scripts/installers/base.sh

# Instalar herramientas de desarrollo (siempre)
bash scripts/installers/development.sh

# Instaladores condicionales
if [[ "$IS_DESKTOP" == true ]]; then
    log_info "Desktop detectado - instalando GUI apps"
    bash scripts/installers/desktop.sh
else
    log_warn "Desktop no detectado - omitiendo GUI apps"
fi

if [[ "$IS_SERVER" == true ]]; then
    log_info "Server detectado - instalando herramientas de servidor"
    bash scripts/installers/server.sh
fi

if [[ "$IS_WSL" == true ]]; then
    log_info "WSL detectado - saltando apps gráficas"
fi

# Instalar core config (siempre)
bash scripts/core/system.sh
bash scripts/core/shell.sh
bash scripts/core/git.sh
bash scripts/core/ssh.sh

# Hooks finales
bash scripts/hooks/post-install.sh

log_success "Instalación completada"
```

---

## 🔗 Sistema de Symlinks

### `scripts/core/shell.sh` Ejemplo

```bash
#!/bin/bash

source "$(dirname "$0")/../lib/utils.sh"
source "$(dirname "$0")/../lib/backup.sh"

link_dotfiles() {
    local dotfiles_dir="$(dirname "$0")/../../dotfiles"
    local home="$HOME"
    
    # Symlinks de shell
    backup_if_exists "$home/.zshrc"
    ln -sf "$dotfiles_dir/shell/.zshrc" "$home/.zshrc"
    
    backup_if_exists "$home/.bashrc"
    ln -sf "$dotfiles_dir/shell/.bashrc" "$home/.bashrc"
    
    # Git config
    backup_if_exists "$home/.gitconfig"
    ln -sf "$dotfiles_dir/git/.gitconfig" "$home/.gitconfig"
    
    log_success "Symlinks creados exitosamente"
}

link_dotfiles
```

---

## 🚀 Flujo de Instalación

```
1. Usuario ejecuta: ./install.sh

2. Sistema detecta entorno
   ├─ ¿Es WSL? → Omite GUI
   ├─ ¿Es Desktop? → Instala GUI apps
   └─ ¿Es Server? → Config especial servidor

3. Instala categorías (ordenadamente):
   ├─ Base tools (apt update, git, curl, etc.)
   ├─ Dev tools (node, python, go, etc.)
   ├─ Condicional: Desktop apps (si IS_DESKTOP)
   ├─ Condicional: Server tools (si IS_SERVER)
   └─ Core config (shell, git, ssh)

4. Crea symlinks para dotfiles

5. Ejecuta hooks post-install

6. Tests de validación
```

---

## 💾 Archivo de Configuración: `config/environments.conf`

```bash
# environments.conf - Define qué instalar en cada entorno

# Entorno: DESKTOP
[desktop]
install_gui_apps=true
install_dev_tools=true
install_docker=true
enable_systemd_user_services=true
install_media_tools=false

# Entorno: SERVER
[server]
install_gui_apps=false
install_dev_tools=true
install_docker=true
enable_systemd_services=true
install_monitoring=true
enable_firewall=true

# Entorno: WSL
[wsl]
install_gui_apps=false
install_dev_tools=true
install_docker=true
enable_windows_interop=true
setup_ssh_passthrough=true

# Entorno: COMMON (Todos)
[common]
install_base_tools=true
install_shell_tools=true
configure_git=true
configure_ssh=true
```

---

## 📋 Archivo de Paquetes: `config/packages.conf`

```bash
# packages.conf - Definir qué paquetes instalar

# Herramientas base (siempre)
PACKAGES_BASE="
    git
    curl
    wget
    build-essential
    software-properties-common
    python3
    python3-pip
"

# Herramientas de desarrollo (siempre)
PACKAGES_DEV="
    nodejs
    npm
    docker.io
    docker-compose
    tmux
    vim
    neovim
"

# Apps GUI (solo desktop)
PACKAGES_DESKTOP="
    gimp
    vlc
    vscode
    gnome-shell-extension-manager
"

# Monitoreo (solo server)
PACKAGES_SERVER="
    htop
    iotop
    nethogs
    prometheus
    grafana
"

# Herramientas terminales (siempre)
PACKAGES_TERMINAL="
    zsh
    starship
    bat
    exa
    ripgrep
    fzf
"
```

---

## 🧪 Tests de Validación: `tests/test_environment.sh`

```bash
#!/bin/bash

# Validar que el entorno se detectó correctamente

source "$(dirname "$0")/../scripts/lib/detect_environment.sh"
source "$(dirname "$0")/../scripts/lib/logging.sh"

test_environment_detection() {
    detect_environment
    
    ENV=$(get_environment_name)
    log_info "Entorno detectado: $ENV"
    
    case $ENV in
        wsl)
            [[ "$IS_WSL" == true ]] && log_success "WSL detectado correctamente" || log_error "Falló detección WSL"
            [[ "$IS_DESKTOP" == false ]] && log_success "GUI deshabilitado en WSL" || log_error "GUI no debería estar en WSL"
            ;;
        desktop)
            [[ "$IS_DESKTOP" == true ]] && log_success "Desktop detectado" || log_error "Falló detección Desktop"
            ;;
        server)
            [[ "$IS_SERVER" == true ]] && log_success "Server detectado" || log_error "Falló detección Server"
            ;;
        *)
            log_error "Entorno desconocido"
            exit 1
            ;;
    esac
}

test_environment_detection
```

---

## 📖 Ventajas de Esta Estructura

### 1. **Escalabilidad**
   - Nuevo entorno? Solo añade carpeta en `environments/`
   - Nuevo installer? Solo crea script en `scripts/installers/`
   - Fácil de expandir sin tocar código existente

### 2. **Mantenibilidad**
   - Cada herramienta/categoría tiene su propio script
   - Cambios isolados, menos riesgo de romper algo
   - Fácil de debuggear problemas

### 3. **Reusabilidad**
   - Funciones comunes en `scripts/lib/`
   - Reutilizables en cualquier script
   - DRY (Don't Repeat Yourself)

### 4. **Confiabilidad**
   - Detección automática del entorno
   - Tests de validación
   - Backup de archivos antes de sobrescribir
   - Logging detallado de cada paso

### 5. **Flexibilidad**
   - Instalación selectiva por categoría
   - Configuración específica por máquina
   - Compatible con múltiples distribuciones

---

## 🎯 Pasos para Migrar tu Proyecto

### Paso 1: Crear estructura base
```bash
mkdir -p scripts/{lib,core,installers,hooks}
mkdir -p dotfiles/{shell,git,ssh,editors,tools,system}
mkdir -p environments/{desktop,server,wsl,common}
mkdir -p docs tests config templates
```

### Paso 2: Mover configuraciones
```bash
# Mueve tus .zshrc, .gitconfig, etc. a dotfiles/
mv ~/.zshrc dotfiles/shell/.zshrc
mv ~/.gitconfig dotfiles/git/.gitconfig
```

### Paso 3: Crear scripts de librería
- Copia `detect_environment.sh` a `scripts/lib/`
- Crea `scripts/lib/utils.sh` con funciones comunes
- Crea `scripts/lib/logging.sh` para logging

### Paso 4: Convertir instaladores a scripts modulares
- Extrae cada sección de tu script a `scripts/installers/`
- Haz cada installer independiente

### Paso 5: Crear install.sh central
- Orquesta los installers llamándolos en orden
- Usa la detección de entorno

---

## 📝 Archivo de Configuración Recomendado

Crea `config/environments.conf` como definición única del qué instalar dónde. Esto permite:
- Cambios fáciles sin tocar scripts
- Una "fuente de verdad" para configuración
- Fácil para usuarios sin conocimiento técnico

---

## 🔒 Seguridad y Buenas Prácticas

1. **Nunca commitees secretos**: Usa `.gitignore` para excluir:
   - `.ssh/` (claves privadas)
   - `.env` (credenciales)
   - Archivos con sensible info

2. **Backup automático**: Siempre haz backup antes de crear symlinks

3. **Validación**: Tests post-install para verificar que todo funcionó

4. **Documentación**: README claro para nuevos usuarios

---

## 🚀 Próximos Pasos

1. Organiza tu repo con esta estructura
2. Implementa `detect_environment.sh`
3. Modulariza tus instaladores
4. Añade documentación en `docs/`
5. Crea tests en `tests/`
6. Prueba en los tres entornos (Desktop, WSL, Server)

¡Así tendrás un dotfiles robusto y profesional! 🎉
