# dotfiles

Entorno de desarrollo profesional, modular y auto-adaptable para Linux (Ubuntu, Fedora, Arch). Detecta automáticamente el entorno y despliega solo lo relevante.

> **Para agentes de código (Claude Code, Copilot, Cursor, etc.):** el archivo de referencia principal es [`CLAUDE.md`](./CLAUDE.md).

---

## Instalación

```bash
git clone https://github.com/VictorMaderaA/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Opciones

| Flag | Efecto |
|------|--------|
| `--verbose` | Información detallada durante la instalación |
| `--debug` | Muestra cada comando ejecutado |
| `--no-backup` | No hacer backup de archivos existentes |
| `--no-tui` | Sin interfaz interactiva |
| `--env <entorno>` | Fuerza entorno: `wsl` \| `desktop` \| `server` |

---

## Estructura

```
dotfiles/
├── install.sh              # Entry point
├── config/
│   └── symlinks.conf       # Mapeo origen:destino de todos los symlinks
├── scripts/
│   ├── lib/                # Librerías: logging, package_manager, backup, detect_environment
│   └── installers/         # Módulos: base, terminal, development, docker, desktop, server
├── dotfiles/               # Archivos de configuración (shell, git, ssh, editors, tools)
├── environments/           # Variables y configs por entorno
├── bin/                    # Herramientas ejecutables (translate-srt, web tools)
└── tests/                  # Dockerfiles para probar en múltiples distros
```

---

## Flujo de instalación

```
install.sh
  → Detecta entorno (IS_WSL / IS_DESKTOP / IS_SERVER)
  → Ejecuta instaladores en orden (base → terminal → development → docker → desktop/server)
  → Crea symlinks según config/symlinks.conf
  → Inicializa configs locales (.env.local, ssh/config.local)
  → Despliega defaults compartidos de terminal, tmux y SSH para sesiones remotas
  → Backup automático de archivos previos en .dotfiles_backup/
```

---

## Herramientas configuradas

- **Shell**: Zsh + Starship + Tmux + Nerd Fonts
- **Terminal remota**: defaults compartidos para `LANG`, `LC_ALL`, `TERM`, `tmux-256color` y keepalive SSH
- **Git**: Aliases, SSH keys, configuración por repo
- **Dev**: Pyenv, NVM, Neovim, Git-flow, AWS CLI, Pipx, Bitwarden CLI
- **DevOps**: Docker (con soporte WSL), Tailscale
- **CLI**: bat, ripgrep, fzf, jq

---

## Configuración local (no versionada)

Dos archivos privados que el instalador inicializa pero no versiona:

- `dotfiles/shell/.env.local` — tokens y variables privadas
- `dotfiles/ssh/config.local` — hosts SSH privados (generado desde `config.local.template`)

Configuración compartida relevante para terminales y SSH:

- `dotfiles/shell/.terminal-env` — defaults versionados para `LANG`, `LC_ALL` y fallback seguro de `TERM`
- `dotfiles/tools/.tmux.conf` — ajustes comunes para color, latencia de `Esc`, mouse y sesiones persistentes
- `dotfiles/ssh/config` — hosts compartidos y keepalive; los overrides privados siguen yendo en `config.local`

---

## Tests

```bash
docker build -f tests/Dockerfile.ubuntu -t dotfiles-ubuntu . && docker run dotfiles-ubuntu
docker build -f tests/Dockerfile.fedora -t dotfiles-fedora . && docker run dotfiles-fedora
docker build -f tests/Dockerfile.arch   -t dotfiles-arch   . && docker run dotfiles-arch
```

---

## Añadir nuevo dotfile

1. Colocar el archivo en `dotfiles/<categoría>/`
2. Agregar la entrada en `config/symlinks.conf` con formato `origen:destino`
3. Ejecutar `./install.sh` o crear el symlink manualmente

## Añadir nuevo instalador

1. Crear `scripts/installers/<nombre>.sh`
2. Sourcea las librerías de `scripts/lib/` y usa `pkg_install` para instalar paquetes
3. Verificar `IS_WSL`/`IS_DESKTOP`/`IS_SERVER` si aplica solo a ciertos entornos
4. Llamarlo desde `install.sh`
