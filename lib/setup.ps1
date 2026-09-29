# winarchy install / update. Install is idempotent: re-running it only does what's
# missing, and every system change is journaled first (lib/journal.ps1).

. "$PSScriptRoot\fonts.ps1"
. "$PSScriptRoot\ui.ps1"      # Write-Step, Write-Ok, the banner, progress bar, finish screen

$Apps = @(
    @{ id = 'glzr-io.glazewm'; name = 'GlazeWM + Zebar'; test = { (Get-Paths).glazewm -and (Get-Paths).zebar }; note = 'Windows will ask for permission (UAC) once.' },
    @{ id = 'Flow-Launcher.Flow-Launcher'; name = 'Flow Launcher'; test = { (Get-Paths).flow } }
)

# Everything git does here is a public HTTPS repo: a credential prompt is never a real
# question, only a hang - and update-check runs git from a hidden process, where a
# prompt (or Git Credential Manager's sign-in window) would wait with nobody to see it.
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'

function Read-YesNo([string]$question, [bool]$default = $true) {
    if ($script:AssumeYes) { return $default }
    $hint = if ($default) { '[Y/n]' } else { '[y/N]' }
    Write-UiQuestion $question $hint
    $a = Read-Host
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
    $admin = Test-Elevated
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
        $deadline = [DateTime]::UtcNow.AddSeconds($timeoutSec)
        $shown = @{}
        while (-not $proc.WaitForExit(500)) {
            if ([DateTime]::UtcNow -gt $deadline) {
                try { $proc.Kill($true) } catch {}
                return [pscustomobject]@{ Ok = $false; Code = $null; Reason = "stopped after $([math]::Round($timeoutSec / 60)) min without finishing" }
            }
            Show-ParkedUac $shown
        }
        $code = $proc.ExitCode
        [pscustomobject]@{ Ok = $code -eq 0; Code = $code; Reason = $(if ($code) { 'exit code 0x{0:X8}' -f $code }) }
    } finally { Remove-Item $stdin -Force -ErrorAction SilentlyContinue }
}

# An installer that elevates from behind the terminal (GlazeWM's bundle does) gets its
# UAC prompt parked: Windows shows only a flashing taskbar button, which is easy to miss
# and invisible once the taskbar is hidden, and the install waits minutes on it. The
# placeholder is a visible consent.exe window of this class; SwitchToThisWindow opens the
# prompt, as clicking the button would (winarchy.ahk ShowUacPrompt does the same).
function Show-ParkedUac([hashtable]$shown) {
    try {
        Add-NativeType Uac @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string name);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")] public static extern void SwitchToThisWindow(IntPtr h, bool altTab);
'@
        $hwnd = [Winarchy.Uac]::FindWindow('$$$Secure UAP Dummy Window Class For Interim Dialog', $null)
        if ($hwnd -eq [IntPtr]::Zero -or $shown.ContainsKey($hwnd) -or -not [Winarchy.Uac]::IsWindowVisible($hwnd)) { return }
        $shown[$hwnd] = $true
        Write-Ok 'Windows is asking for admin permission: answer the prompt to carry on.'
        [Winarchy.Uac]::SwitchToThisWindow($hwnd, $true)
    } catch {}
}

# Start-Process takes one command line: quote what would otherwise split.
function ConvertTo-ArgString([string[]]$list) {
    @($list | ForEach-Object { if ($_ -eq '' -or $_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
}

# Codes that mean the package is fine. Names and texts come from `winget error --input <code>`.
#   0x8A15002B UPDATE_NOT_APPLICABLE: already current, not a failure.
$WingetExitOk = @(0, 0x8A15002B)
# Installed, but Windows must restart to finish: a success that the person still has to act on.
#   0x8A150109 REBOOT_REQUIRED_TO_FINISH   0x8A15010B REBOOT_INITIATED
#   3010 / 1641: the same, as an MSI installer reports it
$WingetRebootCodes = @(0x8A150109, 0x8A15010B, 3010, 1641)
# Another installer holds the machine's install lock: worth waiting for rather than failing.
#   0x8A150102 INSTALL_IN_PROGRESS   1618 ERROR_INSTALL_ALREADY_RUNNING (Windows Installer)
$WingetBusyCodes = @(0x8A150102, 1618)

# Installer arguments that replace the manifest's, per package and verb.
#   Rustlang.Rustup upgrade: winget runs rustup-init (-y -q), which on a PC that has Rust
#   also updates the whole default toolchain - minutes of silent downloading in a window
#   of its own. Updating rustup itself is what was asked for; toolchains stay as they are.
$WingetOverrides = @{
    'upgrade|Rustlang.Rustup' = '-y -q --no-update-default-toolchain'
}

function Get-WingetArgs([string]$verb, [string]$id, [string]$scope) {
    $a = @($verb, '-e', '--id', $id, '--silent', '--accept-source-agreements', '--accept-package-agreements', '--disable-interactivity')
    if ($scope) { $a += @('--scope', $scope) }
    $override = $WingetOverrides["$verb|$id"]
    if ($override) { $a += @('--override', $override) }
    $a
}

# A reason a person can act on, for the exit codes seen in practice; the raw code otherwise.
function Get-WingetReason([int]$code, [string]$suffix = '') {
    switch ($code) {
        { $_ -in 0x80073D02, 0x8A150101, 0x8A150103 } { 'the app is running: close it (and terminals using it) and try again' }
        0x8A150102 { 'another installation kept running: try again in a few minutes' }
        1618 { 'another installation kept running: try again in a few minutes' }
        0x8A15010A { 'Windows must restart first: restart your PC and try again' }
        0x8A150104 { 'a dependency it needs is missing from this PC' }
        0x8A150105 { 'the disk is full' }
        0x8A150106 { 'not enough memory: close other programs and try again' }
        0x8A150107 { 'no internet connection' }
        0x8A150011 { 'the download did not match its checksum (a bad or changed installer): try again later' }
        0xC000013A { 'the installer window was closed before it finished' }
        default { 'exit code 0x{0:X8}{1}' -f $code, $suffix }
    }
}

function Invoke-Winget([string]$verb, [string]$id, [string]$scope) {
    for ($try = 1; ; $try++) {
        $r = Invoke-Unattended 'winget' (Get-WingetArgs $verb $id $scope)
        if ($r.Code -in $WingetBusyCodes -and $try -lt 4) { Write-Ok "another installation is running: waiting a bit, then trying $id again"; Start-Sleep -Seconds 30; continue }
        break
    }
    $r | Add-Member Reboot ($r.Code -in $WingetRebootCodes) -Force
    if ($r.Code -in $WingetExitOk -or $r.Reboot) { $r.Ok = $true; $r.Reason = $null }
    elseif ($null -ne $r.Code) { $r.Reason = Get-WingetReason $r.Code }
    $r
}

# Exit codes that mean "only an administrator can do this" - a machine-wide package
# (WSL, an all-users MSIX or MSI) refuses a normal token. These get one more try, elevated.
#   0x80073D28 MSIX: administrator privileges are required
#   0x80070005 access denied          0x800702E4 / 740 elevation required
#   0x8A150019 winget: the command requires administrator privileges
$WingetAdminCodes = @(-2147009240, -2147024891, -2147024156, 740, -1978335207)

# Names of running programs that live in Git for Windows' own folder (bash.exe and friends).
function Get-GitInUse {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { return }
    $root = Split-Path (Split-Path $git.Source)
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith("$root\", [StringComparison]::OrdinalIgnoreCase) } | ForEach-Object { $_.ProcessName + '.exe' }
}

# After a failed upgrade: which running programs live in that package's folder, so the
# message can name what to close. The folder comes from the app's own uninstall entry or
# its MSIX package, found through the name winget lists it under. Programs this window
# runs inside of (the shell, the terminal hosting it) are left out: they can't be closed
# from under it, and they are not what the person should hunt for.
function Get-PackageInUse([string]$id) {
    try {
        $line = winget list -e --id $id --accept-source-agreements --disable-interactivity 2>$null | Out-String |
            ForEach-Object { $_ -split "`r?`n" } | Where-Object { $_ -match ('(?<!\S)' + [regex]::Escape($id) + '(?=\s)') } | Select-Object -First 1
        if (-not $line) { return }
        $name = ($line -split [regex]::Escape($id))[0].Trim()
        if (-not $name) { return }
        $dirs = @(Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -eq $name -and $_.InstallLocation } | ForEach-Object { $_.InstallLocation.TrimEnd('\') })
        $dirs += @(Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$($name -replace '\s')*" -or $_.PackageFamilyName -like "*$($name -replace '\s')*" } | ForEach-Object InstallLocation)
        $dirs = @($dirs | Where-Object { $_ -and $_.Length -gt 12 } | Select-Object -Unique)
        if (-not $dirs) { return }
        $skip = @{}; $cur = $PID
        while ($cur -and -not $skip.ContainsKey($cur)) {
            $skip[$cur] = $true
            $cur = [int](Get-CimInstance Win32_Process -Filter "ProcessId=$cur" -ErrorAction SilentlyContinue).ParentProcessId
        }
        foreach ($proc in Get-Process -ErrorAction SilentlyContinue) {
            if ($skip.ContainsKey($proc.Id) -or -not $proc.Path) { continue }
            foreach ($d in $dirs) { if ($proc.Path.StartsWith("$d\", [StringComparison]::OrdinalIgnoreCase)) { $proc.ProcessName + '.exe'; break } }
        }
    } catch {}
}

function Add-FailedUpdate([string]$id, $r) {
    $why = $r.Reason
    $busy = @(Get-PackageInUse $id | Sort-Object -Unique)
    if ($busy) { $why += "; still running: $($busy -join ', ') - close it and click update again" }
    Add-Unfinished "$id did not update ($why)"
}

function Test-Elevated {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Upgrades the given packages from one elevated window, so a whole batch costs a single
# UAC prompt. Returns id -> the same result object Invoke-Winget gives. The elevated side
# is an inline command (never a file the user's own processes could swap underneath it).
function Invoke-WingetElevated([string[]]$ids, [int]$timeoutSec = 900) {
    $results = @{}
    $out = New-TemporaryFile
    try {
        $calls = [ordered]@{}
        foreach ($id in $ids) { $calls[$id] = @(Get-WingetArgs upgrade $id $null) }
        $json = ($calls | ConvertTo-Json -Compress -Depth 4) -replace "'", "''"
        $script = @"
`$calls = '$json' | ConvertFrom-Json -AsHashtable
`$res = [ordered]@{}
foreach (`$id in `$calls.Keys) {
    Write-Host "``n==> upgrading `$id as administrator" -ForegroundColor Cyan
    `$a = `$calls[`$id]; & winget @a
    `$res[`$id] = `$LASTEXITCODE
}
`$res | ConvertTo-Json | Set-Content -LiteralPath '$($out.FullName -replace "'", "''")' -Encoding utf8
"@
        $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
        try {
            $proc = Start-Process (Get-Paths).pwsh -Verb RunAs -PassThru -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc"
        } catch {
            foreach ($id in $ids) { $results[$id] = [pscustomobject]@{ Ok = $false; Code = $null; Reason = 'the administrator prompt was declined' } }
            return $results
        }
        if (-not $proc.WaitForExit($timeoutSec * 1000 * [math]::Max(1, $ids.Count))) { try { $proc.Kill($true) } catch {} }
        $codes = try { Get-Content -Raw $out.FullName | ConvertFrom-Json -AsHashtable } catch { $null }
        foreach ($id in $ids) {
            $code = if ($codes -and $codes.Contains($id)) { [int]$codes[$id] } else { $null }
            $reboot = $null -ne $code -and $code -in $WingetRebootCodes
            $ok = $null -ne $code -and ($code -in $WingetExitOk -or $reboot)
            $reason = if ($ok) { $null } elseif ($null -eq $code) { 'the administrator window did not finish' } else { Get-WingetReason $code ', as administrator' }
            $results[$id] = [pscustomobject]@{ Ok = $ok; Code = $code; Reason = $reason; Reboot = $reboot }
        }
        $results
    } finally { Remove-Item $out -Force -ErrorAction SilentlyContinue }
}

# The fresh check only sees what winget still lists. Anything this run could not update
# stays on the bar's update icon either way, so it is not forgotten until the next try.
function Add-PendingUpdates($file, [object[]]$items) {
    if (-not $items) { return }
    $u = Read-Json $file
    $list = [Collections.Generic.List[object]]::new()
    foreach ($i in @($u.items | Where-Object { $_ })) { $list.Add($i) }
    foreach ($i in $items) { if (-not ($list | Where-Object name -eq $i.name)) { $list.Add($i) } }
    Write-Json $file ([ordered]@{ checked = $u.checked ?? (Get-Date).ToString('s'); items = @($list) })
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
    foreach ($u in $script:Unfinished) { Write-Warn $u }
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
    if ($r.Ok) { Write-Done "$name installed" } else { Write-Warn "$name did not install ($($r.Reason))" }
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
    } else { Save-Winget 'AutoHotkey.AutoHotkey' $true; Write-Done "AutoHotkey: $($p.ahk)" }
    if (-not $p.nerdFont) {
        Write-Ok 'installing JetBrainsMono Nerd Font (bar icons + terminal glyphs)'
        [void](Install-NerdFont 'JetBrainsMono')
    } else { Write-Done 'JetBrainsMono Nerd Font: installed' }
}

function Install-Apps {
    Write-Step 'Apps'
    foreach ($a in $Apps) {
        if (& $a.test) { Save-Winget $a.id $true; Write-Done "$($a.name): installed"; continue }
        Save-Winget $a.id $false
        # Before Zebar exists: its first run would otherwise make its generic starter bar
        # the one it opens (Set-ZebarStartup).
        if ($a.id -eq 'glzr-io.glazewm') { try { Set-ZebarStartup } catch { Log "Zebar settings not written yet ($($_.Exception.Message)); apply writes them" } }
        if ($a.note) { Write-Ok $a.note }
        [void](Install-WingetPackage $a.id $a.name $null)
        [void](Update-Paths)
        # Carry on without it: everything else still gets set up, and a second run of
        # install only does what is missing.
        if (-not (& $a.test)) { Add-Unfinished "$($a.name) did not install: run 'winarchy install' again, or: winget install -e --id $($a.id)" }
    }
}

$Extras = @(
    @{ id = 'Fastfetch-cli.Fastfetch'; name = 'fastfetch'; have = { Get-Command fastfetch.exe -ErrorAction SilentlyContinue } },
    @{ id = 'aristocratos.btop4win'; name = 'btop'; have = { (Update-Paths).btopDir } },
    # The bar's AI agent usage runs Omarchy's collectors, which are Python. Find-Python,
    # not Get-Command: the Store's `python` stub is on PATH and would pass for one.
    @{ id = 'Python.Python.3.13'; name = 'Python 3 (the bar''s AI agent usage)'; have = { Find-Python } }
)

# The winget packages winarchy itself runs on. Uninstall treats these apart from the apps
# the person picked (it removes them unless -KeepApps, and never asks about each one).
function Get-CoreWingetIds {
    @('AutoHotkey.AutoHotkey') + @($Apps | ForEach-Object { $_.id }) + @($Extras | ForEach-Object { $_.id })
}

# About (fastfetch), Activity (btop) and the screensaver's effects engine (ttfx).
function Install-Extras {
    Write-Step 'Extras (About, Activity, screensaver effects, agent usage)'
    foreach ($x in $Extras) {
        if (& $x.have) { Save-Winget $x.id $true; Write-Done "$($x.name): installed"; continue }
        Save-Winget $x.id $false
        if (-not (Install-WingetPackage $x.id $x.name $null)) { Add-Unfinished "$($x.name) (optional) did not install: winget install -e --id $($x.id)" }
    }
    $p = Update-Paths
    if ($p.ttfx) { Write-Done "ttfx: $($p.ttfx)"; return }
    # ttfx (Omarchy's Rust port of terminaltexteffects): a download of your own (ttfxUrl),
    # else winarchy's pinned build (default/prebuilt.json), else built with cargo when Rust
    # is present.
    $url = (Get-Config).ttfxUrl
    $dest = Join-Path $Data 'bin\ttfx.exe'
    if ($url) {
        try {
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Invoke-WebRequest $url -OutFile $dest -TimeoutSec 120
            Write-Ok "ttfx: downloaded to $dest"; return
        } catch { Write-Ok "ttfx download failed ($($_.Exception.Message))" }
    } elseif ($pin = Get-Prebuilt 'ttfx') {
        try { Install-PrebuiltTtfx $pin $dest; Write-Ok "ttfx $($pin.version): downloaded to $dest"; return }
        catch { Write-Ok "ttfx download failed ($($_.Exception.Message)): building it instead" }
    }
    $cargo = Get-Command cargo -ErrorAction SilentlyContinue
    if ($cargo) {
        # Compiling takes minutes and only the screensaver needs it: a hidden process builds
        # it while the install carries on. It lands in ~/.cargo/bin, where the screensaver
        # looks when no other ttfx was found (Set-TerminalProfiles), so no apply is needed.
        if (Get-CimInstance Win32_Process -Filter "Name='cargo.exe'" -ErrorAction SilentlyContinue | Where-Object CommandLine -match 'omacom/ttfx') {
            Write-Ok 'ttfx: already being built in the background'; return
        }
        [void](Add-JournalEntry @{ kind = 'cargo'; key = 'cargo|ttfx'; crate = 'ttfx' })
        $log = Join-Path $Data 'logs\ttfx-build.log'
        $src = (Read-Json (Join-Path $Code 'default\prebuilt.json') -AsHashtable).ttfx
        $cmd = "& '$($cargo.Source -replace "'", "''")' install --git https://github.com/$($src.source) --tag $($src.tag) --locked *> '$($log -replace "'", "''")'"
        Start-Hidden (Get-Paths).pwsh @('-NoProfile', '-EncodedCommand', (ConvertTo-EncodedCommand $cmd))
        Write-Ok "ttfx: building in the background (a few minutes; log: $log). The screensaver shows the still logo until then."
    } else {
        Write-Ok 'ttfx not available: the screensaver shows the still logo (install Rust, then: winarchy extras)'
    }
}

# The pinned ttfx release is a zip (ttfx.exe with its license): only the exe is kept.
function Install-PrebuiltTtfx($pin, [string]$dest) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) "winarchy-ttfx-$([guid]::NewGuid().ToString('N'))"
    try {
        Save-PinnedFile $pin.url $pin.sha256 "$tmp.zip" 120
        Expand-Archive -LiteralPath "$tmp.zip" -DestinationPath $tmp -Force
        $exe = Get-ChildItem -LiteralPath $tmp -Recurse -Filter ttfx.exe | Select-Object -First 1
        if (-not $exe) { throw 'the download has no ttfx.exe' }
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Copy-Item -Force -LiteralPath $exe.FullName $dest
    } finally { Remove-Item -LiteralPath $tmp, "$tmp.zip" -Recurse -Force -ErrorAction SilentlyContinue }
}

# Herdr, on a fresh install. Asked for rather than assumed: it is the one thing winarchy
# installs that does not come from winget, and its binary is unsigned. Saying no here
# costs nothing - Omarchy menu > Install > Terminal > Herdr adds it later, and everything
# downstream (config, theming, hdl/hds/hdlm/hsl, the menu rows) is written by the apply
# that runs after this either way.
function Install-HerdrStep {
    if (Test-HerdrInstalled) { Write-Done "Herdr: $(Get-HerdrExe)"; return }
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

# Everything winarchy needs on the machine, installing only what is missing: install runs
# it, and so do `winarchy update` (in a fresh process, after the pull, so a dependency that
# new code brings in - Python arrived this way - lands on PCs installed before it) and
# `winarchy doctor -Fix`. Each step records what it installs in the journal first, and
# notes as preinstalled whatever was already there, so uninstall removes only what winarchy
# added. Herdr is not in here: it is an optional add-on, not something winarchy needs, and
# installing an unsigned binary from outside winget is the person's call (Install-HerdrStep).
function Install-Dependencies {
    Install-Prerequisites
    Install-Apps
    Install-Extras
    [void](Update-Paths)
}

# Install's theme download, in a hidden process of its own (winarchy sync -Background):
# the files, then the pickers' thumbnails. $null if it could not start (install then
# downloads at the themes step, as before).
function Start-ThemeDownload {
    try {
        New-Item -ItemType Directory -Force $Generated | Out-Null
        Remove-Item -LiteralPath $ThemeDownloadProgress -Force -ErrorAction SilentlyContinue
        $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Code 'bin\winarchy.ps1'), 'sync', '-Background')
        Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList (ConvertTo-ArgString $a) -WindowStyle Hidden -PassThru
    } catch { Log "theme download did not start in the background ($($_.Exception.Message))"; $null }
}

# Waits for it, showing its progress. One that hangs is stopped after $timeoutSec; the
# sync that follows fetches whatever it did not bring.
function Wait-ThemeDownload($proc, [int]$timeoutSec = 900) {
    $deadline = [DateTime]::UtcNow.AddSeconds($timeoutSec)
    if (-not $proc.HasExited) { Write-Ok 'Finishing the download that started with the install...' }
    $shown = -1
    while (-not $proc.WaitForExit(500)) {
        if ([DateTime]::UtcNow -gt $deadline) {
            try { $proc.Kill($true) } catch {}
            Log "background theme download stopped after $([math]::Round($timeoutSec / 60)) min"
            break
        }
        $s = Read-Json $ThemeDownloadProgress
        if ($s -and $s.count -and $s.done -ne $shown) {
            $shown = $s.done
            Write-UiProgress 'downloading' $s.done $s.count ('{0:N0}/{1:N0} MB' -f ($s.bytes / 1MB), ($s.total / 1MB))
        }
    }
    Remove-Item -LiteralPath $ThemeDownloadProgress -Force -ErrorAction SilentlyContinue
}

# The few questions whose answer depends on the person, not the machine. Restoring the
# settings an earlier uninstall kept, or a config.json copied in first, only what they
# never answered is asked.
function Get-InstallAnswers($p, [switch]$Restoring) {
    $cfg = Read-UserConfig
    if (-not $cfg) { $cfg = [ordered]@{} }
    $ask = { param([string]$key) -not ($Restoring -and $cfg.Contains($key)) }
    Write-Step $(if ($Restoring) { 'Your choices (kept from before; only new ones are asked)' } else { 'A few choices (Enter = recommended)' })
    if (([int]$p.input.count -gt 1 -or $p.input.ime) -and (& $ask 'takeOverWinSpace')) {
        Write-Ok "You have $($p.input.count) keyboard layouts/input methods. Windows switches them with Win+Space;"
        Write-Ok 'Winarchy uses Super+Space for the Omarchy menu (Alt+Shift still switches layouts).'
        $cfg.takeOverWinSpace = Read-YesNo 'Use Super+Space for the Omarchy menu?' $true
    }
    $personal = Join-Path $p.startup 'launchers.ahk'
    if ((Test-Path $personal) -and (& $ask 'launchers')) {
        Write-Ok "Found your own launcher script ($personal)."
        $cfg.launchers = -not (Read-YesNo 'Keep using it instead of winarchy''s app keys?' $true)
    }
    if (& $ask 'hideTaskbar') { $cfg.hideTaskbar = Read-YesNo 'Hide the Windows taskbar (the top bar replaces it)?' $true }
    # A new install gets Omarchy's capture keys and CapsLock compose; a config from before
    # keeps what it had (Invoke-ConfigMigration writes that when apply runs).
    if ($script:FreshInstall) {
        foreach ($k in $FreshInstallValues.Keys) { if (-not $cfg.Contains($k)) { $cfg[$k] = $FreshInstallValues[$k] } }
        # With an input method (Japanese, Chinese, Korean) CapsLock switches modes: leave it.
        if ($p.input.ime) { $cfg.compose = $false }
    }
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
    # The animation build is unsigned and built locally: Defender can quarantine it between
    # Update-Paths and here. Re-detect so the official GlazeWM starts instead.
    # Apply again too, so the config and winarchy.ahk's restart guard stop pointing at it.
    if ($p.glazewm -and -not (Test-Path $p.glazewm)) {
        $why = if (Get-AnimationQuarantine) { 'Windows Defender removed it' } else { 'it is gone' }
        Log "GlazeWM $($p.glazewm): $why; starting the official GlazeWM (animations back: winarchy animations allow)"
        Use-Lock { Invoke-Apply -NoRestart }
        $p = Get-Paths
    }
    if ($p.glazewm -and -not (Get-GlazeWmProcess)) { Start-GlazeWM $p.glazewm }
    if ($p.flow -and -not (Get-Process Flow.Launcher -ErrorAction SilentlyContinue)) { Start-Process $p.flow }
    Restart-Bar $p
    Restart-OmarchyAhk $p
}

function Invoke-Install([switch]$Yes, [switch]$Adopt) {
    # WINARCHY_YES too, so the one-line `irm | iex` install can run unattended.
    $script:AssumeYes = $Yes -or [bool]$env:WINARCHY_YES
    $script:Unfinished.Clear()
    $cfgVersion = (Get-Content -Raw (Join-Path $Code 'VERSION') -ErrorAction SilentlyContinue)?.Trim()
    Start-UiClock
    Write-UiBanner $cfgVersion
    # Invoke-WebRequest's own progress bar slows big downloads (the Nerd Font zip) a lot,
    # and the theme download draws its own.
    $ProgressPreference = 'SilentlyContinue'
    New-Item -ItemType Directory -Force $Data | Out-Null
    Test-Preflight
    if ($Adopt) { return Invoke-Adopt }
    # An earlier uninstall kept the person's settings: this install puts them back. A
    # config.json put there by hand first (copied from another PC) counts the same: what
    # it already answers is not asked again. One that does not parse stops here, before
    # anything is installed, rather than be replaced by the answers.
    $restoreFile = Join-Path $Data 'restore.json'
    $null = Read-UserConfig
    $script:FreshInstall = -not (Test-Path $ConfigFile)
    $restoring = -not $script:FreshInstall
    if ($restoring -and (Test-Path $restoreFile)) {
        Write-Step "Welcome back: restoring your saved settings (theme $((Read-State).theme), background, font, config.json)"
    } elseif ($restoring) {
        Write-Step "Using the config.json already in $Data"
    }

    if (-not (Test-Journaled 'runkeys')) {
        [void](Add-JournalEntry @{ kind = 'runkeys'; key = 'runkeys'; names = @((Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue).PSObject.Properties.Name | Where-Object { $_ -notlike 'PS*' }) })
    }
    Save-Dir (Join-Path $env:USERPROFILE '.glzr')

    # Asked first, so the download runs while winget installs the apps: it needs none of
    # them, and on most connections it is done before they are. After Save-Dir: its
    # thumbnails go under ~/.glzr, which the journal must see as it was before.
    Write-Step 'Omarchy themes and backgrounds'
    $downloaded = @(Get-ChildItem $Themes -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'colors.toml') }).Count -gt 1
    $themeDownload = $null
    $themeOnline = $false
    if ($restoring -and $downloaded) { Write-Ok 'Already downloaded (kept from before).' }
    elseif (Read-YesNo 'Download Omarchy''s 22 themes and ~100 backgrounds (about 110 MB)? They download while the apps install.' $true) {
        $themeOnline = $true
        $themeDownload = Start-ThemeDownload
        if ($themeDownload) { Write-Ok 'Downloading in the background.' }
    } else { Write-Ok 'Skipped: run "winarchy sync" any time.' }

    Install-Dependencies
    Install-HerdrStep
    Install-TailscaleStep -Restoring:$restoring
    $p = Update-Paths

    $cfg = Get-InstallAnswers $p -Restoring:$restoring
    Write-Json $ConfigFile $cfg

    Write-Step 'Configuring'
    if ((Get-Config).hideTaskbar) { Set-TaskbarAutoHide }
    Add-CliToPath
    Use-Lock { Invoke-Apply -NoRestart }
    Write-Done 'GlazeWM, bar, menus, keys and autostart configured'

    Write-Step 'Omarchy themes and backgrounds'
    if ($themeOnline) {
        if ($themeDownload) { Wait-ThemeDownload $themeDownload }
        # Fetches only what the background download did not bring (usually nothing: one
        # request for the file list), so a failed or never-started one still ends complete.
        Use-Lock { Invoke-Sync }
    } else { Use-Lock { Invoke-Sync -Offline } }
    # The theme used last (a reinstall keeps it, with its background), else tokyo-night.
    $theme = @((Read-State).theme, 'tokyo-night') | Where-Object { $_ -and (Test-Path (Join-Path $Themes "$_\colors.toml")) } | Select-Object -First 1
    if ($theme) { Use-Lock { Invoke-ThemeSet $theme } }

    Write-Step 'Starting'
    Start-Everything $p
    # Last, so a slow or failed build can't hold up the rest: the official GlazeWM already runs.
    Invoke-AnimationOffer
    if ($restoring -and (Test-Path $restoreFile)) { Remove-Item $restoreFile -Force -ErrorAction SilentlyContinue; Write-Done 'Your settings are back.' }
    Write-UiFinish
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
    Start-UiClock
    $ProgressPreference = 'SilentlyContinue'
    $script:Unfinished.Clear()
    $updFile = Join-Path $Pack 'updates.json'
    $pending = @((Read-Json $updFile).items | Where-Object { $_ })
    $notUpdated = [Collections.Generic.List[string]]::new()
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

        # Whatever winarchy needs and this PC is missing - including anything the code just
        # pulled depends on that an older install never set up. A fresh process, like apply
        # below: this one still has the code from before the pull loaded.
        $deps = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Code 'bin\winarchy.ps1'), 'deps')
        & $p.pwsh @deps
        if ($LASTEXITCODE) { Add-Unfinished 'some dependencies did not install (listed above); winarchy doctor -Fix tries again' }

        Write-Step 'Omarchy themes'
        $omarchy = $pending | Where-Object name -eq 'Omarchy themes' | Select-Object -First 1
        if ($omarchy) {
            $s = Read-State; $s.omarchyTag = $omarchy.to; Save-State $s
            # A fresh process too: what gets mirrored (Get-SyncTarget) follows the new code.
            & $p.pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Code 'bin\winarchy.ps1') sync
            if ($LASTEXITCODE) { Add-Unfinished 'Omarchy themes not fully updated; winarchy sync tries again' }
        } else { Write-Ok 'up to date' }

        # Herdr came from its own installer, so winget cannot upgrade it: it has an updater
        # of its own, and it is the only thing here that does.
        if (Test-HerdrInstalled) {
            Write-Step 'Herdr'
            try { & (Get-HerdrExe) update 2>&1 | Out-Host } catch { Write-Ok "herdr update failed: $($_.Exception.Message)" }
        }

        # Omarchy's own apps: a newer pinned build in the code just pulled (a fresh process
        # reads the new default/ports.json with the new code).
        if (Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Programs\Winarchy\oma') -Directory -ErrorAction SilentlyContinue) {
            Write-Step 'Omarchy apps'
            & $p.pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Code 'bin\winarchy.ps1') ports update
            if ($LASTEXITCODE) { Add-Unfinished 'Omarchy apps not updated (see above); winarchy ports update tries again' }
        }

        Write-Step 'Apps'
        $ids = @($pending | Where-Object { $_.name -match '^[\w-]+\.[\w.-]+$' } | ForEach-Object name)
        if (-not $ids) { Write-Ok 'up to date' }
        # Upgrading AutoHotkey closes running scripts: remember them to start them again.
        $scripts = @(Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" | ForEach-Object CommandLine)
        $needAdmin = [Collections.Generic.List[string]]::new()
        $reboots = [Collections.Generic.List[string]]::new()
        $knownAdmin = @((Read-State).adminApps | Where-Object { $_ })
        foreach ($id in $ids) {
            if (-not (Test-WingetUnattended $id)) {
                Add-Unfinished "$id not updated: its installer can't run unattended; open the app and it updates itself"
                $notUpdated.Add($id)
                continue
            }
            # Git's installer refuses to run (exit 1) while any Git Bash / ssh / gpg process
            # from its folder is alive, and nothing here may close a terminal you are using.
            if ($id -eq 'Git.Git') {
                $busy = @(Get-GitInUse)
                if ($busy) {
                    Add-Unfinished "Git.Git not updated: still in use by $(($busy | Sort-Object -Unique) -join ', '). Close terminals running Git Bash (bash.exe) and click update again"
                    $notUpdated.Add($id)
                    continue
                }
            }
            # A package that has refused a normal token before goes straight to the elevated
            # batch: no failed first attempt, no scary error in the window.
            if ($id -in $knownAdmin -and -not (Test-Elevated)) { Write-Ok "$id needs administrator rights: updating it elevated below"; $needAdmin.Add($id); continue }
            Write-Ok "upgrading $id"
            # rustup-init is a console program: winget gives it a window of its own. Only
            # rustup itself updates (see $WingetOverrides), so it closes within seconds.
            if ($id -eq 'Rustlang.Rustup') { Write-Ok 'rustup updates in a separate window that closes itself in a few seconds.' }
            $r = Invoke-Winget upgrade $id $null
            if ($r.Ok) { if ($r.Reboot) { $reboots.Add($id) }; continue }
            if ($r.Code -in $WingetAdminCodes -and -not (Test-Elevated)) {
                Write-Ok "$id needs administrator rights: trying again elevated below"; $needAdmin.Add($id)
                $s = Read-State; $s.adminApps = @(@($s.adminApps) + $id | Where-Object { $_ } | Select-Object -Unique); Save-State $s
                continue
            }
            Add-FailedUpdate $id $r
            $notUpdated.Add($id)
        }
        if ($needAdmin.Count) {
            Write-Ok "Windows asks once (UAC) to update $($needAdmin -join ', ') as administrator; it runs in its own window."
            $elevated = Invoke-WingetElevated @($needAdmin)
            foreach ($id in $needAdmin) {
                $r = $elevated[$id]
                if ($r.Ok) { Write-Ok "$id updated as administrator"; if ($r.Reboot) { $reboots.Add($id) } }
                else { Add-FailedUpdate $id $r; $notUpdated.Add($id) }
            }
        }
        if ($reboots.Count) { Add-Unfinished "$($reboots -join ', ') updated, but Windows must restart to finish: restart your PC when convenient" }
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
        Add-PendingUpdates $updFile @($pending | Where-Object { $notUpdated -contains $_.name })
    } catch {
        $crash = $_
        Add-Unfinished "update stopped: $($_.Exception.Message)"
    } finally {
        # Died before the fresh check: put the list back so the icon doesn't claim all is well.
        if (-not $checked) { Write-Json $updFile ([ordered]@{ checked = (Get-Date).ToString('s'); items = $pending }) }
        $m.ReleaseMutex(); $m.Dispose()
    }
    Write-Unfinished
    if ($script:Unfinished.Count) { Wait-KeyToClose }
    else { Write-Host ''; Write-Host "  $(Format-Ui (Get-UiGlyphs).ok 'green' -Bold) $(Format-Ui 'Up to date.' 'green' -Bold)$(Format-Ui "  took $(Get-UiClock)" 'dim')" }
    if ($crash) { throw $crash }
}
