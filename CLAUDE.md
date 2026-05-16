# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este repositorio

Dotfiles profesional y auto-adaptable para entornos Linux (Ubuntu/Fedora/Arch). Despliega un entorno de desarrollo completo mediante symlinks y scripts modulares.

## Instalación y uso

```bash
# Instalación completa con detección automática de entorno
./install.sh

# Opciones disponibles
./install.sh --verbose        # Información detallada
./install.sh --debug          # Muestra cada comando ejecutado
./install.sh --no-backup      # No hacer backup de archivos existentes
./install.sh --no-tui         # Sin interfaz interactiva
./install.sh --env <entorno>  # Forzar entorno: wsl | desktop | server
```

## Tests

Los tests usan Docker para probar en múltiples distros:

```bash
# Probar en Ubuntu
docker build -f tests/Dockerfile.ubuntu -t dotfiles-test-ubuntu . && docker run dotfiles-test-ubuntu

# Probar en Fedora
docker build -f tests/Dockerfile.fedora -t dotfiles-test-fedora . && docker run dotfiles-test-fedora

# Probar en Arch
docker build -f tests/Dockerfile.arch -t dotfiles-test-arch . && docker run dotfiles-test-arch
```

No hay linter ni test runner automatizado; la validación es manual con Docker.

## Arquitectura

### Flujo de `install.sh`

```
install.sh
  → detect_environment.sh  (wsl / desktop / server)
  → installers/base.sh     (git, curl, build-essential, jq...)
  → installers/terminal.sh (zsh, tmux, starship, nerd-fonts)
  → installers/development.sh (git-flow, neovim, python, node, aws-cli)
  → installers/docker.sh   (solo si no es server)
  → installers/desktop.sh  (solo si IS_DESKTOP)
  → installers/server.sh   (solo si IS_SERVER)
  → Crea symlinks según config/symlinks.conf
  → Init .env.local y dotfiles/ssh/config.local desde templates
  → Backup automático en .dotfiles_backup/
```

### Sistema de symlinks

`config/symlinks.conf` define los mapeos `origen:destino`. El script crea symlinks recursivamente, incluyendo archivos ocultos. Los archivos preexistentes se guardan en `.dotfiles_backup/` con timestamp antes de sobrescribir.

### Estándar de terminal remota

El repositorio ya centraliza la capa que suele romperse por SSH, tmux y distintos clientes de terminal:

- `dotfiles/shell/.terminal-env` define defaults compartidos de `LANG`, `LC_ALL` y un fallback seguro de `TERM`.
- `dotfiles/shell/.bashrc`, `dotfiles/shell/.zshrc` y `dotfiles/shell/.profile` cargan ese bloque común para que login shells, shells interactivos y sesiones remotas se comporten igual.
- `dotfiles/tools/.tmux.conf` fija los defaults comunes de tmux: `tmux-256color`, `RGB`, `escape-time 0`, `focus-events on`, `history-limit` alto y `set-clipboard on`.
- `dotfiles/ssh/config` concentra los defaults compartidos de SSH. Los overrides por máquina o secretos siguen yendo a `dotfiles/ssh/config.local`.

Regla práctica: si un ajuste afecta a todas tus máquinas, va en el fragmento compartido o en `ssh/config`; si cambia por host, usuario o secreto, va en `config.local` o `.env.local`.

### Librerías reutilizables (`scripts/lib/`)

| Archivo | Propósito |
|---------|-----------|
| `detect_environment.sh` | Exporta `IS_WSL`, `IS_DESKTOP`, `IS_SERVER`, `IS_UBUNTU` |
| `logging.sh` | Funciones `log_info`, `log_success`, `log_error`, `log_warn`, `log_debug` |
| `package_manager.sh` | Abstracción multi-distro: `pkg_install`, `pkg_is_installed`, `pkg_update` (soporta apt, pacman, dnf/yum) |
| `backup.sh` | `backup_if_exists`, `restore_backup`, `list_backups` |

Todos los instaladores sourcea estas librerías para detección, logging y gestión de paquetes.

### Configuración local (no versionada)

- `dotfiles/shell/.env.local` — variables privadas (tokens, credenciales). Se inicializa vacío si no existe.
- `dotfiles/ssh/config.local` — hosts SSH privados. Se genera desde `config.local.template` usando `envsubst`.

### Herramientas en `bin/`

- **`translate-srt`** / **`translate-srt-core/`** — traduce subtítulos SRT usando OpenAI API (Node.js). Requiere `OPENAI_API_KEY` en `.env.local`.
- **`web/password-gen.html`** — generador de contraseñas standalone (HTML puro).
- **`web/md-aggregator.html`** — agrega archivos markdown para contexto de LLMs (HTML puro).

## Convenciones al modificar el repositorio

- Cada instalador en `scripts/installers/` debe sourcea las librerías de `scripts/lib/` y usar `pkg_install` en vez de llamar `apt`/`pacman` directamente.
- Al agregar un nuevo dotfile, añadir la entrada correspondiente en `config/symlinks.conf`.
- Las configs sensibles (tokens, hosts SSH privados) van en archivos `.local` no versionados.
- Los instaladores que solo aplican a ciertos entornos deben verificar `IS_WSL`/`IS_DESKTOP`/`IS_SERVER` antes de ejecutar.
