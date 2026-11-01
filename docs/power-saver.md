# power-saver-extras

Servicio systemd opcional (solo desktop) que aplica ajustes extra de ahorro de energía cuando el perfil de `power-profiles-daemon` pasa a **power-saver**, y los revierte al salir de él. Se cambia de perfil como siempre (menú de energía de GNOME o `powerprofilesctl set power-saver`).

## Qué hace en power-saver

| Ajuste | Valor por defecto |
|---|---|
| `scaling_max_freq` (todas las políticas) | 2200000 kHz |
| Límite de potencia GPU NVIDIA | 100 W |

Los valores originales se guardan en `/run/power-saver-extras/` antes de cambiarlos y se restauran al salir del perfil. Como `/run` y sysfs se reinician con la máquina, un reinicio siempre parte de valores por defecto.

## Instalar / desinstalar

```bash
./install.sh --powersave              # solo este servicio
./install.sh --uninstall-powersave    # elimina servicio y revierte ajustes
# o marcar POWERSAVE en el menú del instalador (solo se muestra en desktop)
```

Instala (con `sudo`): `/usr/local/sbin/power-saver-extras`, `/etc/systemd/system/power-saver-extras.service` y, si no existe, `/etc/default/power-saver-extras`. Requiere `power-profiles-daemon`, `gdbus` y `busctl`.

El boost no se toca a propósito: `power-profiles-daemon` escribe `policy*/boost` al cambiar de perfil y falla con EINVAL si el boost global está en 0. Con el tope de 2,2 GHz (por debajo de la base, 3,7 GHz) el boost no se llega a usar.

## Ajustar valores

Editar `/etc/default/power-saver-extras` y `sudo systemctl restart power-saver-extras`. Dejar `MAX_FREQ_KHZ` o `GPU_LIMIT_W` vacíos desactiva ese límite.

## Verificar

```bash
cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
cat /sys/devices/system/cpu/cpufreq/boost
nvidia-smi -q -d POWER | grep -i 'power limit'
journalctl -u power-saver-extras -n 20
```

## Aviso

Con power-saver activo los juegos y la transcodificación por CPU (p. ej. Jellyfin) irán capados. Volver a `performance` o `balanced` antes de usarlos.
