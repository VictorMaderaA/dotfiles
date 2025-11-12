# Plan de Acción: Migración de tu Dotfiles

## 📋 Resumen Ejecutivo

Se te proporcionan:
- **7 archivos de scripts** (detectores, logging, backup, instalador)
- **1 guía completa** con estructura y mejores prácticas
- **Documentación** de cada componente
- **Ejemplos** de configuración

Todo está diseñado para que en **30-45 minutos** tengas un dotfiles **profesional, escalable y auto-detectable**.

---

## 🎯 Fase 1: Preparación (5-10 min)

### 1.1 Backup de tu repo actual
```bash
cd ~/dotfiles
git status
git log --oneline -5

# Crear rama de backup
git checkout -b backup/original-structure
git push origin backup/original-structure
```

### 1.2 Crear estructura de carpetas
```bash
mkdir -p scripts/{lib,core,installers,hooks}
mkdir -p dotfiles/{shell,git,ssh,editors,tools,system}
mkdir -p environments/{desktop,server,wsl,common}
mkdir -p docs tests config templates

# Verificar
tree -d -L 2
```

---

## 🔧 Fase 2: Implementar Scripts Base (10-15 min)

### 2.1 Copiar scripts de libería a `scripts/lib/`

Copia estos 4 archivos:
1. `detect_environment.sh` → Detección de entorno
2. `logging.sh` → Sistema de logging
3. `package_manager.sh` → Abstracción package manager
4. `backup.sh` → Gestión de backups

### 2.2 Copiar install.sh a root
```bash
cp install.sh ./install.sh
chmod +x install.sh
```

### 2.3 Verificar que funciona la detección
```bash
source scripts/lib/detect_environment.sh
detect_environment
show_environment_info

# Debería mostrar:
# Ubuntu: true/false
# WSL: true/false
# Desktop: true/false
# Server: true/false
```

---

## 📦 Fase 3: Migrar tus Dotfiles (5-10 min)

### 3.1 Mover archivos de configuración

Si tienes estos archivos en tu home o repo, muévelos:

```bash
# Shell
cp ~/.zshrc dotfiles/shell/.zshrc 2>/dev/null || echo "No existe .zshrc"
cp ~/.bashrc dotfiles/shell/.bashrc 2>/dev/null || echo "No existe .bashrc"

# Git
cp ~/.gitconfig dotfiles/git/.gitconfig 2>/dev/null || echo "No existe .gitconfig"
cp ~/.gitignore_global dotfiles/git/.gitignore_global 2>/dev/null || echo "No existe"

# SSH (si existen)
[[ -f ~/.ssh/config ]] && cp ~/.ssh/config dotfiles/ssh/config

# Otros
cp ~/.tmux.conf dotfiles/tools/.tmux.conf 2>/dev/null || echo "No existe"
cp ~/.vimrc dotfiles/editors/.vimrc 2>/dev/null || echo "No existe"
```

### 3.2 Si no existen estos archivos, créalos

```bash
# Crear .zshrc básico
cat > dotfiles/shell/.zshrc << 'EOF'
# Configuration for Zsh
export ZSH_CUSTOM="$HOME/.config/zsh"

# Source common aliases
[[ -f ~/.shell_aliases ]] && source ~/.shell_aliases

# Source starship prompt
eval "$(starship init zsh)"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Keybindings (vim-like)
bindkey -v
EOF

# Crear .gitconfig básico
cat > dotfiles/git/.gitconfig << 'EOF'
[user]
    name = "Tu Nombre"
    email = "tu.email@example.com"

[core]
    editor = vim
    excludesFile = ~/.gitignore_global

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --all

[init]
    defaultBranch = main
EOF

# Crear .tmux.conf básico
cat > dotfiles/tools/.tmux.conf << 'EOF'
# Set prefix to Ctrl-a
set -g prefix C-a
bind C-a send-prefix
unbind C-b

# Mouse support
set -g mouse on

# Window numbering from 1
set -g base-index 1

# Status bar
set -g status-bg black
set -g status-fg white
EOF
```

---

## 🔄 Fase 4: Crear Instaladores Modulares (10-15 min)

### 4.1 Si ya tienes un script de instalación grande

Extrae secciones en scripts modulares:

```bash
# scripts/installers/base.sh
#!/bin/bash
source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../lib/package_manager.sh"

log_section "Instalando paquetes base"
detect_package_manager
pkg_update

base_packages=(
    git curl wget build-essential
    software-properties-common ca-certificates
)

for pkg in "${base_packages[@]}"; do
    pkg_install_if_needed "$pkg"
done

log_success "Paquetes base instalados"
```

```bash
# scripts/installers/development.sh
#!/bin/bash
source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../lib/package_manager.sh"

log_section "Instalando herramientas de desarrollo"
detect_package_manager

dev_packages=(
    git git-flow neovim python3 python3-pip nodejs npm
)

for pkg in "${dev_packages[@]}"; do
    pkg_install_if_needed "$pkg"
done

log_success "Dev tools instalados"
```

### 4.2 Si no tienes script existente

Los 7 archivos proporcionados incluyen un `install.sh` completo que ya hace todo esto.

---

## ⚙️ Fase 5: Crear Configuraciones por Entorno (5-10 min)

### 5.1 Crear archivos de configuración

```bash
# config/environments.conf
# (Copia el archivo proporcionado)

# environments/desktop/applications.conf
APPS_DESKTOP="
    gnome-terminal
    nautilus
    gedit
"

# environments/server/services.conf
SERVICES_ENABLED="
    ssh
    fail2ban
    ufw
"

# environments/wsl/interop.sh
#!/bin/bash
# Configuración específica WSL
log_info "Configurando WSL interop..."
```

---

## 🧪 Fase 6: Testing (5 min)

### 6.1 Probar en tu máquina actual

```bash
# Hacer test sin instalar
./install.sh --debug --verbose

# Ver qué haría sin ejecutar nada (simulación)
DEBUG=1 VERBOSE=1 bash -x ./install.sh 2>&1 | head -50
```

### 6.2 Crear un test simple

```bash
# tests/test_detection.sh
#!/bin/bash
source "scripts/lib/detect_environment.sh"
detect_environment
show_environment_info

if [[ "$(get_environment_name)" != "unknown" ]]; then
    echo "✓ Test passed"
    exit 0
else
    echo "✗ Test failed"
    exit 1
fi

chmod +x tests/test_detection.sh
./tests/test_detection.sh
```

---

## 📝 Fase 7: Documentación (5-10 min)

### 7.1 Crear README básico

```bash
cat > README.md << 'EOF'
# Dotfiles - Victor Madera

Auto-configuración de Ubuntu/WSL/Server con detección automática de entorno.

## Instalación Rápida

```bash
git clone https://github.com/VictorMaderaA/dotfiles.git
cd dotfiles
./install.sh
```

## Características

- ✅ Detección automática de entorno
- ✅ Instalación modular
- ✅ Backup automático
- ✅ Soporta Desktop, WSL, Server

## Entornos Soportados

| Entorno | Detección | GUI Apps | Dev Tools |
|---------|-----------|----------|-----------|
| Desktop | Auto ✓ | ✓ | ✓ |
| WSL | Auto ✓ | ✗ | ✓ |
| Server | Auto ✓ | ✗ | ✓ |

## Uso

```bash
./install.sh          # Auto-detección
./install.sh --debug  # Ver qué hace
./install.sh --env desktop  # Forzar entorno
```

## Estructura

```
scripts/lib/    - Funciones reutilizables
scripts/core/   - Configuración base
scripts/installers/ - Instaladores modulares
dotfiles/       - Archivos de configuración
environments/   - Config por entorno
```
EOF
```

### 7.2 Crear INSTALL.md

```bash
cat > docs/INSTALL.md << 'EOF'
# Guía de Instalación

## Requisitos

- Linux (Ubuntu/Debian)
- Git
- Conexión a internet

## Paso a paso

1. Clonar el repo
2. Ejecutar install.sh
3. Reiniciar sesión
4. ¡Listo!

## Troubleshooting

Si algo falla:
1. Ejecuta con `--debug`
2. Revisa logs en `.dotfiles_backup/`
3. Restaura desde backup si es necesario
EOF
```

---

## 🚀 Fase 8: Commit y Push (5 min)

### 8.1 Agregar a Git

```bash
cd ~/dotfiles

# Ver cambios
git status

# Agregar todo
git add .

# Commit
git commit -m "refactor: nueva estructura modular con auto-detección de entorno

- Reorganizado con scripts/lib, scripts/core, scripts/installers
- Añadida detección automática: Desktop/WSL/Server
- Sistema modular y escalable
- Logging consistente y backup automático
- Documentación completa"

# Push
git push origin main
```

### 8.2 Tag de versión

```bash
git tag -a v2.0.0 -m "Refactor: estructura modular con auto-detección"
git push origin v2.0.0
```

---

## ✅ Checklist Final

- [ ] Estructura de carpetas creada
- [ ] Scripts de librería copiados
- [ ] install.sh copiado y funcionando
- [ ] Dotfiles movidos a carpetas correctas
- [ ] Instaladores modulares creados
- [ ] Configuraciones por entorno preparadas
- [ ] Tests creados y pasando
- [ ] Documentación escrita
- [ ] Cambios commiteados
- [ ] Todo pusheado a GitHub

---

## ⏱️ Tiempo Total Estimado

- Fase 1 (Prep): 5-10 min
- Fase 2 (Scripts): 10-15 min
- Fase 3 (Dotfiles): 5-10 min
- Fase 4 (Instaladores): 10-15 min
- Fase 5 (Entornos): 5-10 min
- Fase 6 (Testing): 5 min
- Fase 7 (Docs): 5-10 min
- Fase 8 (Git): 5 min

**Total: 50-85 minutos** (promedio 1 hora)

---

## 🎯 Resultado Final

Tendrás:
- ✅ Dotfiles profesional y modular
- ✅ Auto-detección de entorno
- ✅ Instalación limpia y repetible
- ✅ Fácil de mantener y expandir
- ✅ Documentado
- ✅ Control de versiones

---

## 📚 Archivos Proporcionados

### Scripts (7 archivos):
1. `detect_environment.sh` - Detección inteligente
2. `logging.sh` - Sistema de logging
3. `package_manager.sh` - Abstracción de pkg manager
4. `backup.sh` - Backup de archivos
5. `install.sh` - Script principal
6. `environments.conf` - Config por entorno
7. `dotfiles-guide.md` - Guía detallada

### Documentos:
- README.md - Descripción general
- Guía de arquitectura
- Ejemplos de configuración

---

## 🎉 ¡Adelante!

Tu dotfiles estará listo en menos de 2 horas y será:
- **Profesional** 🏆
- **Escalable** 📈
- **Mantenible** 🔧
- **Robusto** 💪
- **Flexible** 🎨

¡Que disfrutes de tu nuevo setup!

---

## 💬 Preguntas Comunes

**P: ¿Perderé mi configuración antigua?**
R: No. Todos los archivos se respaldan automáticamente en `.dotfiles_backup/`

**P: ¿Puedo probar sin instalar?**
R: Sí, ejecuta con `--debug` para ver qué haría

**P: ¿Funciona en múltiples máquinas?**
R: Sí. Cada una detecta su entorno automáticamente

**P: ¿Qué pasa si algo sale mal?**
R: Revisa `.dotfiles_backup/` o ejecuta `--debug` para ver qué falló

**P: ¿Puedo customizarlo?**
R: Totalmente. Toda la estructura es modular y extensible
