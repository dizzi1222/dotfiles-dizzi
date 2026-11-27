<#
.SYNOPSIS
  Limpieza segura de Windows: libera espacio en C: sin tocar juegos ni programas.

.DESCRIPTION
  Borra solo cosas que se regeneran solas:
    - Dumps de errores del kernel (LiveKernelReports, Minidump, MEMORY.DMP)
    - Temporales de usuario y de Windows
    - Papelera de reciclaje (borrado permanente)
    - Caché de descargas de Windows Update y Delivery Optimization
    - npm-cache y ~/.cache (huggingface, opencode, etc. se vuelven a descargar)
    - Cachés de navegadores (Chrome, Edge, Brave, Firefox, Zen) — no toca perfiles, contraseñas ni historial
  NUNCA borra juegos, apps ni VMs: al final solo los LISTA con su tamaño, como
  información. La hibernación tampoco se toca salvo que respondas "s" a la
  pregunta (por defecto NO) o pases -DisableHibernation a propósito.

.PARAMETER DryRun
  No borra nada: solo muestra cuánto liberaría cada paso.

.PARAMETER DisableHibernation
  Desactiva la hibernación (borra hiberfil.sys) sin preguntar.

.PARAMETER SkipDevCaches
  No toca npm-cache ni ~/.cache.

.EXAMPLE
  .\windows-cleanup.ps1 -DryRun
  .\windows-cleanup.ps1
  .\windows-cleanup.ps1 -DisableHibernation
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$DisableHibernation,
    [switch]$SkipDevCaches
)

# --- Elevar a administrador si hace falta ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
$hasPwsh = [bool](Get-Command pwsh -ErrorAction SilentlyContinue)
$needPwsh = $PSVersionTable.PSVersion.Major -lt 7 -and $hasPwsh
if (-not $isAdmin -or $needPwsh) {
    $shell = if ($hasPwsh) { 'pwsh' } else { 'powershell' }
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', "`"$PSCommandPath`"")
    foreach ($k in $PSBoundParameters.Keys) { $argList += "-$k" }
    Start-Process $shell -Verb RunAs -ArgumentList $argList
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
$U = $env:USERPROFILE
$L = $env:LOCALAPPDATA
$R = $env:APPDATA

function Write-Step($m) { Write-Host ">>> $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "  ✓ $m" -ForegroundColor Green }
function Write-Note($m) { Write-Host "  · $m" -ForegroundColor DarkGray }
function Format-Size([long]$b) { if ($b -ge 1GB) { '{0:N1} GB' -f ($b / 1GB) } else { '{0:N0} MB' -f ($b / 1MB) } }

function Get-Size([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return 0L }
    $item = Get-Item -LiteralPath $path -Force
    if (-not $item.PSIsContainer) { return [long]$item.Length }
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        return [long](Get-ChildItem -LiteralPath $path -Recurse -Force -File | Measure-Object Length -Sum).Sum
    }
    $opt = [System.IO.EnumerationOptions]::new()
    $opt.RecurseSubdirectories = $true; $opt.IgnoreInaccessible = $true
    $opt.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint
    $sum = 0L
    foreach ($f in [System.IO.Directory]::EnumerateFiles($path, '*', $opt)) {
        try { $sum += ([System.IO.FileInfo]$f).Length } catch {}
    }
    return $sum
}

# Vacía el contenido de una carpeta (o borra un archivo). Devuelve los bytes liberados.
function Clear-Path([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return 0L }
    $before = Get-Size $path
    if ($DryRun) { return $before }
    $item = Get-Item -LiteralPath $path -Force
    if ($item.PSIsContainer) {
        Get-ChildItem -LiteralPath $path -Force | Remove-Item -Recurse -Force
    } else {
        Remove-Item -LiteralPath $path -Force
    }
    return [math]::Max(0L, $before - (Get-Size $path))
}

$results = [System.Collections.Generic.List[object]]::new()
function Invoke-Clean([string]$label, [string[]]$paths) {
    $freed = 0L
    foreach ($p in $paths) { $freed += Clear-Path $p }
    $results.Add([pscustomobject]@{ Paso = $label; Liberado = $freed })
    if ($freed -ge 1MB) { Write-Ok "$label — $(Format-Size $freed)" } else { Write-Note "$label — nada" }
}

$freeBefore = (Get-PSDrive C).Free
Write-Host ''
Write-Host ('=== Limpieza de Windows {0}===' -f $(if ($DryRun) { '(SIMULACIÓN) ' } else { '' })) -ForegroundColor Yellow
Write-Host ('Libre en C: antes: {0}' -f (Format-Size $freeBefore))
Write-Host ''

# 1. Dumps de errores
Write-Step 'Dumps de errores del kernel'
$dumps = @()
$dumps += Get-ChildItem "$env:windir\LiveKernelReports" -Recurse -Force -File -Filter *.dmp | ForEach-Object FullName
$dumps += "$env:windir\Minidump", "$env:windir\MEMORY.DMP"
Invoke-Clean 'Dumps (LiveKernelReports, Minidump, MEMORY.DMP)' $dumps

# 2. Temporales
Write-Step 'Temporales'
Invoke-Clean 'Temp de usuario y de Windows' @($env:TEMP, "$env:windir\Temp")

# 3. Papelera
Write-Step 'Papelera de reciclaje'
$binSize = 0L
Get-PSDrive -PSProvider FileSystem | ForEach-Object { $binSize += Get-Size "$($_.Root)`$Recycle.Bin" }
if (-not $DryRun) { Clear-RecycleBin -Force }
$results.Add([pscustomobject]@{ Paso = 'Papelera'; Liberado = $binSize })
if ($binSize -ge 1MB) { Write-Ok "Papelera — $(Format-Size $binSize)" } else { Write-Note 'Papelera — nada' }

# 4. Windows Update + Delivery Optimization
Write-Step 'Caché de Windows Update'
if (-not $DryRun) { Stop-Service wuauserv, bits -Force }
Invoke-Clean 'SoftwareDistribution\Download' @("$env:windir\SoftwareDistribution\Download")
if (-not $DryRun) {
    Start-Service bits, wuauserv
    if (Get-Command Delete-DeliveryOptimizationCache -ErrorAction SilentlyContinue) {
        Delete-DeliveryOptimizationCache -Force
        Write-Note 'Delivery Optimization vaciado'
    }
}

# 5. Cachés de desarrollo
if (-not $SkipDevCaches) {
    Write-Step 'Cachés de desarrollo'
    Invoke-Clean 'npm-cache' @("$L\npm-cache")
    Invoke-Clean '~/.cache (huggingface, opencode, ...)' @("$U\.cache")
}

# 6. Cachés de navegadores (solo caché; perfiles intactos)
Write-Step 'Cachés de navegadores'
$browserRoots = @(
    "$L\Google\Chrome\User Data",
    "$L\Microsoft\Edge\User Data",
    "$L\BraveSoftware\Brave-Browser\User Data",
    "$L\Mozilla\Firefox\Profiles",
    "$L\zen\Profiles"
)
$cacheNames = 'Cache', 'Code Cache', 'GPUCache', 'cache2', 'GrShaderCache', 'ShaderCache', 'DawnGraphiteCache', 'DawnWebGPUCache'
$cacheDirs = foreach ($root in $browserRoots) {
    if (Test-Path -LiteralPath $root) {
        Get-ChildItem -LiteralPath $root -Recurse -Directory -Force -Depth 3 |
            Where-Object { $_.Name -in $cacheNames } | ForEach-Object FullName
    }
}
Invoke-Clean 'Navegadores (Chrome, Edge, Brave, Firefox, Zen)' @($cacheDirs)
if (-not $DryRun -and (Get-Process chrome, msedge, brave, firefox, zen -ErrorAction SilentlyContinue)) {
    Write-Note 'Hay navegadores abiertos: lo que estaba en uso no se pudo borrar.'
}

# --- Resumen ---
$freeAfter = (Get-PSDrive C).Free
$total = ($results | Measure-Object Liberado -Sum).Sum
Write-Host ''
Write-Host '=== Resumen ===' -ForegroundColor Yellow
$results | Where-Object Liberado -ge 1MB |
    Select-Object Paso, @{ n = 'Liberado'; e = { Format-Size $_.Liberado } } | Format-Table -AutoSize | Out-Host
if ($DryRun) {
    Write-Host ('Liberaría ~{0}. Ejecuta sin -DryRun para borrarlo.' -f (Format-Size $total)) -ForegroundColor Green
} else {
    Write-Host ('Libre en C: {0} → {1} (+{2})' -f (Format-Size $freeBefore), (Format-Size $freeAfter),
        (Format-Size ([math]::Max(0L, $freeAfter - $freeBefore)))) -ForegroundColor Green
}

# --- Opcional: lo grande que decides tú ---
Write-Host ''
Write-Host '=== Opcional: solo informativo, NO se borra nada de esto ===' -ForegroundColor Magenta
Write-Host '  Juegos y apps: el script nunca los toca. Si quieres quitar alguno, hazlo tú desde su launcher.' -ForegroundColor DarkGray
$candidates = @(
    @{ Que = 'Fortnite (Epic)';                     Ruta = "$env:ProgramFiles\Epic Games\Fortnite";      Como = 'Desinstalar desde Epic Games Launcher' },
    @{ Que = 'MuMuPlayer VMs (Android, Wild Rift)'; Ruta = "$env:ProgramFiles\Netease\MuMuPlayer\vms";  Como = 'Borrar instancias desde MuMu Multi-instance' },
    @{ Que = 'VALORANT (Riot)';                     Ruta = 'C:\Riot Games\VALORANT';                     Como = 'Desinstalar desde Configuración > Aplicaciones' },
    @{ Que = 'Steam (juegos)';                      Ruta = "${env:ProgramFiles(x86)}\Steam";             Como = 'Steam > Biblioteca > Desinstalar' },
    @{ Que = 'Windows (WinSxS, System32)';          Ruta = "$env:windir";                                Como = 'Déjalo (como mucho: DISM /Online /Cleanup-Image /StartComponentCleanup)' }
)
if (Test-Path 'C:\Games') {
    Get-ChildItem 'C:\Games' -Directory | ForEach-Object {
        $candidates += @{ Que = $_.Name; Ruta = $_.FullName; Como = 'Solo informativo: este script nunca borra juegos' }
    }
}
$rows = foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c.Ruta) {
        $size = if ($c.Ruta -eq $env:windir) { 0L } else { Get-Size $c.Ruta }
        [pscustomobject]@{ Tamano = if ($size) { Format-Size $size } else { '~40 GB' }; Bytes = if ($size) { $size } else { 40GB }; Que = $c.Que; Como = $c.Como }
    }
}
$hiber = "$env:SystemDrive\hiberfil.sys"
$hiberSize = if (Test-Path -LiteralPath $hiber) { (Get-Item -LiteralPath $hiber -Force).Length } else { 0L }
if ($hiberSize) {
    $rows = @($rows) + [pscustomobject]@{ Tamano = Format-Size $hiberSize; Bytes = $hiberSize; Que = 'hiberfil.sys (hibernación)'; Como = 'powercfg /h off  (pierdes Hibernar e Inicio rápido)' }
}
foreach ($r in ($rows | Sort-Object Bytes -Descending)) {
    Write-Host ('  {0,9}  ' -f $r.Tamano) -ForegroundColor White -NoNewline
    Write-Host $r.Que -NoNewline
    Write-Host "  → $($r.Como)" -ForegroundColor DarkGray
}

# --- Hibernación ---
if ($hiberSize -and -not $DryRun) {
    $doIt = $DisableHibernation
    if (-not $doIt) {
        $ans = Read-Host ("¿Desactivar la hibernación y liberar {0}? Es opcional; Intro = no (s/N)" -f (Format-Size $hiberSize))
        $doIt = $ans -match '^(s|si|sí|y|yes)$'
    }
    if ($doIt) {
        powercfg /h off
        Write-Ok ('Hibernación desactivada. Libre en C: ahora {0}' -f (Format-Size (Get-PSDrive C).Free))
        Write-Note 'Para reactivarla: powercfg /h on'
    }
}
