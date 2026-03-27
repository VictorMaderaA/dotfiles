# Guía de Entornos Soportados

Este proyecto de dotfiles está diseñado para adaptarse automáticamente a diferentes tipos de entornos Linux. La detección se realiza mediante el script `scripts/lib/detect_environment.sh`.

## 🖥️ Desktop (Escritorio)

Para sistemas Linux con interfaz gráfica (GNOME recomendado).

- **Detección**: Se activa si existe una sesión de escritorio activa (`$XDG_CURRENT_DESKTOP`).
- **Instalación Específica**:
  - Aplicaciones GUI: VLC, JetBrains Toolbox, Nautilus.
  - Configuración de GNOME Terminal.
  - Atajos de teclado personalizados.
  - Instalación de fuentes Nerd Fonts para la terminal.

## 🪟 WSL (Windows Subsystem for Linux)

Específico para Ubuntu o distribuciones similares ejecutándose sobre Windows.

- **Detección**: Se activa si `/proc/version` contiene la palabra "microsoft" o "WSL".
- **Instalación Específica**:
  - Optimización de permisos para Docker (Docker Desktop suele estar en Windows).
  - Configuración de interoperabilidad de portapapeles.
  - Omisión de aplicaciones gráficas pesadas (GUI).

## ☁️ Server (Servidor)

Para servidores remotos o instancias VPS sin entorno gráfico.

- **Detección**: Se activa si no se detecta Desktop ni WSL.
- **Instalación Específica**:
  - Paquetes de red y monitoreo: `nethogs`, `iotop`, `fail2ban`.
  - Configuración de seguridad básica (UFW).
  - Shell optimizada para SSH.

---

### Tabla Comparativa

| Características | Desktop | WSL | Server |
|-----------------|---------|-----|--------|
| Zsh & Starship  | ✅ | ✅ | ✅ |
| Docker Support  | ✅ | ✅ (Config) | ✅ |
| GUI Apps        | ✅ | ❌ | ❌ |
| Nerd Fonts      | ✅ | ❌ (Host) | ❌ |
| Backup Auto     | ✅ | ✅ | ✅ |
| Tailscale VPN   | ✅ | ✅ | ✅ |

### Forzar un Entorno

Si la auto-detección no es correcta o deseas instalar un perfil diferente, usa el flag `--env`:

```bash
./install.sh --env server
```
