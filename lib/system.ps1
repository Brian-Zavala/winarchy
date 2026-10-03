# The Windows sides of Omarchy's Update > Timezone/Time, Setup > Network > DNS, Trigger >
# Reminder / Speed Test / Transcode / Share and Install > Web App. Each is a verb the menu
# runs in a terminal (CliInTerminal), so a prompt or a result has somewhere to show.

# Run PowerShell text as administrator and wait (one UAC prompt). Changing the time zone
# or a DNS server is a machine setting, which Windows keeps behind elevation.
function Invoke-Elevated([string]$Script) {
    $pwsh = (Get-Process -Id $PID).Path
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Script))
    $proc = Start-Process -FilePath $pwsh -Verb RunAs -Wait -PassThru -WindowStyle Hidden `
        -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded
    if ($proc.ExitCode) { throw "the elevated step failed (exit $($proc.ExitCode))" }
}

# --- Update > Timezone / Time ------------------------------------------------------------

# The menu lists IANA names (the same ones the world clock uses); Windows wants its own ids.
function ConvertTo-WindowsZoneId([string]$Name) {
    $win = $null
    if ([TimeZoneInfo]::TryConvertIanaIdToWindowsId($Name, [ref]$win)) { return $win }
    ([TimeZoneInfo]::FindSystemTimeZoneById($Name)).Id
}

function Set-WinarchyTimeZone([string]$Name) {
    if (-not $Name) { throw 'usage: winarchy timezone-set <Region/City | Windows zone id>' }
    $id = ConvertTo-WindowsZoneId $Name
    try { Set-TimeZone -Id $id -ErrorAction Stop }
    catch { Invoke-Elevated "Set-TimeZone -Id '$($id -replace "'", "''")'" }
    Write-Host "Time zone: $((Get-TimeZone).DisplayName)"
}

function Sync-WinarchyTime {
    try { $null = & w32tm /resync 2>&1; if ($LASTEXITCODE) { throw 'w32tm' } }
    catch { Invoke-Elevated 'Start-Service w32time -ErrorAction SilentlyContinue; w32tm /resync' }
    Write-Host "Time synced: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

# --- Setup > Network > DNS ---------------------------------------------------------------

$DnsProviders = [ordered]@{
    dhcp       = @()
    cloudflare = @('1.1.1.1', '1.0.0.1')
    google     = @('8.8.8.8', '8.8.4.4')
}

function Set-WinarchyDns([string]$Provider) {
    if (-not $Provider) { throw 'usage: winarchy dns-set <dhcp|cloudflare|google|custom>' }
    if ($Provider -eq 'custom') {
        $entered = Read-Host 'DNS servers (space separated, e.g. 9.9.9.9 149.112.112.112)'
        $servers = @($entered -split '[\s,]+' | Where-Object { $_ })
        if (-not $servers) { throw 'no DNS servers given' }
        foreach ($s in $servers) { if (-not [ipaddress]::TryParse($s, [ref]$null)) { throw "not an IP address: $s" } }
    } elseif ($DnsProviders.Contains($Provider)) { $servers = @($DnsProviders[$Provider]) }
    else { throw "unknown DNS provider '$Provider' (dhcp, cloudflare, google, custom)" }
    $set = if ($servers) { "-ServerAddresses '$($servers -join "','")'" } else { '-ResetServerAddresses' }
    Invoke-Elevated "Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex `$_.ifIndex $set }"
    Clear-DnsClientCache
    Write-Host "DNS: $(if ($servers) { $servers -join ', ' } else { 'from DHCP' })"
}

# --- Trigger > Reminder ------------------------------------------------------------------
# A reminder is a one-time scheduled task that shows the OSD, so it survives a restart
# (and a missed one fires when you are next signed in).

$ReminderPrefix = 'winarchy-reminder-'

function ConvertTo-ReminderTime([string]$Text) {
    $t = $Text.Trim().ToLower()
    if ($t -match '^(\d+)\s*(m|min|mins|minutes?)?$') { return (Get-Date).AddMinutes([int]$Matches[1]) }
    if ($t -match '^(\d+(?:\.\d+)?)\s*(h|hr|hrs|hours?)$') { return (Get-Date).AddMinutes([double]$Matches[1] * 60) }
    if ($t -match '^(\d{1,2}):(\d{2})$') {
        $at = (Get-Date).Date.AddHours([int]$Matches[1]).AddMinutes([int]$Matches[2])
        if ($at -le (Get-Date)) { $at = $at.AddDays(1) }
        return $at
    }
    throw "can't read '$Text' as a time (try 10, 90m, 2h or 14:30)"
}

function New-WinarchyReminder([string]$When, [string]$Message) {
    if (-not $When) { $When = Read-Host 'Remind me in / at (10, 90m, 2h, 14:30)' }
    if (-not $Message) { $Message = Read-Host 'About' }
    $at = ConvertTo-ReminderTime $When
    if (-not $Message) { $Message = 'Reminder' }
    $p = Get-Paths
    $menu = Join-Path $Code 'ahk\menu.ahk'
    $name = "$ReminderPrefix$([DateTimeOffset]::Now.ToUnixTimeSeconds())"
    $action = New-ScheduledTaskAction -Execute $p.ahk -Argument "`"$menu`" notify `"$($Message -replace '"', "'")`""
    $trigger = New-ScheduledTaskTrigger -Once -At $at
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -Description $Message -Force | Out-Null
    Write-Host "Reminder set for $($at.ToString('ddd HH:mm')): $Message"
    Update-ReminderFile
}

# Every reminder still to come. One that has gone off is a task with no next run: it is
# removed here, so they don't pile up in Task Scheduler.
function Get-WinarchyReminders {
    Get-ScheduledTask -TaskName "$ReminderPrefix*" -ErrorAction SilentlyContinue | ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        if (-not $info.NextRunTime -or $info.NextRunTime -lt (Get-Date)) {
            if ($info.LastRunTime -and $info.LastRunTime.Year -gt 2000) { Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction SilentlyContinue }
            return
        }
        [pscustomobject]@{ name = $_.TaskName; at = $info.NextRunTime; message = $_.Description }
    } | Sort-Object at
}

# reminders.json for the bar's bell: the next one and how many there are. It lives in the
# pack beside the other state files, and only ever comes from here (never from the code).
function Update-ReminderFile {
    $all = @(Get-WinarchyReminders)
    $next = $all | Select-Object -First 1
    Write-Json (Join-Path $Pack 'reminders.json') ([ordered]@{
            count = $all.Count
            next = $(if ($next) { [ordered]@{ at = $next.at.ToString('o'); message = $next.message } })
        })
}

function Show-WinarchyReminders {
    $all = @(Get-WinarchyReminders)
    Update-ReminderFile
    if (-not $all) { Write-Host 'No reminders.'; return }
    foreach ($r in $all) { Write-Host ("{0:ddd HH:mm}  {1}" -f $r.at, $r.message) }
}

function Clear-WinarchyReminders {
    $all = @(Get-ScheduledTask -TaskName "$ReminderPrefix*" -ErrorAction SilentlyContinue)
    foreach ($r in $all) { Unregister-ScheduledTask -TaskName $r.TaskName -Confirm:$false }
    Write-Host "Cleared $($all.Count) reminder$(if ($all.Count -ne 1) { 's' })."
    Update-ReminderFile
}

# --- Trigger > Speed Test ----------------------------------------------------------------

function Invoke-SpeedTest([string]$Kind) {
    if ($Kind -eq 'disk') {
        $file = Join-Path ([IO.Path]::GetTempPath()) "winarchy-disk-$PID.bin"
        $size = 512MB
        $buf = [byte[]]::new(8MB)
        [Random]::new().NextBytes($buf)
        try {
            $sw = [Diagnostics.Stopwatch]::StartNew()
            $fs = [IO.File]::Create($file, 8MB, [IO.FileOptions]::WriteThrough)
            for ($i = 0; $i -lt $size / $buf.Length; $i++) { $fs.Write($buf, 0, $buf.Length) }
            $fs.Dispose()
            $w = $size / 1MB / $sw.Elapsed.TotalSeconds
            $sw.Restart()
            $fs = [IO.File]::OpenRead($file)
            while ($fs.Read($buf, 0, $buf.Length) -gt 0) { }
            $fs.Dispose()
            $r = $size / 1MB / $sw.Elapsed.TotalSeconds
            Write-Host ("Disk (temp drive, 512 MB): write {0:N0} MB/s, read {1:N0} MB/s (read may be cached)" -f $w, $r)
        } finally { Remove-Item $file -Force -ErrorAction SilentlyContinue }
        return
    }
    $bytes = 50MB
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WebRequest "https://speed.cloudflare.com/__down?bytes=$bytes" -UseBasicParsing -TimeoutSec 60
    $mbps = $r.RawContentLength * 8 / 1e6 / $sw.Elapsed.TotalSeconds
    Write-Host ("Network: download {0:N0} Mbit/s (Cloudflare, {1:N0} MB)" -f $mbps, ($r.RawContentLength / 1MB))
}

# --- Trigger > Transcode -----------------------------------------------------------------

# Omarchy's omarchy-transcode: a picture to jpg / png at high, medium or low size, a video to
# mp4 / gif at 4k, 1080p or 720p, saved beside it as <name>-<size>.<format> and copied to
# the clipboard as a file. The same sizes and encoder settings; pictures go through
# ImageMagick as there when it is installed, else through FFmpeg.
$TranscodePictureExt = 'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'avif', 'bmp', 'tif', 'tiff'
$TranscodeVideoExt = 'mp4', 'mov', 'm4v', 'mkv', 'webm', 'avi'

function Get-TranscodeType([string]$Path) {
    $ext = [IO.Path]::GetExtension($Path).TrimStart('.').ToLower()
    if ($TranscodeVideoExt -contains $ext) { 'video' } elseif ($TranscodePictureExt -contains $ext) { 'picture' } else { $null }
}

function Get-TranscodeOutput([string]$Path, [string]$Format, [string]$Resolution) {
    Join-Path ([IO.Path]::GetDirectoryName($Path)) "$([IO.Path]::GetFileNameWithoutExtension($Path))-$Resolution.$Format"
}

# The program and its arguments for one transcode (no shell in between: paths may have spaces).
function Get-TranscodeCommand([string]$Type, [string]$In, [string]$Format, [string]$Resolution, [string]$Out, [bool]$Magick) {
    if ($Type -eq 'picture') {
        $width = @{ high = 3160; medium = 2160; low = 1080 }[$Resolution]
        if (-not $width) { throw "picture sizes are high, medium or low (not '$Resolution')" }
        if ($Format -notin 'jpg', 'png') { throw "pictures become jpg or png (not '$Format')" }
        if ($Magick) {
            $opts = if ($Format -eq 'jpg') { @('-quality', '85', '-strip') }
                else { @('-strip', '-define', 'png:compression-filter=5', '-define', 'png:compression-level=9', '-define', 'png:compression-strategy=1', '-define', 'png:exclude-chunk=all') }
            return @{ exe = 'magick'; args = @($In, '-resize', "${width}x>") + $opts + @($Out) }
        }
        # FFmpeg's equivalent of "${width}x>": narrower pictures keep their size.
        $q = if ($Format -eq 'jpg') { @('-q:v', '3') } else { @('-compression_level', '9') }
        return @{ exe = 'ffmpeg'; args = @('-y', '-i', $In, '-vf', "scale='min($width,iw)':-2", '-frames:v', '1') + $q + @($Out) }
    }
    $height = @{ '4k' = 2160; '1080p' = 1080; '720p' = 720 }[$Resolution]
    if (-not $height) { throw "video sizes are 4k, 1080p or 720p (not '$Resolution')" }
    $scale = "scale=-2:$height"
    switch ($Format) {
        'mp4' {
            $codec = if ($Resolution -eq '4k') { @('-c:v', 'libx265', '-preset', 'slow', '-crf', '24') } else { @('-c:v', 'libx264', '-preset', 'fast', '-crf', '23') }
            @{ exe = 'ffmpeg'; args = @('-y', '-i', $In, '-vf', $scale) + $codec + @('-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart', $Out) }
        }
        'gif' { @{ exe = 'ffmpeg'; args = @('-y', '-i', $In, '-vf', "fps=10,${scale}:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse", $Out) } }
        default { throw "videos become mp4 or gif (not '$Format')" }
    }
}

# A numbered pick, Omarchy's omarchy-menu-select in a terminal.
function Read-Choice([string]$Title, [string[]]$Options) {
    Write-Host $Title
    for ($i = 0; $i -lt $Options.Count; $i++) { Write-Host "  $($i + 1)  $($Options[$i])" }
    $a = Read-Host 'Number'
    if ($a -match '^\d+$' -and [int]$a -ge 1 -and [int]$a -le $Options.Count) { return $Options[[int]$a - 1] }
    throw 'nothing picked'
}

function Invoke-Transcode([string]$Path, [string]$Format, [string]$Resolution) {
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host 'ffmpeg is not installed: installing it (winget)...'
        winget install -e --id Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
        Update-ProcessPath
        if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { throw 'ffmpeg is installed but not on PATH yet: open a new terminal and run this again' }
    }
    if (-not $Path) {
        # The newest pictures and videos in Pictures and Videos, like Omarchy's picker.
        $dirs = @([Environment]::GetFolderPath('MyPictures'), [Environment]::GetFolderPath('MyVideos')) | Where-Object { $_ -and (Test-Path $_) }
        $recent = @(Get-ChildItem $dirs -File -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                Where-Object { Get-TranscodeType $_.FullName } | Sort-Object LastWriteTime -Descending | Select-Object -First 15)
        for ($i = 0; $i -lt $recent.Count; $i++) { Write-Host "  $($i + 1)  $($recent[$i].Name)" }
        $a = (Read-Host "$(if ($recent) { 'Number, or ' })drag a picture or video in here").Trim('"', ' ')
        $Path = if ($a -match '^\d+$' -and [int]$a -ge 1 -and [int]$a -le $recent.Count) { $recent[[int]$a - 1].FullName } else { $a }
    }
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { throw "no such file: $Path" }
    $type = Get-TranscodeType $Path
    if (-not $type) { throw "not a picture or video: $Path" }
    if (-not $Format) { $Format = Read-Choice 'Format' $(if ($type -eq 'picture') { 'jpg', 'png' } else { 'mp4', 'gif' }) }
    if (-not $Resolution) { $Resolution = Read-Choice 'Size' $(if ($type -eq 'picture') { 'high', 'medium', 'low' } else { '4k', '1080p', '720p' }) }
    $out = Get-TranscodeOutput $Path $Format $Resolution
    $cmd = Get-TranscodeCommand $type $Path $Format $Resolution $out ([bool](Get-Command magick -ErrorAction SilentlyContinue))
    & $cmd.exe @($cmd.args)
    if ($LASTEXITCODE) { throw "$($cmd.exe) failed (exit $LASTEXITCODE)" }
    Set-Clipboard -Path $out
    Write-Host "Saved $out and copied it to the clipboard."
}

# --- Trigger > Share (LocalSend) ---------------------------------------------------------

function Start-Share {
    $exe = Get-ChildItem "$env:LOCALAPPDATA\Programs\LocalSend", "$env:ProgramFiles\LocalSend" -Filter 'localsend_app.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($exe) { Start-Process $exe.FullName; return }
    Write-Host 'LocalSend is not installed: installing it (winget)...'
    winget install -e --id LocalSend.LocalSend --accept-package-agreements --accept-source-agreements
}

# Install > Web App lives in lib/webapps.ps1 (presets, keys, shortcuts with their own
# AppUserModelID).
