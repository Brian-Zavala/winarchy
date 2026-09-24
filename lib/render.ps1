# Omarchy theme colors (colors.toml) and templates (default/themed/*.tpl syntax).

function Read-Colors([string]$theme) {
    $file = Join-Path $Themes "$theme\colors.toml"
    if (-not (Test-Path $file)) { throw "Theme '$theme' not found ($file). Run: omarchy-win sync" }
    $c = @{}
    foreach ($line in Get-Content $file) {
        if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*"([^"]*)"') { $c[$Matches[1]] = $Matches[2] }
    }
    # Fallbacks for keys some themes leave out.
    if (-not $c.mode) { $c.mode = 'dark' }
    if (-not $c.background) { $c.background = '#1a1b26' }
    if (-not $c.foreground) { $c.foreground = '#a9b1d6' }
    if (-not $c.accent) { $c.accent = if ($c.blue) { $c.blue } else { $c.foreground } }
    $fill = @{
        dark_background = 'background'; darker_background = 'background'; lighter_background = 'selection'
        selection = 'muted'; muted = 'dark_foreground'; dark_foreground = 'foreground'
        light_foreground = 'foreground'; bright_foreground = 'foreground'
        red = 'accent'; green = 'accent'; yellow = 'accent'; blue = 'accent'; magenta = 'accent'; cyan = 'accent'
        orange = 'yellow'; brown = 'orange'
        selection_background = 'selection'; selection_foreground = 'foreground'
        bright_red = 'red'; bright_green = 'green'; bright_yellow = 'yellow'; bright_blue = 'blue'
        bright_magenta = 'magenta'; bright_cyan = 'cyan'
    }
    for ($pass = 0; $pass -lt 3; $pass++) {
        foreach ($k in $fill.Keys) { if (-not $c[$k] -and $c[$fill[$k]]) { $c[$k] = $c[$fill[$k]] } }
    }
    foreach ($k in @($c.Keys)) { if ($c[$k] -match '^#[0-9a-fA-F]{8}$') { $c[$k] = $c[$k].Substring(0, 7) } }
    $c.theme_type = $c.mode
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
