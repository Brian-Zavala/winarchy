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
# @(...) around the if: a one-item array would otherwise unroll to the string '-Yes', and
# splatting a string passes it one character at a time.
$yes = @(if ($env:WINARCHY_YES) { '-Yes' })
# Public repo over HTTPS: a git credential prompt would only ever be a hang.
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Write-Host 'Winarchy: Omarchy''s look, keys and themes for Windows 11 (unofficial)' -ForegroundColor Green

if ([Environment]::OSVersion.Version.Build -lt 22000) { throw 'Windows 11 is required.' }
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is missing: install "App Installer" from the Microsoft Store, then run this again.'
}
# 1.4 is the first winget with --disable-interactivity, which every unattended call uses.
$wingetVersion = "$(winget --version 2>$null)".Trim().TrimStart('v')
try { $wingetOld = [version]($wingetVersion -replace '[^\d.].*$', '') -lt [version]'1.4' } catch { $wingetOld = $false }
if ($wingetOld) {
    throw "winget $wingetVersion is too old (1.4 or newer is needed): update ""App Installer"" in the Microsoft Store, then run this again."
}
# Elevated, everything winarchy starts would run elevated too; it installs per user.
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -and -not $env:WINARCHY_ALLOW_ELEVATED) {
    throw 'This window runs as administrator. Open a normal PowerShell window (not "Run as administrator") and run the install there.'
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
function Get-PwshVersion([string]$exe) {
    try { [version](& $exe -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()' 2>$null | Select-Object -First 1).Split('-')[0] } catch { $null }
}
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
# winarchy needs 7.2 or newer; an older 7.x gets upgraded in place.
# A version that can't be read is left alone rather than reinstalled.
$pwshVersion = if ($pwsh) { Get-PwshVersion $pwsh }
$pwshOld = [bool]($pwshVersion -and $pwshVersion -lt [version]'7.2')
if (-not $pwsh -or $pwshOld) {
    $verb = if ($pwshOld) { 'upgrade' } else { 'install' }
    Write-Host "==> $(if ($pwshOld) { 'Updating' } else { 'Installing' }) PowerShell 7"
    winget $verb -e --id Microsoft.PowerShell --silent --accept-source-agreements --accept-package-agreements --disable-interactivity | Out-Host
    $code = $LASTEXITCODE
    $pwsh = Find-Pwsh7
    $pwshVersion = if ($pwsh) { Get-PwshVersion $pwsh }
    if (-not $pwsh -or ($pwshVersion -and $pwshVersion -lt [version]'7.2')) {
        throw "PowerShell 7.2 or newer did not install (winget exit code $code). It asks Windows for permission first: answer Yes to that prompt, or install it from https://aka.ms/powershell, then run this again."
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
# git, with what it prints to stderr as plain text: in Windows PowerShell 5.1 a native
# program's redirected stderr becomes an error record, which 'Stop' above makes fatal.
function Invoke-Git {
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & git @args 2>&1 | ForEach-Object { if ($_ -is [Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" } } }
    finally { $ErrorActionPreference = $eap }
}
$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
# Files, not folders: an empty leftover folder (an uninstall that a program held open) is not a copy.
$hasFiles = (Test-Path $dest) -and @(Get-ChildItem -Force -Recurse -File $dest -ErrorAction SilentlyContinue).Count -gt 0
if ($hasGit -and (Test-Path (Join-Path $dest '.git'))) {
    Write-Host "==> Updating $dest"
    # Edits in the code folder (by hand, or an agent started there) would stop the pull:
    # set aside in a stash, never thrown away.
    if (Invoke-Git -C $dest status --porcelain) {
        $msg = "winarchy $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Invoke-Git -C $dest stash push -u -q -m $msg | Out-Host
        if (-not $LASTEXITCODE) { Write-Host "    Your changes to winarchy's files are saved in a git stash (""$msg""): git -C ""$dest"" stash pop brings them back." }
    }
    $branch = "$(Invoke-Git -C $dest rev-parse --abbrev-ref HEAD)".Trim()
    Invoke-Git -C $dest fetch -q origin "+refs/heads/${ref}:refs/remotes/origin/$ref" | Out-Host
    if ($LASTEXITCODE) {
        # Offline: the copy already there still installs; it just isn't the newest.
        Write-Warning "Could not reach GitHub to update $dest; installing the copy that is there."
    } elseif ($branch -ne $ref) {
        # WINARCHY_REF names another branch than the one checked out.
        Invoke-Git -C $dest checkout -q -B $ref "origin/$ref" | Out-Host
        if ($LASTEXITCODE) { throw "Could not switch $dest to $ref. Run: git -C ""$dest"" checkout -B $ref origin/$ref" }
        Invoke-Git -C $dest branch -q --set-upstream-to "origin/$ref" | Out-Null
    } else {
        Invoke-Git -C $dest merge -q --ff-only "origin/$ref" | Out-Host
        # Installing the old code quietly would look like the fix never arrived.
        if ($LASTEXITCODE) {
            throw "$dest has commits of its own, so it can't move to the latest $ref. Keep them on a branch and reset: git -C ""$dest"" branch my-changes; git -C ""$dest"" reset --hard origin/$ref. Then run this again."
        }
    }
} elseif ($hasGit -and (Test-Path $dest)) {
    # An earlier install came from the zip, before git was here, or an uninstall left the
    # folder behind (empty, or with files a program held open): git clone refuses a folder
    # that isn't empty, so clone beside it and move the checkout in.
    Write-Host "==> $(if ($hasFiles) { 'Updating' } else { 'Downloading winarchy to' }) $dest"
    $tmp = Join-Path $env:TEMP 'winarchy-git'
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    Invoke-Git clone --depth 1 --branch $ref --no-checkout "https://github.com/$repo.git" $tmp | Out-Host
    if ($LASTEXITCODE) {
        if (-not $hasFiles) { throw "Could not download winarchy (git clone of $repo failed)." }
        Write-Warning "Could not update $dest (git clone of $repo failed); installing the copy that is there."
    } else {
        Move-Item (Join-Path $tmp '.git') (Join-Path $dest '.git')
        Invoke-Git -C $dest reset --hard -q | Out-Host
        Remove-StaleFiles @(Invoke-Git -C $dest ls-files | ForEach-Object { $_ -replace '/', '\' })
        Remove-Item -Force $manifest -ErrorAction SilentlyContinue
    }
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
} elseif ($hasGit) {
    Write-Host "==> Downloading winarchy to $dest"
    Invoke-Git clone --depth 1 --branch $ref "https://github.com/$repo.git" $dest | Out-Host
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
