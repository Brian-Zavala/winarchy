# omarchy-win bootstrap. Run from any PowerShell window (no admin needed):
#
#   irm https://raw.githubusercontent.com/OWNER/omarchy-win/main/install.ps1 | iex
#
# It gets PowerShell 7 if missing, downloads omarchy-win to %LOCALAPPDATA%\omarchy-win
# (git clone when git is available, else the release zip) and starts the installer,
# which asks a few questions and explains every change. Undo: omarchy-win uninstall
#
# Windows PowerShell 5.1 compatible on purpose (it's what every Windows 11 PC has).

$ErrorActionPreference = 'Stop'
$repo = if ($env:OMARCHY_WIN_REPO) { $env:OMARCHY_WIN_REPO } else { 'OWNER/omarchy-win' }
$ref = if ($env:OMARCHY_WIN_REF) { $env:OMARCHY_WIN_REF } else { 'main' }
$dest = Join-Path $env:LOCALAPPDATA 'omarchy-win'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Write-Host 'omarchy-win: Omarchy''s look, keys and themes for Windows 11 (unofficial)' -ForegroundColor Green

if ([Environment]::OSVersion.Version.Build -lt 22000) { throw 'Windows 11 is required.' }
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is missing: install "App Installer" from the Microsoft Store, then run this again.'
}

# 1. PowerShell 7 (omarchy-win's scripts need it).
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwsh) {
    Write-Host '==> Installing PowerShell 7'
    winget install -e --id Microsoft.PowerShell --silent --accept-source-agreements --accept-package-agreements | Out-Host
    $pwsh = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    if (-not (Test-Path $pwsh)) { throw 'PowerShell 7 did not install; install it from https://aka.ms/powershell and run this again.' }
}

# 2. The code.
if (Test-Path (Join-Path $dest '.git')) {
    Write-Host "==> Updating $dest"
    git -C $dest pull --ff-only | Out-Host
} elseif (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "==> Downloading omarchy-win to $dest"
    git clone --depth 1 --branch $ref "https://github.com/$repo.git" $dest | Out-Host
} else {
    Write-Host "==> Downloading omarchy-win to $dest"
    $zip = Join-Path $env:TEMP 'omarchy-win.zip'
    Invoke-WebRequest "https://github.com/$repo/archive/refs/heads/$ref.zip" -OutFile $zip -UseBasicParsing
    $tmp = Join-Path $env:TEMP 'omarchy-win-src'
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    Expand-Archive $zip $tmp -Force
    New-Item -ItemType Directory -Force $dest | Out-Null
    Copy-Item -Recurse -Force (Join-Path (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName '*') $dest
    Remove-Item -Recurse -Force $tmp, $zip -ErrorAction SilentlyContinue
}
# Files from the internet are marked as such; clear that so they run.
Get-ChildItem $dest -Recurse -File | Unblock-File

# 3. The installer (questions, backup journal, apps, configs, themes).
& $pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dest 'bin\omarchy-win.ps1') install @args
