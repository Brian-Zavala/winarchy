# Shared paths, logging, JSON, config/state and native helpers.
# Dot-sourced by bin/omarchy-win.ps1 (PowerShell 7).

$Code        = Split-Path -Parent $PSScriptRoot
$Data        = Join-Path $env:USERPROFILE '.omarchy-win'
$Pack        = Join-Path $env:USERPROFILE '.glzr\zebar\omarchy'
$GlazeConfig = Join-Path $env:USERPROFILE '.glzr\glazewm\config.yaml'
$Themes      = Join-Path $Data 'themes'
$Walls       = Join-Path $Data 'wallpapers'
$Thumbs      = Join-Path $Pack 'thumbs'
$Generated   = Join-Path $Data 'generated'
$StateFile   = Join-Path $Data 'state.json'
$ConfigFile  = Join-Path $Data 'config.json'
$PathsFile   = Join-Path $Data 'paths.json'
$LogFile     = Join-Path $Data 'logs\omarchy-win.log'
$ImageExt    = '.jpg', '.jpeg', '.png', '.bmp', '.webp'
$Invariant   = [Globalization.CultureInfo]::InvariantCulture

function Log([string]$msg) {
    $line = "$(Get-Date -Format 'HH:mm:ss') [$Verb] $msg"
    Write-Host $line
    try {
        New-Item -ItemType Directory -Force (Split-Path $LogFile) | Out-Null
        Add-Content -LiteralPath $LogFile -Value $line
    } catch {}
}

function Write-Utf8([string]$path, [string]$text) {
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    # Write-then-rename so readers (the bar polls some of these) never see half a file.
    $tmp = "$path.tmp"
    [IO.File]::WriteAllText($tmp, $text, [Text.UTF8Encoding]::new($false))
    Move-Item -Force -LiteralPath $tmp $path
}

function Read-Json([string]$path, [switch]$AsHashtable) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try { Get-Content -Raw -LiteralPath $path | ConvertFrom-Json -AsHashtable:$AsHashtable } catch { $null }
}
function Write-Json([string]$path, $obj, [int]$Depth = 32) { Write-Utf8 $path ($obj | ConvertTo-Json -Depth $Depth) }

# ~ and %VARS% in user-supplied paths.
function Expand-UserPath([string]$p) {
    if (-not $p) { return $p }
    $p = [Environment]::ExpandEnvironmentVariables($p)
    if ($p -match '^~[\\/]?') { $p = Join-Path $env:USERPROFILE ($p -replace '^~[\\/]?', '') }
    $p
}

# --- config (user settings) ------------------------------------------------------
# default/config.json holds every key with its default; ~/.omarchy-win/config.json only
# needs the keys the user changed.
function Merge-Hashtable($base, $over) {
    $out = @{}
    foreach ($k in $base.Keys) { $out[$k] = $base[$k] }
    foreach ($k in $over.Keys) {
        if ($out[$k] -is [hashtable] -and $over[$k] -is [hashtable]) { $out[$k] = Merge-Hashtable $out[$k] $over[$k] }
        else { $out[$k] = $over[$k] }
    }
    $out
}
function Get-Config {
    $def = Read-Json (Join-Path $Code 'default\config.json') -AsHashtable
    $user = Read-Json $ConfigFile -AsHashtable
    $cfg = if ($user) { Merge-Hashtable $def $user } else { $def }
    $cfg.Remove('_help')
    $cfg
}

# --- state (what omarchy-win last applied) ----------------------------------------
function Read-State {
    $s = Read-Json $StateFile -AsHashtable
    if (-not $s) { $s = @{} }
    if (-not $s.theme) { $s.theme = 'tokyo-night' }
    if (-not $s.perTheme) { $s.perTheme = @{} }
    $s
}
function Save-State($s) { Write-Json $StateFile $s 5 }

# --- detected paths (lib/detect.ps1 writes paths.json) ----------------------------
function Get-Paths {
    $p = Read-Json $PathsFile -AsHashtable
    if (-not $p) { $p = Update-Paths }
    $p
}

# status.json is polled by the bar (theme reload) and read by the menu (current selection).
function Write-Status($s, [switch]$BumpTheme) {
    $path = Join-Path $Pack 'status.json'
    $old = Read-Json $path
    $ver = if ($BumpTheme -or -not $old) { [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() } else { $old.themeVersion }
    Write-Json $path ([ordered]@{ theme = $s.theme; background = $s.background; font = $s.font; themeVersion = $ver })
}

# "0-winding-road.jpg" -> "Winding Road" (omarchy-theme-bg-current naming)
function Get-Label([string]$file) {
    $n = [IO.Path]::GetFileNameWithoutExtension($file) -replace '^\d+-', '' -replace '[-_]+', ' '
    $Invariant.TextInfo.ToTitleCase($n.Trim())
}
function Get-ThemeLabel([string]$name) { $Invariant.TextInfo.ToTitleCase(($name -replace '-', ' ')) }

# One writer at a time: quick successive picks queue up instead of racing on
# state.json, Flow's settings and Windows Terminal's settings.
function Use-Lock([scriptblock]$body) {
    $m = [Threading.Mutex]::new($false, 'Local\OmarchyWin')
    $got = $false
    try {
        try { $got = $m.WaitOne(120000) } catch [Threading.AbandonedMutexException] { $got = $true }
        if (-not $got) { throw 'another omarchy-win command is still running' }
        & $body
    } finally {
        if ($got) { $m.ReleaseMutex() }
        $m.Dispose()
    }
}

# --- native -----------------------------------------------------------------------
function Initialize-Native {
    if (-not ('OmarchyWin.Native' -as [type])) {
        Add-Type -Namespace OmarchyWin -Name Native -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool SystemParametersInfo(uint action, uint param, string vparam, uint winIni);
[DllImport("user32.dll", EntryPoint = "SystemParametersInfoW")]
public static extern bool SystemParametersInfoInt(uint action, uint param, IntPtr vparam, uint winIni);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, UIntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);
[DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
public static extern int AddFontResource(string file);
[DllImport("shell32.dll")]
public static extern int SHGetKnownFolderPath([MarshalAs(UnmanagedType.LPStruct)] Guid id, uint flags, IntPtr token, out IntPtr path);
'@
    }
}

# Tell Explorer/apps a setting changed (HWND_BROADCAST, WM_SETTINGCHANGE).
function Send-SettingChange([string]$what = 'ImmersiveColorSet') {
    Initialize-Native
    $r = [UIntPtr]::Zero
    [void][OmarchyWin.Native]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, $what, 2, 1000, [ref]$r)
}

function Get-KnownFolder([guid]$id) {
    Initialize-Native
    $ptr = [IntPtr]::Zero
    if ([OmarchyWin.Native]::SHGetKnownFolderPath($id, 0, [IntPtr]::Zero, [ref]$ptr) -ne 0) { return $null }
    try { [Runtime.InteropServices.Marshal]::PtrToStringUni($ptr) } finally { [Runtime.InteropServices.Marshal]::FreeCoTaskMem($ptr) }
}

# --- colors -----------------------------------------------------------------------
function ConvertTo-Rgb([string]$hex) {
    $h = $hex.TrimStart('#')
    @([Convert]::ToInt32($h.Substring(0, 2), 16), [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16))
}
# a*(1-t) + b*t, like Omarchy's template `mix a b t`.
function Mix([string]$a, [string]$b, [double]$t) {
    $x = ConvertTo-Rgb $a; $y = ConvertTo-Rgb $b
    '#' + (-join (0..2 | ForEach-Object { '{0:x2}' -f [int][Math]::Round($x[$_] + ($y[$_] - $x[$_]) * $t) }))
}
function To-Dword([uint32]$v) { [BitConverter]::ToInt32([BitConverter]::GetBytes($v), 0) }

# Run something hidden and detached (no console flash).
function Start-Hidden([string]$file, [string[]]$arguments) {
    Start-Process -FilePath $file -ArgumentList $arguments -WindowStyle Hidden
}
