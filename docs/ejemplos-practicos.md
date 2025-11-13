# Ejemplos Prácticos: Implementación de Dotfiles Modular

## 🎯 Escenarios Reales de Uso

Este documento muestra ejemplos prácticos de cómo tu dotfiles funciona en diferentes situaciones.

---

## Escenario 1: Instalación en Desktop Ubuntu

### Paso a Paso

```bash
# 1. Clonar el repositorio
git clone https://github.com/VictorMaderaA/dotfiles.git
cd dotfiles

# 2. Ver qué se detecto
./install.sh --debug

# Output esperado:
# Entorno detectado:
#   Ubuntu: true
#   WSL: false
#   Desktop: true
#   Server: false
# Entorno: desktop

# 3. El script instalará:
✓ Paquetes base (git, curl, wget, etc)
✓ Shell tools (zsh, tmux, bat, ripgrep, etc)
✓ Dev tools (python, node, neovim, etc)
✓ Docker
✓ Apps GUI (gnome-terminal, nautilus, etc)
✗ Server tools (omitidos - no es server)

# 4. Resultado:
Desktop ubuntu completamente configurado
```

### Qué Pasó Internamente

```bash
# El install.sh orquestó esto:

scripts/installers/base.sh
  ├─ apt update
  ├─ apt install git curl wget build-essential
  └─ ... más paquetes base

scripts/installers/development.sh
  ├─ apt install python3 python3-pip nodejs npm
  └─ ... dev tools

scripts/installers/docker.sh
  ├─ curl get-docker.sh
  ├─ sudo sh get-docker.sh
  └─ sudo usermod -aG docker $USER

scripts/installers/desktop.sh
  ├─ apt install gnome-terminal nautilus
  └─ ... GUI apps

# Luego creó symlinks:
~/.zshrc → dotfiles/shell/.zshrc
~/.gitconfig → dotfiles/git/.gitconfig
~/.tmux.conf → dotfiles/tools/.tmux.conf
```

---

## Escenario 2: Instalación en WSL2

### Paso a Paso

```bash
# En WSL2 Ubuntu
$ ./install.sh --debug

# Output:
# Entorno detectado:
#   Ubuntu: true
#   WSL: true ✓
#   Desktop: false ✓ (automáticamente deshabilitado)
#   Server: false
# Entorno: wsl

# 3. El script instalará:
✓ Paquetes base
✓ Shell tools
✓ Dev tools
✓ Docker (pero con advertencia)
✗ Apps GUI (NO instala - no tiene sentido en WSL)
✗ Server tools

# 4. Advertencia especial:
⚠ WSL detectado - saltando Docker (instala Docker Desktop en Windows)
⚠ GUI deshabilitado en WSL (no hay display manager)
```

### Lo que WSL Detectó Automáticamente

```bash
# El script ejecutó:
uname -r
# Output: 5.4.72-microsoft-standard-WSL2

# Vio "microsoft" en el kernel → IS_WSL=true
systemctl list-units --all | grep -i "display-manager"
# Output: (vacío)

# No encontró display manager → IS_DESKTOP=false automáticamente
```

### Caso: Instalar Docker en WSL

```bash
# En WSL, cuando ejecuta docker.sh:

if [[ "$IS_WSL" == true ]]; then
    log_warn "WSL detectado - saltando Docker"
    log_info "Para usar Docker en WSL, instala Docker Desktop en Windows"
    log_info "Luego configura: Settings → Resources → WSL Integration"
    return 0
fi

# Resultado: Docker NO se instala en WSL (correcto)
# Se instala en Windows y se accede desde WSL
```

---

## Escenario 3: Instalación en Server Ubuntu

### Paso a Paso

```bash
# En servidor remoto
$ ssh user@servidor
$ cd dotfiles
$ ./install.sh

# Auto-detecta:
# Entorno detectado:
#   Ubuntu: true
#   WSL: false
#   Desktop: false
#   Server: true ✓ (no tiene display manager)
# Entorno: server

# Instala:
✓ Paquetes base
✓ Shell tools
✓ Dev tools
✓ Docker (para containerizar aplicaciones)
✓ Server tools (monitoreo, firewall, etc)
✗ Apps GUI (no tiene sentido)
```

### Instalaciones Específicas de Server

```bash
# scripts/installers/server.sh ejecutó:

log_section "Instalando herramientas de servidor"

pkg_install_if_needed "htop"        # Monitoreo
pkg_install_if_needed "iotop"       # I/O monitoring
pkg_install_if_needed "nethogs"     # Network monitoring
pkg_install_if_needed "curl"        # HTTP client
pkg_install_if_needed "wget"        # Download tool

# Configuró:
- SSH hardening
- Firewall rules
- System monitoring
- Log rotation
```

---

## Escenario 4: Múltiples Máquinas Diferentes

### Máquina 1: Laptop Desktop
```bash
$ ./install.sh

Detectó: Desktop
Instaló: Dev tools + GUI apps + Docker
Resultado: Ambiente de desarrollo completo
```

### Máquina 2: Servidor VPS
```bash
$ ./install.sh

Detectó: Server
Instaló: Dev tools + Docker (sin GUI)
Resultado: Servidor ligero y eficiente
```

### Máquina 3: WSL en Windows
```bash
$ ./install.sh

Detectó: WSL
Instaló: Dev tools (Docker de Windows)
Resultado: Entorno dev integrado con Windows
```

### Clave
```bash
# MISMO repositorio funciona en las 3 máquinas
# CADA UNA instala solo lo que necesita
# Sin necesidad de branches diferentes
# Sin necesidad de scripts separados
```

---

## Escenario 5: Agregar Nueva Herramienta

Imaginemos que quieres agregar `lazygit`:

### Método Tradicional (Plano)
1. Editar `install.sh` gigante
2. Encontrar la sección correcta
3. Añadir comando de instalación
4. Esperar a limpiar todo
5. Riesgo de romper algo

### Método Modular (Tu Nueva Estructura)

```bash
# 1. Crear nuevo script
cat > scripts/installers/tools.sh << 'EOF'
#!/bin/bash
source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../lib/package_manager.sh"

log_section "Instalando herramientas de terminal avanzadas"

# Lazygit
if ! command -v lazygit &> /dev/null; then
    log_info "Instalando lazygit..."
    go install github.com/jesseduffield/lazygit@latest
fi

# Otros tools
pkg_install_if_needed "ripgrep"
pkg_install_if_needed "fd-find"

log_success "Tools instalados"
EOF

chmod +x scripts/installers/tools.sh

# 2. Llamar desde install.sh principal
echo "bash scripts/installers/tools.sh" >> install.sh

# 3. Crear config en dotfiles
mkdir -p dotfiles/tools/lazygit
cat > dotfiles/tools/lazygit/config.yml << 'EOF'
gui:
  theme:
    activeBorderColor:
      - green
      - bold
  ...
EOF

# 4. Crear symlink
# (se hace automáticamente en link_dotfiles())

# 5. Commit
git add .
git commit -m "feat: añadir lazygit y config"
git push
```

**Resultado:**
- ✅ Cambio aislado en archivo nuevo
- ✅ No toca el install.sh principal
- ✅ Fácil de revertir
- ✅ Fácil de mantener
- ✅ Fácil de reutilizar

---

## Escenario 6: Customizar por Máquina

Imagina que tienes Desktop con 2 monitores y otro Desktop con 1 monitor.

### Opción 1: Configuración Común

```bash
# dotfiles/system/ubuntu/.ubuntu-desktop.conf
# Configuración que funciona en todos

TERMINAL_FONT="Monospace 12"
THEME="Adwaita"
```

### Opción 2: Customización Local

```bash
# ~/.config/dotfiles/local.conf
# Solo en esta máquina (gitignored)

MONITOR_PRIMARY="HDMI-1"
MONITOR_SECONDARY="HDMI-2"
RESOLUTION="3840x2160"
```

### Opción 3: Máquina Específica

```bash
# dotfiles/environments/desktop/hostname-specific.sh
# Por hostname específico

if [[ "$(hostname)" == "laptop-victor" ]]; then
    # Configuración para laptop
    TOUCHPAD_ENABLED=true
    BATTERY_MONITOR=true
elif [[ "$(hostname)" == "desktop-victor" ]]; then
    # Configuración para desktop
    TOUCHPAD_ENABLED=false
    EXTERNAL_MONITOR=true
fi
```

---

## Escenario 7: Actualizar Dotfiles en Todos Lados

Realizaste cambios en tu `.zshrc` y quieres actualizar en todas tus máquinas:

### Máquina 1: Hiciste cambio
```bash
cd ~/dotfiles
# Editaste: dotfiles/shell/.zshrc
git add .
git commit -m "feature: nuevo alias para docker"
git push
```

### Máquina 2: Actualizar
```bash
cd ~/dotfiles
git pull
# Los cambios se aplican automáticamente (symlinks)
# Si no funciona:
./install.sh  # Re-ejecuta (fast, todo ya existe)
```

### Máquina 3: WSL
```bash
cd ~/dotfiles
git pull
# Autoáticamente disponible
```

**Clave:** 
```bash
# Gracias a symlinks, todos están "linked" al mismo repo
# git pull → cambios disponibles inmediatamente
```

---

## Escenario 8: Recuperarse de Error

Accidentalmente editaste algo en `~/.gitconfig` directamente:

```bash
# Problema:
$ cat ~/.gitconfig
# Está editado manualmente, ya no está en sync

# Solución 1: Restaurar desde Git
cd ~/dotfiles
git checkout dotfiles/git/.gitconfig
# El symlink apunta a la version original

# Solución 2: Restaurar desde Backup
source scripts/lib/backup.sh
restore_backup ~/.gitconfig
# Restaura desde .dotfiles_backup/

# Solución 3: Re-instalar todo
./install.sh
# Verifica que todo es correcto
```

---

## Escenario 9: Colaborar en Equipo

Tu equipo también usa dotfiles:

```bash
# Tu repo
git clone https://github.com/VictorMaderaA/dotfiles.git

# Cada persona ejecuta en su máquina
./install.sh  # Auto-detecta y configura

# Mejoras compartidas
git pull origin main  # Todos obtenemos las mejoras

# Customización personal (gitignored)
~/.dotfiles_local/  # Personal, no tracked
```

---

## Escenario 10: Testing en Contenedor

Probar tu dotfiles en un entorno limpio:

```bash
# Dockerfile de test
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y git

WORKDIR /home/user
RUN git clone https://github.com/VictorMaderaA/dotfiles.git

WORKDIR /home/user/dotfiles

# Probar auto-detección
RUN ./install.sh --debug

# Validar
RUN tests/test_environment.sh
RUN tests/test_symlinks.sh
```

**Resultado:**
```bash
$ docker build -t dotfiles-test .

# Output:
✓ Auto-detección correcta
✓ Paquetes instalados
✓ Symlinks creados
✓ Tests pasaron
```

---

## Resumen de Casos de Uso

| Caso | Solución |
|------|----------|
| Nueva máquina | `./install.sh` - auto-detecta |
| Agregar tool | Nuevo script en `scripts/installers/` |
| Customizar | Local `.conf` files (gitignored) |
| Actualizar | `git pull` (symlinks se aplican) |
| Recuperarse | Backups automáticos o Git |
| Equipo | Mismo repo, cada uno ejecuta |
| Testing | Tests incluidos en `tests/` |
| Debug | `./install.sh --debug` |
| WSL vs Desktop | Auto-detección automática |

---

## Tips Profesionales

### 1. Alias para Update
```bash
alias dotfiles-update='cd ~/dotfiles && git pull && ./install.sh'
```

### 2. Cron Job
```bash
# Backup diario
0 2 * * * ~/dotfiles/scripts/lib/backup.sh

# Update semanal
0 0 * * 0 ~/dotfiles/scripts/hooks/post-install.sh
```

### 3. Pre-commit Hook
```bash
# .git/hooks/pre-commit
#!/bin/bash
bash tests/test_symlinks.sh || exit 1
```

### 4. Documentar Cambios
```bash
git commit -m "feat: nueva configuración X

- Qué cambió
- Por qué cambió
- Cómo verificar que funciona"
```

---

## 🎉 Conclusión

Con esta estructura:
- ✅ Escalas fácilmente
- ✅ Colaboras con equipo
- ✅ Mantienes múltiples máquinas
- ✅ Evitas errores
- ✅ Documentas cambios
- ✅ Haces backup automático

**¡Es un sistema completo y profesional!**
