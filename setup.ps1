#Requires -Version 5.1

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PwshDir  = Join-Path $RepoRoot "powershell"
$AhkDir   = Join-Path $RepoRoot "autohotkey"

function Write-Step { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Skip { param($msg) Write-Host "    [--] $msg" -ForegroundColor DarkGray }
function Write-Warn { param($msg) Write-Host "    [!!] $msg" -ForegroundColor Yellow }

# ── 1. PowerShell profile ────────────────────────────────────────────────────
Write-Step "PowerShell profile"

$srcProfile = Join-Path $PwshDir "Microsoft.PowerShell_profile.ps1"
$destProfile = $PROFILE
$profileDir  = Split-Path $destProfile

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force $profileDir | Out-Null
}
if (Test-Path $destProfile) {
    Copy-Item $destProfile "$destProfile.bak" -Force
    Write-Skip "Existing profile backed up to $destProfile.bak"
}
Copy-Item $srcProfile $destProfile -Force
Write-OK "Profile copied to $destProfile"

# ── 2. Git aliases ───────────────────────────────────────────────────────────
Write-Step "Git aliases"
& (Join-Path $PwshDir "add-git-aliases.ps1")

# ── 3. Windows Terminal settings.json ───────────────────────────────────────
Write-Step "Windows Terminal settings"

$srcSettings  = Join-Path $PwshDir "settings.json"
$wtCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"),
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState")
)
$wtFound = $false
foreach ($dir in $wtCandidates) {
    if (Test-Path $dir) {
        $destSettings = Join-Path $dir "settings.json"
        if (Test-Path $destSettings) {
            Copy-Item $destSettings "$destSettings.bak" -Force
            Write-Skip "Existing settings backed up to $destSettings.bak"
        }
        Copy-Item $srcSettings $destSettings -Force
        Write-OK "settings.json copied to $destSettings"
        $wtFound = $true
        break
    }
}
if (-not $wtFound) {
    Write-Warn "Windows Terminal package not found — skipping settings.json"
}

# ── 4. AutoHotkey ────────────────────────────────────────────────────────────
Write-Step "AutoHotkey"

$autorunAhk = Join-Path $AhkDir "autorun.ahk"

$ahkExe = $null
$ahkCandidates = @(
    "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe",
    "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe",
    "C:\Program Files\AutoHotkey\AutoHotkey64.exe",
    "C:\Program Files\AutoHotkey\AutoHotkey.exe",
    "C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe"
)
foreach ($c in $ahkCandidates) { if (Test-Path $c) { $ahkExe = $c; break } }
if (-not $ahkExe) {
    foreach ($name in @("AutoHotkey64.exe", "AutoHotkey.exe")) {
        try { $ahkExe = (Get-Command $name -ErrorAction Stop).Source; break } catch {}
    }
}

if (-not $ahkExe) {
    Write-Warn "AutoHotkey executable not found — install AHK and re-run setup"
} else {
    Write-OK "AHK executable: $ahkExe"

    $startupDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    $lnkPath    = Join-Path $startupDir "dotfiles-autorun.lnk"
    $wsh = New-Object -ComObject WScript.Shell
    $sc  = $wsh.CreateShortcut($lnkPath)
    $sc.TargetPath       = $ahkExe
    $sc.Arguments        = "`"$autorunAhk`""
    $sc.WorkingDirectory = $AhkDir
    $sc.Save()
    Write-OK "Startup shortcut created: $lnkPath"

    Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Process $ahkExe -ArgumentList "`"$autorunAhk`""
    Write-OK "AutoHotkey launched"
}

Write-Host "`nSetup complete. Open a new PowerShell session to load the profile." -ForegroundColor Cyan
