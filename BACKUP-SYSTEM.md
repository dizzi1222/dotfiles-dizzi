# 📦 Sistema de Backup del Sistema (Timeshift + Snapper)

> Script de gestión automática de snapshots y backups completos

## 🎯 Resumen Rápido

Este proyecto automatiza la configuración de un sistema robusto de backups:
- **ext4**: Timeshift con máximo 5GB por actualización
- **Btrfs**: Snapper con límites configurables
- **Snapshots automáticos** antes de cada actualización (`pacman -Syu`)
- **Integración con Grub** para boot desde snapshots
- **Opciones de full-backup** (imagen completa pesada)

---

## 📋 Requisitos Previos

```bash
# Verificar filesystem
df -T /

# Timeshift debe estar instalado (para ext4)
sudo pacman -S timeshift

# O Snapper (para Btrfs)
sudo pacman -S snapper
```

Tu sistema actual:
- **Filesystem**: ext4 ✓
- **Dispositivo**: /dev/sda4
- **Uso**: 81% (59GB de 78GB)
- **Herramienta**: Timeshift

---

## 🚀 Instalación Rápida

### 1. Ejecutar Setup Inicial

```bash
# Configuración automática (una sola vez)
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh setup
```

El script hará automáticamente:
- ✓ Detectar tu filesystem
- ✓ Instalar Timeshift (si falta)
- ✓ Crear configuración optimizada
- ✓ Crear hook de pacman para pre-actualizaciones
- ✓ Configurar límites de espacio (~5GB)

### 2. Configurar Dispositivo de Destino

Después del setup inicial, necesitas seleccionar el dispositivo:

```bash
# Abrir interfaz gráfica de Timeshift
sudo timeshift --ui
```

**En la GUI:**
1. Haz clic en "Settings" (Configuración)
2. Selecciona tu dispositivo (puede ser la misma partición `/`)
3. Configura frecuencia (recomendado: semanal)
4. Cierra la GUI

---

## 💾 Límites de Almacenamiento

### Configuración Actual para ext4

- **Máximo de snapshots**: 2-3 simultáneamente
- **Espacio total**: ~5GB máximo
- **Retención automática**: Los más recientes se conservan

### Configurar Límites Manualmente

```bash
# Opción 1: GUI de Timeshift
sudo timeshift --ui
# Ir a Settings → Snapshot Retention

# Opción 2: Usar script
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh limits
```

### Para Btrfs (Snapper)

Si usaras Btrfs, los límites se configurarían en `/etc/snapper/configs/root`:

```bash
SPACE_LIMIT="0.2"      # 20% del espacio disponible o ~5GB
NUMBER_LIMIT="5"       # Máximo 5 snapshots simultáneos
TIMELINE_LIMIT_DAILY="3"
TIMELINE_LIMIT_WEEKLY="2"
TIMELINE_LIMIT_MONTHLY="1"
```

---

## 📸 Menú Interactivo

Accede a todas las funciones desde el menú:

```bash
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh menu
```

**Opciones disponibles:**
1. Ver snapshots actuales
2. Crear snapshot manual
3. Crear imagen completa (full backup pesada)
4. Remover snapshots antiguos
5. Información de Grub y snapshots
6. Configurar límites de almacenamiento
7. Salir

---

## 🖥️ Casos de Uso

### Listar Snapshots Actuales

```bash
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh list
# o
sudo timeshift --list
```

### Crear Snapshot Manual

```bash
# Interactivo (te pedirá descripción)
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh create

# Directo con descripción
sudo timeshift --create --comments "Mi descripción"
```

### Snapshots Automáticos Pre-Actualización

Los snapshots se crean **automáticamente** antes de cada:

```bash
sudo pacman -Syu
```

**Cómo funciona:**
1. Hook de pacman se activa automáticamente
2. Crea snapshot con etiqueta "Pre-update snapshot"
3. Luego procede con la actualización
4. Si falla la actualización, puedes restaurar

---

## 🌐 Integración con Grub

### ✓ Grub ya está configurado para snapshots

```
Estado:  ✓ Grub instalado en /boot/grub/grub.cfg
Config:  skip_grub = false (permite boot desde snapshots)
```

### Cómo Usar Snapshots en Grub

**Al iniciar tu PC:**

1. Presiona **ESC** durante el boot (para abrir menú de Grub)
2. Selecciona → "Snapshots" o "Timeshift"
3. Elige el snapshot que deseas restaurar
4. El sistema bootea desde ese snapshot

### Restaurar desde Snapshot (Opción 1: Grub)

```
[En menú de Grub al iniciar]
→ Advanced options for Arch Linux
→ Timeshift Snapshots
→ Seleccionar snapshot
```

### Restaurar desde Snapshot (Opción 2: Sistema en Vivo)

```bash
# Ver snapshots disponibles
sudo timeshift --list

# Restaurar un snapshot específico
# (requiere reboot)
sudo timeshift --restore --snapshot "2025-02-09_22:39:45"
```

---

## 📦 Imagen Completa (Full Backup)

Para crear un backup **pesado completo** de todo el sistema:

```bash
# Método interactivo
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh full-backup

# O desde el menú
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh menu
# Opción 3
```

### Métodos de Full Backup

**Opción 1: Timeshift (RECOMENDADO)**
- Crea snapshot etiquetado como "Full-Backup"
- Incluye compresión automática
- Recuperable fácilmente desde Grub
- Espacio: Variable (~10-20GB típico)

**Opción 2: dd (Imagen Raw)**
- Imagen **sin compresión** (pesada)
- Bitácora exacta del disco
- Lento pero muy confiable
- Espacio: Mismo tamaño que la partición
- Uso: `sudo dd if=/dev/sda4 of=backup.img bs=4M`

**Opción 3: tar (Portable)**
- Archivo comprimido (.tar.gz)
- Más lento pero muy portable
- Espacio: 30-50% del tamaño original
- Ideal para almacenar en externo

### Ubicación de Backups Completos

```
/mnt/backups/full-backup-YYYYMMDD-HHMMSS/
```

---

## 🗑️ Remover Snapshots Antiguos

### Método Manual

```bash
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh remove
```

**El script te pedirá confirmación:**
- Lista todos los snapshots actuales
- Confirma que deseas remover
- Confirma la acción (irreversible)

### Método Automático

Timeshift limpia automáticamente según la política:
- Mantiene los más recientes
- Respeta límite de 5GB
- Ejecutable `sudo timeshift --delete-all --yes`

### ⚠️ Advertencia

Los snapshots removidos **no se pueden recuperar**. Asegúrate de:
1. Ver qué vas a remover (`--list`)
2. Tener backups alternativos si es crítico
3. Confirmar la acción dos veces

---

## 🔧 Línea de Comandos Completa

```bash
# Setup inicial
sudo bash setup-backup-system.sh setup

# Menú interactivo
sudo bash setup-backup-system.sh menu

# Comandos directos
sudo bash setup-backup-system.sh list              # Ver snapshots
sudo bash setup-backup-system.sh create            # Crear manual
sudo bash setup-backup-system.sh full-backup       # Imagen pesada
sudo bash setup-backup-system.sh remove            # Remover antiguos
sudo bash setup-backup-system.sh grub-info         # Info de Grub
sudo bash setup-backup-system.sh limits            # Configurar límites
sudo bash setup-backup-system.sh help              # Mostrar ayuda

# Directamente con Timeshift
sudo timeshift --list                              # Ver snapshots
sudo timeshift --create                            # Crear manual
sudo timeshift --restore --snapshot "NOMBRE"       # Restaurar
sudo timeshift --ui                                # GUI gráfica
```

---

## 📊 Estructura de Archivos

```
~/.dotfiles-dizzi/
├── setup-backup-system.sh         # Script principal
└── BACKUP-SYSTEM.md              # Este archivo

/etc/
├── timeshift/
│   └── timeshift.json            # Configuración Timeshift
├── pacman.d/hooks/
│   ├── timeshift-pre-update.hook  # Hook pre-actualización
│   └── snapper-pre-update.hook    # Hook pre-actualización (Btrfs)
└── snapper/configs/
    └── root                       # Configuración Snapper (si Btrfs)

/mnt/
├── timeshift-snapshots/          # Directorio de snapshots
└── backups/
    └── full-backup-*/            # Backups completos
```

---

## ⚙️ Configuraciones Clave

### Timeshift (ext4)

**Archivo**: `/etc/timeshift/timeshift.json`

```json
{
  "btrfs_mode": false,           // ext4, no Btrfs
  "skip_grub": false,            // Permite boot desde Grub
  "compression": "gzip",         // Compresión automática
  "snapshot_type": 1,            // 1=RSYNC, 2=BTRFS
  "exclude": [
    "/home",
    "/tmp",
    "/proc",
    "/sys",
    "/dev",
    "/run",
    "/var/cache",
    "/lost+found"
  ]
}
```

### Hook de Pacman

**Archivo**: `/etc/pacman.d/hooks/timeshift-pre-update.hook`

```ini
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Creating Timeshift snapshot before update...
When = PreTransaction
Exec = /usr/bin/timeshift --create --comments "Pre-update snapshot" --tags O --scripted
```

Se ejecuta automáticamente **antes** de `pacman -Syu`

---

## 📈 Monitoreo y Mantenimiento

### Ver Uso de Espacio

```bash
# Espacio en disco
df -h /

# Tamaño de snapshots
du -sh /mnt/timeshift-snapshots/

# Información detallada de Timeshift
sudo timeshift --info
```

### Verificar Salud del Sistema

```bash
# Estado de Timeshift
sudo systemctl status timeshift

# Ver últimos snapshots
sudo timeshift --list --recent

# Ver detalles de configuración
cat /etc/timeshift/timeshift.json | jq .
```

### Limpiar Automáticamente

```bash
# Ejecutar limpieza manual
sudo timeshift --delete-all --confirm

# O dejar que Timeshift lo haga automáticamente
# (según política de retención configurada)
```

---

## 🚨 Troubleshooting

### "No snapshots found"

**Problema**: El dispositivo no está seleccionado

**Solución**:
```bash
sudo timeshift --ui
# Haz clic en "Settings"
# Selecciona tu dispositivo
# Cierra y guarda
```

### "Device: Not Selected"

**Problema**: Necesitas seleccionar dónde guardar snapshots

**Solución**:
```bash
sudo timeshift --setup
# Selecciona el dispositivo (puede ser el mismo /)
```

### Hook de Pacman No Funciona

**Problema**: Snapshots no se crean antes de actualizar

**Solución**:
```bash
# Verificar que el hook existe
sudo cat /etc/pacman.d/hooks/timeshift-pre-update.hook

# Recrear el hook
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh setup

# Probar manualmente
sudo timeshift --create --scripted
```

### Espacio Insuficiente

**Problema**: "Insufficient space for backup"

**Solución**:
```bash
# Opción 1: Remover snapshots antiguos
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh remove

# Opción 2: Aumentar espacio disponible
sudo du -sh /mnt/timeshift-snapshots/

# Opción 3: Reducir retención
sudo timeshift --ui  # Settings → Snapshot Retention
```

---

## 📝 Flujo de Trabajo Típico

### Día a Día

1. **Sistema funciona normalmente**
   ```bash
   # No requiere intervención
   # Los snapshots se crean automáticamente
   ```

2. **Cuando actualizas el sistema**
   ```bash
   sudo pacman -Syu
   # Hook se activa automáticamente
   # Se crea snapshot pre-actualización
   # Si falla, tienes snapshot para restaurar
   ```

3. **Revisar estado ocasionalmente**
   ```bash
   sudo bash ~/dotfiles-dizzi/setup-backup-system.sh list
   ```

### Si Algo Falla

1. **Diagnosticar el problema**
   ```bash
   sudo timeshift --info
   sudo bash ~/dotfiles-dizzi/setup-backup-system.sh grub-info
   ```

2. **Restaurar desde Snapshot**
   - Opción A: Desde Grub al iniciar (recomendado)
   - Opción B: `sudo timeshift --restore --snapshot "NOMBRE"`
   - Opción C: Live USB si es crítico

3. **Crear nuevo snapshot después de arreglarlo**
   ```bash
   sudo bash ~/dotfiles-dizzi/setup-backup-system.sh create
   ```

---

## 🔐 Seguridad y Buenas Prácticas

### ✓ Recomendaciones

- **Backup externo**: Copia full-backups a USB/externo mensualmente
- **Verificación**: Prueba restaurar un snapshot al menos 1 vez/mes
- **Rotación**: Mantén solo 2-3 snapshots activos (~5GB)
- **Monitoreo**: Revisa `sudo timeshift --list` regularmente

### ✗ Evitar

- ❌ No dejes crecer los snapshots sin límite
- ❌ No ignores mensajes de "espacio insuficiente"
- ❌ No borres snapshots sin verificar primero
- ❌ No restaures snapshots sin hacer backup previo

---

## 📚 Referencias y Comandos Útiles

```bash
# Información general
man timeshift
timeshift --help

# Ver versión
sudo timeshift --version

# Verificar integridad
sudo timeshift --verify

# Cambiar configuración
sudo timeshift --ui
sudo timeshift --setup

# Test de snapshot (sin guardar)
sudo timeshift --check

# Logs
sudo journalctl -u timeshift -f
sudo tail -f /var/log/timeshift.log
```

---

## 🎯 Resumen de Características

| Característica | Estado |
|---|---|
| **Filesystem Detectado** | ext4 ✓ |
| **Herramienta** | Timeshift ✓ |
| **Snapshots Automáticos** | Sí (pre-actualización) ✓ |
| **Máximo Espacio** | 5GB (~2-3 snapshots) ✓ |
| **Integración Grub** | Configurada ✓ |
| **Full Backup** | Soportado ✓ |
| **Limpieza Automática** | Sí ✓ |
| **Menú Interactivo** | Sí ✓ |

---

## 📞 Soporte

Para problemas específicos:

```bash
# Ver logs de Timeshift
sudo journalctl SYSLOG_IDENTIFIER=timeshift

# Buscar errores
sudo timeshift --info

# Ejecutar diagnóstico
sudo bash ~/dotfiles-dizzi/setup-backup-system.sh grub-info
```

---

**Última actualización**: 2025-02-09
**Versión**: 1.0
**Autor**: Setup Automático del Sistema
