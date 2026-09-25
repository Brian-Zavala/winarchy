# Bar extras: weather (Omarchy's weather module) and the update indicator.

# WMO weather codes (Open-Meteo) -> words.
function Get-WeatherText([int]$code) {
    switch ($code) {
        0 { 'clear' } 1 { 'mostly clear' } 2 { 'partly cloudy' } 3 { 'overcast' }
        { $_ -in 45, 48 } { 'fog' }
        { $_ -in 51, 53, 55, 56, 57 } { 'drizzle' }
        { $_ -in 61, 63, 65, 66, 67 } { 'rain' }
        { $_ -in 71, 73, 75, 77 } { 'snow' }
        { $_ -in 80, 81, 82 } { 'showers' }
        { $_ -in 85, 86 } { 'snow showers' }
        { $_ -in 95, 96, 99 } { 'thunderstorm' }
        default { 'weather' }
    }
}

# weather.json for the bar. Location: config "location" {lat, lon, name}, else an IP lookup
# (ipinfo.io, cached a day). Set "weather": false in config.json to turn it off.
function Update-Weather {
    $cfg = Get-Config
    if ($cfg.weather -eq $false) { return }
    $s = Read-State
    $loc = $cfg.location
    if (-not $loc -or -not $loc.lat) {
        $loc = $s.location
        if (-not $loc -or ((Get-Date) - [datetime]$loc.at).TotalHours -gt 24) {
            $ip = Invoke-RestMethod 'https://ipinfo.io/json' -TimeoutSec 10
            $lat, $lon = $ip.loc -split ','
            $loc = @{ lat = $lat; lon = $lon; name = $ip.city; at = (Get-Date).ToString('s') }
            $s.location = $loc
            Save-State $s
        }
    }
    $p = Get-Paths
    $metric = switch ($cfg.units) { 'C' { $true } 'F' { $false } default { [bool]$p.metric } }
    $url = 'https://api.open-meteo.com/v1/forecast?latitude={0}&longitude={1}&current=temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m&temperature_unit={2}&wind_speed_unit={3}' -f `
        $loc.lat, $loc.lon, $(if ($metric) { 'celsius' } else { 'fahrenheit' }), $(if ($metric) { 'kmh' } else { 'mph' })
    $cur = (Invoke-RestMethod $url -TimeoutSec 15).current
    $unit = if ($metric) { 'C' } else { 'F' }
    $desc = Get-WeatherText $cur.weather_code
    $temp = [int][Math]::Round($cur.temperature_2m)
    $w = [ordered]@{
        temp = $temp; unit = $unit; code = [int]$cur.weather_code; isDay = [bool]$cur.is_day; desc = $desc; place = $loc.name
        text = "$(if ($loc.name) { "$($loc.name): " })$temp°$unit $desc, feels $([int][Math]::Round($cur.apparent_temperature))°, wind $([int][Math]::Round($cur.wind_speed_10m)) $(if ($metric) { 'km/h' } else { 'mph' })"
        updated = (Get-Date).ToString('s')
    }
    Write-Json (Join-Path $Pack 'weather.json') $w
    Log "weather: $($w.text)"
}

# updates.json for the bar's update icon.
function Invoke-UpdateCheck {
    $cfg = Get-Config
    $items = [Collections.Generic.List[object]]::new()
    $tag = (Read-State).omarchyTag ?? $cfg.omarchyTag
    try {
        $rel = Invoke-RestMethod "https://api.github.com/repos/$($cfg.omarchyRepo)/releases/latest" -TimeoutSec 15
        if ($rel.tag_name -and $rel.tag_name -ne $tag -and $rel.tag_name -match '^v4\.') {
            $items.Add([ordered]@{ name = 'Omarchy themes'; from = $tag; to = $rel.tag_name })
        }
    } catch { Log "update-check: GitHub unreachable ($($_.Exception.Message))" }
    if ((Test-Path (Join-Path $Code '.git')) -and (git -C $Code remote)) {
        try {
            git -C $Code fetch --quiet 2>$null
            $behind = [int](git -C $Code rev-list --count 'HEAD..@{u}' 2>$null)
            if ($behind -gt 0) { $items.Add([ordered]@{ name = 'winarchy'; from = 'installed'; to = "$behind new commit(s)" }) }
        } catch {}
    }
    try {
        $out = winget list --upgrade-available --accept-source-agreements 2>$null | Out-String
        foreach ($id in 'glzr-io.glazewm', 'Flow-Launcher.Flow-Launcher', 'Fastfetch-cli.Fastfetch', 'aristocratos.btop4win', 'AutoHotkey.AutoHotkey') {
            $line = ($out -split "`r?`n") | Where-Object { $_ -match [regex]::Escape($id) } | Select-Object -First 1
            if ($line -and $line -match [regex]::Escape($id) + '\s+(\S+)\s+(\S+)') {
                $items.Add([ordered]@{ name = $id; from = $Matches[1]; to = $Matches[2] })
            }
        }
    } catch {}
    Write-Json (Join-Path $Pack 'updates.json') ([ordered]@{ checked = (Get-Date).ToString('s'); items = @($items) })
    Log "update-check: $($items.Count) update(s)"
}
