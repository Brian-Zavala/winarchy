# winarchy install / update. Install is idempotent: re-running it only does what's
# missing, and every system change is journaled first (lib/journal.ps1).

. "$PSScriptRoot\fonts.ps1"

$Apps = @(
    @{ id = 'glzr-io.glazewm'; name = 'GlazeWM + Zebar'; test = { (Get-Paths).glazewm -and (Get-Paths).zebar }; note = 'Windows will ask for permission (UAC) once.' },
    @{ id = 'Flow-Launcher.Flow-Launcher'; name = 'Flow Launcher'; test = { (Get-Paths).flow } }
)

# Everything git does here is a public HTTPS repo: a credential prompt is never a real
# question, only a hang - and update-check runs git from a hidden process, where a
# prompt (or Git Credential Manager's sign-in window) would wait with nobody to see it.
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'

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

# Install and update run with nobody at the keyboard, so nothing they start may wait on
# one: stdin is an empty file (a prompt reads end-of-input instead of hanging), a
# watchdog ends whatever still does not finish, and the result comes back to the caller
# instead of being lost in the scrollback. Output is not redirected, so it still streams
# live into the window.
function Invoke-Unattended([string]$file, [string[]]$arguments, [int]$timeoutSec = 900) {
    $stdin = New-TemporaryFile
    try {
        $start = @{ FilePath = $file; NoNewWindow = $true; PassThru = $true; RedirectStandardInput = $stdin.FullName }
        if ($arguments) { $start.ArgumentList = ConvertTo-ArgString $arguments }
        $proc = Start-Process @start
        if (-not $proc.WaitForExit($timeoutSec * 1000)) {
            try { $proc.Kill($true) } catch {}
            return [pscustomobject]@{ Ok = $false; Code = $null; Reason = "stopped after $([math]::Round($timeoutSec / 60)) min without finishing" }
        }
        $code = $proc.ExitCode
        [pscustomobject]@{ Ok = $code -eq 0; Code = $code; Reason = $(if ($code) { 'exit code 0x{0:X8}' -f $code }) }
    } finally { Remove-Item $stdin -Force -ErrorAction SilentlyContinue }
}

# Start-Process takes one command line: quote what would otherwise split.
function ConvertTo-ArgString([string[]]$list) {
    @($list | ForEach-Object { if ($_ -eq '' -or $_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
}

# 0x8A15002B: "no applicable upgrade", i.e. it is already current - not a failure.
$WingetExitOk = @(0, -1978335189)

function Get-WingetArgs([string]$verb, [string]$id, [string]$scope) {
    $a = @($verb, '-e', '--id', $id, '--silent', '--accept-source-agreements', '--accept-package-agreements', '--disable-interactivity')
    if ($scope) { $a += @('--scope', $scope) }
    $a
}

function Invoke-Winget([string]$verb, [string]$id, [string]$scope) {
    $r = Invoke-Unattended 'winget' (Get-WingetArgs $verb $id $scope)
    if ($r.Code -in $WingetExitOk) { $r.Ok = $true; $r.Reason = $null }
    $r
}

# Whether a package can be installed with nobody watching. winget brings the silent
# switch for almost everything; a row says `silent = 'none'` only when the manifest has
# none at all, so its setup window would open and wait for clicks.
function Test-WingetUnattended([string]$id) {
    foreach ($group in $Catalog) {
        foreach ($item in $group.items) { if ($item.id -eq $id) { return $item.silent -ne 'none' } }
    }
    $true
}

# What an unattended run could not finish, said once at the end instead of scrolling past.
$script:Unfinished = [Collections.Generic.List[string]]::new()
function Add-Unfinished([string]$what) { $script:Unfinished.Add($what); Log "unfinished: $what" }
function Write-Unfinished {
    if (-not $script:Unfinished.Count) { return }
    Write-Step 'Needs attention'
    foreach ($u in $script:Unfinished) { Write-Host "    $u" -ForegroundColor Yellow }
}

# Only when there is something to read: a clean run just closes its window.
function Wait-KeyToClose {
    if ([Console]::IsInputRedirected) { return }
    Write-Host "`nPress any key to close."; [void][Console]::ReadKey($true)
}

function Install-WingetPackage([string]$id, [string]$name, [string]$scope) {
    if (-not (Test-WingetUnattended $id)) { Write-Ok "$name has no silent installer: its own setup window opens, finish it there." }
    Write-Ok "installing $name ($id)..."
    $r = Invoke-Winget install $id $scope
    # Not every package offers a per-user scope: fall back to the default.
    if (-not $r.Ok -and $scope -and $null -ne $r.Code) { $r = Invoke-Winget install $id $null }
    if (-not $r.Ok) { Write-Ok "$name did not install ($($r.Reason))" }
    $r.Ok
}

function Install-Prerequisites {
    Write-Step 'Prerequisites'
    $p = Update-Paths
    if (-not $p.ahk) {
        Save-Winget 'AutoHotkey.AutoHotkey' $false
        [void](Install-WingetPackage 'AutoHotkey.AutoHotkey' 'AutoHotkey v2' 'user')
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
        [void](Install-WingetPackage $a.id $a.name $null)
        [void](Update-Paths)
        # Carry on without it: everything else still gets set up, and a second run of
        # install only does what is missing.
        if (-not (& $a.test)) { Add-Unfinished "$($a.name) did not install: run 'winarchy install' again, or: winget install -e --id $($a.id)" }
    }
}

# About (fastfetch), Activity (btop) and the screensaver's effects engine (ttfx).
function Install-Extras {
    Write-Step 'Extras (About, Activity, screensaver effects, agent usage)'
    foreach ($x in @(
            @{ id = 'Fastfetch-cli.Fastfetch'; name = 'fastfetch'; have = { Get-Command fastfetch.exe -ErrorAction SilentlyContinue } },
            @{ id = 'aristocratos.btop4win'; name = 'btop'; have = { (Update-Paths).btopDir } },
            # The bar's AI agent usage runs Omarchy's collectors, which are Python. Find-Python,
            # not Get-Command: the Store's `python` stub is on PATH and would pass for one.
            @{ id = 'Python.Python.3.13'; name = 'Python 3 (the bar''s AI agent usage)'; have = { Find-Python } })) {
        if (& $x.have) { Save-Winget $x.id $true; Write-Ok "$($x.name): installed"; continue }
        Save-Winget $x.id $false
        if (-not (Install-WingetPackage $x.id $x.name $null)) { Add-Unfinished "$($x.name) (optional) did not install: winget install -e --id $($x.id)" }
    }
    $p = Update-Paths
    if ($p.ttfx) { Write-Ok "ttfx: $($p.ttfx)"; return }
    # ttfx (Omarchy's Rust port of terminaltexteffects): a prebuilt Windows binary from the
    # winarchy release if one is published, else built with cargo when Rust is present.
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
        Write-Ok 'ttfx not available: the screensaver shows the still logo (install Rust, then: winarchy extras)'
    }
}

# Herdr, on a fresh install. Asked for rather than assumed: it is the one thing winarchy
# installs that does not come from winget, and its binary is unsigned. Saying no here
# costs nothing - Omarchy menu > Install > Terminal > Herdr adds it later, and everything
# downstream (config, theming, hdl/hds/hdlm/hsl, the menu rows) is written by the apply
# that runs after this either way.
function Install-HerdrStep {
    if (Test-HerdrInstalled) { Write-Ok "Herdr: $(Get-HerdrExe)"; return }
    Write-Step 'Herdr (optional)'
    Write-Ok 'Omarchy Quattro replaced tmux with Herdr: one terminal holding your editor, your'
    Write-Ok 'coding agent and a shell, laid out in one word with hdl / hds / hdlm / hsl.'
    Write-Ok "It has no winget package, so this runs herdr.dev's own installer, and the binary"
    Write-Ok 'is unsigned (Windows may show a SmartScreen warning).'
    # Unattended (-Yes / WINARCHY_YES) never takes this one: running a remote installer
    # for an unsigned binary is a choice someone has to actually make, not a default.
    if ($script:AssumeYes) {
        Write-Ok 'Skipped in an unattended install. Omarchy menu > Install > Terminal > Herdr adds it.'
        return
    }
    if (-not (Read-YesNo 'Install Herdr?' $true)) {
        Write-Ok 'Skipped. Omarchy menu > Install > Terminal > Herdr adds it any time.'
        return
    }
    # A failed optional extra must not take the whole install down with it.
    try { Install-Herdr } catch { Write-Ok "Herdr install failed (skipping): $($_.Exception.Message)" }
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
        $cfg.launchers = -not (Read-YesNo 'Keep using it instead of winarchy''s app keys?' $true)
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
    if ($p.glazewm -and -not (Get-GlazeWmProcess)) { Start-Process $p.glazewm }
    if ($p.flow -and -not (Get-Process Flow.Launcher -ErrorAction SilentlyContinue)) { Start-Process $p.flow }
    Restart-Bar $p
    Restart-OmarchyAhk $p
}

function Invoke-Install([switch]$Yes, [switch]$Adopt) {
    # WINARCHY_YES too, so the one-line `irm | iex` install can run unattended.
    $script:AssumeYes = $Yes -or [bool]$env:WINARCHY_YES
    $script:Unfinished.Clear()
    $cfgVersion = (Get-Content -Raw (Join-Path $Code 'VERSION') -ErrorAction SilentlyContinue)?.Trim()
    Write-Host "winarchy $cfgVersion - Omarchy's look and keys on Windows 11 (unofficial)" -ForegroundColor Green
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
    Install-HerdrStep
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
    } else { Use-Lock { Invoke-Sync -Offline }; Write-Ok 'Skipped: run "winarchy sync" any time.' }
    $theme = if (Test-Path (Join-Path $Themes 'tokyo-night\colors.toml')) { 'tokyo-night' }
    if ($theme) { Use-Lock { Invoke-ThemeSet $theme } }

    Write-Step 'Starting'
    Start-Everything $p
    Write-Host ''
    Write-Host 'Done. Super = the Windows key. Start here:' -ForegroundColor Green
    Write-Host '  Super + K             all keybindings'
    Write-Host '  Super + Alt + Space   Omarchy menu        Super + Space   app launcher'
    Write-Host '  Super + Return        terminal            Super + 1..0    workspaces'
    Write-Host '  winarchy doctor    check the setup     winarchy uninstall   undo everything'
    Write-Host "  Settings: $ConfigFile   (then: winarchy apply)"
    Write-Unfinished
}

# This PC was set up by hand before winarchy existed: take it over in place.
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
    Write-Host "`nAdopted. Run 'winarchy doctor' to check." -ForegroundColor Green
}

# winarchy update (also the bar's update icon): exactly what update-check found,
# once at a time, then a fresh check so the icon shows what is really left. Nothing in
# it waits for a person: the window closes by itself unless something needs attention.
function Invoke-Update {
    $m = [Threading.Mutex]::new($false, 'Local\WinarchyUpdate')
    if (-not $m.WaitOne(0)) { Write-Host 'An update is already running in another window.'; return }
    $script:Unfinished.Clear()
    $updFile = Join-Path $Pack 'updates.json'
    $pending = @((Read-Json $updFile).items | Where-Object { $_ })
    $checked = $false
    try {
        # Hide the bar icon while this runs, so it can't be clicked again.
        Write-Json $updFile ([ordered]@{ checked = (Get-Date).ToString('s'); updating = $true; items = @() })
        $p = Get-Paths

        Write-Step 'winarchy'
        $codeChanged = $false
        if ((Test-Path (Join-Path $Code '.git')) -and (git -C $Code remote)) {
            $before = git -C $Code rev-parse HEAD
            git -C $Code pull --ff-only 2>&1 | Out-Host
            if ($LASTEXITCODE) {
                # Carry on with the rest: themes and apps don't depend on the code moving.
                $own = [int](git -C $Code rev-list --count '@{u}..HEAD' 2>$null)
                Add-Unfinished $(if ($own) { "winarchy code not updated: this copy has $own commit(s) of its own, so it can't fast-forward (nothing was changed)" }
                    else { 'winarchy code not updated: git pull failed (see above)' })
            }
            $codeChanged = $before -ne (git -C $Code rev-parse HEAD)
        } else { Write-Ok 'installed from a local copy (no git remote): nothing to pull' }

        Write-Step 'Omarchy themes'
        $omarchy = $pending | Where-Object name -eq 'Omarchy themes' | Select-Object -First 1
        if ($omarchy) {
            $s = Read-State; $s.omarchyTag = $omarchy.to; Save-State $s
            Use-Lock { Invoke-Sync }
        } else { Write-Ok 'up to date' }

        # Herdr came from its own installer, so winget cannot upgrade it: it has an updater
        # of its own, and it is the only thing here that does.
        if (Test-HerdrInstalled) {
            Write-Step 'Herdr'
            try { & (Get-HerdrExe) update 2>&1 | Out-Host } catch { Write-Ok "herdr update failed: $($_.Exception.Message)" }
        }

        Write-Step 'Apps'
        $ids = @($pending | Where-Object { $_.name -match '^[\w-]+\.[\w.-]+$' } | ForEach-Object name)
        if (-not $ids) { Write-Ok 'up to date' }
        # Upgrading AutoHotkey closes running scripts: remember them to start them again.
        $scripts = @(Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" | ForEach-Object CommandLine)
        foreach ($id in $ids) {
            if (-not (Test-WingetUnattended $id)) {
                Add-Unfinished "$id not updated: its installer can't run unattended; open the app and it updates itself"
                continue
            }
            Write-Ok "upgrading $id"
            # rustup-init is a console program: winget gives it a window of its own, and in
            # quiet mode it prints nothing while it downloads the toolchain.
            if ($id -eq 'Rustlang.Rustup') { Write-Ok 'Rust updates in a separate window that closes itself when done.' }
            $r = Invoke-Winget upgrade $id $null
            if (-not $r.Ok) { Add-Unfinished "$id did not update ($($r.Reason))" }
        }
        if ($ids -contains 'AutoHotkey.AutoHotkey') {
            $p = Update-Paths
            $running = @(Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" | ForEach-Object CommandLine)
            foreach ($cmd in $scripts | Where-Object { $running -notcontains $_ }) {
                if ($cmd -match '^"?[^"]+\.exe"?\s+(.+)$') { Start-Process $p.ahk -ArgumentList $Matches[1]; Write-Ok "restarted $($Matches[1])" }
            }
        }

        Write-Step 'Applying'
        # A fresh process so new code is used; restart the bar/keys only when something changed.
        $restart = $codeChanged -or ($ids -contains 'glzr-io.glazewm') -or ($ids -contains 'AutoHotkey.AutoHotkey')
        $applyArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Code 'bin\winarchy.ps1'), 'apply') + $(if (-not $restart) { '-NoRestart' })
        & $p.pwsh @applyArgs
        if ($LASTEXITCODE) { Add-Unfinished "applying failed: see $LogFile" }

        Write-Step 'Checking again'
        Invoke-UpdateCheck
        $checked = $true
    } catch {
        $crash = $_
        Add-Unfinished "update stopped: $($_.Exception.Message)"
    } finally {
        # Died before the fresh check: put the list back so the icon doesn't claim all is well.
        if (-not $checked) { Write-Json $updFile ([ordered]@{ checked = (Get-Date).ToString('s'); items = $pending }) }
        $m.ReleaseMutex(); $m.Dispose()
    }
    Write-Unfinished
    if ($script:Unfinished.Count) { Wait-KeyToClose } else { Write-Host "`nDone." -ForegroundColor Green }
    if ($crash) { throw $crash }
}
