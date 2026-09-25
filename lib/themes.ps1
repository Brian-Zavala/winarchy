# Omarchy themes + backgrounds: sync, background, theme-set.
# Mirrors Omarchy's bin/omarchy-theme-set, omarchy-theme-bg-set and omarchy-theme-bg-next.

# --- sync -------------------------------------------------------------------------
function New-Thumb([string]$src, [string]$dst, [int]$Width = 480) {
    Add-Type -AssemblyName PresentationCore, WindowsBase
    $bi = [System.Windows.Media.Imaging.BitmapImage]::new()
    $bi.BeginInit()
    $bi.UriSource = [Uri]::new($src)
    $bi.DecodePixelWidth = $Width
    $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bi.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile
    $bi.EndInit()
    $enc = [System.Windows.Media.Imaging.JpegBitmapEncoder]::new()
    $enc.QualityLevel = 82
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bi))
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    $fs = [IO.File]::Create($dst)
    try { $enc.Save($fs) } finally { $fs.Close() }
}

function Update-Thumb([string]$src, [string]$dst, [int]$Width = 480) {
    if ((Test-Path $dst) -and (Get-Item $dst).LastWriteTime -ge (Get-Item $src).LastWriteTime) { return $true }
    try { New-Thumb $src $dst -Width $Width; $true } catch { Log "thumbnail failed for ${src}: $($_.Exception.Message)"; $false }
}

function Get-BackgroundDirs {
    $cfg = Get-Config
    @($cfg.backgroundDirs | ForEach-Object { Expand-UserPath $_ } | Where-Object { $_ -and (Test-Path $_) })
}

# Which files of the Omarchy repo we mirror, and where they go.
function Get-SyncTarget([string]$path) {
    if ($path -match '^themes/([^/]+)/backgrounds/([^/]+)$') { return Join-Path $Walls "$($Matches[1])\$($Matches[2])" }
    if ($path -match '^themes/([^/]+)/(colors\.toml|neovim\.lua|preview\.png|vscode\.json|btop\.theme|chromium\.theme)$') { return Join-Path $Themes "$($Matches[1])\$($Matches[2])" }
    if ($path -match '^default/themed/(neovim\.lua|btop\.theme|vscode-theme\.json|claude\.json|chromium\.theme)\.tpl$') { return Join-Path $Themes "_templates\$($Matches[1]).tpl" }
    if ($path -eq 'default/fonts/omarchy/omarchy.ttf') { return Join-Path $Themes '_templates\omarchy.ttf' }
    if ($path -match '^(logo|icon)\.txt$') { return Join-Path $Themes "_templates\$path" }
    if ($path -eq 'etc/fastfetch/config.jsonc') { return Join-Path $Themes '_templates\fastfetch.jsonc' }
    $null
}

function Invoke-Sync([switch]$Offline) {
    $cfg = Get-Config
    $repo = $cfg.omarchyRepo; $tag = (Read-State).omarchyTag ?? $cfg.omarchyTag
    New-Item -ItemType Directory -Force $Themes, $Walls, $Thumbs | Out-Null
    if (-not $Offline) {
        try {
            Log "fetching $repo@$tag file list"
            $tree = Invoke-RestMethod "https://api.github.com/repos/$repo/git/trees/${tag}?recursive=1" -TimeoutSec 30
            $want = @($tree.tree | Where-Object { $_.type -eq 'blob' } | ForEach-Object {
                $dest = Get-SyncTarget $_.path
                if ($dest) { @{ path = $_.path; size = $_.size; dest = $dest } }
            })
            $todo = @($want | Where-Object { -not ((Test-Path $_.dest) -and (Get-Item $_.dest).Length -eq $_.size) })
            $total = ($todo | Measure-Object size -Sum).Sum
            if ($todo) { Log ("downloading {0} file(s), {1:N0} MB" -f $todo.Count, ($total / 1MB)) }
            $n = 0; $i = 0
            foreach ($f in $todo) {
                $i++
                Write-Progress -Activity 'Omarchy themes and backgrounds' -Status $f.path -PercentComplete (100 * $i / $todo.Count)
                New-Item -ItemType Directory -Force (Split-Path $f.dest) | Out-Null
                $url = "https://raw.githubusercontent.com/$repo/$tag/$($f.path)"
                try {
                    Invoke-WebRequest $url -OutFile "$($f.dest).part" -TimeoutSec 120
                    Move-Item -Force "$($f.dest).part" $f.dest
                    $n++
                } catch { Log "download failed: $url ($($_.Exception.Message))"; Remove-Item "$($f.dest).part" -ErrorAction SilentlyContinue }
            }
            Write-Progress -Activity 'Omarchy themes and backgrounds' -Completed
            Log "downloaded $n new file(s)"
        } catch { Log "offline or GitHub unavailable, using local files ($($_.Exception.Message))" }
    }
    Update-Index
}

# index.json feeds the theme and background pickers. Each theme carries its bar palette,
# so the theme picker can morph into a theme before it is applied.
function Update-Index {
    New-Item -ItemType Directory -Force $Thumbs | Out-Null
    # Theme previews are the picker's big cover-flow cards, so they are twice the width of the
    # wallpaper thumbs. The width is in the folder name: Update-Thumb only compares timestamps.
    Remove-Item (Join-Path $Thumbs '_themes') -Recurse -Force -ErrorAction SilentlyContinue
    $themeList = foreach ($dir in Get-ChildItem $Themes -Directory | Where-Object Name -NotLike '_*' | Sort-Object Name) {
        if (-not (Test-Path (Join-Path $dir.FullName 'colors.toml'))) { continue }
        $c = Read-Colors $dir.Name
        $preview = Join-Path $dir.FullName 'preview.png'
        $thumb = $null
        if ((Test-Path $preview) -and (Update-Thumb $preview (Join-Path $Thumbs "_themes-960\$($dir.Name).jpg") -Width 960)) {
            $thumb = "thumbs/_themes-960/$($dir.Name).jpg"
        }
        [ordered]@{
            name = $dir.Name; label = Get-ThemeLabel $dir.Name; mode = $c.mode; thumb = $thumb
            palette = Get-BarPalette $c
        }
    }

    $groups = [Collections.Generic.List[object]]::new()
    if (Test-Path $Walls) {
        foreach ($dir in Get-ChildItem $Walls -Directory | Sort-Object Name) {
            $items = foreach ($f in Get-ChildItem $dir.FullName -File | Where-Object { $ImageExt -contains $_.Extension.ToLower() } | Sort-Object Name) {
                $rel = "thumbs/$($dir.Name)/$($f.BaseName).jpg"
                if (Update-Thumb $f.FullName (Join-Path $Pack $rel)) {
                    [ordered]@{ label = Get-Label $f.Name; path = $f.FullName; thumb = $rel }
                }
            }
            if ($items) { $groups.Add([ordered]@{ id = $dir.Name; label = Get-ThemeLabel $dir.Name; items = @($items) }) }
        }
    }
    $mine = foreach ($d in Get-BackgroundDirs) {
        foreach ($f in Get-ChildItem $d -File | Where-Object { $ImageExt -contains $_.Extension.ToLower() } | Sort-Object Name) {
            $key = ($f.BaseName -replace '[^\w\-]', '_')
            $rel = "thumbs/_mine/$key.jpg"
            if (Update-Thumb $f.FullName (Join-Path $Pack $rel)) {
                [ordered]@{ label = Get-Label $f.Name; path = $f.FullName; thumb = $rel }
            }
        }
    }
    if ($mine) { $groups.Add([ordered]@{ id = 'mine'; label = 'Mine'; items = @($mine) }) }

    $index = [ordered]@{ generated = (Get-Date).ToString('s'); themes = @($themeList); groups = @($groups) }
    Write-Utf8 (Join-Path $Pack 'index.json') ($index | ConvertTo-Json -Depth 6 -Compress)
    Write-Status (Read-State)
    Log "index: $(@($themeList).Count) themes, $(($groups | ForEach-Object { $_.items.Count } | Measure-Object -Sum).Sum) backgrounds in $($groups.Count) groups"
}

# --- backgrounds ------------------------------------------------------------------
# $covered: a point on the monitor the background picker covers (it reveals that one itself).
function Set-DesktopWallpaper([string]$path, [int[]]$covered) {
    Initialize-Native
    Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10'   # Fill
    Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'
    # SPI_SETDESKWALLPAPER, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE, under Omarchy's reveal
    # animation (lib/transition.ps1) when it can play.
    $set = { if (-not [Winarchy.Native]::SystemParametersInfo(0x14, 0, $path, 3)) { throw "SystemParametersInfo failed for $path" } }.GetNewClosure()
    if (Get-Command Invoke-BackgroundReveal -ErrorAction SilentlyContinue) { Invoke-BackgroundReveal $path $set $covered } else { & $set }
}

function Set-Background([string]$path, $state, [int[]]$covered) {
    $path = (Resolve-Path -LiteralPath $path).Path
    Save-Wallpaper; Save-LockScreen
    Set-DesktopWallpaper $path $covered
    # Status last: the background picker holds the new wallpaper over its monitor until
    # status.json names it, then fades to a desktop that already shows it.
    $state.background = $path
    $state.perTheme[$state.theme] = $path
    Save-State $state
    Write-Status $state
    # Lock screen follows (WinRT API needs Windows PowerShell 5.1); detached so the picker
    # feels instant. lockscreen.ps1 skips itself if a newer pick has landed meanwhile.
    $p = Get-Paths
    Start-Hidden $p.powershell @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$Code\ps51\lockscreen.ps1`"", '-Path', "`"$path`"", '-StateFile', "`"$StateFile`"")
    Log "background -> $path"
}

function Get-ThemeBackgrounds([string]$theme) {
    $dir = Join-Path $Walls $theme
    if (-not (Test-Path $dir)) { return @() }
    @(Get-ChildItem $dir -File | Where-Object { $ImageExt -contains $_.Extension.ToLower() } | Sort-Object Name | ForEach-Object FullName)
}

function Invoke-BackgroundNext {
    $s = Read-State
    $list = @(Get-ThemeBackgrounds $s.theme)
    if (-not $list) { Log "No background was found for theme $($s.theme)"; return }
    $i = [array]::IndexOf($list, $s.background)
    Set-Background $list[($i + 1) % $list.Count] $s
}

# --- theme targets ----------------------------------------------------------------
# The bar + menu CSS variables (theme.css, and index.json for the theme picker's preview):
# css name -> colors.toml key.
function Get-BarPalette($c) {
    $vars = [ordered]@{
        'bg' = 'background'; 'bg-dark' = 'dark_background'; 'bg-darker' = 'darker_background'; 'bg-light' = 'lighter_background'
        'fg' = 'foreground'; 'fg-dim' = 'dark_foreground'; 'fg-light' = 'light_foreground'; 'fg-bright' = 'bright_foreground'
        'accent' = 'accent'; 'alert' = 'red'; 'muted' = 'muted'; 'selection' = 'selection'
        'red' = 'red'; 'green' = 'green'; 'yellow' = 'yellow'; 'blue' = 'blue'; 'magenta' = 'magenta'; 'cyan' = 'cyan'; 'orange' = 'orange'
    }
    $palette = [ordered]@{}
    foreach ($k in $vars.Keys) { $palette[$k] = $c[$vars[$k]] }
    $palette
}

function Set-BarTheme($c) {
    $palette = Get-BarPalette $c
    $lines = foreach ($k in $palette.Keys) { "  --${k}: $($palette[$k]);" }
    Write-Utf8 (Join-Path $Pack 'theme.css') ("/* Generated by winarchy theme-set. */`n:root {`n  color-scheme: $($c.mode);`n$($lines -join "`n")`n}`n")
}

function Set-GlazeTheme($c) {
    if (-not (Test-Path $GlazeConfig)) { return 'skipped' }
    $yaml = Get-Content -Raw $GlazeConfig
    $new = [regex]::Replace($yaml, "(?m)^(\s*color:\s*)'#[0-9A-Fa-f]{6}'(\s*# theme:focused-border)", "`${1}'$($c.accent)'`${2}")
    if ($new -ne $yaml) {
        Write-Utf8 $GlazeConfig $new
        $cli = (Get-Paths).glazewmCli
        if ($cli) { & $cli command wm-reload-config | Out-Null }
    }
}

function Get-FontFamily {
    $s = Read-State
    if ($s.font) { $s.font } else { 'JetBrainsMono Nerd Font' }
}

function Set-FlowTheme($c) {
    $p = Get-Paths
    if (-not $p.flow -or -not (Test-Path $p.flowSettings)) { return 'skipped' }
    $tpl = Get-Content -Raw (Join-Path $Code 'templates\flow-theme.xaml.tpl')
    $c2 = $c.Clone()
    $c2.selected_row = Mix $c.background $c.foreground 0.08
    $c2.font = Get-FontFamily
    $xaml = Expand-Template $tpl $c2
    New-Item -ItemType Directory -Force $p.flowThemes | Out-Null
    Save-File $p.flowSettings; Save-File (Join-Path $p.flowThemes 'Omarchy.xaml')
    # Kill (not close) so Flow can't write its in-memory settings over ours on exit.
    Get-Process Flow.Launcher -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 400
    Write-Utf8 (Join-Path $p.flowThemes 'Omarchy.xaml') $xaml
    $s = Read-Json $p.flowSettings
    $font = Get-FontFamily
    $set = @{
        Theme = 'Omarchy'; UseSound = $false; BackdropType = 0; ColorScheme = $(if ($c.mode -eq 'light') { 'Light' } else { 'Dark' })
        QueryBoxFont = $font; ResultFont = $font; ResultSubFont = $font
    }
    foreach ($k in $set.Keys) { $s | Add-Member -Force -NotePropertyName $k -NotePropertyValue $set[$k] }
    Write-Json $p.flowSettings $s
    Start-Process $p.flow
}

# WT's profiles can be {defaults, list} or a bare list.
function Get-TerminalDefaults($wt) {
    if ($wt.profiles -is [array]) {
        $wt | Add-Member -Force -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{ defaults = [pscustomobject]@{}; list = $wt.profiles })
    }
    if (-not $wt.profiles.defaults) { $wt.profiles | Add-Member -Force -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) }
    $wt.profiles.defaults
}

function Set-TerminalTheme($c) {
    $file = (Get-Paths).wtSettings
    if (-not $file -or -not (Test-Path $file)) { return 'skipped' }
    $wt = Read-Json $file
    if (-not $wt) { throw "can't parse $file" }
    foreach ($ptr in 'theme', 'profiles.defaults.colorScheme', 'profiles.defaults.padding') { Save-JsonProperty $file $ptr }
    Save-JsonItem $file 'schemes' 'Omarchy'; Save-JsonItem $file 'themes' 'Omarchy'
    # Same mapping as Omarchy's alacritty.toml.tpl.
    $scheme = [ordered]@{
        name = 'Omarchy'; background = $c.background; foreground = $c.foreground
        cursorColor = $c.bright_foreground; selectionBackground = $c.selection
        black = $c.background; red = $c.red; green = $c.green; yellow = $c.yellow
        blue = $c.blue; purple = $c.magenta; cyan = $c.cyan; white = $c.foreground
        brightBlack = $c.muted; brightRed = $c.bright_red; brightGreen = $c.bright_green; brightYellow = $c.bright_yellow
        brightBlue = $c.bright_blue; brightPurple = $c.bright_magenta; brightCyan = $c.bright_cyan; brightWhite = $c.bright_foreground
    }
    $theme = [ordered]@{
        name = 'Omarchy'
        window = [ordered]@{ applicationTheme = $c.mode; useMica = $false }
        tabRow = [ordered]@{ background = "$($c.background)FF"; unfocusedBackground = "$($c.background)FF" }
        tab = [ordered]@{ background = "$($c.lighter_background)FF"; unfocusedBackground = "$($c.background)FF"; showCloseButton = 'hover' }
    }
    $wt | Add-Member -Force -NotePropertyName schemes -NotePropertyValue (@(@($wt.schemes) | Where-Object { $_ -and $_.name -ne 'Omarchy' }) + $scheme)
    $wt | Add-Member -Force -NotePropertyName themes -NotePropertyValue (@(@($wt.themes) | Where-Object { $_ -and $_.name -ne 'Omarchy' }) + $theme)
    $wt | Add-Member -Force -NotePropertyName theme -NotePropertyValue 'Omarchy'
    $d = Get-TerminalDefaults $wt
    $d | Add-Member -Force -NotePropertyName colorScheme -NotePropertyValue 'Omarchy'
    $d | Add-Member -Force -NotePropertyName padding -NotePropertyValue '14'
    Write-Json $file $wt
}

function Set-WindowsAccent($c) {
    $rgb = ConvertTo-Rgb $c.accent
    # [int64] math: PowerShell reads 0xFF000000 as a negative Int32.
    $abgr = [uint32]([int64]0xFF * 16777216 + $rgb[2] * 65536 + $rgb[1] * 256 + $rgb[0])
    $argb = [uint32]([int64]0xC4 * 16777216 + $rgb[0] * 65536 + $rgb[1] * 256 + $rgb[2])
    # AccentPalette: 3 lighter shades, the accent, 3 darker shades, and a spare, 4 bytes (RGBA) each.
    $shades = @((Mix $c.accent '#ffffff' 0.6), (Mix $c.accent '#ffffff' 0.4), (Mix $c.accent '#ffffff' 0.2), $c.accent,
                (Mix $c.accent '#000000' 0.2), (Mix $c.accent '#000000' 0.4), (Mix $c.accent '#000000' 0.6), (Mix $c.accent '#808080' 0.5))
    $palette = [byte[]]($shades | ForEach-Object { $p = ConvertTo-Rgb $_; $p[0], $p[1], $p[2], 0 })
    $dark = ConvertTo-Rgb $shades[4]
    $startAbgr = [uint32]([int64]0xFF * 16777216 + $dark[2] * 65536 + $dark[1] * 256 + $dark[0])

    $dwm = 'HKCU:\Software\Microsoft\Windows\DWM'
    $acc = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
    $per = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    foreach ($v in @(@($dwm, 'AccentColor'), @($dwm, 'ColorizationColor'), @($dwm, 'ColorizationAfterglow'),
                      @($acc, 'AccentColorMenu'), @($acc, 'StartColorMenu'), @($acc, 'AccentPalette'),
                      @($per, 'AppsUseLightTheme'), @($per, 'SystemUsesLightTheme'))) { Save-Reg $v[0] $v[1] }
    New-Item -Force $acc -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty $dwm -Name AccentColor -Type DWord -Value (To-Dword $abgr)
    Set-ItemProperty $dwm -Name ColorizationColor -Type DWord -Value (To-Dword $argb)
    Set-ItemProperty $dwm -Name ColorizationAfterglow -Type DWord -Value (To-Dword $argb)
    Set-ItemProperty $acc -Name AccentColorMenu -Type DWord -Value (To-Dword $abgr)
    Set-ItemProperty $acc -Name StartColorMenu -Type DWord -Value (To-Dword $startAbgr)
    Set-ItemProperty $acc -Name AccentPalette -Type Binary -Value $palette
    $light = [int]($c.mode -eq 'light')
    Set-ItemProperty $per -Name AppsUseLightTheme -Type DWord -Value $light
    Set-ItemProperty $per -Name SystemUsesLightTheme -Type DWord -Value $light
    Send-SettingChange
}

# Neovim configs that follow Omarchy's convention (lua/plugins/theme.lua + theme.name).
function Set-NeovimTheme([string]$theme, $c) {
    $p = Get-Paths
    $mode = (Get-Config).themeTargets.neovim
    if ($mode -eq $false -or ($mode -eq 'auto' -and -not $p.nvimOmarchy)) { return 'skipped' }
    $target = Join-Path $p.nvimConfig 'lua\plugins\theme.lua'
    $src = Join-Path $Themes "$theme\neovim.lua"
    $tpl = Join-Path $Themes '_templates\neovim.lua.tpl'
    # Themes without their own neovim.lua get Omarchy's generated aether.nvim spec.
    $body = if (Test-Path $src) { Get-Content -Raw $src }
            elseif (Test-Path $tpl) { Expand-Template (Get-Content -Raw $tpl) $c }
    $name = Join-Path $env:USERPROFILE '.local\state\omarchy\current\theme.name'
    $pin = Join-Path $env:LOCALAPPDATA 'nvim-data\omarchy-colorscheme-pin'
    Save-File $target; Save-File $name; Save-File $pin
    if ($body -and (Test-Path (Split-Path $target))) {
        Write-Utf8 $target ("-- Stand-in for Omarchy's theme symlink. Written by winarchy theme-set $theme.`n" + $body)
    }
    Write-Utf8 $name $theme
    Remove-Item $pin -ErrorAction SilentlyContinue   # `omarchy theme set` unpins
}

function Get-ThemeTargets {
    # name -> scriptblock(theme, colors); config.themeTargets switches each one off.
    [ordered]@{
        bar      = @{ label = 'bar + menu'; run = { param($t, $c) Set-BarTheme $c } }
        glazewm  = @{ label = 'GlazeWM borders'; run = { param($t, $c) Set-GlazeTheme $c } }
        terminal = @{ label = 'Windows Terminal'; run = { param($t, $c) Set-TerminalTheme $c } }
        accent   = @{ label = 'Windows accent'; run = { param($t, $c) Set-WindowsAccent $c } }
        neovim   = @{ label = 'Neovim'; run = { param($t, $c) Set-NeovimTheme $t $c } }
        vscode   = @{ label = 'VS Code'; run = { param($t, $c) Set-VSCodeTheme $t $c } }
        claude   = @{ label = 'Claude Code'; run = { param($t, $c) Set-ClaudeTheme $c } }
        browser  = @{ label = 'Browser toolbar'; run = { param($t, $c) Set-BrowserTheme $t $c } }
        btop     = @{ label = 'btop'; run = { param($t, $c) Set-BtopTheme $t $c } }
        flow     = @{ label = 'Flow Launcher'; run = { param($t, $c) Set-FlowTheme $c } }
    }
}

function Invoke-ThemeSet([string]$theme) {
    $c = Read-Colors $theme
    $cfg = Get-Config
    $state = Read-State
    $state.theme = $theme
    Save-State $state
    $targets = Get-ThemeTargets
    foreach ($name in $targets.Keys) {
        if ($cfg.themeTargets[$name] -eq $false) { continue }
        $t = $targets[$name]
        try {
            $r = & $t.run $theme $c
            Log "theme $theme -> $($t.label)$(if ($r -eq 'skipped') { ' (skipped: not installed)' })"
        } catch { Log "theme $theme -> $($t.label) FAILED: $($_.Exception.Message)" }
    }
    Write-Status $state -BumpTheme
    # Background: the one last used with this theme, else the theme's first (omarchy-theme-set).
    $bg = $state.perTheme[$theme]
    if (-not $bg -or -not (Test-Path -LiteralPath $bg)) { $bg = Get-ThemeBackgrounds $theme | Select-Object -First 1 }
    if ($bg) { Set-Background $bg $state }
}
