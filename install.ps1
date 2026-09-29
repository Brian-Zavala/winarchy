# Winarchy bootstrap. Run from any PowerShell window (no admin needed):
#
#   irm https://raw.githubusercontent.com/Brian-Zavala/winarchy/main/install.ps1 | iex
#
# Unattended (every question takes its recommended answer, nothing waits for a key):
#
#   $env:WINARCHY_YES = 1; irm https://raw.githubusercontent.com/Brian-Zavala/winarchy/main/install.ps1 | iex
#
# It gets PowerShell 7 if missing, downloads winarchy to %LOCALAPPDATA%\winarchy
# (git clone when git is available, else the release zip) and starts the installer,
# which asks a few questions and explains every change. Undo: winarchy uninstall
#
# Windows PowerShell 5.1 compatible on purpose (it's what every Windows 11 PC has).

$ErrorActionPreference = 'Stop'
$repo = if ($env:WINARCHY_REPO) { $env:WINARCHY_REPO } else { 'Brian-Zavala/winarchy' }
$ref = if ($env:WINARCHY_REF) { $env:WINARCHY_REF } else { 'main' }
$dest = Join-Path $env:LOCALAPPDATA 'winarchy'
# Piped into iex this script gets no arguments, so -Yes can only arrive this way.
$yes = if ($env:WINARCHY_YES) { @('-Yes') } else { @() }
# Public repo over HTTPS: a git credential prompt would only ever be a hang.
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Write-Host 'Winarchy: Omarchy''s look, keys and themes for Windows 11 (unofficial)' -ForegroundColor Green

if ([Environment]::OSVersion.Version.Build -lt 22000) { throw 'Windows 11 is required.' }
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is missing: install "App Installer" from the Microsoft Store, then run this again.'
}

# 1. PowerShell 7 (winarchy's scripts need it).
# Where it lands depends on the package (MSI in Program Files, or the Store's alias), and
# this window's PATH is from before the install: look in each place rather than assume one.
function Find-Pwsh7 {
    $appPath = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\pwsh.exe' -ErrorAction SilentlyContinue).'(default)'
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    foreach ($c in @((Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'), $appPath,
                     (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\pwsh.exe'), (Get-Command pwsh -ErrorAction SilentlyContinue).Source)) {
        if ($c -and (Test-Path $c.Trim('"'))) { return $c.Trim('"') }
    }
}
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwsh) {
    Write-Host '==> Installing PowerShell 7'
    winget install -e --id Microsoft.PowerShell --silent --accept-source-agreements --accept-package-agreements --disable-interactivity | Out-Host
    $code = $LASTEXITCODE
    $pwsh = Find-Pwsh7
    if (-not $pwsh) {
        throw "PowerShell 7 did not install (winget exit code $code). It asks Windows for permission first: answer Yes to that prompt, or install it from https://aka.ms/powershell, then run this again."
    }
}

# 2. The code.
# A zip install keeps a list of the files it wrote, so the next one can take out those the
# new version no longer has (nothing else: never a file winarchy did not put there).
$manifest = Join-Path $dest '.winarchy-files'
function Remove-StaleFiles([string[]]$keep) {
    if (-not (Test-Path $manifest)) { return }
    $want = @{}; foreach ($k in $keep) { $want[$k.ToLower()] = $true }
    foreach ($rel in Get-Content $manifest) {
        if ($rel -and -not $want[$rel.ToLower()]) { Remove-Item -LiteralPath (Join-Path $dest $rel) -Force -ErrorAction SilentlyContinue }
    }
}
$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
$hasFiles = (Test-Path $dest) -and @(Get-ChildItem -Force $dest -ErrorAction SilentlyContinue).Count -gt 0
if (Test-Path (Join-Path $dest '.git')) {
    Write-Host "==> Updating $dest"
    git -C $dest pull --ff-only | Out-Host
    # The copy already there still installs; it just isn't the newest.
    if ($LASTEXITCODE) { Write-Warning "Could not update $dest (git pull failed); installing the copy that is there." }
} elseif ($hasGit -and $hasFiles) {
    # An earlier install came from the zip, before git was here: turn that copy into a git
    # checkout (git clone refuses a folder with files in it), so winarchy update can pull.
    Write-Host "==> Updating $dest"
    $tmp = Join-Path $env:TEMP 'winarchy-git'
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    git clone --depth 1 --branch $ref --no-checkout "https://github.com/$repo.git" $tmp | Out-Host
    if ($LASTEXITCODE) {
        Write-Warning "Could not update $dest (git clone of $repo failed); installing the copy that is there."
    } else {
        Move-Item (Join-Path $tmp '.git') (Join-Path $dest '.git')
        git -C $dest reset --hard -q | Out-Host
        Remove-StaleFiles @(git -C $dest ls-files | ForEach-Object { $_ -replace '/', '\' })
        Remove-Item -Force $manifest -ErrorAction SilentlyContinue
    }
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
} elseif ($hasGit) {
    Write-Host "==> Downloading winarchy to $dest"
    git clone --depth 1 --branch $ref "https://github.com/$repo.git" $dest | Out-Host
    if ($LASTEXITCODE) { throw "Could not download winarchy (git clone of $repo failed)." }
} else {
    Write-Host "==> Downloading winarchy to $dest"
    $zip = Join-Path $env:TEMP 'winarchy.zip'
    Invoke-WebRequest "https://github.com/$repo/archive/refs/heads/$ref.zip" -OutFile $zip -UseBasicParsing
    $tmp = Join-Path $env:TEMP 'winarchy-src'
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    Expand-Archive $zip $tmp -Force
    $src = (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName
    $files = @(Get-ChildItem $src -Recurse -File -Force | ForEach-Object { $_.FullName.Substring($src.Length + 1) })
    New-Item -ItemType Directory -Force $dest | Out-Null
    Remove-StaleFiles $files
    Copy-Item -Recurse -Force (Join-Path $src '*') $dest
    Set-Content -Path $manifest -Value $files -Encoding UTF8
    Remove-Item -Recurse -Force $tmp, $zip -ErrorAction SilentlyContinue
}
# Files from the internet are marked as such; clear that so they run.
Get-ChildItem $dest -Recurse -File | Unblock-File

# 3. The installer (questions, backup journal, apps, configs, themes).
& $pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dest 'bin\winarchy.ps1') install @yes @args
