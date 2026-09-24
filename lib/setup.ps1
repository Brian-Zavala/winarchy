# omarchy-win install / update. Install is idempotent: re-running it only does what's
# missing, and every system change is journaled first (lib/journal.ps1).

. "$PSScriptRoot\fonts.ps1"

$Apps = @(
    @{ id = 'glzr-io.glazewm'; name = 'GlazeWM + Zebar'; test = { (Get-Paths).glazewm -and (Get-Paths).zebar }; note = 'Windows will ask for permission (UAC) once.' },
    @{ id = 'Flow-Launcher.Flow-Launcher'; name = 'Flow Launcher'; test = { (Get-Paths).flow } }
)

function Write-Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg) { Write-Host "    $msg" -ForegroundColor DarkGray }

function Read-YesNo([string]$question, [bool]$default = $true) {
    if ($script:AssumeYes) { return $default }
    $hint = if ($default) { '[Y/n]' } else { '[y/N]' }
    $a = Read-Host "    $question $hint"
    if (-not $a) { return $default }
    $a -match '^(y|yes)$'
}

function Test-Preflight {
    Write-Step 'Checking this PC'
    $build = [Environment]::OSVersion.Version.Build
    if ($build -lt 22000) { throw "Windows 11 is required (this is build $build)." }
    if ($build -lt 22621) { Write-Warning 'Windows 11 22H2 or newer is recommended; some panels may not open on older builds.' }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget (App Installer) is missing. Install "App Installer" from the Microsoft Store, then run this again.'
    }
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($admin) { Write-Warning 'Running as administrator: settings would land in the admin profile. Run from a normal terminal.' }
    Write-Ok "Windows build $build, $env:PROCESSOR_ARCHITECTURE, winget OK"
}

function Install-WingetPackage([string]$id, [string]$name, [string]$scope) {
    Write-Ok "installing $name ($id)..."
    $wingetArgs = @('install', '-e', '--id', $id, '--silent', '--accept-source-agreements', '--accept-package-agreements')
    & winget @($wingetArgs + $(if ($scope) { @('--scope', $scope) })) | Out-Host
    # Not every package offers a per-user scope: fall back to the default.
    if ($LASTEXITCODE -ne 0 -and $scope) { & winget @wingetArgs | Out-Host }
}

function Install-Prerequisites {
    Write-Step 'Prerequisites'
    $p = Update-Paths
    if (-not $p.ahk) {
        Save-Winget 'AutoHotkey.AutoHotkey' $false
        Install-WingetPackage 'AutoHotkey.AutoHotkey' 'AutoHotkey v2' 'user'
        $p = Update-Paths
        if (-not $p.ahk) { throw 'AutoHotkey v2 did not install; install it from https://www.autohotkey.com and run install again.' }
    } else { Save-Winget 'AutoHotkey.AutoHotkey' $true; Write-Ok "AutoHotkey: $($p.ahk)" }
    if (-not $p.nerdFont) {
        Write-Ok 'installing JetBrainsMono Nerd Font (bar icons + terminal glyphs)'
        [void](Install-NerdFont 'JetBrainsMono')
    } else { Write-Ok 'JetBrainsMono Nerd Font: installed' }
}

function Install-Apps {
    Write-Step 'Apps'
    foreach ($a in $Apps) {
        if (& $a.test) { Save-Winget $a.id $true; Write-Ok "$($a.name): installed"; continue }
        Save-Winget $a.id $false
        if ($a.note) { Write-Ok $a.note }
        Install-WingetPackage $a.id $a.name $null
        [void](Update-Paths)
        if (-not (& $a.test)) { throw "$($a.name) did not install. Try: winget install -e --id $($a.id)" }
    }
}

# About (fastfetch), Activity (btop) and the screensaver's effects engine (ttfx).
function Install-Extras {
    Write-Step 'Extras (About, Activity, screensaver effects)'
    foreach ($x in @(
            @{ id = 'Fastfetch-cli.Fastfetch'; name = 'fastfetch'; have = { Get-Command fastfetch.exe -ErrorAction SilentlyContinue } },
            @{ id = 'aristocratos.btop4win'; name = 'btop'; have = { (Update-Paths).btopDir } })) {
        if (& $x.have) { Save-Winget $x.id $true; Write-Ok "$($x.name): installed"; continue }
        Save-Winget $x.id $false
        Install-WingetPackage $x.id $x.name $null
    }
    $p = Update-Paths
    if ($p.ttfx) { Write-Ok "ttfx: $($p.ttfx)"; return }
    # ttfx (Omarchy's Rust port of terminaltexteffects): a prebuilt Windows binary from the
    # omarchy-win release if one is published, else built with cargo when Rust is present.
    $url = (Get-Config).ttfxUrl
    $dest = Join-Path $Data 'bin\ttfx.exe'
    if ($url) {
        try {
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Invoke-WebRequest $url -OutFile $dest -TimeoutSec 120
            Write-Ok "ttfx: downloaded to $dest"; return
        } catch { Write-Ok "ttfx download failed ($($_.Exception.Message))" }
    }
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        Write-Ok 'building ttfx with cargo (a few minutes)...'
        [void](Add-JournalEntry @{ kind = 'cargo'; key = 'cargo|ttfx'; crate = 'ttfx' })
        cargo install --git https://github.com/omacom/ttfx --tag v0.3.3 --locked 2>&1 | Select-Object -Last 2 | Out-Host
    } else {
        Write-Ok 'ttfx not available: the screensaver shows the still logo (install Rust, then: omarchy-win extras)'
    }
}

# The few questions whose answer depends on the person, not the machine.
function Get-InstallAnswers($p) {
    Write-Step 'A few choices (Enter = recommended)'
    $cfg = Read-Json $ConfigFile -AsHashtable
    if (-not $cfg) { $cfg = [ordered]@{} }
    if ([int]$p.input.count -gt 1 -or $p.input.ime) {
        Write-Ok "You have $($p.input.count) keyboard layouts/input methods. Windows switches them with Win+Space;"
        Write-Ok 'Omarchy uses Super+Space for the app launcher (Alt+Shift still switches layouts).'
        $cfg.takeOverWinSpace = Read-YesNo 'Use Super+Space for the launcher?' $true
    }
    $personal = Join-Path $p.startup 'launchers.ahk'
    if (Test-Path $personal) {
        Write-Ok "Found your own launcher script ($personal)."
        $cfg.launchers = -not (Read-YesNo 'Keep using it instead of omarchy-win''s app keys?' $true)
    }
    $cfg.hideTaskbar = Read-YesNo 'Hide the Windows taskbar (the top bar replaces it)?' $true
    $wall = Join-Path $p.pictures 'Wallpapers'
    Write-Ok "Your own backgrounds go in $wall (shown as 'Mine' in the picker)."
    New-Item -ItemType Directory -Force $wall | Out-Null
    $cfg
}

function Set-TaskbarAutoHide {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
    $cur = (Get-ItemProperty $key -ErrorAction SilentlyContinue).Settings
    if (-not $cur) { return }
    if (-not (Test-Journaled 'taskbar')) {
        [void](Add-JournalEntry @{ kind = 'taskbar'; key = 'taskbar'; autoHide = ($cur[8] -eq 3); stuckRects3 = [Convert]::ToBase64String($cur) })
    }
    if ($cur[8] -eq 3) { return }
    $cur[8] = 3
    Set-ItemProperty $key -Name Settings -Value $cur
    $mm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MMStuckRects3'
    if (Test-Path $mm) {
        foreach ($n in (Get-Item $mm).Property) { $v = (Get-ItemProperty $mm).$n; $v[8] = 3; Set-ItemProperty $mm -Name $n -Value $v }
    }
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
}

function Add-CliToPath {
    $bin = Join-Path $Code 'bin'
    $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (($cur -split ';') -contains $bin) { return }
    [void](Add-JournalEntry @{ kind = 'envpath'; key = "envpath|$bin"; dir = $bin })
    [Environment]::SetEnvironmentVariable('Path', ($cur.TrimEnd(';') + ";$bin"), 'User')
    Send-SettingChange 'Environment'
}

function Start-Everything($p) {
    if ($p.glazewm -and -not (Get-Process glazewm -ErrorAction SilentlyContinue)) { Start-Process $p.glazewm }
    if ($p.flow -and -not (Get-Process Flow.Launcher -ErrorAction SilentlyContinue)) { Start-Process $p.flow }
    Restart-Bar $p
    Restart-OmarchyAhk $p
}

function Invoke-Install([switch]$Yes, [switch]$Adopt) {
    $script:AssumeYes = $Yes
    $cfgVersion = (Get-Content -Raw (Join-Path $Code 'VERSION') -ErrorAction SilentlyContinue)?.Trim()
    Write-Host "omarchy-win $cfgVersion - Omarchy's look and keys on Windows 11 (unofficial)" -ForegroundColor Green
    New-Item -ItemType Directory -Force $Data | Out-Null
    Test-Preflight
    if ($Adopt) { return Invoke-Adopt }

    if (-not (Test-Journaled 'runkeys')) {
        [void](Add-JournalEntry @{ kind = 'runkeys'; key = 'runkeys'; names = @((Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue).PSObject.Properties.Name | Where-Object { $_ -notlike 'PS*' }) })
    }
    Save-Dir (Join-Path $env:USERPROFILE '.glzr')
    Install-Prerequisites
    Install-Apps
    Install-Extras
    $p = Update-Paths

    $cfg = Get-InstallAnswers $p
    Write-Json $ConfigFile $cfg

    Write-Step 'Configuring'
    if ((Get-Config).hideTaskbar) { Set-TaskbarAutoHide }
    Add-CliToPath
    Use-Lock { Invoke-Apply -NoRestart }
    Write-Ok 'GlazeWM, bar, menus, keys and autostart configured'

    Write-Step 'Omarchy themes and backgrounds'
    if (Read-YesNo 'Download Omarchy''s 22 themes and ~100 backgrounds now (about 110 MB)?' $true) {
        Use-Lock { Invoke-Sync }
    } else { Use-Lock { Invoke-Sync -Offline }; Write-Ok 'Skipped: run "omarchy-win sync" any time.' }
    $theme = if (Test-Path (Join-Path $Themes 'tokyo-night\colors.toml')) { 'tokyo-night' }
    if ($theme) { Use-Lock { Invoke-ThemeSet $theme } }

    Write-Step 'Starting'
    Start-Everything $p
    Write-Host ''
    Write-Host 'Done. Super = the Windows key. Start here:' -ForegroundColor Green
    Write-Host '  Super + K             all keybindings'
    Write-Host '  Super + Alt + Space   Omarchy menu        Super + Space   app launcher'
    Write-Host '  Super + Return        terminal            Super + 1..0    workspaces'
    Write-Host '  omarchy-win doctor    check the setup     omarchy-win uninstall   undo everything'
    Write-Host "  Settings: $ConfigFile   (then: omarchy-win apply)"
}

# This PC was set up by hand before omarchy-win existed: take it over in place.
function Invoke-Adopt {
    $legacy = Get-ChildItem (Join-Path $Data 'backup') -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'values.json') } | Sort-Object Name | Select-Object -First 1
    if ($legacy) {
        Write-Step "Importing the earlier backup ($($legacy.Name)) into the journal"
        Import-LegacyBackup $legacy.FullName
        Write-Ok "$((Read-Journal).entries.Count) entries"
    }
    $p = Update-Paths
    if (-not (Test-Path $ConfigFile)) {
        $cfg = [ordered]@{}
        if (Test-Path (Join-Path $p.startup 'launchers.ahk')) { $cfg.launchers = $false }
        if (Test-Path (Join-Path $p.startup 'Screenshot to Clipboard.lnk')) { $cfg.screenshotAutoCopy = $true }
        # Keep the favourites folder the old omarchy.ps1 used ($MineDirs).
        $oldScript = Join-Path $Data 'omarchy.ps1'
        if ((Test-Path $oldScript) -and ((Get-Content -Raw $oldScript) -match '\$MineDirs\s*=\s*@\(([^)]*)\)')) {
            $dirs = @([regex]::Matches($Matches[1], "'([^']+)'") | ForEach-Object { $_.Groups[1].Value } | Where-Object { Test-Path $_ })
            if ($dirs) { $cfg.backgroundDirs = $dirs }
        }
        Write-Json $ConfigFile $cfg
        Write-Ok "wrote $ConfigFile"
    }
    Write-Step 'Configuring from this code'
    Add-CliToPath
    Use-Lock { Invoke-Apply -NoRestart }
    Use-Lock { Invoke-Sync -Offline }
    Write-Step 'Moving the old hand-made scripts aside'
    $old = Join-Path $Data 'legacy'
    New-Item -ItemType Directory -Force $old | Out-Null
    foreach ($f in 'omarchy-wm.ahk', 'menu.ahk', 'omarchy.ps1', 'drop.ps1', 'lockscreen.ps1', 'bluetooth.ps1', 'flow-theme.xaml.tpl', 'keybindings.txt', 'revert.ps1', 'README.txt') {
        $src = Join-Path $Data $f
        if (Test-Path $src) { Move-Item -Force $src (Join-Path $old $f); Write-Ok "$f -> legacy\" }
    }
    Write-Step 'Restarting'
    Start-Everything $p
    Write-Host "`nAdopted. Run 'omarchy-win doctor' to check." -ForegroundColor Green
}

function Invoke-Update {
    Write-Step 'Updating omarchy-win'
    if ((Test-Path (Join-Path $Code '.git')) -and (git -C $Code remote)) {
        git -C $Code pull --ff-only | Out-Host
    } else { Write-Ok 'no git remote configured; skipping code update' }
    # Re-apply with the (possibly new) code in a fresh process.
    & (Get-Paths).pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Code 'bin\omarchy-win.ps1') apply
    Write-Step 'Apps (winget)'
    foreach ($id in 'glzr-io.glazewm', 'Flow-Launcher.Flow-Launcher') {
        winget upgrade -e --id $id --silent --accept-source-agreements --accept-package-agreements | Out-Host
    }
    Write-Ok 'If the bar or menus misbehave after a GlazeWM/Zebar upgrade, run: omarchy-win doctor'
}
