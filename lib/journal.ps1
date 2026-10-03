# Backup journal. Every change winarchy makes to the system first records what was
# there, in ~/.winarchy/backup/<timestamp>/journal.json, and `winarchy uninstall`
# replays it newest-first. The first recording of a target wins, so re-running install
# or apply never overwrites the real original.

$BackupRoot = Join-Path $Data 'backup'

function Get-JournalDir {
    if ($script:JournalDir) { return $script:JournalDir }
    $existing = Get-ChildItem $BackupRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'journal.json') } | Sort-Object Name | Select-Object -First 1
    $script:JournalDir = if ($existing) { $existing.FullName } else {
        $d = Join-Path $BackupRoot (Get-Date -Format 'yyyyMMdd-HHmmss')
        New-Item -ItemType Directory -Force $d | Out-Null
        Write-Json (Join-Path $d 'journal.json') ([ordered]@{ created = (Get-Date).ToString('s'); computer = $env:COMPUTERNAME; entries = @() })
        $d
    }
    $script:JournalDir
}

function Read-Journal {
    if ($script:JournalCache) { return $script:JournalCache }
    $j = Read-Json (Join-Path (Get-JournalDir) 'journal.json') -AsHashtable
    if (-not $j) { $j = @{ entries = @() } }
    if (-not $j.entries) { $j.entries = @() }
    $script:JournalKeys = [Collections.Generic.HashSet[string]]::new([string[]]@($j.entries | ForEach-Object { $_.key }))
    $script:JournalCache = $j
    $j
}

function Add-JournalEntry([hashtable]$entry) {
    $j = Read-Journal
    if ($script:JournalKeys.Contains($entry.key)) { return $false }
    $entry.at = (Get-Date).ToString('s')
    $j.entries = @($j.entries) + $entry
    [void]$script:JournalKeys.Add($entry.key)
    Write-Json (Join-Path (Get-JournalDir) 'journal.json') $j 8
    $true
}

function Test-Journaled([string]$key) { [void](Read-Journal); $script:JournalKeys.Contains($key) }

# Drop a recording because the thing it describes is gone for good (the menu's Remove
# took a package back out). Without this, uninstall would try to remove it a second time.
function Remove-JournalEntry([string]$key) {
    $j = Read-Journal
    if (-not $script:JournalKeys.Contains($key)) { return $false }
    $j.entries = @($j.entries | Where-Object { $_.key -ne $key })
    [void]$script:JournalKeys.Remove($key)
    Write-Json (Join-Path (Get-JournalDir) 'journal.json') $j 8
    $true
}

# --- recorders --------------------------------------------------------------------
function Save-Reg([string]$path, [string]$name) {
    $key = "reg|$path|$name"
    if (Test-Journaled $key) { return }
    $e = @{ kind = 'reg'; key = $key; path = $path; name = $name; existed = $false }
    $item = Get-Item $path -ErrorAction SilentlyContinue
    if ($item -and ($item.GetValueNames() -contains $name)) {
        $kind = $item.GetValueKind($name).ToString()
        $v = $item.GetValue($name, $null, 'DoNotExpandEnvironmentNames')
        $e.existed = $true; $e.type = $kind
        $e.value = switch ($kind) {
            'Binary' { [Convert]::ToBase64String([byte[]]$v) }
            'MultiString' { @($v) }
            default { $v }
        }
    }
    $e.keyExisted = [bool]$item
    [void](Add-JournalEntry $e)
}

function Save-File([string]$path) {
    $key = "file|$path"
    if (Test-Journaled $key) { return }
    $e = @{ kind = 'file'; key = $key; path = $path; existed = (Test-Path -LiteralPath $path) }
    if ($e.existed) {
        $copy = 'files\' + ([IO.Path]::GetFileName($path)) + '.' + [guid]::NewGuid().ToString('N').Substring(0, 6)
        New-Item -ItemType Directory -Force (Join-Path (Get-JournalDir) 'files') | Out-Null
        Copy-Item -LiteralPath $path (Join-Path (Get-JournalDir) $copy)
        $e.copy = $copy
    }
    [void](Add-JournalEntry $e)
}

function Save-Dir([string]$path) {
    [void](Add-JournalEntry @{ kind = 'dir'; key = "dir|$path"; path = $path; existed = (Test-Path -LiteralPath $path) })
}

# A property inside a JSON settings file, by dotted path ("profiles.defaults.colorScheme").
# $setTo, when given, is the one value winarchy puts there: uninstall then restores only
# while it still reads that, so a choice the person made afterwards is left alone.
function Save-JsonProperty([string]$path, [string]$pointer, [string]$setTo) {
    $key = "json|$path|$pointer"
    if (Test-Journaled $key) { return }
    $obj = Read-Json $path
    $existed = $false; $value = $null
    foreach ($part in $pointer -split '\.') {
        if ($null -ne $obj -and $obj.PSObject.Properties.Name -contains $part) { $obj = $obj.$part; $existed = $true }
        else { $existed = $false; $obj = $null; break }
    }
    if ($existed) { $value = $obj }
    $e = @{ kind = 'json'; key = $key; path = $path; pointer = $pointer; existed = $existed; value = $value }
    if ($setTo) { $e.setTo = $setTo }
    [void](Add-JournalEntry $e)
}

# A string key in a JSONC file (VS Code settings: comments must survive).
function Save-JsoncProperty([string]$path, [string]$key) {
    $jkey = "jsonc|$path|$key"
    if (Test-Journaled $jkey) { return }
    $v = Get-JsoncString $path $key
    [void](Add-JournalEntry @{ kind = 'jsonc'; key = $jkey; path = $path; name = $key; existed = ($null -ne $v); value = $v })
}

# An item we add to a JSON array (WT scheme/theme/profile named "Omarchy..."): removed on uninstall.
function Save-JsonItem([string]$path, [string]$array, [string]$name) {
    [void](Add-JournalEntry @{ kind = 'jsonItem'; key = "jsonItem|$path|$array|$name"; path = $path; array = $array; name = $name })
}

function Save-Wallpaper {
    if (Test-Journaled 'wallpaper') { return }
    $d = Get-ItemProperty 'HKCU:\Control Panel\Desktop'
    [void](Add-JournalEntry @{ kind = 'wallpaper'; key = 'wallpaper'; path = $d.WallPaper; style = $d.WallpaperStyle; tile = $d.TileWallpaper })
}

function Save-LockScreen {
    if (Test-Journaled 'lockscreen') { return }
    $img = Get-LockScreenImage
    if ($img -and -not (Test-Path -LiteralPath $img)) { $img = $null }

    if (-not $img) {
        $creative = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen\Creative' -ErrorAction SilentlyContinue).LandscapeAssetPath
        if ($creative -and (Test-Path -LiteralPath $creative)) { $img = $creative }
    }
    if (-not $img) {
        $csp = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP' -ErrorAction SilentlyContinue).LockScreenImagePath
        if ($csp -and (Test-Path -LiteralPath $csp)) { $img = $csp }
    }
    # Still one of ours (an earlier uninstall that couldn't put it back): that is no
    # original to return to, so the uninstall goes to Windows' default instead.
    if (Test-WinarchyImage $img) { $img = $null }
    [void](Add-JournalEntry @{ kind = 'lockscreen'; key = 'lockscreen'; path = $img })
}

# The picture the lock screen shows, as the file it was set from (WinRT, so Windows
# PowerShell 5.1); $null when Windows won't say.
function Get-LockScreenImage {
    try {
        $ps = (Get-Paths).powershell ?? 'powershell.exe'
        $res = & $ps -NoProfile -ExecutionPolicy Bypass -Command @'
            try {
                [void][Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime]
                $uri = [Windows.System.UserProfile.LockScreen]::OriginalImageFile
                if ($uri -and $uri.LocalPath) { $uri.LocalPath }
            } catch {}
'@
        if ($res) { return "$res".Trim() }
    } catch {}
    $null
}

# A picture winarchy put there: its backgrounds, its code and data folders, and the older
# omarchy-win ones (or a backup copy of them).
function Test-WinarchyImage([string]$Path) {
    if (-not $Path) { return $false }
    foreach ($root in $Data, $Code) {
        if ($root -and $Path.StartsWith($root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    $Path -match '(?i)[\\/]\.?(winarchy|omarchy)[^\\/]*[\\/]'
}

# Windows' own lock screen picture: img100.jpg, or whichever one this Windows ships.
function Get-DefaultLockScreenImage {
    $dir = Join-Path $env:SystemRoot 'Web\Screen'
    $def = Join-Path $dir 'img100.jpg'
    if (Test-Path -LiteralPath $def) { return $def }
    Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
        Where-Object Extension -in '.jpg', '.jpeg', '.png' | Sort-Object Name | Select-Object -First 1 -ExpandProperty FullName
}

# Sets the lock screen now (ps51\lockscreen.ps1), throwing when Windows refused. A background
# picked just before is still on its way (lockscreen.ps1 -StateFile, detached): it goes
# first, or it would land after this and put winarchy's picture back.
function Set-LockScreenImage([string]$Path) {
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like '*lockscreen.ps1*-StateFile*' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    $script = Join-Path $Code 'ps51\lockscreen.ps1'
    if (-not (Test-Path -LiteralPath $script)) { throw "$script is missing" }
    $ps = (Get-Paths).powershell ?? 'powershell.exe'
    $global:LASTEXITCODE = 0
    & $ps -NoProfile -ExecutionPolicy Bypass -File $script -Path $Path
    if ($LASTEXITCODE) { throw "Windows did not take $Path as the lock screen (the log says why)" }
}

# The lock screen as it was before winarchy, or Windows' default when that picture is gone
# or was winarchy's own: never one of winarchy's backgrounds.
function Restore-LockScreen([string]$Original) {
    $target = if ($Original -and -not (Test-WinarchyImage $Original) -and (Test-Path -LiteralPath $Original)) { $Original } else { Get-DefaultLockScreenImage }
    if (-not $target) { throw 'no Windows lock screen picture found; pick one in Settings > Personalization > Lock screen' }
    Set-LockScreenImage $target
}

# $source 'menu' = the person picked it from the menu's Install section (theirs to keep
# or remove at uninstall), as opposed to something winarchy itself needs.
function Save-Winget([string]$id, [bool]$preinstalled, [string]$source) {
    $e = @{ kind = 'winget'; key = "winget|$id"; id = $id; preinstalled = $preinstalled }
    if ($source) { $e.source = $source }
    [void](Add-JournalEntry $e)
}

function Save-Note([string]$key, [string]$text) {
    [void](Add-JournalEntry @{ kind = 'note'; key = "note|$key"; text = $text })
}

# --- this PC's pre-journal backup (values.json / phase2.json / phase3.json) ---------
function Import-LegacyBackup([string]$dir) {
    $script:JournalDir = $dir
    $script:JournalCache = $null
    if (-not (Test-Path (Join-Path $dir 'journal.json'))) {
        Write-Json (Join-Path $dir 'journal.json') ([ordered]@{ created = (Get-Date).ToString('s'); computer = $env:COMPUTERNAME; importedFrom = 'values.json, phase2.json, phase3.json'; entries = @() })
    }
    $v = Read-Json (Join-Path $dir 'values.json')
    $m = Read-Json (Join-Path $dir 'manifest.json')
    if ($v) {
        [void](Add-JournalEntry @{ kind = 'taskbar'; key = 'taskbar'; autoHide = [bool]$v.taskbarAutoHide; stuckRects3 = $v.stuckRects3Settings })
        [void](Add-JournalEntry @{ kind = 'runkeys'; key = 'runkeys'; names = @($v.runKey.PSObject.Properties.Name) })
        Save-Note 'desktops' "You had $($v.virtualDesktopCount) virtual desktops before; recreate extras with Ctrl+Win+D if you want them."
    }
    if ($m) {
        Save-Winget 'glzr-io.glazewm' ([bool]$m.preinstalled.glazewm)
        Save-Winget 'Flow-Launcher.Flow-Launcher' ([bool]$m.preinstalled.flow)
        [void](Add-JournalEntry @{ kind = 'dir'; key = "dir|$env:USERPROFILE\.glzr"; path = "$env:USERPROFILE\.glzr"; existed = [bool]$m.preinstalled.glzrDirExisted })
    }
    $startup = [Environment]::GetFolderPath('Startup')
    [void](Add-JournalEntry @{ kind = 'file'; key = "file|$startup\omarchy-wm.lnk"; path = "$startup\omarchy-wm.lnk"; existed = $false })

    $p2 = Read-Json (Join-Path $dir 'phase2.json')
    if ($p2) {
        [void](Add-JournalEntry @{ kind = 'wallpaper'; key = 'wallpaper'; path = $p2.wallpaper.path; style = $p2.wallpaper.style; tile = $p2.wallpaper.tile })
        [void](Add-JournalEntry @{ kind = 'lockscreen'; key = 'lockscreen'; path = $p2.lockScreenImage })
        foreach ($p in $p2.registry.PSObject.Properties) {
            $path, $name = $p.Name -split '\|', 2
            $e = @{ kind = 'reg'; key = "reg|$path|$name"; path = $path; name = $name; existed = $null -ne $p.Value; keyExisted = $true }
            if ($p.Value) {
                $e.type = switch ($p.Value.type) { 'binary' { 'Binary' } 'dword' { 'DWord' } default { 'String' } }
                $e.value = if ($p.Value.type -eq 'dword') { [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]$p.Value.value), 0) } else { $p.Value.value }
            }
            [void](Add-JournalEntry $e)
        }
        [void](Add-JournalEntry @{ kind = 'file'; key = "file|$($p2.flowSettings)"; path = $p2.flowSettings; existed = $true; copy = 'FlowLauncher-Settings.json' })
        [void](Add-JournalEntry @{ kind = 'file'; key = "file|$env:APPDATA\FlowLauncher\Themes\Omarchy.xaml"; path = "$env:APPDATA\FlowLauncher\Themes\Omarchy.xaml"; existed = $false })
        [void](Add-JournalEntry @{ kind = 'file'; key = "file|$($p2.nvimTheme)"; path = $p2.nvimTheme; existed = $true; copy = 'nvim-theme.lua' })
        $name = "$env:USERPROFILE\.local\state\omarchy\current\theme.name"
        [void](Add-JournalEntry @{ kind = 'file'; key = "file|$name"; path = $name; existed = $false })
        $wt = $p2.wt.path
        foreach ($k in 'colorScheme', 'padding') {
            $had = $p2.wt."hadDefaults$($k.Substring(0,1).ToUpper())$($k.Substring(1))"
            [void](Add-JournalEntry @{ kind = 'json'; key = "json|$wt|profiles.defaults.$k"; path = $wt; pointer = "profiles.defaults.$k"; existed = [bool]$had; value = $p2.wt.$k })
        }
        [void](Add-JournalEntry @{ kind = 'json'; key = "json|$wt|theme"; path = $wt; pointer = 'theme'; existed = [bool]$p2.wt.hadTheme; value = $p2.wt.theme })
        Save-JsonItem $wt 'schemes' 'Omarchy'
        Save-JsonItem $wt 'themes' 'Omarchy'
    }
}

# --- restore ----------------------------------------------------------------------
# Run values of the apps winarchy installs, the only ones uninstall takes out of Run.
$WinarchyRunPattern = '(?i)\\(glazewm|zebar|Flow\.Launcher|AutoHotkey\w*)\.exe|winarchy'

# The Flow Launcher settings Set-FlowTheme writes; the rest of the file is Flow's own.
$FlowOwnedKeys = 'Theme', 'UseSound', 'BackdropType', 'ColorScheme', 'QueryBoxFont', 'ResultFont', 'ResultSubFont'

# Files winarchy only writes a part of. Copying the install-day file back would lose
# every change made to them since, so uninstall takes out just winarchy's part.
# Returns $false for a file winarchy owns whole, which the journal copy restores.
function Restore-PartOwnedFile($e, [string]$dir) {
    $path = $e.path
    $leaf = Split-Path $path -Leaf
    # Gone since: nothing of ours left in it to take out.
    if (-not (Test-Path -LiteralPath $path)) {
        return $leaf -in 'profile.ps1', 'Microsoft.PowerShell_profile.ps1', 'btop.conf' -or $path -like '*\.vscode\extensions\extensions.json'
    }
    if ($leaf -in 'profile.ps1', 'Microsoft.PowerShell_profile.ps1') {
        Remove-HerdrProfile $path
        if (Get-Command Remove-AccountProfile -ErrorAction SilentlyContinue) { Remove-AccountProfile $path }
        if (Get-Command Remove-ShellProfile -ErrorAction SilentlyContinue) { Remove-ShellProfile $path }
    } elseif ($path -like '*\.vscode\extensions\extensions.json') {
        Write-Json $path @(@(Read-Json $path) | Where-Object { $_ -and $_.identifier.id -ne 'local.omarchy-theme' }) 12
    } elseif ($path -like '*\FlowLauncher\Settings\Settings.json' -and $e.existed -and $e.copy) {
        $was = Read-Json (Join-Path $dir $e.copy)
        $s = Read-Json $path
        if (-not $s -or -not $was) { return $false }
        foreach ($k in $FlowOwnedKeys) {
            if ($was.PSObject.Properties.Name -contains $k) { $s | Add-Member -Force -NotePropertyName $k -NotePropertyValue $was.$k }
            else { $s.PSObject.Properties.Remove($k) }
        }
        Write-Json $path $s
    } elseif ($leaf -eq 'btop.conf' -and $e.existed -and $e.copy) {
        $was = Get-Content -Raw (Join-Path $dir $e.copy)
        $t = Get-Content -Raw -LiteralPath $path
        foreach ($k in 'color_theme', 'theme_background') {
            if ($was -match "(?m)^$k\s*=.*$") { $line = $Matches[0]; $t = [regex]::new("(?m)^$k\s*=.*$").Replace($t, $line.Replace('$', '$$'), 1) }
        }
        Write-Utf8 $path $t
    } else { return $false }
    # A file that only ever held winarchy's part goes, as it would have with the copy.
    if (-not $e.existed -and -not (Get-Content -Raw -LiteralPath $path).Trim().Trim('[]').Trim()) { Remove-Item -LiteralPath $path -Force }
    $true
}

function Set-JsonPointer($obj, [string]$pointer, $value, [bool]$remove) {
    $parts = $pointer -split '\.'
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        if ($null -eq $obj.($parts[$i])) { if ($remove) { return } ; $obj | Add-Member -Force -NotePropertyName $parts[$i] -NotePropertyValue ([pscustomobject]@{}) }
        $obj = $obj.($parts[$i])
    }
    $last = $parts[-1]
    if ($remove) { $obj.PSObject.Properties.Remove($last) }
    else { $obj | Add-Member -Force -NotePropertyName $last -NotePropertyValue $value }
}

function Restore-JournalEntry($e, [string]$dir) {
    switch ($e.kind) {
        'reg' {
            if ($e.existed) {
                if (-not (Test-Path $e.path)) { New-Item -Force $e.path | Out-Null }
                $val = if ($e.type -eq 'Binary') { [Convert]::FromBase64String($e.value) } else { $e.value }
                Set-ItemProperty $e.path -Name $e.name -Type $e.type -Value $val
            } else {
                Remove-ItemProperty $e.path -Name $e.name -ErrorAction SilentlyContinue
                if (-not $e.keyExisted -and (Test-Path $e.path) -and -not (Get-Item $e.path).GetValueNames() -and -not (Get-ChildItem $e.path)) {
                    Remove-Item $e.path -ErrorAction SilentlyContinue
                }
            }
        }
        'file' {
            if (Restore-PartOwnedFile $e $dir) { return }
            if ($e.existed -and $e.copy) { Copy-Item -Force (Join-Path $dir $e.copy) $e.path }
            elseif (-not $e.existed) { Remove-Item -LiteralPath $e.path -Force -ErrorAction SilentlyContinue }
        }
        'dir' {
            if (-not $e.existed -and (Test-Path -LiteralPath $e.path)) {
                Move-Item -LiteralPath $e.path (Join-Path $dir ((Split-Path $e.path -Leaf).TrimStart('.') + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
            }
        }
        'json' {
            $obj = Read-Json $e.path
            if (-not $obj) { return }
            if ($e.setTo) {
                $now = $obj
                foreach ($part in $e.pointer -split '\.') { $now = if ($null -ne $now) { $now.$part } }
                if ($now -ne $e.setTo) { return }
            }
            Set-JsonPointer $obj $e.pointer $e.value (-not $e.existed); Write-Json $e.path $obj
        }
        'jsonc' {
            if ($e.existed) { Set-JsoncString $e.path $e.name $e.value }
            elseif (Test-Path $e.path) {
                $t = Get-Content -Raw $e.path
                $new = [regex]::Replace($t, '(?m)^\s*"' + [regex]::Escape($e.name) + '"\s*:\s*"(?:[^"\\]|\\.)*"\s*,?\s*\r?\n', '', 1)
                if ($new -ne $t) { Write-Utf8 $e.path $new }
            }
        }
        'jsonItem' {
            $obj = Read-Json $e.path
            if ($obj) {
                $parts = $e.array -split '\.'
                $parent = $obj
                for ($i = 0; $i -lt $parts.Count - 1; $i++) { $parent = $parent.($parts[$i]) }
                $arr = $parent.($parts[-1])
                if ($null -ne $arr) {
                    $parent.($parts[-1]) = @(@($arr) | Where-Object { $_ -and $_.name -ne $e.name })
                    Write-Json $e.path $obj
                }
            }
        }
        'wallpaper' {
            Initialize-Native
            Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value $e.style
            Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value $e.tile
            $wp = if ($e.path -and (Test-Path -LiteralPath $e.path)) {
                $e.path
            } elseif (Test-Path "$env:SystemRoot\Web\Wallpaper\Windows\img0.jpg") {
                "$env:SystemRoot\Web\Wallpaper\Windows\img0.jpg"
            } else {
                $e.path
            }
            [void][Winarchy.Native]::SystemParametersInfo(0x14, 0, $wp, 3)
        }
        'lockscreen' { Restore-LockScreen $e.path }
        'taskbar' { Restore-Taskbar $e }
        'runkeys' {
            # Only what the apps winarchy set up added at login: anything else installed
            # since then is yours. (The GlazeWM value winarchy writes is its own reg entry.)
            $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
            (Get-ItemProperty $runKey).PSObject.Properties |
                Where-Object { $_.Name -notlike 'PS*' -and $e.names -notcontains $_.Name -and "$($_.Value)" -match $WinarchyRunPattern } |
                ForEach-Object { Write-Host "  removing Run\$($_.Name)"; Remove-ItemProperty $runKey -Name $_.Name }
        }
        'envpath' {
            [void](Edit-UserPath $e.dir -Remove)
        }
        # Herdr came from its own installer, not winget, so uninstalling it is our job.
        # The envpath entry recorded beside this one takes its PATH entry back out.
        'herdr' { Remove-HerdrFiles $e.bin $e.packages }
        # A web app's Start menu shortcut and icon (lib/webapps.ps1).
        'webapp' { Remove-WebAppFiles $e }
        # One of Omarchy's own apps, built for Windows (lib/ports.ps1).
        'port' { Remove-PortFiles $e }
        'browsertask' { Disable-BrowserPolicy }
        'gametask' { Disable-GameHelper }
        'defender' {
            $list = (@($e.paths) | ForEach-Object { "'$_'" }) -join ','
            Start-Process (Get-Paths).powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $(ConvertTo-EncodedCommand "Remove-MpPreference -ExclusionPath $list")"
        }
        'cargo' { if (Get-Command cargo -ErrorAction SilentlyContinue) { cargo uninstall $e.crate 2>&1 | Out-Host } }
        'file-if-ours' { if (Test-Path -LiteralPath $e.path) { Remove-Item -LiteralPath $e.path -Force -ErrorAction SilentlyContinue } }
        'screensaver' {
            Initialize-Native
            [void][Winarchy.Native]::SystemParametersInfoInt(0x11, [uint32]($e.active -eq '1'), [IntPtr]::Zero, 3)   # SPI_SETSCREENSAVEACTIVE
        }
        'minanimate' { Set-MinimizeAnimation ([int]$e.value) }
        'deskicons' {
            Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideIcons -Value ([int]$e.hidden) -Type DWord
            Set-DesktopIconsVisible ([int]$e.hidden -eq 0)
        }
        default { }
    }
}

function Restore-Taskbar($e) {
    Add-Type -Namespace OmarchyRevert -Name AppBar -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)]
public struct APPBARDATA { public int cbSize; public IntPtr hWnd; public uint uCallbackMessage; public uint uEdge; public RECT rc; public IntPtr lParam; }
[StructLayout(LayoutKind.Sequential)]
public struct RECT { public int left, top, right, bottom; }
[DllImport("shell32.dll")] public static extern IntPtr SHAppBarMessage(uint dwMessage, ref APPBARDATA pData);
[DllImport("user32.dll")] public static extern IntPtr FindWindow(string cls, string name);
'@ -ErrorAction SilentlyContinue
    $d = New-Object OmarchyRevert.AppBar+APPBARDATA
    $d.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($d)
    $d.hWnd = [OmarchyRevert.AppBar]::FindWindow('Shell_TrayWnd', $null)
    $d.lParam = [IntPtr]$(if ($e.autoHide) { 1 } else { 2 })    # ABS_AUTOHIDE=1, ABS_ALWAYSONTOP=2
    [void][OmarchyRevert.AppBar]::SHAppBarMessage(10, [ref]$d)  # ABM_SETSTATE
    # The live call alone is not reliable on Win11: persist to the registry
    # (main + per-monitor taskbars); Explorer is restarted at the end of uninstall.
    $orig = [Convert]::FromBase64String($e.stuckRects3)
    Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3' -Name Settings -Value $orig
    $mm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MMStuckRects3'
    if (Test-Path $mm) {
        foreach ($n in (Get-Item $mm).Property) {
            $v = (Get-ItemProperty $mm).$n; $v[8] = $orig[8]; Set-ItemProperty $mm -Name $n -Value $v
        }
    }
    $script:RestartExplorer = $true
}
