# Hyprland-style dwindle auto-tiling: `winarchy autotile on|off|toggle|status` toggles
# lib/autotile-watch.ps1, a background watcher started/stopped by GlazeWM itself (like
# Zebar) that keeps each tiling container's split direction matched to its own shape.
# GlazeWM has no built-in equivalent (glzr-io/glazewm#1175, #1281 are open feature
# requests) -- see lib/autotile-watch.ps1 for the algorithm and its known limits.

function Set-AutoTile([bool]$on) {
    Set-ConfigValue 'autoTiling.enabled' $on
}

function Invoke-AutoTile([string]$action) {
    switch ($action) {
        'on' { Set-AutoTile $true; Use-Lock { Invoke-Apply } }
        'off' { Set-AutoTile $false; Use-Lock { Invoke-Apply } }
        'toggle' { Invoke-AutoTile $(if ((Get-Config).autoTiling.enabled) { 'off' } else { 'on' }) }
        default {
            $enabled = (Get-Config).autoTiling.enabled
            "auto-tiling:     $(if ($enabled) { 'on' } else { 'off' })"
            $running = Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandLine -like '*autotile-watch.ps1*' }
            "watcher running: $(if ($running) { "pid $($running[0].ProcessId)" } else { 'not running' })"
        }
    }
}

# The extra `startup_commands` entry for GlazeWM's config (empty when off, so nothing is
# added to the list). $cli is the currently-selected GlazeWM CLI path (official install,
# or the animations-fork build -- see Get-SelectedGlazeWM in lib/animations.ps1), passed
# through so the watcher always talks to whichever GlazeWM is actually running.
function ConvertTo-AutoTileStartup($cfg, [string]$cli) {
    if (-not $cfg.autoTiling.enabled -or -not $cli) { return '' }
    # A YAML single-quoted string: an apostrophe in a path (a user name like O'Brien) is ''.
    $script = (Join-Path $Code 'lib\autotile-watch.ps1') -replace "'", "''"
    $cli = $cli -replace "'", "''"
    ", 'shell-exec pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$script"" -Cli ""$cli""'"
}
