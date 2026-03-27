# Guía de Instalación Rápida

Este documento proporciona instrucciones paso a paso para instalar y configurar estos dotfiles en un sistema nuevo.

## 🚀 Instalación Automática

El script `install.sh` se encarga de detectar tu entorno (WSL, Desktop o Server) e instalar las herramientas adecuadas.

```bash
# 1. Clonar el repositorio
git clone https://github.com/VictorMaderaA/dotfiles.git ~/dotfiles

# 2. Entrar al directorio
cd ~/dotfiles

# 3. Ejecutar el instalador
./install.sh
```

### Opciones del Instalador

| Opción | Descripción |
|--------|-------------|
| `--verbose` | Muestra información detallada de cada paso. |
| `--debug` | Activa el modo debug de shell (muestra comandos ejecutados). |
| `--no-backup` | No realiza copias de seguridad de los archivos existentes (usar con precaución). |
| `--env <env>` | Fuerza la instalación para un entorno específico (`wsl`, `desktop`, `server`). |

## 🛠️ Requisitos Previos

- **Sistema Operativo**: Linux (basado en Debian/Ubuntu recomendado).
- **Git**: Debe estar instalado para clonar el repositorio.
- **Conexión a Internet**: Necesaria para descargar paquetes y herramientas externas.

## ✅ Qué se instala

Dependiendo de tu entorno, se configurará:
- **Shell**: Zsh con Starship prompt, plugins de autocompletado y resaltado de sintaxis.
- **Herramientas de Lenguaje**: NVM (Node), Pyenv (Python), Pipx.
- **DevOps**: Docker, AWS CLI.
- **Utilidades**: Tmux, Bat, Fzf, Ripgrep, Bitwarden CLI.
- **Escritorio (si aplica)**: GNOME Terminal con fuentes Nerd Fonts y atajos de teclado.

## 🔄 Post-Instalación

1. **Reiniciar la sesión**: Es necesario cerrar y volver a abrir la terminal o reiniciar la sesión para que el cambio de shell (`zsh`) surta efecto.
2. **Configurar Git**: Asegúrate de revisar tu `.gitconfig` en `dotfiles/git/` si necesitas personalizar tu nombre o email.
3. **Actualizaciones**: Puedes actualizar tus dotfiles en cualquier momento ejecutando el alias `dotfiles-update` (si está configurado) o volviendo a ejecutar `./install.sh`.
