# Shared paths, logging, JSON, config/state and native helpers.
# Dot-sourced by bin/winarchy.ps1 (PowerShell 7).

$Code        = Split-Path -Parent $PSScriptRoot
# Called through a junction (the old %LOCALAPPDATA%\omarchy-win, still on the PATH of
# shells started before the rename), $Code would name the junction, and apply would point
# autostart and the running scripts there: always the real folder.
try { if ($t = [IO.Directory]::ResolveLinkTarget($Code, $true)) { $Code = $t.FullName } } catch {}
$Data        = Join-Path $env:USERPROFILE '.winarchy'
$Pack        = Join-Path $env:USERPROFILE '.glzr\zebar\omarchy'
$GlazeConfig = Join-Path $env:USERPROFILE '.glzr\glazewm\config.yaml'
$Themes      = Join-Path $Data 'themes'
$Walls       = Join-Path $Data 'wallpapers'
$Thumbs      = Join-Path $Pack 'thumbs'
$Generated   = Join-Path $Data 'generated'
$StateFile   = Join-Path $Data 'state.json'
$ConfigFile  = Join-Path $Data 'config.json'
$PathsFile   = Join-Path $Data 'paths.json'
$LogFile     = Join-Path $Data 'logs\winarchy.log'
$ImageExt    = '.jpg', '.jpeg', '.png', '.bmp', '.webp'
$Invariant   = [Globalization.CultureInfo]::InvariantCulture

function Log([string]$msg) {
    $line = "$(Get-Date -Format 'HH:mm:ss') [$Verb] $msg"
    # Install and update show a tidy bullet instead (lib/ui.ps1); the file keeps the full line.
    if ($script:UiPretty) { Write-UiLog $msg } else { Write-Host $line }
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

# ~ and %VARS% in user-supplied paths. ~\Pictures (Videos, Documents, Music, Desktop)
# means that folder wherever Windows keeps it: OneDrive often moves it out of the profile,
# and install makes Pictures\Wallpapers in the real one. A literal folder that exists wins.
function Expand-UserPath([string]$p) {
    if (-not $p) { return $p }
    $p = [Environment]::ExpandEnvironmentVariables($p)
    if ($p -match '^~[\\/]?') {
        $rest = $p -replace '^~[\\/]?', ''
        $p = Join-Path $env:USERPROFILE $rest
        if ($rest -match '^(Pictures|Videos|Documents|Music|Desktop)(?:[\\/](.*))?$' -and -not (Test-Path -LiteralPath $p)) {
            $sub = $Matches[2]
            $known = Get-KnownUserFolder $Matches[1]
            if ($known) { $p = if ($sub) { [IO.Path]::Combine($known, $sub) } else { $known } }
        }
    }
    $p
}

function Get-KnownUserFolder([string]$name) {
    $special = @{ Pictures = 'MyPictures'; Videos = 'MyVideos'; Documents = 'MyDocuments'; Music = 'MyMusic'; Desktop = 'DesktopDirectory' }[$name]
    if ($special) { [Environment]::GetFolderPath($special) }
}

# --- config (user settings) ------------------------------------------------------
# default/config.json holds every key with its default; ~/.winarchy/config.json only
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
# The user's config.json as a hashtable, $null when there is none. A file that does not
# parse throws, saying where: Read-Json would return $null, and the next write would
# then replace every setting in it with this one change.
function Read-UserConfig {
    if (-not (Test-Path -LiteralPath $ConfigFile)) { return $null }
    $text = Get-Content -Raw -LiteralPath $ConfigFile
    if (-not "$text".Trim()) { return $null }
    try { $text | ConvertFrom-Json -AsHashtable }
    catch { throw "$ConfigFile is not valid JSON, so it was left alone: $(($_.Exception.Message -split "`n")[0]). Fix it (a \ in a path is written \\), then run winarchy apply." }
}

function Get-Config {
    $def = Read-Json (Join-Path $Code 'default\config.json') -AsHashtable
    # Reading goes on with the defaults so the bar and keys keep working; doctor and
    # every write say what is wrong with the file.
    $user = try { Read-UserConfig } catch { Log $_.Exception.Message; Write-Warning $_.Exception.Message; $null }
    $cfg = if ($user) { Merge-Hashtable $def $user } else { $def }
    $cfg.Remove('_help')
    $cfg
}

# Write one setting into the user's config.json by dotted path ("apps.agent"), keeping
# every other key they have. winarchy.ahk re-applies config.json when it is saved, so the
# selfwrite stamp tells it this change is already being applied by whoever called this.
function Set-ConfigValue([string]$path, $value) {
    $user = Read-UserConfig
    if (-not $user) { $user = [ordered]@{} }
    $parts = @($path -split '\.')
    $node = $user
    foreach ($part in @($parts | Select-Object -SkipLast 1)) {
        if ($node[$part] -isnot [hashtable] -and $node[$part] -isnot [System.Collections.Specialized.OrderedDictionary]) { $node[$part] = @{} }
        $node = $node[$part]
    }
    $node[$parts[-1]] = $value
    Save-UserConfig $user
}

function Save-UserConfig($user) {
    Write-Json $ConfigFile $user 8
    New-Item -ItemType Directory -Force $Generated | Out-Null
    Write-Utf8 (Join-Path $Generated 'config.selfwrite') (Get-Item $ConfigFile).LastWriteTime.ToString('yyyyMMddHHmmss')
}

# Settings that changed what a new install gets. A config.json from before one of them
# keeps what that PC had: the value here is written into it, once (winarchy apply runs
# this first; update ends in an apply). A new install writes the new value instead
# ($FreshInstallValues, Get-InstallAnswers). Only a missing key is written, so a value
# you set yourself is never touched.
$ConfigMigrations = [ordered]@{
    captureKeys = 'winarchy'   # Super+Print = full screenshot, Super+Ctrl+Print = color picker
    compose     = $false       # CapsLock stays CapsLock
    hideDesktopIcons = $false  # desktop icons stay as they were
}
$FreshInstallValues = [ordered]@{
    hideDesktopIcons = $true   # a clean desktop: the wallpaper is the point
    captureKeys = 'omarchy'    # Omarchy's: Super+Print = color picker, Super+Ctrl+Print = text
    compose     = $true        # CapsLock + keys: emoji, em dash, name and email (Omarchy's xcompose)
}

function Invoke-ConfigMigration {
    # A file that does not parse is left alone: apply and doctor say what is wrong with it.
    $user = try { Read-UserConfig } catch { return }
    if (-not $user) { return }
    $added = @($ConfigMigrations.Keys | Where-Object { -not $user.Contains($_) })
    if (-not $added) { return }
    foreach ($k in $added) { $user[$k] = $ConfigMigrations[$k] }
    Save-UserConfig $user
    Log "config: $($added -join ', ') written with what this PC had so far (manual/31-dotfiles.md)"
}

# --- state (what winarchy last applied) ----------------------------------------
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
    # The effective font (the default when none was picked), so the font picker can mark it.
    $font = if (Get-Command Get-FontFamily -ErrorAction SilentlyContinue) { Get-FontFamily } else { $s.font }
    # The current defaults, so Setup > Defaults can tick the one in use. Empty when
    # nothing is picked: Omarchy chooses no agent for you and leaves the list unchecked.
    $agent = if (Get-Command Get-DefaultAgent -ErrorAction SilentlyContinue) { Get-DefaultAgent } else { $null }
    Write-Json $path ([ordered]@{
        theme = $s.theme; background = $s.background; font = $font; agent = $agent; themeVersion = $ver
    })
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
    $m = [Threading.Mutex]::new($false, 'Local\Winarchy')
    $got = $false
    try {
        try { $got = $m.WaitOne(120000) } catch [Threading.AbandonedMutexException] { $got = $true }
        if (-not $got) { throw 'another winarchy command is still running' }
        & $body
    } finally {
        if ($got) { $m.ReleaseMutex() }
        $m.Dispose()
    }
}

# --- native -----------------------------------------------------------------------
# Add-Type -MemberDefinition for [Winarchy.<name>], compiled once: the C# compiler costs
# ~250 ms per process, loading the compiled DLL ~20 ms. The DLL's name carries a hash of
# the source (and of the .NET version it was built on), so an edited definition compiles
# afresh. -TypeDefinition/-TypeName: a whole C# source whose type is named in it (audio's
# Core Audio interop), cached the same way - the bar's panels run those every few seconds.
function Add-NativeType([string]$name, [string]$members, [string]$TypeDefinition, [string]$TypeName) {
    $full = if ($TypeDefinition) { $TypeName } else { "Winarchy.$name" }
    if ($full -as [type]) { return }
    $source = if ($TypeDefinition) { "type|$TypeDefinition" } else { $members }
    $bytes = [Text.Encoding]::UTF8.GetBytes("$([Environment]::Version.Major)|$source")
    $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).Substring(0, 16)
    $dir = Join-Path $Generated 'native'
    $dll = Join-Path $dir "Winarchy.$name.$hash.dll"
    $add = {
        param([string]$out)
        $a = if ($TypeDefinition) { @{ TypeDefinition = $TypeDefinition } } else { @{ Namespace = 'Winarchy'; Name = $name; MemberDefinition = $members } }
        if ($out) { Add-Type @a -OutputAssembly $out -OutputType Library } else { Add-Type @a }
    }
    try {
        if (-not (Test-Path -LiteralPath $dll)) {
            New-Item -ItemType Directory -Force $dir | Out-Null
            $tmp = Join-Path $dir "Winarchy.$name.$hash.$PID.tmp"
            & $add $tmp
            try { Move-Item -LiteralPath $tmp $dll -ErrorAction Stop }
            catch { Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue }   # another process won
            Get-ChildItem $dir -Filter "Winarchy.$name.*.dll" | Where-Object Name -ne (Split-Path -Leaf $dll) |
                Remove-Item -ErrorAction SilentlyContinue                             # older sources
        }
        Add-Type -LiteralPath $dll
    } catch {
        if (-not ($full -as [type])) { & $add $null }
    }
}

function Initialize-Native {
    if (-not ('Winarchy.Native' -as [type])) {
        Add-NativeType Native @'
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
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string title);
[DllImport("user32.dll")]
public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
[DllImport("user32.dll")]
public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
'@
    }
}

# Tell Explorer/apps a setting changed (HWND_BROADCAST, WM_SETTINGCHANGE).
function Send-SettingChange([string]$what = 'ImmersiveColorSet') {
    Initialize-Native
    $r = [UIntPtr]::Zero
    [void][Winarchy.Native]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, $what, 2, 1000, [ref]$r)
}

# "Animate windows when minimizing and maximizing" (SPI_GETANIMATION / SPI_SETANIMATION,
# ANIMATIONINFO { cbSize, iMinAnimate }): 1 on, 0 off.
function Get-MinimizeAnimation {
    Initialize-Native
    $buf = [Runtime.InteropServices.Marshal]::AllocHGlobal(8)
    try {
        [Runtime.InteropServices.Marshal]::WriteInt32($buf, 0, 8)
        if (-not [Winarchy.Native]::SystemParametersInfoInt(0x48, 8, $buf, 0)) { throw 'SPI_GETANIMATION failed' }
        [Runtime.InteropServices.Marshal]::ReadInt32($buf, 4)
    } finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($buf) }
}

function Set-MinimizeAnimation([int]$on) {
    Initialize-Native
    $buf = [Runtime.InteropServices.Marshal]::AllocHGlobal(8)
    try {
        [Runtime.InteropServices.Marshal]::WriteInt32($buf, 0, 8)
        [Runtime.InteropServices.Marshal]::WriteInt32($buf, 4, $on)
        # SPIF_UPDATEINIFILE | SPIF_SENDCHANGE: saved in the profile, not just this session.
        if (-not [Winarchy.Native]::SystemParametersInfoInt(0x49, 8, $buf, 3)) { throw 'SPI_SETANIMATION failed' }
    } finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($buf) }
}

# winarchy.ahk's blockMinimize takes WS_MINIMIZEBOX off windows and tags each one with the
# property "winarchy.nomin"; its OnExit puts the buttons back. A force-stopped or crashed
# daemon never runs OnExit, so these find and undo the leftovers from here.
function Initialize-MinBox {
    Add-NativeType MinBox @'
public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
[DllImport("user32.dll")]
public static extern bool EnumWindows(EnumProc f, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr GetPropW(IntPtr hWnd, string name);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr RemovePropW(IntPtr hWnd, string name);
[DllImport("user32.dll")]
public static extern IntPtr GetWindowLongPtrW(IntPtr hWnd, int index);
[DllImport("user32.dll")]
public static extern IntPtr SetWindowLongPtrW(IntPtr hWnd, int index, IntPtr value);
[DllImport("user32.dll")]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern int GetClassName(IntPtr hWnd, System.Text.StringBuilder name, int max);
[DllImport("user32.dll")]
public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
[DllImport("user32.dll")]
public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll")]
public static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
[DllImport("dwmapi.dll")]
public static extern int DwmGetWindowAttribute(IntPtr hWnd, int attr, out int value, int size);
[DllImport("dwmapi.dll")]
public static extern int DwmSetWindowAttribute(IntPtr hWnd, int attr, ref int value, int size);
'@
}

function Get-MinimizeBoxStripped {
    Initialize-MinBox
    $found = [Collections.Generic.List[IntPtr]]::new()
    [void][Winarchy.MinBox]::EnumWindows({ param($h, $l)
            if ([Winarchy.MinBox]::GetPropW($h, 'winarchy.nomin') -ne [IntPtr]::Zero) { $found.Add($h) }
            $true }, [IntPtr]::Zero)
    , $found.ToArray()
}

function Restore-MinimizeBoxes {
    $windows = Get-MinimizeBoxStripped
    foreach ($h in $windows) {
        $style = [Winarchy.MinBox]::GetWindowLongPtrW($h, -16).ToInt64()                  # GWL_STYLE
        [void][Winarchy.MinBox]::SetWindowLongPtrW($h, -16, [IntPtr]($style -bor 0x20000))   # WS_MINIMIZEBOX
        # SWP_FRAMECHANGED | NOACTIVATE | NOZORDER | NOMOVE | NOSIZE: redraw the title bar.
        [void][Winarchy.MinBox]::SetWindowPos($h, [IntPtr]::Zero, 0, 0, 0, 0, 0x37)
        [void][Winarchy.MinBox]::RemovePropW($h, 'winarchy.nomin')
    }
    $windows.Count
}

# GlazeWM's window effects outlive it: on exit (even a clean wm-exit) it resets only
# transparency and turns the border off; hidden title bars (WS_DLGFRAME removed) and
# square corners stay, and a force-stop leaves its colored borders too - a resize then
# flashes the theme's accent. Undo them the way GlazeWM set them. Only resizable, unowned
# windows with a system menu that lost WS_DLGFRAME *and* have square corners count, so
# apps that draw their own title bar are left alone. Returns how many were repaired.
function Restore-WindowFrames {
    Initialize-MinBox
    $fixed = [Collections.Generic.List[IntPtr]]::new()
    [void][Winarchy.MinBox]::EnumWindows({ param($h, $l)
            if ([Winarchy.MinBox]::GetWindow($h, 4) -ne [IntPtr]::Zero) { return $true }   # GW_OWNER: GlazeWM never manages these
            $style = [Winarchy.MinBox]::GetWindowLongPtrW($h, -16).ToInt64()
            if (-not ($style -band 0x40000)) { return $true }                                 # WS_THICKFRAME
            $color = -1                                                                      # DWMWA_COLOR_DEFAULT
            [void][Winarchy.MinBox]::DwmSetWindowAttribute($h, 34, [ref]$color, 4)           # DWMWA_BORDER_COLOR
            $corner = 0
            [void][Winarchy.MinBox]::DwmGetWindowAttribute($h, 33, [ref]$corner, 4)          # DWMWA_WINDOW_CORNER_PREFERENCE
            $noTitle = ($style -band 0x800000) -and -not ($style -band 0x400000) -and ($style -band 0x80000)   # WS_BORDER, no WS_DLGFRAME, WS_SYSMENU
            if ($noTitle -and $corner -eq 1) {                                                # DWMWCP_DONOTROUND
                [void][Winarchy.MinBox]::SetWindowLongPtrW($h, -16, [IntPtr]($style -bor 0x400000))
                $corner = 0                                                                  # DWMWCP_DEFAULT
                [void][Winarchy.MinBox]::DwmSetWindowAttribute($h, 33, [ref]$corner, 4)
                # SWP_FRAMECHANGED | NOOWNERZORDER | NOACTIVATE | NOZORDER | NOMOVE | NOSIZE
                [void][Winarchy.MinBox]::SetWindowPos($h, [IntPtr]::Zero, 0, 0, 0, 0, 0x237)
                $fixed.Add($h)
            }
            $true }, [IntPtr]::Zero)
    $fixed.Count
}

# Ask AutoHotkey scripts to exit the way their tray menu's Exit does (WM_CLOSE to the
# hidden main window), so their OnExit handlers run. Process.CloseMainWindow() can't: the
# window is hidden, so .NET sees no main window. Returns how many were asked.
function Close-AhkGracefully([int[]]$processIds) {
    Initialize-MinBox
    $asked = [Collections.Generic.List[IntPtr]]::new()
    [void][Winarchy.MinBox]::EnumWindows({ param($h, $l)
            $wp = [uint32]0
            [void][Winarchy.MinBox]::GetWindowThreadProcessId($h, [ref]$wp)
            if ($processIds -contains [int]$wp) {
                $cls = [Text.StringBuilder]::new(64)
                [void][Winarchy.MinBox]::GetClassName($h, $cls, 64)
                if ($cls.ToString() -eq 'AutoHotkey') {
                    [void][Winarchy.MinBox]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero)
                    $asked.Add($h)
                }
            }
            $true }, [IntPtr]::Zero)
    $asked.Count
}

# Base64 UTF-16 for powershell -EncodedCommand: no quoting to break on the way through
# Start-Process -Verb RunAs.
function ConvertTo-EncodedCommand([string]$script) {
    [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
}

# Screenshot auto-copy (ps51\screenshot-to-clipboard.ps1), found by its script name so a
# copy started from an older path (the pre-rename junction) counts too.
function Get-ScreenshotWatcher {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like '*screenshot-to-clipboard.ps1*' }
}

function Stop-ScreenshotWatcher {
    Get-ScreenshotWatcher | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Get-KnownFolder([guid]$id) {
    Initialize-Native
    $ptr = [IntPtr]::Zero
    if ([Winarchy.Native]::SHGetKnownFolderPath($id, 0, [IntPtr]::Zero, [ref]$ptr) -ne 0) { return $null }
    try { [Runtime.InteropServices.Marshal]::PtrToStringUni($ptr) } finally { [Runtime.InteropServices.Marshal]::FreeCoTaskMem($ptr) }
}

# --- colors -----------------------------------------------------------------------
function ConvertTo-Rgb([string]$hex) {
    $h = $hex.TrimStart('#')
    @([Convert]::ToInt32($h.Substring(0, 2), 16), [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16))
}
# a*(1-t) + b*t, like Omarchy's template `mix a b t`, rounding .5 up as its awk does.
function Mix([string]$a, [string]$b, [double]$t) {
    $x = ConvertTo-Rgb $a; $y = ConvertTo-Rgb $b
    '#' + (-join (0..2 | ForEach-Object { '{0:x2}' -f [int][Math]::Round($x[$_] + ($y[$_] - $x[$_]) * $t, [MidpointRounding]::AwayFromZero) }))
}
function To-Dword([uint32]$v) { [BitConverter]::ToInt32([BitConverter]::GetBytes($v), 0) }

# Run something hidden and detached (no console flash).
function Start-Hidden([string]$file, [string[]]$arguments) {
    Start-Process -FilePath $file -ArgumentList $arguments -WindowStyle Hidden
}

# The window manager itself, never its CLI: cli\glazewm.exe has the same process name, and
# the auto-tiling watcher keeps one running for its event subscription. So a plain
# `Get-Process glazewm` says "running" even when the WM has crashed, which quietly disables
# every watchdog and liveness check. The official build's Path reads empty (it runs with UI
# access) and that is precisely the one that must count, so only a readable \cli\ path is
# excluded.
function Get-GlazeWmProcess {
    @(Get-Process glazewm -ErrorAction SilentlyContinue | Where-Object {
        $path = $null
        try { $path = $_.Path } catch {}
        $path -notlike '*\cli\*'
    })
}

# GlazeWM starts glazewm-watcher as a child, and the child inherits GlazeWM's IPC socket.
# If the WM dies and the watcher stays, the watcher keeps 127.0.0.1:6123 held. The next
# GlazeWM then fails with "Fatal error ... (os error 10048)". So stop any leftover watcher
# before starting GlazeWM, but only when no WM is running (a live WM's watcher is doing its job).
# A watcher stuck while exiting can't be killed, and only a reboot frees the port. In that
# case say so instead of starting a GlazeWM that can only fail.
function Start-GlazeWM([string]$exe) {
    if (-not $exe) { return }
    if (-not (Get-GlazeWmProcess)) {
        Get-Process glazewm-watcher -ErrorAction SilentlyContinue | ForEach-Object {
            Log "GlazeWM: stopping leftover glazewm-watcher $($_.Id) (it holds the IPC port)"
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
        $held = $null
        for ($i = 0; $i -lt 10; $i++) {
            $held = Get-NetTCPConnection -LocalPort 6123 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $held) { break }
            Start-Sleep -Milliseconds 300
        }
        if ($held) {
            $msg = "GlazeWM not started: port 6123 is still held by process $($held.OwningProcess), a GlazeWM that did not exit cleanly. Restart Windows, then run: winarchy doctor -Fix"
            Log $msg
            Write-Warning $msg
            return
        }
    }
    Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe)
}
