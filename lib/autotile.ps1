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

# Workspaces left on the wrong split direction (lib/autotile-watch.ps1 flips them back).
# GlazeWM flattens H[V[win]] into V[win] when the window beside a dwindle split closes
# (flatten_child_split_containers), so the workspace takes the split's direction and the
# next window stacks underneath instead of beside. A workspace holding one window or none
# should split along its monitor's long side, as a fresh one does. $monitors is
# `query monitors`' .data.monitors; returns workspace ids.
function Get-DirectionFixes($monitors) {
    foreach ($mon in $monitors) {
        $want = if ([int]$mon.width -ge [int]$mon.height) { 'horizontal' } else { 'vertical' }
        foreach ($ws in $mon.children) {
            if ($ws.type -ne 'workspace' -or $ws.tilingDirection -eq $want) { continue }
            $tiling = @($ws.children | Where-Object { $_.type -eq 'split' -or ($_.type -eq 'window' -and $_.state.type -eq 'tiling') })
            if ($tiling.Count -gt 1 -or ($tiling.Count -eq 1 -and $tiling[0].type -eq 'split')) { continue }
            $ws.id
        }
    }
}

# A new window GlazeWM started as fullscreen only because its saved size covers the whole
# screen (no taskbar here, so Chrome, Explorer and co. reopen that big): it would sit
# behind the bar. Real fullscreen (Chrome F11, video players, launchers' fullscreen modes)
# is borderless; an ordinary window keeps its resizing frame (WS_THICKFRAME).
function Test-TileFullSize($win, [long]$style) {
    $win.state.type -eq 'fullscreen' -and -not $win.state.maximized -and ($style -band 0x40000) -ne 0
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
    # conhost --headless: started plainly, pwsh gets handed to the default terminal (Windows
    # Terminal), whose window -WindowStyle Hidden can't hide -- and the watcher never exits,
    # so it sat on screen showing "autotile: watching". Headless conhost makes no window at all.
    ", 'shell-exec conhost.exe --headless pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$script"" -Cli ""$cli""'"
}
