# ⚡ ModernTerminal.ps1

> Script de modernización de terminal Windows 100% desatendido. Instala, configura y mantiene actualizado todo el stack necesario para tener una terminal profesional con prompt inteligente, iconos, autocompletado avanzado e integración con Git — en un solo comando.

![PowerShell](https://img.shields.io/badge/PowerShell-7.4%2B-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)
![License](https://img.shields.io/badge/license-MIT-green)
![Unattended](https://img.shields.io/badge/modo-100%25%20desatendido-brightgreen)

---

## 📸 Preview

```
  ● mdesa@MDS  ~  Desktop  main ✔   
❯ ls
```

Con iconos de color por tipo de archivo, segmento git en tiempo real, tiempo de ejecución de comandos y hora en el lado derecho del prompt.

---

## ✨ ¿Qué instala y configura?

| Componente | Versión mínima | Descripción |
|---|---|---|
| **PowerShell 7** | 7.4.0 LTS | Shell moderno, rápido y multiplataforma |
| **Windows Terminal** | 1.18.0 | Terminal con pestañas, paneles y temas |
| **Git for Windows** | 2.40.0 | Control de versiones + configuración global óptima |
| **CaskaydiaCove Nerd Font** | Latest | Fuente monoespaciada con +3000 iconos |
| **Oh-My-Posh** | 23.0.0 | Motor de prompt con tema Tokyo Night |
| **Terminal-Icons** | 0.11.0 | Iconos de color en `ls` / `Get-ChildItem` |
| **PSReadLine** | 2.3.0 | Autocompletado con lista predictiva, syntax highlighting |
| **posh-git** | 1.1.0 | Información de git en el prompt |
| **z** | 1.1.0 | Navegación rápida a directorios frecuentes |
| **CompletionPredictor** | 0.0.1 | Predicciones de autocompletado mejoradas |

### Temas incluidos en Windows Terminal
- 🌙 **Tokyo Night** *(por defecto)*
- 🐱 **Catppuccin Mocha**
- 🧛 **Dracula**

---

## 🧠 Lógica inteligente por componente

El script **no es solo un instalador** — en cada ejecución:

- ✅ Si el componente **no existe** → lo instala
- 🔄 Si el componente está **desactualizado** → lo actualiza
- ✔️ Si el componente está **al día** → no hace nada, solo reporta

Esto lo hace **idempotente**: puedes ejecutarlo cada vez que quieras para mantener todo actualizado.

---

## 🚀 Instalación

### Requisitos previos
- Windows 10 (21H1 o superior) o Windows 11
- Conexión a Internet
- PowerShell 5.1 o superior (viene preinstalado en Windows)

### Un solo comando

Abre **PowerShell como Administrador** y ejecuta:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\ModernTerminal.ps1
```

O directamente desde la web:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TU_USUARIO/ModernTerminal/main/ModernTerminal.ps1" -OutFile "$env:TEMP\ModernTerminal.ps1"
& "$env:TEMP\ModernTerminal.ps1"
```

> **Nota:** Se recomienda ejecutar como Administrador para instalar fuentes del sistema y paquetes globales. Sin permisos de admin el script continuará pero algunas instalaciones pueden quedar en scope de usuario.

### ¿Qué pasa durante la ejecución?

```
  ● Verificaciones previas...
    ✔ Ejecutando como Administrador
    ✔ Conexion a Internet OK

  ● Verificando WinGet...
    ✔ WinGet v1.12.0 - OK

  ● Verificando PowerShell 7...
    ✔ PowerShell 7.5.4 - OK

  ● Verificando Windows Terminal...
    ✔ Windows Terminal v1.21.0 - OK

  ● Verificando Git...
    ✔ Git 2.47.0 - version OK
    ✔ Git configurado (autocrlf, longpaths, push.autoSetupRemote, aliases...)

  ● Verificando Nerd Font: CaskaydiaCove...
    ✔ CaskaydiaCove Nerd Font v3.3.0 - OK

  ● Verificando Oh-My-Posh...
    ✔ Oh-My-Posh v24.1.0 - OK

  ● Verificando modulos de PowerShell...
    = PSReadLine v2.3.6 - OK
    = Terminal-Icons v0.11.0 - OK
    + posh-git instalado v1.1.0
    + z instalado v1.1.0
    + CompletionPredictor instalado v0.0.1

  ╔══════════════════════════════════════════════════════╗
  ║         MODERNIZACION COMPLETADA ✔                  ║
  ╚══════════════════════════════════════════════════════╝
```

---

## ⌨️ Atajos de Windows Terminal configurados

| Atajo | Acción |
|---|---|
| `Ctrl+T` | Nueva pestaña |
| `Ctrl+W` | Cerrar pestaña |
| `Ctrl+1` … `Ctrl+5` | Ir a pestaña 1-5 |
| `Alt+Shift+-` | Split horizontal |
| `Alt+Shift++` | Split vertical |
| `Alt+Flechas` | Navegar entre paneles |
| `Alt+Shift+Flechas` | Redimensionar paneles |
| `Ctrl+=` / `Ctrl+-` | Aumentar/reducir fuente |
| `Ctrl+0` | Restablecer tamaño fuente |
| `Shift+Arriba/Abajo` | Scroll de 5 líneas |
| `Alt+Enter` | Pantalla completa |

---

## 🔧 Funciones y aliases del perfil

### Navegación
```powershell
..          # cd ..
...         # cd ..\..
....        # cd ..\..\..
mkcd ruta   # Crear directorio y entrar en él
gcd         # Ir a la raíz del repositorio git actual
z proyecto  # Saltar a directorio frecuente por nombre parcial
```

### Información del sistema
```powershell
sysinfo     # OS, CPU, RAM, disco, versión de PS
myip        # Muestra tu IP pública
portof 8080 # Qué proceso está usando ese puerto
```

### Git shortcuts
```powershell
gs          # git status -sb
ga .        # git add
gaa         # git add --all
gc "msg"    # git commit -m
gca         # git commit --amend --no-edit
gp          # git push
gpf         # git push --force-with-lease
gl          # git log --oneline --graph -20
gla         # git log --oneline --graph --all -30
gco rama    # git checkout
gb          # git branch
gd          # git diff
gds         # git diff --staged
gst         # git stash
gstp        # git stash pop
gf          # git fetch --prune
gpl         # git pull --rebase
```

### Utilidades
```powershell
ll          # Get-ChildItem (listado completo)
which cmd   # Donde está instalado un comando
grep texto  # Select-String
reload      # Recargar el perfil de PS sin reiniciar
```

### PSReadLine - atajos de teclado
| Atajo | Acción |
|---|---|
| `Tab` | Menú de autocompletado |
| `↑` / `↓` | Buscar en historial por lo que has escrito |
| `Ctrl+D` | Cerrar terminal |
| `Ctrl+L` | Limpiar pantalla |

---

## 🎨 Cambiar el tema de color

Edita el `settings.json` de Windows Terminal y cambia el campo `colorScheme` en `profiles.defaults`:

```json
"colorScheme": "Tokyo Night"
```

Opciones disponibles: `Tokyo Night` · `Catppuccin Mocha` · `Dracula`

Para editar el tema del prompt Oh-My-Posh, modifica:
```
~\.config\ohmyposh\theme.omp.json
```

---

## 🔄 Mantener actualizado

Simplemente vuelve a ejecutar el script en cualquier momento:

```powershell
.\ModernTerminal.ps1
```

Solo actualizará los componentes que tengan una versión más nueva disponible. Los que ya estén al día se omiten.

---

## 🗂️ Archivos generados

| Archivo | Ubicación |
|---|---|
| Perfil PowerShell 7 | `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| Perfil PowerShell 5 | `~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |
| Tema Oh-My-Posh | `~\.config\ohmyposh\theme.omp.json` |
| Windows Terminal config | `~\AppData\Local\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json` |
| Version tracker fuente | `~\.config\ohmyposh\.nf_version` |

> El script hace backup automático del `settings.json` de Windows Terminal antes de modificarlo.

---

## ⚙️ Configuración de Git aplicada automáticamente

```ini
core.autocrlf        = input   # LF en repo, compatible Linux/Mac
core.longpaths       = true    # Rutas largas en Windows
core.fscache         = true    # Cache de filesystem (rendimiento)
pull.rebase          = false   # pull = merge, sin sorpresas
push.autoSetupRemote = true    # git push sin -u la primera vez
init.defaultBranch   = main    # Rama por defecto moderna
fetch.prune          = true    # Limpia ramas remotas borradas
rerere.enabled       = true    # Recuerda resoluciones de conflictos
help.autocorrect     = 10      # Autocorrige typos (~1 segundo)

# Aliases globales
alias.st        = status -sb
alias.lg        = log --oneline --graph --decorate --all
alias.undo      = reset HEAD~1 --mixed
alias.stash-all = stash save --include-untracked
```

> Si Git no tiene `user.name` y `user.email` configurados, el script te avisa con los comandos exactos a ejecutar.

---

## 🛠️ Solución de problemas

**Los iconos se ven como rectángulos o símbolos extraños**
→ Asegúrate de que Windows Terminal usa la fuente `CaskaydiaCove Nerd Font`. Ve a Settings → Perfil → Fuente.

**"git command could not be found" al abrir terminal**
→ Git está instalado pero el PATH no se actualizó. Cierra y vuelve a abrir Windows Terminal.

**El tema OMP no carga / prompt sin cambios**
→ Ejecuta `oh-my-posh init pwsh --config "$env:USERPROFILE\.config\ohmyposh\theme.omp.json" | Invoke-Expression` manualmente para ver el error.

**El script se detiene por Execution Policy**
→ Ejecuta primero: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force`

**Error de permisos en instalación de fuentes**
→ Ejecuta PowerShell como Administrador.

---

## 📋 Requisitos del sistema

| Requisito | Detalle |
|---|---|
| OS | Windows 10 21H1+ / Windows 11 |
| PowerShell | 5.1+ (para ejecutar el script) |
| Permisos | Administrador (recomendado) |
| Internet | Requerido durante la instalación |
| Espacio en disco | ~200 MB aproximado |

---

## 📄 Licencia

MIT — libre para usar, modificar y distribuir.

---

<div align="center">

Hecho con ❤️ para la comunidad de desarrolladores Windows

⭐ Si te fue útil, dale una estrella al repositorio

</div>
