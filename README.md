# README - Estructura Recomendada de Dotfiles

## 🎯 Objetivo

Transformar tu repositorio de dotfiles en una solución **profesional, escalable y auto-adaptable** que:
- ✅ Detecte automáticamente el entorno (Desktop, WSL, Server)
- ✅ Instale solo lo relevante para cada ambiente
- ✅ Mantenga configuraciones compartidas y específicas
- ✅ Sea fácil de expandir y mantener
- ✅ Tenga control de versiones de todas las configuraciones

---

## 📁 Estructura Nueva vs Antigua

### Problemas con estructura plana/desorganizada:
```
dotfiles/
├── install.sh (GIGANTE, difícil mantener)
├── .zshrc
├── .gitconfig
├── .tmux.conf
└── ... (todo mezclado)
```

**Problemas:**
- Difícil de leer y mantener
- Imposible activar/desactivar módulos
- Difícil expandir
- Sin separación entre entornos

### Solución: Estructura Modular
```
dotfiles/
├── scripts/lib/          # Funciones reutilizables
├── scripts/core/         # Configuración núcleo
├── scripts/installers/   # Instaladores modulares
├── scripts/hooks/        # Post-instalación
├── dotfiles/             # Archivos de config (symlinks)
├── environments/         # Configs por entorno
├── config/               # Archivos de configuración
├── docs/                 # Documentación
├── tests/                # Validación
└── install.sh            # Entry point simple
```

---

## 🔄 Flujo de Instalación

```
1. ./install.sh
   ↓
2. Detectar entorno (detect_environment.sh)
   ├─ ¿WSL? → true/false
   ├─ ¿Desktop? → true/false
   └─ ¿Server? → true/false
   ↓
3. Instalar categorías (en orden):
   ├─ Base packages (siempre)
   ├─ Shell tools (siempre)
   ├─ Dev tools (siempre)
   ├─ Docker (siempre)
   ├─ Desktop apps (SOLO si IS_DESKTOP)
   └─ Server tools (SOLO si IS_SERVER)
   ↓
4. Crear symlinks (dotfiles)
   ↓
5. Configurar shell
   ↓
6. Ejecutar hooks post-install
   ↓
7. Validar instalación
```

---

## 🚀 Cómo Migrar tu Proyecto

### Paso 1: Preparar Estructura

```bash
cd ~/dotfiles

# Crear carpetas
mkdir -p scripts/{lib,core,installers,hooks}
mkdir -p dotfiles/{shell,git,ssh,editors,tools,system}
mkdir -p environments/{desktop,server,wsl,common}
mkdir -p docs tests config templates
```

### Paso 2: Mover Archivos de Configuración

```bash
# Mover tus dotfiles existentes
mv ~/.zshrc dotfiles/shell/.zshrc
mv ~/.bashrc dotfiles/shell/.bashrc
mv ~/.gitconfig dotfiles/git/.gitconfig
mv ~/.tmux.conf dotfiles/tools/.tmux.conf
# etc...
```

### Paso 3: Copiar Scripts de Librería

Copia estos scripts a `scripts/lib/`:
1. `detect_environment.sh` - Detección automática de entorno
2. `logging.sh` - Sistema de logging
3. `package_manager.sh` - Abstracción de apt/pacman/yum
4. `backup.sh` - Backup de archivos existentes

### Paso 4: Crear install.sh Principal

Copia el archivo `install.sh` proporcionado como punto de entrada.

### Paso 5: Modularizar Instaladores

Extrae tu script de instalación en módulos bajo `scripts/installers/`:
- `base.sh` - Herramientas base
- `development.sh` - Dev tools
- `desktop.sh` - Apps GUI
- `terminal.sh` - Terminal tools
- `docker.sh` - Docker
- `languages.sh` - Lenguajes de programación
- `server.sh` - Configuración de servidor

### Paso 6: Crear Configuraciones por Entorno

En `environments/{desktop,server,wsl,common}/`:
- Archivos `.conf` con configuraciones
- Scripts específicos del entorno

---

## 💡 Ejemplos de Uso

### Instalación en Desktop Ubuntu:
```bash
./install.sh
# Detectará: Desktop ✓, instala todo incluyendo GUI apps
```

### Instalación en WSL:
```bash
./install.sh
# Detectará: WSL ✓, salta GUI apps
```

### Instalación en Server:
```bash
./install.sh
# Detectará: Server ✓, instala server tools
```

### Instalación en modo debug:
```bash
./install.sh --debug --verbose
# Muestra cada paso
```

### Forzar entorno (para testing):
```bash
./install.sh --env desktop
./install.sh --env wsl
./install.sh --env server
```

### Sin backup:
```bash
./install.sh --no-backup
```

---

## 📦 Archivos Clave Proporcionados

### 1. **detect_environment.sh**
Detecta automáticamente:
- ¿Es WSL?
- ¿Es Desktop?
- ¿Es Server?
- ¿Qué distribución?

Exporta flags globales que se usan en todo el sistema.

### 2. **logging.sh**
Sistema consistente de logging con:
- Mensajes de info (ℹ)
- Mensajes de éxito (✓)
- Mensajes de error (✗)
- Mensajes de advertencia (⚠)
- Debug (🐛)
- Secciones (━━━━)

### 3. **package_manager.sh**
Abstracción que funciona con:
- apt (Debian/Ubuntu)
- pacman (Arch)
- yum (RedHat)

Funciones:
- `pkg_install` - Instalar paquete
- `pkg_install_if_needed` - Instalar si no existe
- `pkg_is_installed` - Verificar si está instalado
- `pkg_update` - Actualizar cache

### 4. **backup.sh**
Gestión de backups:
- `backup_if_exists` - Hacer backup automático
- `restore_backup` - Restaurar desde backup
- `list_backups` - Listar backups disponibles
- Timestamp automático de backups

### 5. **install.sh**
Script principal que:
- Orquesta todo el flujo
- Detecta entorno
- Llama instaladores en orden
- Crea symlinks
- Valida instalación
- Resumen final

---

## 🎨 Características de la Solución

### ✅ Modular
- Cada componente es independiente
- Fácil de añadir/remover
- Reutilizable en otros proyectos

### ✅ Escalable
- Nuevo entorno? Solo añade carpeta
- Nuevo installer? Solo crea script
- Nuevo dotfile? Solo copia y añade symlink

### ✅ Robusto
- Detección automática
- Backup automático
- Validación post-instalación
- Logging detallado

### ✅ Flexible
- Múltiples entornos soportados
- Configuración centralizada
- Override manual de entorno
- Sin backup si lo prefieres

### ✅ Profesional
- Código limpio y bien documentado
- Manejo de errores
- Validación de requisitos
- Tests incluidos

---

## 📝 Siguientes Pasos

1. **Organiza tu repo** con la nueva estructura
2. **Copia los scripts** de libería proporcionados
3. **Mueve tus dotfiles** a `dotfiles/`
4. **Modulariza instaladores** si tienes script monolítico
5. **Prueba** en los 3 entornos (Desktop, WSL, Server)
6. **Añade documentación** específica de tu setup

---

## 🛠️ Scripts Adicionales Útiles

### test_environment.sh
Valida que la detección funcionó correctamente

### test_symlinks.sh
Verifica que todos los symlinks se crearon

### test_packages.sh
Comprueba que los paquetes se instalaron

---

## 📚 Documentación Recomendada

Crea estos archivos en `docs/`:

1. **INSTALL.md** - Guía de instalación paso a paso
2. **ENVIRONMENTS.md** - Diferencias por entorno
3. **CUSTOMIZATION.md** - Cómo customizar para tu setup
4. **TROUBLESHOOTING.md** - Solución de problemas comunes
5. **ARCHITECTURE.md** - Explicación de la arquitectura

---

## 🎁 Bonus

### Alias para actualizar dotfiles
```bash
# En tu .zshrc/.bashrc
alias dotfiles-update='cd ~/dotfiles && git pull && ./install.sh'
```

### Git hook para auto-push
```bash
# .git/hooks/post-commit
git push origin master
```

### Cron job para backup
```bash
# Backup automático cada semana
0 0 * * 0 ~/dotfiles/scripts/lib/cleanup_old_backups.sh
```

---

## 📞 Soporte

Si tienes problemas:

1. Ejecuta con `--debug`:
   ```bash
   ./install.sh --debug --verbose
   ```

2. Revisa logs en `.dotfiles_backup/`

3. Restaura desde backup si es necesario:
   ```bash
   bash scripts/lib/restore_backup.sh
   ```

---

## 🎉 ¡Listo!

Con esta estructura tendrás un dotfiles:
- **Profesional** ✓
- **Escalable** ✓
- **Mantenible** ✓
- **Robusto** ✓
- **Flexible** ✓

¡Que disfrutes de tu nuevo setup!
