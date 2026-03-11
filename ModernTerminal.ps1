#Requires -Version 5.1
<#
.SYNOPSIS
    Terminal Modernization Script - 100% Desatendido v3
.DESCRIPTION
    Instala y configura automaticamente:
      - PowerShell 7
      - Windows Terminal con tema Tokyo Night
      - Nerd Fonts (CaskaydiaCove)
      - Oh-My-Posh (prompt moderno)
      - Git, Terminal-Icons, PSReadLine, posh-git, z
      - Perfil PS completo con aliases, funciones y git shortcuts
.NOTES
    Ejecutar como Administrador. Requiere conexion a Internet.
#>

Set-StrictMode -Off
$ErrorActionPreference  = 'SilentlyContinue'
$ProgressPreference     = 'SilentlyContinue'
$WarningPreference      = 'SilentlyContinue'

Clear-Host
Write-Host ""
Write-Host "  ████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗ █████╗ ██╗     " -ForegroundColor Blue
Write-Host "     ██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗██║     " -ForegroundColor Blue
Write-Host "     ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║███████║██║     " -ForegroundColor Cyan
Write-Host "     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══██║██║     " -ForegroundColor Cyan
Write-Host "     ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██║  ██║███████╗" -ForegroundColor Magenta
Write-Host "     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "          MODERNIZACION DE TERMINAL  -  100% DESATENDIDO v3" -ForegroundColor White
Write-Host ""

# ── Helpers ──────────────────────────────────────────────────────────────────
function Write-Step { param([string]$M) Write-Host "`n  ● $M" -ForegroundColor Cyan }
function Write-OK   { param([string]$M) Write-Host "    ✔ $M" -ForegroundColor Green }
function Write-Warn { param([string]$M) Write-Host "    ⚠ $M" -ForegroundColor Yellow }
function Write-Info { param([string]$M) Write-Host "    → $M" -ForegroundColor DarkGray }

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Compara versiones: 1 = ok/nueva, -1 = vieja/actualizar
function Compare-SemVer {
    param([string]$Current, [string]$Minimum)
    try {
        $c = [Version]($Current -replace '[^\d\.]','')
        $m = [Version]($Minimum -replace '[^\d\.]','')
        if ($c -ge $m) { return 1 } else { return -1 }
    } catch { return 1 }  # Si no se puede parsear, asumir OK
}

function Test-Admin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    ([System.Security.Principal.WindowsPrincipal]$id).IsInRole(
        [System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-WingetPkg {
    param([string]$Id, [string]$Name)
    Write-Info "Instalando $Name via WinGet..."
    winget install --id $Id --accept-source-agreements --accept-package-agreements --silent --scope machine 2>&1 | Out-Null
    Refresh-Path
    Write-OK "$Name instalado/verificado"
}

# ── Verificaciones previas ────────────────────────────────────────────────────
Write-Step "Verificaciones previas..."

if (Test-Admin) { Write-OK "Ejecutando como Administrador" }
else { Write-Warn "No es Administrador - algunas instalaciones pueden fallar" }

try {
    $null = Invoke-WebRequest -Uri "https://raw.githubusercontent.com" -UseBasicParsing -TimeoutSec 8
    Write-OK "Conexion a Internet OK"
} catch {
    Write-Host "`n  [ERROR] Sin conexion a Internet." -ForegroundColor Red
    exit 1
}

# ── 1. WinGet ─────────────────────────────────────────────────────────────────
Write-Step "Verificando WinGet..."
$_wgMin = "1.6.0"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Info "WinGet no encontrado. Instalando..."
    $vcUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $vc    = "$env:TEMP\VCLibs.appx"
    Invoke-WebRequest -Uri $vcUrl -OutFile $vc -UseBasicParsing
    Add-AppxPackage -Path $vc -ErrorAction SilentlyContinue

    $api   = (Invoke-WebRequest "https://api.github.com/repos/microsoft/winget-cli/releases/latest" -UseBasicParsing | ConvertFrom-Json)
    $asset = $api.assets | Where-Object { $_.name -match '\.msixbundle$' } | Select-Object -First 1
    $wgp   = "$env:TEMP\WinGet.msixbundle"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $wgp -UseBasicParsing
    Add-AppxPackage -Path $wgp
    Refresh-Path
    Write-OK "WinGet instalado: $(winget --version 2>$null)"
} else {
    $wgVer = (winget --version 2>$null) -replace 'v',''
    if ((Compare-SemVer $wgVer $_wgMin) -lt 0) {
        Write-Warn "WinGet v$wgVer detectado (minimo $_wgMin). Actualizando..."
        winget upgrade --id Microsoft.AppInstaller --silent --accept-source-agreements 2>&1 | Out-Null
        Refresh-Path
        Write-OK "WinGet actualizado: $(winget --version 2>$null)"
    } else {
        Write-OK "WinGet v$wgVer - OK"
    }
}

# ── 2. PowerShell 7 ───────────────────────────────────────────────────────────
Write-Step "Verificando PowerShell 7..."
$_ps7Min = "7.4.0"
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-Info "PowerShell 7 no encontrado. Instalando..."
    try {
        Install-WingetPkg -Id "Microsoft.PowerShell" -Name "PowerShell 7"
    } catch {
        Write-Info "Fallback: descargando MSI de PS7..."
        $ps7api  = (Invoke-WebRequest "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" -UseBasicParsing | ConvertFrom-Json)
        $msi     = $ps7api.assets | Where-Object { $_.name -match 'win-x64\.msi$' } | Select-Object -First 1
        $msiPath = "$env:TEMP\PS7.msi"
        Invoke-WebRequest -Uri $msi.browser_download_url -OutFile $msiPath -UseBasicParsing
        Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait
        Refresh-Path
    }
    Write-OK "PowerShell 7 instalado: $(pwsh --version 2>$null)"
} else {
    $ps7VerRaw = (pwsh --version 2>$null) -replace 'PowerShell ',''
    if ((Compare-SemVer $ps7VerRaw $_ps7Min) -lt 0) {
        Write-Warn "PowerShell $ps7VerRaw detectado (minimo $_ps7Min). Actualizando..."
        winget upgrade --id Microsoft.PowerShell --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        Refresh-Path
        Write-OK "PowerShell actualizado: $(pwsh --version 2>$null)"
    } else {
        Write-OK "PowerShell $ps7VerRaw - OK"
    }
}

# ── 3. Windows Terminal ───────────────────────────────────────────────────────
Write-Step "Verificando Windows Terminal..."
$_wtMin = "1.18.0"
$wtPkg  = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
if (-not $wtPkg) {
    Write-Info "Windows Terminal no encontrado. Instalando..."
    Install-WingetPkg -Id "Microsoft.WindowsTerminal" -Name "Windows Terminal"
    $wtPkg = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
    Write-OK "Windows Terminal instalado: v$($wtPkg.Version)"
} else {
    $wtVer = $wtPkg.Version
    if ((Compare-SemVer $wtVer $_wtMin) -lt 0) {
        Write-Warn "Windows Terminal v$wtVer detectado (minimo $_wtMin). Actualizando..."
        winget upgrade --id Microsoft.WindowsTerminal --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        $wtPkg = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
        Write-OK "Windows Terminal actualizado: v$($wtPkg.Version)"
    } else {
        Write-OK "Windows Terminal v$wtVer - OK"
    }
}

# ── 4. Git ───────────────────────────────────────────────────────────────────
Write-Step "Verificando Git..."

# Buscar git en PATH y en rutas tipicas de Visual Studio / Git for Windows
$gitPaths = @(
    (Get-Command git -ErrorAction SilentlyContinue)?.Source,
    "$env:ProgramFiles\Git\cmd\git.exe",
    "$env:ProgramFiles\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\cmd\git.exe",
    "$env:ProgramFiles\Microsoft Visual Studio\2022\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\cmd\git.exe",
    "$env:ProgramFiles\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\cmd\git.exe",
    "$env:ProgramFiles\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\cmd\git.exe"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if ($gitPaths) {
    # Asegurar que el directorio de git este en el PATH de sesion
    $gitDir = Split-Path $gitPaths
    if ($env:Path -notlike "*$gitDir*") {
        $env:Path = "$gitDir;$env:Path"
        Write-Info "Git encontrado fuera del PATH, agregado temporalmente: $gitDir"
    }
}

if (Get-Command git -ErrorAction SilentlyContinue) {
    # Git encontrado - verificar version y actualizar si es vieja
    $gitVerRaw = git --version 2>$null
    $gitVerMatch = [regex]::Match($gitVerRaw, '(\d+)\.(\d+)\.(\d+)')
    if ($gitVerMatch.Success) {
        $major = [int]$gitVerMatch.Groups[1].Value
        $minor = [int]$gitVerMatch.Groups[2].Value
        $gitVerStr = "$major.$minor.$($gitVerMatch.Groups[3].Value)"

        # Minimo recomendado: 2.40.0 (soporte completo de features modernos)
        $needsUpdate = ($major -lt 2) -or ($major -eq 2 -and $minor -lt 40)

        if ($needsUpdate) {
            Write-Warn "Git $gitVerStr detectado - version antigua. Actualizando..."
            winget upgrade --id Git.Git `
                --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
            Refresh-Path
            $gitVerNew = git --version 2>$null
            Write-OK "Git actualizado: $gitVerNew"
        } else {
            Write-OK "Git $gitVerStr - version OK (no necesita actualizacion)"
        }
    } else {
        Write-OK "Git detectado: $gitVerRaw"
    }
} else {
    # Git no encontrado en ninguna ruta - instalar
    Write-Info "Git no encontrado. Instalando Git for Windows..."
    winget install --id Git.Git `
        --accept-source-agreements `
        --accept-package-agreements `
        --silent `
        --override "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=icons,ext\reg\shellhere,assoc,assoc_sh" 2>&1 | Out-Null
    Refresh-Path
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-OK "Git instalado: $(git --version 2>$null)"
    } else {
        Write-Warn "Git instalado. Requiere reiniciar terminal para activarse en PATH"
    }
}

# Configurar Git global si no tiene identidad configurada
$gitUserName  = git config --global user.name  2>$null
$gitUserEmail = git config --global user.email 2>$null

if (Get-Command git -ErrorAction SilentlyContinue) {
    # Configuracion de rendimiento y UX siempre aplicada
    git config --global core.autocrlf   input          2>$null  # LF en repo, CRLF en checkout Windows
    git config --global core.safecrlf   warn           2>$null
    git config --global core.longpaths  true           2>$null  # Rutas largas en Windows
    git config --global core.fscache    true           2>$null  # Cache filesystem (rendimiento)
    git config --global pull.rebase     false          2>$null  # pull = merge por defecto
    git config --global push.autoSetupRemote true      2>$null  # git push sin -u automatico
    git config --global init.defaultBranch   main      2>$null  # rama por defecto: main
    git config --global color.ui        auto           2>$null
    git config --global diff.colorMoved zebra          2>$null
    git config --global fetch.prune     true           2>$null  # limpiar ramas remotas borradas
    git config --global rerere.enabled  true           2>$null  # recordar resoluciones de conflictos
    git config --global help.autocorrect 10           2>$null  # autocorregir typos (1 seg)

    # Aliases de git globales
    git config --global alias.st        "status -sb"   2>$null
    git config --global alias.lg       "log --oneline --graph --decorate --all" 2>$null
    git config --global alias.undo      "reset HEAD~1 --mixed"  2>$null
    git config --global alias.aliases   "config --get-regexp alias" 2>$null
    git config --global alias.stash-all "stash save --include-untracked" 2>$null

    Write-OK "Git configurado (autocrlf, longpaths, push.autoSetupRemote, aliases, rerere...)"

    if (-not $gitUserName -or -not $gitUserEmail) {
        Write-Warn "Git sin identidad global configurada."
        Write-Warn "Ejecuta estos comandos para configurarla:"
        Write-Host '    git config --global user.name  "Tu Nombre"'  -ForegroundColor DarkYellow
        Write-Host '    git config --global user.email "tu@email.com"' -ForegroundColor DarkYellow
    } else {
        Write-OK "Identidad git: $gitUserName <$gitUserEmail>"
    }
}

# ── 5. Nerd Font - CaskaydiaCove ──────────────────────────────────────────────
Write-Step "Verificando Nerd Font: CaskaydiaCove..."
$fontsDir      = "$env:SystemRoot\Fonts"
$nfRegPath     = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
$nfRegKey      = "CaskaydiaCoveNerdFont-Regular (TrueType)"
$nfRegKeyAlt   = "Caskaydia Cove Nerd Font Regular (TrueType)"
$nfInstalled   = (Get-ItemProperty -Path $nfRegPath -Name $nfRegKey -ErrorAction SilentlyContinue) -or
                 (Get-ItemProperty -Path $nfRegPath -Name $nfRegKeyAlt -ErrorAction SilentlyContinue) -or
                 (Test-Path "$fontsDir\CaskaydiaCoveNerdFont-Regular.ttf")

# Obtener version latest de Nerd Fonts desde GitHub
$nfVerFile     = "$env:USERPROFILE\.config\ohmyposh\.nf_version"
$nfLatestVer   = $null
try {
    $nfApi       = Invoke-WebRequest "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" -UseBasicParsing | ConvertFrom-Json
    $nfLatestVer = $nfApi.tag_name -replace '^v',''
} catch { $nfLatestVer = "0.0.0" }

$nfInstalledVer = if (Test-Path $nfVerFile) { Get-Content $nfVerFile -Raw | ForEach-Object { $_.Trim() } } else { "0.0.0" }

$needsNfUpdate = $nfInstalled -and $nfLatestVer -ne "0.0.0" -and ((Compare-SemVer $nfInstalledVer $nfLatestVer) -lt 0)

if (-not $nfInstalled) {
    Write-Info "CaskaydiaCove Nerd Font no instalada. Descargando v$nfLatestVer..."
    $installFont = $true
} elseif ($needsNfUpdate) {
    Write-Warn "Nerd Font v$nfInstalledVer instalada. Disponible v$nfLatestVer. Actualizando..."
    $installFont = $true
} else {
    Write-OK "CaskaydiaCove Nerd Font v$nfInstalledVer - OK"
    $installFont = $false
}

if ($installFont) {
    $nfUrl  = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
    $nfZip  = "$env:TEMP\CascadiaCode_NF.zip"
    $nfDir  = "$env:TEMP\CascadiaCode_NF"
    try {
        Invoke-WebRequest -Uri $nfUrl -OutFile $nfZip -UseBasicParsing
        Expand-Archive -Path $nfZip -DestinationPath $nfDir -Force

        $fontFiles = Get-ChildItem -Path $nfDir -Include "*.ttf","*.otf" -Recurse |
                     Where-Object { $_.Name -notmatch "WindowsCompatible" }
        foreach ($f in $fontFiles) {
            $dest = "$fontsDir\$($f.Name)"
            Copy-Item -Path $f.FullName -Destination $dest -Force
            $regName = [IO.Path]::GetFileNameWithoutExtension($f.Name) + " (TrueType)"
            New-ItemProperty -Path $nfRegPath -Name $regName -Value $f.Name -PropertyType String -Force | Out-Null
        }
        # Guardar version instalada
        New-Item -ItemType Directory -Path (Split-Path $nfVerFile) -Force | Out-Null
        Set-Content -Path $nfVerFile -Value $nfLatestVer -Encoding UTF8
        Write-OK "CaskaydiaCove Nerd Font v$nfLatestVer instalada ($($fontFiles.Count) archivos)"
    } catch {
        Write-Warn "Error instalando fuente: $_"
    } finally {
        Remove-Item $nfZip -Force -ErrorAction SilentlyContinue
        Remove-Item $nfDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ── 6. Oh-My-Posh ─────────────────────────────────────────────────────────────
Write-Step "Verificando Oh-My-Posh..."
$_ompMin = "23.0.0"
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Info "Oh-My-Posh no encontrado. Instalando..."
    try {
        Install-WingetPkg -Id "JanDeDobbeleer.OhMyPosh" -Name "Oh-My-Posh"
    } catch {
        Write-Info "Fallback: script oficial Oh-My-Posh..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
        Refresh-Path
    }
    Write-OK "Oh-My-Posh instalado: $(oh-my-posh version 2>$null)"
} else {
    $ompVer = (oh-my-posh version 2>$null) -replace '^v',''
    if ((Compare-SemVer $ompVer $_ompMin) -lt 0) {
        Write-Warn "Oh-My-Posh v$ompVer detectado (minimo $_ompMin). Actualizando..."
        winget upgrade --id JanDeDobbeleer.OhMyPosh --silent --accept-source-agreements 2>&1 | Out-Null
        Refresh-Path
        Write-OK "Oh-My-Posh actualizado: v$(oh-my-posh version 2>$null)"
    } else {
        Write-OK "Oh-My-Posh v$ompVer - OK"
    }
}
Refresh-Path

# Crear tema OMP (Tokyo Night) desde Base64 para evitar problemas de encoding
$ompDir = "$env:USERPROFILE\.config\ohmyposh"
New-Item -ItemType Directory -Path $ompDir -Force | Out-Null
$ompThemePath = "$ompDir\theme.omp.json"
$_themeB64 = "ewogICIkc2NoZW1hIjogImh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9KYW5EZURvYmJlbGVlci9vaC1teS1wb3NoL21haW4vdGhlbWVzL3NjaGVtYS5qc29uIiwKICAidmVyc2lvbiI6IDIsCiAgImZpbmFsX3NwYWNlIjogdHJ1ZSwKICAiY29uc29sZV90aXRsZV90ZW1wbGF0ZSI6ICJ7eyAuU2hlbGwgfX0gaW4ge3sgLkZvbGRlciB9fSIsCiAgInRyYW5zaWVudF9wcm9tcHQiOiB7CiAgICAiYmFja2dyb3VuZCI6ICJ0cmFuc3BhcmVudCIsCiAgICAiZm9yZWdyb3VuZCI6ICIjN0FBMkY3IiwKICAgICJ0ZW1wbGF0ZSI6ICI+ICIKICB9LAogICJibG9ja3MiOiBbCiAgICB7CiAgICAgICJ0eXBlIjogInByb21wdCIsCiAgICAgICJhbGlnbm1lbnQiOiAibGVmdCIsCiAgICAgICJuZXdsaW5lIjogdHJ1ZSwKICAgICAgInNlZ21lbnRzIjogWwogICAgICAgIHsKICAgICAgICAgICJ0eXBlIjogIm9zIiwKICAgICAgICAgICJzdHlsZSI6ICJkaWFtb25kIiwKICAgICAgICAgICJsZWFkaW5nX2RpYW1vbmQiOiAiXHVFMEI2IiwKICAgICAgICAgICJ0cmFpbGluZ19kaWFtb25kIjogIlx1RTBCNCIsCiAgICAgICAgICAiYmFja2dyb3VuZCI6ICIjN0FBMkY3IiwKICAgICAgICAgICJmb3JlZ3JvdW5kIjogIiMxQTFCMjYiLAogICAgICAgICAgInRlbXBsYXRlIjogIiBcdUU2MkEgIgogICAgICAgIH0sCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAic2Vzc2lvbiIsCiAgICAgICAgICAic3R5bGUiOiAiZGlhbW9uZCIsCiAgICAgICAgICAibGVhZGluZ19kaWFtb25kIjogIiBcdUUwQjYiLAogICAgICAgICAgInRyYWlsaW5nX2RpYW1vbmQiOiAiXHVFMEI0IiwKICAgICAgICAgICJiYWNrZ3JvdW5kIjogIiNCQjlBRjciLAogICAgICAgICAgImZvcmVncm91bmQiOiAiIzFBMUIyNiIsCiAgICAgICAgICAidGVtcGxhdGUiOiAiIHt7IC5Vc2VyTmFtZSB9fUB7eyAuSG9zdE5hbWUgfX0gIiwKICAgICAgICAgICJwcm9wZXJ0aWVzIjogewogICAgICAgICAgICAiZGlzcGxheV9ob3N0IjogdHJ1ZQogICAgICAgICAgfQogICAgICAgIH0sCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAicGF0aCIsCiAgICAgICAgICAic3R5bGUiOiAicG93ZXJsaW5lIiwKICAgICAgICAgICJwb3dlcmxpbmVfc3ltYm9sIjogIlx1RTBCNCIsCiAgICAgICAgICAiYmFja2dyb3VuZCI6ICIjNDE0ODY4IiwKICAgICAgICAgICJmb3JlZ3JvdW5kIjogIiNDMENBRjUiLAogICAgICAgICAgInRlbXBsYXRlIjogIiAge3sgLlBhdGggfX0gIiwKICAgICAgICAgICJwcm9wZXJ0aWVzIjogewogICAgICAgICAgICAic3R5bGUiOiAiYWdub3N0ZXJfc2hvcnQiLAogICAgICAgICAgICAibWF4X2RlcHRoIjogNCwKICAgICAgICAgICAgImZvbGRlcl9pY29uIjogIlx1RjA3QiIsCiAgICAgICAgICAgICJob21lX2ljb24iOiAiXHVGN0RCIgogICAgICAgICAgfQogICAgICAgIH0sCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAiZ2l0IiwKICAgICAgICAgICJzdHlsZSI6ICJwb3dlcmxpbmUiLAogICAgICAgICAgInBvd2VybGluZV9zeW1ib2wiOiAiXHVFMEI0IiwKICAgICAgICAgICJiYWNrZ3JvdW5kIjogIiM5RUNFNkEiLAogICAgICAgICAgImJhY2tncm91bmRfdGVtcGxhdGVzIjogWwogICAgICAgICAgICAie3sgaWYgb3IgKC5Xb3JraW5nLkNoYW5nZWQpICguU3RhZ2luZy5DaGFuZ2VkKSB9fSNFMEFGNjh7eyBlbmQgfX0iLAogICAgICAgICAgICAie3sgaWYgYW5kIChndCAuQWhlYWQgMCkgKGd0IC5CZWhpbmQgMCkgfX0jRjc3NjhFe3sgZW5kIH19IiwKICAgICAgICAgICAgInt7IGlmIGd0IC5BaGVhZCAwIH19IzdBQTJGN3t7IGVuZCB9fSIsCiAgICAgICAgICAgICJ7eyBpZiBndCAuQmVoaW5kIDAgfX0jRjc3NjhFe3sgZW5kIH19IgogICAgICAgICAgXSwKICAgICAgICAgICJmb3JlZ3JvdW5kIjogIiMxQTFCMjYiLAogICAgICAgICAgInRlbXBsYXRlIjogIiAge3sgLkhFQUQgfX17eyBpZiAuV29ya2luZy5DaGFuZ2VkIH19IFx1RjA0NCB7eyAuV29ya2luZy5TdHJpbmcgfX17eyBlbmQgfX17eyBpZiAuU3RhZ2luZy5DaGFuZ2VkIH19IFx1RjA0NiB7eyAuU3RhZ2luZy5TdHJpbmcgfX17eyBlbmQgfX17eyBpZiBndCAuQWhlYWQgMCB9fSBcdUYxNzYge3sgLkFoZWFkIH19e3sgZW5kIH19e3sgaWYgZ3QgLkJlaGluZCAwIH19IFx1RjE3NSB7eyAuQmVoaW5kIH19e3sgZW5kIH19ICIsCiAgICAgICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAgICAgImZldGNoX3N0YXR1cyI6IHRydWUsCiAgICAgICAgICAgICJicmFuY2hfbWF4X2xlbmd0aCI6IDI1LAogICAgICAgICAgICAidHJ1bmNhdGVfc3ltYm9sIjogIlx1MjAyNiIKICAgICAgICAgIH0KICAgICAgICB9LAogICAgICAgIHsKICAgICAgICAgICJ0eXBlIjogIm5vZGUiLAogICAgICAgICAgInN0eWxlIjogInBvd2VybGluZSIsCiAgICAgICAgICAicG93ZXJsaW5lX3N5bWJvbCI6ICJcdUUwQjQiLAogICAgICAgICAgImJhY2tncm91bmQiOiAiIzQxYTA2YiIsCiAgICAgICAgICAiZm9yZWdyb3VuZCI6ICIjMUExQjI2IiwKICAgICAgICAgICJ0ZW1wbGF0ZSI6ICIgIHt7IC5GdWxsIH19ICIsCiAgICAgICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAgICAgImRpc3BsYXlfbW9kZSI6ICJmaWxlcyIsCiAgICAgICAgICAgICJtaXNzaW5nX2NvbW1hbmRfdGV4dCI6ICIiCiAgICAgICAgICB9CiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAidHlwZSI6ICJweXRob24iLAogICAgICAgICAgInN0eWxlIjogInBvd2VybGluZSIsCiAgICAgICAgICAicG93ZXJsaW5lX3N5bWJvbCI6ICJcdUUwQjQiLAogICAgICAgICAgImJhY2tncm91bmQiOiAiIzM2NzBBMCIsCiAgICAgICAgICAiZm9yZWdyb3VuZCI6ICIjRkZERDU0IiwKICAgICAgICAgICJ0ZW1wbGF0ZSI6ICIgIHt7IC5GdWxsIH19ICIsCiAgICAgICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAgICAgImRpc3BsYXlfbW9kZSI6ICJmaWxlcyIsCiAgICAgICAgICAgICJtaXNzaW5nX2NvbW1hbmRfdGV4dCI6ICIiCiAgICAgICAgICB9CiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAidHlwZSI6ICJkb3RuZXQiLAogICAgICAgICAgInN0eWxlIjogInBvd2VybGluZSIsCiAgICAgICAgICAicG93ZXJsaW5lX3N5bWJvbCI6ICJcdUUwQjQiLAogICAgICAgICAgImJhY2tncm91bmQiOiAiIzUxMkJENCIsCiAgICAgICAgICAiZm9yZWdyb3VuZCI6ICIjRThFOEU4IiwKICAgICAgICAgICJ0ZW1wbGF0ZSI6ICIgXHVFNzdGIHt7IC5GdWxsIH19ICIsCiAgICAgICAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAgICAgImRpc3BsYXlfbW9kZSI6ICJmaWxlcyIsCiAgICAgICAgICAgICJtaXNzaW5nX2NvbW1hbmRfdGV4dCI6ICIiCiAgICAgICAgICB9CiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAidHlwZSI6ICJleGVjdXRpb250aW1lIiwKICAgICAgICAgICJzdHlsZSI6ICJwb3dlcmxpbmUiLAogICAgICAgICAgInBvd2VybGluZV9zeW1ib2wiOiAiXHVFMEI0IiwKICAgICAgICAgICJiYWNrZ3JvdW5kIjogIiMxQTFCMjYiLAogICAgICAgICAgImZvcmVncm91bmQiOiAiI0UwQUY2OCIsCiAgICAgICAgICAidGVtcGxhdGUiOiAiIFx1RjAxNyB7eyAuRm9ybWF0dGVkTXMgfX0gIiwKICAgICAgICAgICJwcm9wZXJ0aWVzIjogewogICAgICAgICAgICAidGhyZXNob2xkIjogMjAwMCwKICAgICAgICAgICAgInN0eWxlIjogImF1c3RpbiIsCiAgICAgICAgICAgICJhbHdheXNfZW5hYmxlZCI6IGZhbHNlCiAgICAgICAgICB9CiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAidHlwZSI6ICJzdGF0dXMiLAogICAgICAgICAgInN0eWxlIjogImRpYW1vbmQiLAogICAgICAgICAgImxlYWRpbmdfZGlhbW9uZCI6ICIgXHVFMEI2IiwKICAgICAgICAgICJ0cmFpbGluZ19kaWFtb25kIjogIlx1RTBCNCIsCiAgICAgICAgICAiYmFja2dyb3VuZCI6ICIjOUVDRTZBIiwKICAgICAgICAgICJiYWNrZ3JvdW5kX3RlbXBsYXRlcyI6IFsKICAgICAgICAgICAgInt7IGlmIGd0IC5Db2RlIDAgfX0jRjc3NjhFe3sgZW5kIH19IgogICAgICAgICAgXSwKICAgICAgICAgICJmb3JlZ3JvdW5kIjogIiMxQTFCMjYiLAogICAgICAgICAgInRlbXBsYXRlIjogIiB7eyBpZiBndCAuQ29kZSAwIH19XHVGMDBEIHt7IC5Db2RlIH19e3sgZWxzZSB9fVx1RjAwQ3t7IGVuZCB9fSAiLAogICAgICAgICAgInByb3BlcnRpZXMiOiB7CiAgICAgICAgICAgICJhbHdheXNfZW5hYmxlZCI6IHRydWUKICAgICAgICAgIH0KICAgICAgICB9CiAgICAgIF0KICAgIH0sCiAgICB7CiAgICAgICJ0eXBlIjogInJwcm9tcHQiLAogICAgICAib3ZlcmZsb3ciOiAiaGlkZGVuIiwKICAgICAgInNlZ21lbnRzIjogWwogICAgICAgIHsKICAgICAgICAgICJ0eXBlIjogInRpbWUiLAogICAgICAgICAgInN0eWxlIjogInBsYWluIiwKICAgICAgICAgICJiYWNrZ3JvdW5kIjogInRyYW5zcGFyZW50IiwKICAgICAgICAgICJmb3JlZ3JvdW5kIjogIiM0MTQ4NjgiLAogICAgICAgICAgInRlbXBsYXRlIjogInt7IC5DdXJyZW50RGF0ZSB8IGRhdGUgXCIxNTowNDowNVwiIH19IgogICAgICAgIH0KICAgICAgXQogICAgfSwKICAgIHsKICAgICAgInR5cGUiOiAicHJvbXB0IiwKICAgICAgImFsaWdubWVudCI6ICJsZWZ0IiwKICAgICAgIm5ld2xpbmUiOiB0cnVlLAogICAgICAic2VnbWVudHMiOiBbCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAidGV4dCIsCiAgICAgICAgICAic3R5bGUiOiAicGxhaW4iLAogICAgICAgICAgImJhY2tncm91bmQiOiAidHJhbnNwYXJlbnQiLAogICAgICAgICAgImZvcmVncm91bmQiOiAiIzdBQTJGNyIsCiAgICAgICAgICAidGVtcGxhdGUiOiAiPiAiCiAgICAgICAgfQogICAgICBdCiAgICB9CiAgXQp9Cg=="
[System.IO.File]::WriteAllBytes(
    $ompThemePath,
    [Convert]::FromBase64String($_themeB64)
)
Write-OK "Tema Tokyo Night creado: $ompThemePath"

# ── 7. Modulos PowerShell ─────────────────────────────────────────────────────
Write-Step "Verificando modulos de PowerShell..."
$pwshExe = (Get-Command pwsh -ErrorAction SilentlyContinue)
if ($pwshExe) { $pwshExe = $pwshExe.Source } else { $pwshExe = "powershell" }

$modBlock = {
    $ProgressPreference    = 'SilentlyContinue'
    $ErrorActionPreference = 'SilentlyContinue'
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    # Tabla: modulo -> version minima recomendada
    $mods = [ordered]@{
        "PSReadLine"          = "2.3.0"
        "Terminal-Icons"      = "0.11.0"
        "posh-git"            = "1.1.0"
        "z"                   = "1.1.0"
        "CompletionPredictor" = "0.0.1"
    }

    foreach ($m in $mods.Keys) {
        $minVer  = [Version]$mods[$m]
        $inst    = Get-Module -ListAvailable -Name $m | Sort-Object Version -Descending | Select-Object -First 1

        if (-not $inst) {
            # No instalado -> instalar
            Install-Module -Name $m -Force -SkipPublisherCheck -Scope CurrentUser -AllowClobber
            $inst = Get-Module -ListAvailable -Name $m | Sort-Object Version -Descending | Select-Object -First 1
            Write-Host "    + $m instalado v$($inst.Version)" -ForegroundColor Green
        } elseif ($inst.Version -lt $minVer) {
            # Instalado pero version vieja -> actualizar
            Write-Host "    ~ $m v$($inst.Version) < $minVer - actualizando..." -ForegroundColor Yellow
            Update-Module -Name $m -Force -ErrorAction SilentlyContinue
            $inst = Get-Module -ListAvailable -Name $m | Sort-Object Version -Descending | Select-Object -First 1
            Write-Host "    + $m actualizado a v$($inst.Version)" -ForegroundColor Green
        } else {
            # OK
            Write-Host "    = $m v$($inst.Version) - OK" -ForegroundColor DarkGreen
        }
    }
}
$enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($modBlock.ToString()))
Start-Process $pwshExe -ArgumentList "-NoProfile -EncodedCommand $enc" -Wait -NoNewWindow
Write-OK "Modulos verificados/actualizados"

# ── 8. Perfil de PowerShell ───────────────────────────────────────────────────
Write-Step "Configurando perfil de PowerShell..."

$profilePS7  = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$profilePS5  = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
New-Item -ItemType Directory -Path (Split-Path $profilePS7) -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $profilePS5) -Force | Out-Null

# Construir el perfil como array de strings para evitar problemas de escape
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# ================================================================")
$lines.Add("#   POWERSHELL MODERN PROFILE - Generado por ModernTerminal.ps1")
$lines.Add("# ================================================================")
$lines.Add("")
$lines.Add("# Oh-My-Posh")
$lines.Add('$_omp = "$env:USERPROFILE\.config\ohmyposh\theme.omp.json"')
$lines.Add('if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $_omp)) {')
$lines.Add('    oh-my-posh init pwsh --config $_omp | Invoke-Expression')
$lines.Add('} elseif (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {')
$lines.Add('    oh-my-posh init pwsh | Invoke-Expression')
$lines.Add('}')
$lines.Add("")
$lines.Add("# Modulos")
$lines.Add('Import-Module Terminal-Icons      -ErrorAction SilentlyContinue')
$lines.Add('Import-Module PSReadLine          -ErrorAction SilentlyContinue')
$lines.Add('Import-Module posh-git            -ErrorAction SilentlyContinue')
$lines.Add('Import-Module z                   -ErrorAction SilentlyContinue')
$lines.Add('Import-Module CompletionPredictor -ErrorAction SilentlyContinue')
$lines.Add("")
$lines.Add("# PSReadLine")
$lines.Add('if ($PSVersionTable.PSVersion.Major -ge 7) {')
$lines.Add('    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue')
$lines.Add('} else {')
$lines.Add('    Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue')
$lines.Add('}')
$lines.Add('Set-PSReadLineOption -PredictionViewStyle ListView         -ErrorAction SilentlyContinue')
$lines.Add('Set-PSReadLineOption -EditMode Windows                     -ErrorAction SilentlyContinue')
$lines.Add('Set-PSReadLineOption -BellStyle None                       -ErrorAction SilentlyContinue')
$lines.Add('Set-PSReadLineOption -MaximumHistoryCount 10000            -ErrorAction SilentlyContinue')
$lines.Add('Set-PSReadLineOption -HistorySearchCursorMovesToEnd        -ErrorAction SilentlyContinue')
$lines.Add('Set-PSReadLineOption -Colors @{')
$lines.Add('    Command            = "#7AA2F7"')
$lines.Add('    Keyword            = "#BB9AF7"')
$lines.Add('    String             = "#9ECE6A"')
$lines.Add('    Variable           = "#9ECCEA"')
$lines.Add('    Comment            = "#565F89"')
$lines.Add('    Error              = "#F7768E"')
$lines.Add('    InlinePrediction   = "#565F89"')
$lines.Add('    ListPrediction     = "#9ECE6A"')
$lines.Add('    ListPredictionSelected = "#7AA2F7"')
$lines.Add('} -ErrorAction SilentlyContinue')
$lines.Add("")
$lines.Add('Set-PSReadLineKeyHandler -Key Tab             -Function MenuComplete')
$lines.Add('Set-PSReadLineKeyHandler -Key UpArrow         -Function HistorySearchBackward')
$lines.Add('Set-PSReadLineKeyHandler -Key DownArrow       -Function HistorySearchForward')
$lines.Add('Set-PSReadLineKeyHandler -Key Ctrl+d          -Function DeleteCharOrExit')
$lines.Add('Set-PSReadLineKeyHandler -Key Ctrl+l          -Function ClearScreen')
$lines.Add("")
$lines.Add("# Variables de entorno")
$lines.Add('$env:VIRTUAL_ENV_DISABLE_PROMPT = 1')
$lines.Add('$env:POSH_GIT_ENABLED           = $true')
$lines.Add("")
$lines.Add("# Aliases")
$lines.Add('Set-Alias -Name ll     -Value Get-ChildItem -Force')
$lines.Add('Set-Alias -Name touch  -Value New-Item      -Force')
$lines.Add('Set-Alias -Name which  -Value Get-Command   -Force')
$lines.Add('Set-Alias -Name grep   -Value Select-String -Force')
$lines.Add("")
$lines.Add("# Funciones de navegacion")
$lines.Add('function .. { Set-Location .. }')
$lines.Add('function ... { Set-Location ..\.. }')
$lines.Add('function .... { Set-Location ..\..\.. }')
$lines.Add("")
$lines.Add('function mkcd {')
$lines.Add('    param([Parameter(Mandatory)][string]$Path)')
$lines.Add('    New-Item -ItemType Directory -Path $Path -Force | Out-Null')
$lines.Add('    Set-Location $Path')
$lines.Add('    Write-Host "  Directorio creado: $Path" -ForegroundColor Cyan')
$lines.Add('}')
$lines.Add("")
$lines.Add('function gcd {')
$lines.Add('    $root = git rev-parse --show-toplevel 2>$null')
$lines.Add('    if ($root) { Set-Location $root }')
$lines.Add('    else { Write-Host "  No estas en un repositorio git" -ForegroundColor Yellow }')
$lines.Add('}')
$lines.Add("")
$lines.Add('function myip {')
$lines.Add('    try {')
$lines.Add('        $ip = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec 5).ip')
$lines.Add('        Write-Host "  IP Publica: $ip" -ForegroundColor Cyan')
$lines.Add('    } catch { Write-Host "  Sin conexion" -ForegroundColor Red }')
$lines.Add('}')
$lines.Add("")
$lines.Add('function sysinfo {')
$lines.Add('    $os  = Get-CimInstance Win32_OperatingSystem')
$lines.Add('    $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name')
$lines.Add('    $ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)')
$lines.Add('    $free = [math]::Round($os.FreePhysicalMemory / 1MB, 1)')
$lines.Add('    $disk = Get-PSDrive C')
$lines.Add('    Write-Host ""')
$lines.Add('    Write-Host "  OS   : $($os.Caption)" -ForegroundColor Blue')
$lines.Add('    Write-Host "  CPU  : $cpu" -ForegroundColor Cyan')
$lines.Add('    Write-Host "  RAM  : ${ram}GB total / ${free}GB libre" -ForegroundColor Cyan')
$lines.Add('    Write-Host "  Disco: C: $([math]::Round($disk.Used/1GB,1))GB usado / $([math]::Round($disk.Free/1GB,1))GB libre" -ForegroundColor Cyan')
$lines.Add('    Write-Host "  Shell: PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Cyan')
$lines.Add('    Write-Host ""')
$lines.Add('}')
$lines.Add("")
$lines.Add('function Get-PortProcess {')
$lines.Add('    param([Parameter(Mandatory)][int]$Port)')
$lines.Add('    $c = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue')
$lines.Add('    if ($c) {')
$lines.Add('        $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue')
$lines.Add('        Write-Host "  Puerto $Port : $($p.Name) (PID $($p.Id))" -ForegroundColor Cyan')
$lines.Add('    } else { Write-Host "  Puerto $Port no en uso" -ForegroundColor Yellow }')
$lines.Add('}')
$lines.Add('Set-Alias -Name portof -Value Get-PortProcess -Force')
$lines.Add("")
$lines.Add('function Update-Profile { . $PROFILE; Write-Host "  Perfil recargado" -ForegroundColor Green }')
$lines.Add('Set-Alias -Name reload -Value Update-Profile -Force')
$lines.Add("")
$lines.Add("# Git shortcuts")
$lines.Add('function gs   { git status -sb @args }')
$lines.Add('function ga   { git add @args }')
$lines.Add('function gaa  { git add --all }')
$lines.Add('function gc   { git commit -m @args }')
$lines.Add('function gca  { git commit --amend --no-edit }')
$lines.Add('function gp   { git push @args }')
$lines.Add('function gpf  { git push --force-with-lease }')
$lines.Add('function gl   { git log --oneline --graph --decorate -20 }')
$lines.Add('function gla  { git log --oneline --graph --decorate --all -30 }')
$lines.Add('function gco  { git checkout @args }')
$lines.Add('function gb   { git branch @args }')
$lines.Add('function gd   { git diff @args }')
$lines.Add('function gds  { git diff --staged @args }')
$lines.Add('function gst  { git stash @args }')
$lines.Add('function gstp { git stash pop }')
$lines.Add('function gf   { git fetch --prune }')
$lines.Add('function gpl  { git pull --rebase }')

$profileText = $lines -join "`n"
[System.IO.File]::WriteAllText($profilePS7, $profileText, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($profilePS5, $profileText, [System.Text.Encoding]::UTF8)
Write-OK "Perfil PS7 configurado: $profilePS7"
Write-OK "Perfil PS5 configurado: $profilePS5"

# ── 9. Windows Terminal settings.json ─────────────────────────────────────────
Write-Step "Configurando Windows Terminal..."

$wtPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
$wtPath = $null
foreach ($p in $wtPaths) {
    if (Test-Path (Split-Path $p)) { $wtPath = $p; break }
}
if (-not $wtPath) {
    $wtPath = $wtPaths[0]
    New-Item -ItemType Directory -Path (Split-Path $wtPath) -Force | Out-Null
}
if (Test-Path $wtPath) {
    $bak = "$wtPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $wtPath $bak -Force
    Write-Info "Backup: $bak"
}

$_wtB64 = "ewogICIkc2NoZW1hIjogImh0dHBzOi8vYWthLm1zL3Rlcm1pbmFsLXNldHRpbmdzLXNjaGVtYSIsCiAgImRlZmF1bHRQcm9maWxlIjogIns1NzRlNzc1ZS00ZjJhLTViOTYtYWMxZS1hMjk2MmE0MDIzMzZ9IiwKICAiY29weU9uU2VsZWN0IjogZmFsc2UsCiAgImNvcHlGb3JtYXR0aW5nIjogIm5vbmUiLAogICJ3b3JkRGVsaW1pdGVycyI6ICIgL1xcKClcXFwiJzs6Liw8PiEmfCN7fVtdQCIsCiAgInRyaW1CbG9ja1NlbGVjdGlvbiI6IHRydWUsCiAgInRyaW1QYXN0ZSI6IHRydWUsCiAgImZvY3VzRm9sbG93TW91c2UiOiBmYWxzZSwKICAiaW5pdGlhbENvbHMiOiAxMzAsCiAgImluaXRpYWxSb3dzIjogMzQsCiAgInRoZW1lIjogImRhcmsiLAogICJ1c2VBY3J5bGljSW5UYWJSb3ciOiB0cnVlLAogICJuZXdUYWJNZW51IjogW3sgInR5cGUiOiAicmVtYWluaW5nUHJvZmlsZXMiIH1dLAogICJwcm9maWxlcyI6IHsKICAgICJkZWZhdWx0cyI6IHsKICAgICAgImZvbnQiOiB7CiAgICAgICAgImZhY2UiOiAiQ2Fza2F5ZGlhQ292ZSBOZXJkIEZvbnQiLAogICAgICAgICJzaXplIjogMTEsCiAgICAgICAgIndlaWdodCI6ICJub3JtYWwiCiAgICAgIH0sCiAgICAgICJvcGFjaXR5IjogOTIsCiAgICAgICJ1c2VBY3J5bGljIjogdHJ1ZSwKICAgICAgImFjcnlsaWNPcGFjaXR5IjogMC44OCwKICAgICAgImNvbG9yU2NoZW1lIjogIlRva3lvIE5pZ2h0IiwKICAgICAgImN1cnNvclNoYXBlIjogImJhciIsCiAgICAgICJjdXJzb3JDb2xvciI6ICIjN0FBMkY3IiwKICAgICAgInNjcm9sbGJhclN0YXRlIjogImhpZGRlbiIsCiAgICAgICJwYWRkaW5nIjogIjEwLCAxMCIsCiAgICAgICJhbnRpYWxpYXNpbmdNb2RlIjogImNsZWFydHlwZSIsCiAgICAgICJiZWxsU3R5bGUiOiAibm9uZSIsCiAgICAgICJjbG9zZU9uRXhpdCI6ICJncmFjZWZ1bCIsCiAgICAgICJoaXN0b3J5U2l6ZSI6IDIwMDAwLAogICAgICAic25hcE9uSW5wdXQiOiB0cnVlLAogICAgICAiYWx0R3JBbGlhc2luZyI6IHRydWUKICAgIH0sCiAgICAibGlzdCI6IFsKICAgICAgewogICAgICAgICJndWlkIjogIns1NzRlNzc1ZS00ZjJhLTViOTYtYWMxZS1hMjk2MmE0MDIzMzZ9IiwKICAgICAgICAibmFtZSI6ICJQb3dlclNoZWxsIiwKICAgICAgICAiY29tbWFuZGxpbmUiOiAicHdzaC5leGUgLU5vTG9nbyIsCiAgICAgICAgImhpZGRlbiI6IGZhbHNlLAogICAgICAgICJzdGFydGluZ0RpcmVjdG9yeSI6ICIlVVNFUlBST0ZJTEUlIiwKICAgICAgICAiaWNvbiI6ICJtcy1hcHB4Oi8vL1Byb2ZpbGVJY29ucy97NTc0ZTc3NWUtNGYyYS01Yjk2LWFjMWUtYTI5NjJhNDAyMzM2fS5zY2FsZS0yMDAucG5nIgogICAgICB9LAogICAgICB7CiAgICAgICAgImd1aWQiOiAiezBjYWEwZGFkLTM1YmUtNWY1Ni1hOGZmLWFmY2VlZWFhNjEwMX0iLAogICAgICAgICJuYW1lIjogIkNNRCIsCiAgICAgICAgImhpZGRlbiI6IGZhbHNlCiAgICAgIH0sCiAgICAgIHsKICAgICAgICAiZ3VpZCI6ICJ7NjFjNTRiYmQtYzJjNi01MjcxLTk2ZTctMDA5YTg3ZmY0NGJmfSIsCiAgICAgICAgIm5hbWUiOiAiV2luZG93cyBQb3dlclNoZWxsIiwKICAgICAgICAiaGlkZGVuIjogZmFsc2UKICAgICAgfQogICAgXQogIH0sCiAgInNjaGVtZXMiOiBbCiAgICB7CiAgICAgICJuYW1lIjogIlRva3lvIE5pZ2h0IiwKICAgICAgImJhY2tncm91bmQiOiAiIzFBMUIyNiIsCiAgICAgICJmb3JlZ3JvdW5kIjogIiNDMENBRjUiLAogICAgICAiY3Vyc29yQ29sb3IiOiAiI0MwQ0FGNSIsCiAgICAgICJzZWxlY3Rpb25CYWNrZ3JvdW5kIjogIiMyODM0NTciLAogICAgICAiYmxhY2siOiAiIzE1MTYxRSIsCiAgICAgICJyZWQiOiAiI0Y3NzY4RSIsCiAgICAgICJncmVlbiI6ICIjOUVDRTZBIiwKICAgICAgInllbGxvdyI6ICIjRTBBRjY4IiwKICAgICAgImJsdWUiOiAiIzdBQTJGNyIsCiAgICAgICJwdXJwbGUiOiAiI0JCOUFGNyIsCiAgICAgICJjeWFuIjogIiM3RENGRkYiLAogICAgICAid2hpdGUiOiAiI0E5QjFENiIsCiAgICAgICJicmlnaHRCbGFjayI6ICIjNDE0ODY4IiwKICAgICAgImJyaWdodFJlZCI6ICIjRjc3NjhFIiwKICAgICAgImJyaWdodEdyZWVuIjogIiM5RUNFNkEiLAogICAgICAiYnJpZ2h0WWVsbG93IjogIiNFMEFGNjgiLAogICAgICAiYnJpZ2h0Qmx1ZSI6ICIjN0FBMkY3IiwKICAgICAgImJyaWdodFB1cnBsZSI6ICIjQkI5QUY3IiwKICAgICAgImJyaWdodEN5YW4iOiAiIzdEQ0ZGRiIsCiAgICAgICJicmlnaHRXaGl0ZSI6ICIjQzBDQUY1IgogICAgfSwKICAgIHsKICAgICAgIm5hbWUiOiAiQ2F0cHB1Y2NpbiBNb2NoYSIsCiAgICAgICJiYWNrZ3JvdW5kIjogIiMxRTFFMkUiLAogICAgICAiZm9yZWdyb3VuZCI6ICIjQ0RENkY0IiwKICAgICAgImN1cnNvckNvbG9yIjogIiNGNUUwREMiLAogICAgICAic2VsZWN0aW9uQmFja2dyb3VuZCI6ICIjNTg1QjcwIiwKICAgICAgImJsYWNrIjogIiM0NTQ3NUEiLAogICAgICAicmVkIjogIiNGMzhCQTgiLAogICAgICAiZ3JlZW4iOiAiI0E2RTNBMSIsCiAgICAgICJ5ZWxsb3ciOiAiI0Y5RTJBRiIsCiAgICAgICJibHVlIjogIiM4OUI0RkEiLAogICAgICAicHVycGxlIjogIiNDQkE2RjciLAogICAgICAiY3lhbiI6ICIjODlEQ0VCIiwKICAgICAgIndoaXRlIjogIiNCQUMyREUiLAogICAgICAiYnJpZ2h0QmxhY2siOiAiIzU4NUI3MCIsCiAgICAgICJicmlnaHRSZWQiOiAiI0YzOEJBOCIsCiAgICAgICJicmlnaHRHcmVlbiI6ICIjQTZFM0ExIiwKICAgICAgImJyaWdodFllbGxvdyI6ICIjRjlFMkFGIiwKICAgICAgImJyaWdodEJsdWUiOiAiIzg5QjRGQSIsCiAgICAgICJicmlnaHRQdXJwbGUiOiAiI0NCQTZGNyIsCiAgICAgICJicmlnaHRDeWFuIjogIiM4OURDRUIiLAogICAgICAiYnJpZ2h0V2hpdGUiOiAiI0E2QURDOCIKICAgIH0sCiAgICB7CiAgICAgICJuYW1lIjogIkRyYWN1bGEiLAogICAgICAiYmFja2dyb3VuZCI6ICIjMjgyQTM2IiwKICAgICAgImZvcmVncm91bmQiOiAiI0Y4RjhGMiIsCiAgICAgICJjdXJzb3JDb2xvciI6ICIjRjhGOEYyIiwKICAgICAgInNlbGVjdGlvbkJhY2tncm91bmQiOiAiIzQ0NDc1QSIsCiAgICAgICJibGFjayI6ICIjMjEyMjJDIiwKICAgICAgInJlZCI6ICIjRkY1NTU1IiwKICAgICAgImdyZWVuIjogIiM1MEZBN0IiLAogICAgICAieWVsbG93IjogIiNGMUZBOEMiLAogICAgICAiYmx1ZSI6ICIjQkQ5M0Y5IiwKICAgICAgInB1cnBsZSI6ICIjRkY3OUM2IiwKICAgICAgImN5YW4iOiAiIzhCRTlGRCIsCiAgICAgICJ3aGl0ZSI6ICIjRjhGOEYyIiwKICAgICAgImJyaWdodEJsYWNrIjogIiM2MjcyQTQiLAogICAgICAiYnJpZ2h0UmVkIjogIiNGRjZFNkUiLAogICAgICAiYnJpZ2h0R3JlZW4iOiAiIzY5RkY5NCIsCiAgICAgICJicmlnaHRZZWxsb3ciOiAiI0ZGRkZBNSIsCiAgICAgICJicmlnaHRCbHVlIjogIiNENkFDRkYiLAogICAgICAiYnJpZ2h0UHVycGxlIjogIiNGRjkyREYiLAogICAgICAiYnJpZ2h0Q3lhbiI6ICIjQTRGRkZGIiwKICAgICAgImJyaWdodFdoaXRlIjogIiNGRkZGRkYiCiAgICB9CiAgXSwKICAiYWN0aW9ucyI6IFsKICAgIHsgImNvbW1hbmQiOiAicGFzdGUiLCAgICAgICAgICAia2V5cyI6ICJjdHJsK3YiIH0sCiAgICB7ICJjb21tYW5kIjogImNvcHkiLCAgICAgICAgICAgImtleXMiOiAiY3RybCtjIiB9LAogICAgeyAiY29tbWFuZCI6ICJmaW5kIiwgICAgICAgICAgICJrZXlzIjogImN0cmwrc2hpZnQrZiIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAibmV3VGFiIiB9LCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAia2V5cyI6ICJjdHJsK3QiIH0sCiAgICB7ICJjb21tYW5kIjogImNsb3NlVGFiIiwgICAgICAgImtleXMiOiAiY3RybCt3IiB9LAogICAgeyAiY29tbWFuZCI6IHsgImFjdGlvbiI6ICJzcGxpdFBhbmUiLCAic3BsaXQiOiAiaG9yaXpvbnRhbCIsICJzcGxpdE1vZGUiOiAiZHVwbGljYXRlIiB9LCAia2V5cyI6ICJhbHQrc2hpZnQrbWludXMiIH0sCiAgICB7ICJjb21tYW5kIjogeyAiYWN0aW9uIjogInNwbGl0UGFuZSIsICJzcGxpdCI6ICJ2ZXJ0aWNhbCIsICAgInNwbGl0TW9kZSI6ICJkdXBsaWNhdGUiIH0sICJrZXlzIjogImFsdCtzaGlmdCtwbHVzIiB9LAogICAgeyAiY29tbWFuZCI6IHsgImFjdGlvbiI6ICJtb3ZlRm9jdXMiLCAgICJkaXJlY3Rpb24iOiAibGVmdCIgIH0sICJrZXlzIjogImFsdCtsZWZ0IiB9LAogICAgeyAiY29tbWFuZCI6IHsgImFjdGlvbiI6ICJtb3ZlRm9jdXMiLCAgICJkaXJlY3Rpb24iOiAicmlnaHQiIH0sICJrZXlzIjogImFsdCtyaWdodCIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAibW92ZUZvY3VzIiwgICAiZGlyZWN0aW9uIjogInVwIiAgICB9LCAia2V5cyI6ICJhbHQrdXAiIH0sCiAgICB7ICJjb21tYW5kIjogeyAiYWN0aW9uIjogIm1vdmVGb2N1cyIsICAgImRpcmVjdGlvbiI6ICJkb3duIiAgfSwgImtleXMiOiAiYWx0K2Rvd24iIH0sCiAgICB7ICJjb21tYW5kIjogeyAiYWN0aW9uIjogInJlc2l6ZVBhbmUiLCAgImRpcmVjdGlvbiI6ICJsZWZ0IiAgfSwgImtleXMiOiAiYWx0K3NoaWZ0K2xlZnQiIH0sCiAgICB7ICJjb21tYW5kIjogeyAiYWN0aW9uIjogInJlc2l6ZVBhbmUiLCAgImRpcmVjdGlvbiI6ICJyaWdodCIgfSwgImtleXMiOiAiYWx0K3NoaWZ0K3JpZ2h0IiB9LAogICAgeyAiY29tbWFuZCI6IHsgImFjdGlvbiI6ICJyZXNpemVQYW5lIiwgICJkaXJlY3Rpb24iOiAidXAiICAgIH0sICJrZXlzIjogImFsdCtzaGlmdCt1cCIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAicmVzaXplUGFuZSIsICAiZGlyZWN0aW9uIjogImRvd24iICB9LCAia2V5cyI6ICJhbHQrc2hpZnQrZG93biIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAic3dpdGNoVG9UYWIiLCAiaW5kZXgiOiAwIH0sICJrZXlzIjogImN0cmwrMSIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAic3dpdGNoVG9UYWIiLCAiaW5kZXgiOiAxIH0sICJrZXlzIjogImN0cmwrMiIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAic3dpdGNoVG9UYWIiLCAiaW5kZXgiOiAyIH0sICJrZXlzIjogImN0cmwrMyIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAic3dpdGNoVG9UYWIiLCAiaW5kZXgiOiAzIH0sICJrZXlzIjogImN0cmwrNCIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAic3dpdGNoVG9UYWIiLCAiaW5kZXgiOiA0IH0sICJrZXlzIjogImN0cmwrNSIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAiYWRqdXN0Rm9udFNpemUiLCAiZGVsdGEiOiAgMSB9LCAia2V5cyI6ICJjdHJsKz0iIH0sCiAgICB7ICJjb21tYW5kIjogeyAiYWN0aW9uIjogImFkanVzdEZvbnRTaXplIiwgImRlbHRhIjogLTEgfSwgImtleXMiOiAiY3RybCstIiB9LAogICAgeyAiY29tbWFuZCI6ICJyZXNldEZvbnRTaXplIiwgICJrZXlzIjogImN0cmwrMCIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAic2Nyb2xsVXAiLCAgICAgICAicm93c1RvU2Nyb2xsIjogNSB9LCAia2V5cyI6ICJzaGlmdCt1cCIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAic2Nyb2xsRG93biIsICAgICAicm93c1RvU2Nyb2xsIjogNSB9LCAia2V5cyI6ICJzaGlmdCtkb3duIiB9LAogICAgeyAiY29tbWFuZCI6IHsgImFjdGlvbiI6ICJzY3JvbGxVcFBhZ2UiICAgfSwgImtleXMiOiAic2hpZnQrcGd1cCIgfSwKICAgIHsgImNvbW1hbmQiOiB7ICJhY3Rpb24iOiAic2Nyb2xsRG93blBhZ2UiIH0sICJrZXlzIjogInNoaWZ0K3BnZG4iIH0sCiAgICB7ICJjb21tYW5kIjogInRvZ2dsZUZ1bGxzY3JlZW4iLCAia2V5cyI6ICJhbHQrZW50ZXIiIH0KICBdCn0K"
[System.IO.File]::WriteAllBytes(
    $wtPath,
    [Convert]::FromBase64String($_wtB64)
)
Write-OK "Windows Terminal configurado: $wtPath"

# ── 10. Execution Policy ───────────────────────────────────────────────────────
Write-Step "Configurando Execution Policy..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Write-OK "ExecutionPolicy: RemoteSigned (CurrentUser)"

# ── Resumen ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "  ║         MODERNIZACION COMPLETADA ✔              ║" -ForegroundColor Blue
Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "  Instalado:" -ForegroundColor White
Write-Host "    ✔  PowerShell 7          pwsh
    ✔  Git                   git + integracion posh-git"                 -ForegroundColor Green
Write-Host "    ✔  Windows Terminal      Tema Tokyo Night"     -ForegroundColor Green
Write-Host "    ✔  CaskaydiaCove NF      Iconos y simbolos"    -ForegroundColor Green
Write-Host "    ✔  Oh-My-Posh            Prompt moderno"       -ForegroundColor Green
Write-Host "    ✔  Terminal-Icons        Iconos en ls"         -ForegroundColor Green
Write-Host "    ✔  PSReadLine            Autocompletado"       -ForegroundColor Green
Write-Host "    ✔  posh-git + z          Git y navegar dirs"   -ForegroundColor Green
Write-Host "    ✔  Perfil configurado    Aliases y funciones"  -ForegroundColor Green
Write-Host ""
Write-Host "  Atajos Windows Terminal:" -ForegroundColor White
Write-Host "    Ctrl+T        Nueva pestana"                   -ForegroundColor DarkCyan
Write-Host "    Ctrl+W        Cerrar pestana"                  -ForegroundColor DarkCyan
Write-Host "    Alt+Shift+-   Split horizontal"                -ForegroundColor DarkCyan
Write-Host "    Alt+Shift++   Split vertical"                  -ForegroundColor DarkCyan
Write-Host "    Alt+Flechas   Navegar entre paneles"           -ForegroundColor DarkCyan
Write-Host "    Alt+Enter     Pantalla completa"               -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Funciones del perfil:" -ForegroundColor White
Write-Host "    sysinfo  myip  mkcd  gcd  portof  reload"     -ForegroundColor DarkYellow
Write-Host "    gs ga gc gp gl gco gb gd  (git shortcuts)"    -ForegroundColor DarkYellow
Write-Host "    .. ... ....  (navegar directorios)"           -ForegroundColor DarkYellow
Write-Host ""
Write-Host "  >> REINICIA Windows Terminal para aplicar cambios <<" -ForegroundColor Yellow
Write-Host ""