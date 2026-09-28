# Omarchy theme colors (colors.toml) and templates (default/themed/*.tpl syntax).

function Read-Colors([string]$theme) {
    $file = Join-Path $Themes "$theme\colors.toml"
    if (-not (Test-Path $file)) { throw "Theme '$theme' not found ($file). Run: winarchy sync" }
    $c = @{}
    foreach ($line in Get-Content $file) {
        # Double- or single-quoted, or bare; a trailing # comment is dropped.
        if ($line -match '^\s*([A-Za-z0-9_-]+)\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^#"'']*?))\s*(#.*)?$') {
            $c[$Matches[1]] = "$($Matches[2])$($Matches[3])$($Matches[4])".Trim()
        }
    }
    Resolve-ThemeColors $c (Test-Path (Join-Path (Split-Path $file) 'light.mode'))
}

# Omarchy's bin/omarchy-theme-color resolve_theme_colors, key for key, so a theme that
# leaves keys out gets the same palette here as on Omarchy.
function Resolve-ThemeColors([hashtable]$c, [bool]$lightModeFile) {
    $set = { param($k, $v) if (-not $c[$k] -and $v) { $c[$k] = $v } }
    $first = { foreach ($v in $args) { if ($v) { return $v } } }
    $legacy = [ordered]@{
        background = 'bg'; dark_background = 'dark_bg'; darker_background = 'darker_bg'; lighter_background = 'lighter_bg'
        foreground = 'fg'; dark_foreground = 'dark_fg'; light_foreground = 'light_fg'; bright_foreground = 'bright_fg'
    }
    foreach ($k in $legacy.Keys) { & $set $k $c[$legacy[$k]] }
    # Themes from before the semantic palette may only have ANSI names.
    & $set background $c.color0
    & $set foreground $c.color7
    # Winarchy's last resort, so a broken theme still renders (Omarchy has none).
    & $set background '#1a1b26'
    & $set foreground '#a9b1d6'
    $c.color0 = $c.background
    $c.color7 = $c.foreground
    $ansi = [ordered]@{
        red = 'color1'; green = 'color2'; yellow = 'color3'; blue = 'color4'; magenta = 'color5'; cyan = 'color6'
        bright_red = 'color9'; bright_green = 'color10'; bright_yellow = 'color11'; bright_blue = 'color12'
        bright_magenta = 'color13'; bright_cyan = 'color14'
    }
    foreach ($k in $ansi.Keys) { & $set $k $c[$ansi[$k]] }
    & $set magenta $c.purple
    & $set bright_magenta $c.bright_purple

    & $set light_foreground (& $first $c.color7 $c.foreground)
    & $set bright_foreground (& $first $c.color15 $c.foreground)
    $c.cursor = $c.bright_foreground
    & $set lighter_background (& $first $c.color0 $c.background)
    & $set dark_foreground (& $first $c.color8 $c.foreground)
    & $set muted (& $first $c.color8 $c.dark_foreground)
    & $set selection (& $first $c.selection_background $c.color8 $c.color0 $c.background)
    & $set selection_background $c.selection
    & $set selection_foreground $c.bright_foreground
    & $set orange $c.yellow
    if ($c.orange) { & $set brown (Mix $c.orange '#000000' 0.5) }

    & $set dark_background (Mix $c.background '#000000' 0.25)
    & $set darker_background (Mix $c.background '#000000' 0.5)
    foreach ($k in 'red', 'yellow', 'green', 'cyan', 'blue', 'magenta') {
        if ($c[$k]) { & $set "bright_$k" (Mix $c[$k] '#ffffff' 0.2) }
    }
    & $set purple $c.magenta
    & $set bright_purple $c.bright_magenta

    $toAnsi = [ordered]@{
        color1 = 'red'; color2 = 'green'; color3 = 'yellow'; color4 = 'blue'; color5 = 'magenta'; color6 = 'cyan'
        color8 = 'muted'; color9 = 'bright_red'; color10 = 'bright_green'; color11 = 'bright_yellow'
        color12 = 'bright_blue'; color13 = 'bright_magenta'; color14 = 'bright_cyan'; color15 = 'bright_foreground'
    }
    foreach ($k in $toAnsi.Keys) { & $set $k $c[$toAnsi[$k]] }
    foreach ($k in $legacy.Keys) { if ($c[$k]) { $c[$legacy[$k]] = $c[$k] } }

    # mode: its own key, the legacy theme_type, a light.mode file, then the background.
    & $set mode $c.theme_type
    if (-not $c.mode) {
        $c.mode = if ($lightModeFile) { 'light' }
                  elseif ($c.background -match '^#[0-9A-Fa-f]{6}$' -and ((ConvertTo-Rgb $c.background) | Measure-Object -Sum).Sum -gt 382) { 'light' }
                  else { 'dark' }
    }
    $c.theme_type = $c.mode

    # Winarchy's own: the accent every Windows target uses, and GlazeWM's focused border
    # (Hyprland's active border, whose first colour is the one GlazeWM can show).
    & $set accent (& $first $c.blue $c.foreground)
    $c.focused_border = if ($c.hyprland_active_border -match 'rgba?\(\s*([0-9A-Fa-f]{6})') { "#$($Matches[1].ToLower())" } else { $c.accent }
    foreach ($k in @($c.Keys)) { if ($c[$k] -match '^#[0-9a-fA-F]{8}$') { $c[$k] = $c[$k].Substring(0, 7) } }
    $c
}

function Format-Color([string]$value, [string]$suffix) {
    switch ($suffix) {
        '_strip' { $value.TrimStart('#') }
        '_rgb' { (ConvertTo-Rgb $value) -join ',' }
        default { $value }
    }
}

# Omarchy template placeholders (bin/omarchy-theme-set-templates):
#   {{ key }}  {{ key_strip }}  {{ key_rgb }}  {{ mix a b 35% }}  {{ mix_strip ... }}  {{ mix_rgb ... }}
# Unknown keys are left as they are.
function Expand-Template([string]$text, $c) {
    $text = [regex]::Replace($text, '\{\{\s*mix(_strip|_rgb)?\s+([A-Za-z0-9_]+)\s+([A-Za-z0-9_]+)\s+([0-9.]+)(%?)\s*\}\}', {
        param($m)
        $a = $c[$m.Groups[2].Value]; $b = $c[$m.Groups[3].Value]
        if (-not $a -or -not $b) { return $m.Value }
        $t = [double]::Parse($m.Groups[4].Value, $Invariant)
        if ($m.Groups[5].Value -eq '%' -or $t -gt 1) { $t /= 100 }
        # 0.0/1.0, not 0/1: with an int literal PowerShell picks Max(int,int) and rounds $t away.
        Format-Color (Mix $a $b ([Math]::Min(1.0, [Math]::Max(0.0, $t)))) $m.Groups[1].Value
    })
    [regex]::Replace($text, '\{\{\s*([A-Za-z0-9_]+?)(_strip|_rgb)?\s*\}\}', {
        param($m)
        $key = $m.Groups[1].Value; $suffix = $m.Groups[2].Value
        if ($c.ContainsKey($key + $suffix)) { return [string]$c[$key + $suffix] }
        $v = $c[$key]
        if ($null -eq $v) { return $m.Value }
        Format-Color $v $suffix
    })
}
