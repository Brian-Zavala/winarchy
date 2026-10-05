# Omarchy's own apps, built for Windows: Omawrite, Omacalc, Omacut, Hype and Aether
# (default/ports.json, built by .github/workflows/ports.yml). Each is one self-contained
# x64 zip, pinned by its SHA-256, unpacked into %LOCALAPPDATA%\Programs\Winarchy\oma\<key>,
# with a Start menu shortcut. They follow the theme through the colors.toml winarchy
# keeps where they look for it (Set-OmarchyStateTheme, lib/themes.ps1).

function Get-PortRoot { Join-Path $env:LOCALAPPDATA 'Programs\Winarchy\oma' }
function Get-PortStartDir { Join-Path ([Environment]::GetFolderPath('Programs')) 'Winarchy' }

function Get-PortManifest {
    @((Read-Json (Join-Path $Code 'default\ports.json') -AsHashtable).apps)
}

# Only the ones with a published build.
function Get-PublishedPorts { @(Get-PortManifest | Where-Object { $_.url -and $_.sha256 }) }

function Get-PortExe([string]$key) { Join-Path (Get-PortRoot) "$key\$key.exe" }

# Smart App Control (Windows 11, on by default on some new PCs) runs only signed apps, and
# these builds are not signed: say so up front instead of an install Windows then blocks.
# 0 off, 1 on, 2 evaluating (it may turn itself on).
function Get-SmartAppControlState {
    $v = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -Name VerifiedAndReputablePolicyState -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState
    if ($null -eq $v) { 0 } else { [int]$v }
}

function Test-Port([string]$key) { Test-Path -LiteralPath (Get-PortExe $key) }

function Install-Port([string]$key) {
    $app = Get-PortManifest | Where-Object key -eq $key | Select-Object -First 1
    if (-not $app) { throw "no Omarchy app '$key'" }
    if (-not $app.url -or -not $app.sha256) { throw "$($app.label) has no Windows build yet" }
    switch (Get-SmartAppControlState) {
        1 { throw "$($app.label) is not signed, and Smart App Control (Windows Security > App & browser control) only runs signed apps. Turning it off lets it run; Windows does not let it be turned back on without a reset." }
        2 { Write-Ok 'Smart App Control is evaluating this PC: if it turns itself on, it will block this unsigned app.' }
    }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) "winarchy-$key-$([guid]::NewGuid()).zip"
    try {
        Write-Ok "downloading $($app.label) $($app.version)..."
        Invoke-WebRequest $app.url -OutFile $tmp -TimeoutSec 600 -ErrorAction Stop
        $hash = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash
        if ($hash -ne $app.sha256.ToUpper()) { throw "$($app.label): the download does not match its pinned SHA-256 (got $hash); nothing was installed" }
        $dir = Join-Path (Get-PortRoot) $key
        $lnk = Join-Path (Get-PortStartDir) "$($app.label -replace ' \(.*\)$', '').lnk"
        [void](Add-JournalEntry @{ kind = 'port'; key = "port|$key"; label = $app.label; dir = $dir; lnk = $lnk })
        if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
        New-Item -ItemType Directory -Force $dir | Out-Null
        Expand-Archive -LiteralPath $tmp -DestinationPath $dir -Force
        Get-ChildItem -LiteralPath $dir -Recurse -File | Unblock-File
        Set-Content -LiteralPath (Join-Path $dir 'winarchy-version.txt') $app.version
        $exe = Get-PortExe $key
        if (-not (Test-Path -LiteralPath $exe)) { throw "$($app.label): the build has no $key.exe" }
        New-Item -ItemType Directory -Force (Split-Path $lnk) | Out-Null
        $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
        $s.TargetPath = $exe; $s.WorkingDirectory = $dir; $s.Description = $app.label
        $s.Save()
        try { Initialize-ShortcutNative; [Winarchy.Shortcut]::SetAppId($lnk, "Winarchy.Oma.$key") } catch { Log "$key shortcut: no AppUserModelID ($($_.Exception.Message))" }
        Write-Ok "$($app.label) is in Start$(if ($app.note) { ". $($app.note)" })"
    } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}

function Remove-PortFiles($entry) {
    foreach ($p in $entry.lnk) { if ($p) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } }
    if ($entry.dir) { Remove-Item -LiteralPath $entry.dir -Recurse -Force -ErrorAction SilentlyContinue }
    foreach ($d in (Get-PortStartDir), (Get-PortRoot)) {
        if ((Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force)) { Remove-Item -LiteralPath $d -Force -ErrorAction SilentlyContinue }
    }
}

function Remove-Port([string]$key) {
    $e = Get-JournalEntry "port|$key"
    if (-not $e) { $e = @{ dir = Join-Path (Get-PortRoot) $key } }
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$($e.dir)\*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    Remove-PortFiles $e
    [void](Remove-JournalEntry "port|$key")
}

# Installed ones whose pinned build is newer (winarchy update installs those again).
function Get-OutdatedPorts {
    foreach ($app in Get-PublishedPorts) {
        $v = Join-Path (Get-PortRoot) "$($app.key)\winarchy-version.txt"
        if ((Test-Path -LiteralPath $v) -and (Get-Content -LiteralPath $v -TotalCount 1) -ne $app.version) { $app }
    }
}

# winarchy ports [list | update]
function Invoke-Ports([string]$what) {
    switch ($what) {
        'update' {
            $old = @(Get-OutdatedPorts)
            if (-not $old) { Write-Ok 'up to date'; return }
            foreach ($a in $old) { Install-Port $a.key }
        }
        { $_ -in '', 'list' } {
            foreach ($a in Get-PortManifest) {
                $state = if (Test-Port $a.key) { 'installed' } elseif ($a.url) { 'available' } else { 'no Windows build yet' }
                '{0,-22} {1,-9} {2}' -f $a.label, $a.version, $state
            }
        }
        default { throw 'usage: winarchy ports [list|update]' }
    }
}

# The Install > Omarchy Apps rows (lib/catalog.ps1), one per published build. Made from
# text, not closures, for the same reason as the web apps' (lib/webapps.ps1).
function Get-PortCatalogItems {
    foreach ($a in Get-PublishedPorts) {
        $k = $a.key
        @{
            key = $k; label = $a.label; id = "port-$k"; note = $a.note
            test = [scriptblock]::Create("Test-Port '$k'")
            install = [scriptblock]::Create("Install-Port '$k'")
            remove = [scriptblock]::Create("Remove-Port '$k'")
        }
    }
}
