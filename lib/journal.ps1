# Backup journal. Every change omarchy-win makes to the system first records what was
# there, in ~/.omarchy-win/backup/<timestamp>/journal.json, and `omarchy-win uninstall`
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
function Save-JsonProperty([string]$path, [string]$pointer) {
    $key = "json|$path|$pointer"
    if (Test-Journaled $key) { return }
    $obj = Read-Json $path
    $existed = $false; $value = $null
    foreach ($part in $pointer -split '\.') {
        if ($null -ne $obj -and $obj.PSObject.Properties.Name -contains $part) { $obj = $obj.$part; $existed = $true }
        else { $existed = $false; $obj = $null; break }
    }
    if ($existed) { $value = $obj }
    [void](Add-JournalEntry @{ kind = 'json'; key = $key; path = $path; pointer = $pointer; existed = $existed; value = $value })
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
    $img = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen\Creative' -ErrorAction SilentlyContinue).LandscapeAssetPath
    [void](Add-JournalEntry @{ kind = 'lockscreen'; key = 'lockscreen'; path = $img })
}

function Save-Winget([string]$id, [bool]$preinstalled) {
    [void](Add-JournalEntry @{ kind = 'winget'; key = "winget|$id"; id = $id; preinstalled = $preinstalled })
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
            if ($obj) { Set-JsonPointer $obj $e.pointer $e.value (-not $e.existed); Write-Json $e.path $obj }
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
            [void][OmarchyWin.Native]::SystemParametersInfo(0x14, 0, $e.path, 3)
        }
        'lockscreen' {
            if ($e.path -and (Test-Path -LiteralPath $e.path)) {
                & (Get-Paths).powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Code 'ps51\lockscreen.ps1') -Path $e.path
            } else { Write-Warning "  lock screen image $($e.path) is gone; set one in Settings > Personalization > Lock screen" }
        }
        'taskbar' { Restore-Taskbar $e }
        'runkeys' {
            $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
            (Get-ItemProperty $runKey).PSObject.Properties |
                Where-Object { $_.Name -notlike 'PS*' -and $e.names -notcontains $_.Name } |
                ForEach-Object { Write-Host "  removing Run\$($_.Name)"; Remove-ItemProperty $runKey -Name $_.Name }
        }
        'envpath' {
            $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
            $new = ($cur -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ne $e.dir.TrimEnd('\') }) -join ';'
            [Environment]::SetEnvironmentVariable('Path', $new, 'User')
        }
        'screensaver' {
            Initialize-Native
            [void][OmarchyWin.Native]::SystemParametersInfoInt(0x11, [uint32]($e.active -eq '1'), [IntPtr]::Zero, 3)   # SPI_SETSCREENSAVEACTIVE
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
