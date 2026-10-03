# winarchy apply: renders every generated file from templates + config.json +
# paths.json, so the same code fits any machine (monitors, DPI, apps, paths).

# --- workspaces -------------------------------------------------------------------
# 10 workspaces split over the monitors left to right (the order GlazeWM and Zebar
# use): 1 monitor -> 1-10, 2 -> 1-5 / 6-0, 3 -> 1-4 / 5-7 / 8-0, ...
# config.workspaces can instead map monitor positions to names: { "1": ["1","2"], "2": [...] }.
function Get-WorkspaceLayout([int]$monitorCount, $spec = 'auto') {
    $monitorCount = [Math]::Max(1, $monitorCount)
    $list = [Collections.Generic.List[object]]::new()
    if ($spec -is [hashtable]) {
        foreach ($m in $spec.Keys | Sort-Object { [int]$_ }) {
            $i = 0
            foreach ($name in $spec[$m]) {
                $list.Add(@{ name = "$name"; monitor = [Math]::Min([int]$m, $monitorCount) - 1; keepAlive = $i++ -lt 5 })
            }
        }
        return $list
    }
    $per = [Math]::Floor(10 / [Math]::Min($monitorCount, 10))
    $extra = 10 % [Math]::Min($monitorCount, 10)
    $n = 1
    for ($m = 0; $m -lt [Math]::Min($monitorCount, 10); $m++) {
        $count = $per + [int]($m -lt $extra)
        for ($i = 0; $i -lt $count; $i++) {
            $list.Add(@{ name = "$n"; monitor = $m; keepAlive = $i -lt 5 }); $n++
        }
    }
    $list
}

function ConvertTo-WorkspacesYaml($layout) {
    ($layout | ForEach-Object {
        $lines = @("  - name: '$($_.name)'")
        if ($_.name -eq '10') { $lines += "    display_name: '0'" }
        $lines += "    bind_to_monitor: $($_.monitor)"
        if ($_.keepAlive) { $lines += '    keep_alive: true' }
        $lines -join "`n"
    }) -join "`n"
}

# The workspaces a GlazeWM config binds to a monitor: [{name; monitor; keepAlive}], read
# from the YAML itself so a custom glazewm.yaml.tpl is honoured too.
function Get-WorkspaceBindings([string]$yaml) {
    if ($yaml -notmatch '(?ms)^workspaces:\s*$(.*?)(?=^\S|\z)') { return }
    foreach ($m in [regex]::Matches($Matches[1], "(?m)^\s*- name:\s*'([^']+)'((?:\r?\n[ \t]+(?!- )\S.*)*)")) {
        $body = $m.Groups[2].Value
        if ($body -match 'bind_to_monitor:\s*(\d+)') {
            [pscustomobject]@{ name = $m.Groups[1].Value; monitor = [int]$Matches[1]; keepAlive = $body -match 'keep_alive:\s*true' }
        }
    }
}

# How many monitors a GlazeWM config spreads the workspaces over (0: none bound).
function Get-BoundMonitorCount([string]$yaml) {
    $max = (@(Get-WorkspaceBindings $yaml) | Measure-Object monitor -Maximum).Maximum
    if ($null -eq $max) { 0 } else { [int]$max + 1 }
}

# Monitors to split the workspaces over. The split never shrinks by itself: a monitor in
# power-save (screensaver, sleep) looks unplugged to Windows, and GlazeWM only puts its
# workspaces back on wake if the config still binds them to it. Meanwhile GlazeWM opens
# workspaces bound to a missing monitor on the focused one. -Resplit: size the split to
# the monitors connected right now (a monitor removed for good).
function Get-LayoutMonitorCount([int]$connected, [int]$bound, [switch]$Resplit) {
    if ($Resplit) { [Math]::Max(1, $connected) } else { [Math]::Max(1, [Math]::Max($connected, $bound)) }
}

# Workspaces GlazeWM holds on another monitor than the one they are bound to (from/to are
# monitor indexes), plus keep-alive ones missing from a connected monitor (from = $null).
# $monitors: `glazewm query monitors` data, in GlazeWM's index order (left to right).
function Get-MisplacedWorkspaces($monitors, $bindings) {
    $monitors = @($monitors)
    $where = @{}
    for ($i = 0; $i -lt $monitors.Count; $i++) {
        foreach ($ws in $monitors[$i].children) { $where[$ws.name] = $i }
    }
    foreach ($b in $bindings) {
        if ($b.monitor -ge $monitors.Count) { continue }   # its monitor isn't connected
        if ($where.ContainsKey($b.name)) {
            if ($where[$b.name] -ne $b.monitor) { [pscustomobject]@{ name = $b.name; from = $where[$b.name]; to = $b.monitor } }
        } elseif ($b.keepAlive) { [pscustomobject]@{ name = $b.name; from = $null; to = $b.monitor } }
    }
}

# Which way monitor $to lies from monitor $from (GlazeWM's move-workspace directions).
function Get-MonitorDirection($from, $to) {
    $dx = ($to.x + $to.width / 2) - ($from.x + $from.width / 2)
    $dy = ($to.y + $to.height / 2) - ($from.y + $from.height / 2)
    if ([Math]::Abs($dx) -ge [Math]::Abs($dy)) { if ($dx -gt 0) { 'right' } else { 'left' } }
    elseif ($dy -gt 0) { 'down' } else { 'up' }
}

# Puts every workspace back on the monitor it is bound to. GlazeWM does that itself when
# a monitor appears, but only with the config loaded at that moment, and reloading the
# config never moves workspaces; so after the split changes (or a monitor woke up before
# its bindings were back) they stay where they were. Changes nothing when all are in place;
# otherwise the moved workspaces flash by and each monitor then shows what it did before.
function Repair-WorkspaceMonitors([string]$cli, $bindings) {
    $query = { @((& $cli query monitors | ConvertFrom-Json).data.monitors) }
    $monitors = & $query
    $todo = @(Get-MisplacedWorkspaces $monitors $bindings)
    if (-not $todo) { return }
    $shown = @(for ($i = 0; $i -lt $monitors.Count; $i++) {
        $ws = $monitors[$i].children | Where-Object isDisplayed | Select-Object -First 1
        if ($ws) { [pscustomobject]@{ name = $ws.name; monitor = $i; focused = [bool]$monitors[$i].hasFocus } }
    })
    foreach ($t in $todo) {
        # Focusing a workspace that doesn't exist yet opens it on its bound monitor.
        & $cli command focus --workspace $t.name | Out-Null
        for ($hop = 0; $hop -lt $monitors.Count; $hop++) {
            $monitors = & $query
            $at = @(for ($i = 0; $i -lt $monitors.Count; $i++) { if ($monitors[$i].children.name -contains $t.name) { $i } })[0]
            if ($null -eq $at -or $at -eq $t.to -or $t.to -ge $monitors.Count) { break }
            & $cli command move-workspace --direction (Get-MonitorDirection $monitors[$at] $monitors[$t.to]) | Out-Null
        }
    }
    # Show each monitor's previous workspace again (if it is still there), the focused one last.
    $monitors = & $query
    foreach ($s in $shown | Sort-Object focused) {
        if ($s.monitor -lt $monitors.Count -and $monitors[$s.monitor].children.name -contains $s.name) {
            & $cli command focus --workspace $s.name | Out-Null
        }
    }
    $done = @()
    $moved = @($todo | Where-Object { $null -ne $_.from } | ForEach-Object name)
    $opened = @($todo | Where-Object { $null -eq $_.from } | ForEach-Object name)
    if ($moved) { $done += "moved $($moved -join ',') to their monitors" }
    if ($opened) { $done += "opened $($opened -join ',')" }
    Log "workspaces: $($done -join '; ')"
}

# Games manage their own window and display mode: GlazeWM tiling one (or redrawing it
# after a display change) knocks it out of fullscreen. Process names (no .exe) of the
# games Windows' Game Bar has recognised (GameConfigStore; any PC) + config.games.
# winarchy.ahk does the same at run time for games recognised after this apply.
function Get-GameProcesses($cfg, [string[]]$exePaths) {
    if ($cfg.gameMode -eq $false) { return @() }
    if ($null -eq $exePaths) {
        $exePaths = foreach ($k in Get-ChildItem 'HKCU:\System\GameConfigStore\Children' -ErrorAction SilentlyContinue) {
            (Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue).MatchedExeFullPath
        }
    }
    $names = [Collections.Generic.SortedSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($e in $exePaths) { if ($e) { [void]$names.Add([IO.Path]::GetFileNameWithoutExtension($e)) } }
    foreach ($g in @($cfg.games)) { if ($g) { [void]$names.Add(($g -replace '(?i)\.exe$', '')) } }
    # Never apps winarchy itself manages, should Game Bar ever have been told they're games.
    @($names | Where-Object { $_ -notmatch '^(explorer|WindowsTerminal|pwsh|powershell|cmd|Code|chrome|msedge|firefox|zebar|glazewm)$' })
}

# Super+Ctrl+G (winarchy.ahk MarkAsGame) / `winarchy game-add <name>`: add one process
# name to config.json's own "games" list, so it's caught from the next apply/restart on
# (winarchy.ahk already registered the window itself for this session).
function Add-ConfigGame([string]$name) {
    $name = ($name -replace '(?i)\.exe$', '').Trim()
    if (-not $name) { return }
    $games = @(@((Read-UserConfig).games) | Where-Object { $_ })
    if ($games -contains $name) { return }
    # Through Set-ConfigValue for its selfwrite stamp: without it winarchy.ahk would see
    # config.json change and run a full apply, restarting the bar over the game.
    Set-ConfigValue 'games' ($games + $name)
    Log "games: added '$name' to config.json"
}

function ConvertTo-GamesYaml([string[]]$names) {
    if (-not $names) { return '      # (none yet)' }
    ($names | ForEach-Object { "      - window_process: { equals: '$($_ -replace "'", "''")' }" }) -join "`n"
}

function Write-GlazeConfig([int]$monitorCount) {
    $cfg = Get-Config
    if ($cfg.glazewmManaged -eq $false) { Log 'GlazeWM config: not managed (glazewmManaged=false)'; return $false }
    $tplFile = Join-Path $Data 'glazewm.yaml.tpl'
    if (-not (Test-Path $tplFile)) { $tplFile = Join-Path $Code 'templates\glazewm.yaml.tpl' }
    $old = if (Test-Path $GlazeConfig) { Get-Content -Raw $GlazeConfig } else { '' }
    # Keep what the toggles/theme last set: gaps on/off and the focused border colour.
    # A 0px gap means Super + Shift + Backspace turned gaps off, unless the gap set in
    # config.json at the last apply was 0 itself: then it is just the old setting.
    $gap = [int]$cfg.gap
    $state = Read-State
    $lastGap = if ($null -ne $state.gap) { [int]$state.gap } else { $gap }
    if ($lastGap -ne 0 -and $old -match "inner_gap:\s*'0px'\s*# gaps") { $gap = 0 }
    if ($state.gap -ne [int]$cfg.gap) { $state.gap = [int]$cfg.gap; Save-State $state }
    # The bar's strip lives in GlazeWM's top gap (scaled per monitor like the bar itself).
    # (None while the bar is turned off: Super+Shift+Space / winarchy bar off.)
    $gapTop = if (Test-Path (Join-Path $Generated 'bar-off')) { $gap } else { (Get-BarHeight $cfg) + $gap }
    $border = if ($old -match "color:\s*'(#[0-9A-Fa-f]{6})'\s*# theme:focused-border") { $Matches[1] } else {
        try { (Read-Colors (Read-State).theme).focused_border } catch { '#7aa2f7' }
    }
    $values = @{
        gap = "$gap"; gap_top = "$gapTop"; focused_border = $border
        workspaces = ConvertTo-WorkspacesYaml (Get-WorkspaceLayout $monitorCount $cfg.workspaces)
        animations = ConvertTo-AnimationsYaml $cfg
        games = ConvertTo-GamesYaml (Get-GameProcesses $cfg)
        autotile_startup = ConvertTo-AutoTileStartup $cfg (Get-Paths).glazewmCli
    }
    $yaml = Expand-Template (Get-Content -Raw $tplFile) $values
    if ($yaml -eq $old) { return $false }
    Save-File $GlazeConfig
    Write-Utf8 $GlazeConfig $yaml
    Log "GlazeWM config written ($monitorCount monitor(s))"
    $true
}

# Your name and email from git, for compose's CapsLock Space N / Space E (Omarchy fills
# them in from its first-run setup). Nothing when git or the setting is missing.
function Get-GitIdentity([string]$key) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return '' }
    try { "$(git config --global --get $key 2>$null)".Trim() -replace '[\r\n]', '' } catch { '' }
}

# --- AutoHotkey settings (UTF-16 so IniRead handles any user name) ------------------
function Write-AhkIni($p, $cfg) {
    $editor = switch ($cfg.apps.editor) {
        'auto' { if ($p.nvim) { $p.nvim } elseif ($p.vscode) { $p.vscode } else { 'notepad.exe' } }
        default { Expand-UserPath $cfg.apps.editor }
    }
    $terminal = switch ($cfg.apps.terminal) {
        'auto' { if ($p.wt) { 'wt.exe' } else { $p.pwsh } }
        default { Expand-UserPath $cfg.apps.terminal }
    }
    $browser = if ($cfg.apps.browser -eq 'auto') { $p.browser } else { Expand-UserPath $cfg.apps.browser }
    $files = if (-not $cfg.apps.files -or $cfg.apps.files -eq 'auto') { 'explorer.exe' } else { Expand-UserPath $cfg.apps.files }
    $ini = [ordered]@{
        paths  = [ordered]@{
            code = $Code; data = $Data; pack = $Pack; log = $LogFile; glazeConfig = $GlazeConfig
            ahk = $p.ahk; pwsh = $p.pwsh; powershell = $p.powershell
            glazewm = $p.glazewm; glazewmCli = $p.glazewmCli; zebar = $p.zebar; flow = $p.flow
            terminal = $terminal; wt = $p.wt; editor = $editor; files = $files
            browser = $browser; browserPrivate = $(if ($cfg.apps.browser -eq 'auto') { $p.browserPrivate } else { Get-BrowserPrivateFlag $browser })
            btop = $(if ($p.btopDir) { Join-Path $p.btopDir 'btop4win.exe' })
            herdr = $p.herdr
            # Set-TerminalProfiles' Omarchy Shell, once it is in Terminal's settings.
            wtProfile = $(if ($p.wtSettings -and (Select-String -LiteralPath $p.wtSettings -SimpleMatch $ShellProfile -Quiet -ErrorAction SilentlyContinue)) { $ShellProfile })
        }
        config = [ordered]@{
            flowHotkey = $p.flowHotkey
            takeOverWinSpace = [int][bool]$cfg.takeOverWinSpace
            launchers = [int][bool]$cfg.launchers
            hideTaskbar = [int][bool]$cfg.hideTaskbar
            gap = [int]$cfg.gap
            barHeight = Get-BarHeight $cfg
            syncAtLogin = [int][bool]$cfg.syncAtLogin
            screensaver = [int][bool]($cfg.screensaver.enabled -and $p.wt)
            screensaverIdle = [int]$cfg.screensaver.idleSeconds
            screensaverProfile = 'Omarchy Screensaver'
            weather = [int]($cfg.weather -ne $false)
            agentUsage = [int]($cfg.agentUsage.enabled -ne $false)
            # Omarchy's widget allows 30 s to an hour; the same bounds here.
            agentUsageSeconds = [Math]::Min(3600, [Math]::Max(30, [int]($cfg.agentUsage.refreshSeconds ?? 900)))
            animations = [int]($p.glazewm -and $p.glazewm -ne $p.glazewmOfficial)
            gameMode = [int]($cfg.gameMode -ne $false)
            games = (@($cfg.games) | Where-Object { $_ }) -join '|'
            gameDirs = (@($cfg.gameDirs) | Where-Object { $_ }) -join '|'
            blockMinimize = [int]($cfg.blockMinimize -ne $false)
            minimizeAllowed = (@($cfg.minimizeAllowed) | Where-Object { $_ }) -join '|'
            gameFocusGuard = [int]($cfg.gameFocusGuard -ne $false)
            openOnHoveredMonitor = [int]($cfg.openOnHoveredMonitor -ne $false)
            focusFollowsCursor = [int]($cfg.focusFollowsCursor -ne $false)
            autoTiling = [int]($cfg.autoTiling.enabled -ne $false)
            # Keys your own Startup scripts have (lib/keys.ps1): BindUnlessUser leaves them be.
            userKeys = (@($p.userHotkeys.keys) | Where-Object { $_ }) -join '|'
            captureKeys = $(if ($cfg.captureKeys -eq 'omarchy') { 'omarchy' } else { 'winarchy' })
            # CapsLock compose (ahk/lib/compose.ahk); never with an input method, whose
            # CapsLock switches modes.
            compose = [int]([bool]$cfg.compose -and -not $p.input.ime)
            composeName = Get-GitIdentity 'user.name'
            composeEmail = Get-GitIdentity 'user.email'
        }
    }
    $text = foreach ($section in $ini.Keys) {
        "[$section]"
        foreach ($k in $ini[$section].Keys) { "$k=$($ini[$section][$k])" }
        ''
    }
    New-Item -ItemType Directory -Force $Generated | Out-Null
    [IO.File]::WriteAllLines((Join-Path $Generated 'winarchy.ini'), [string[]]$text, [Text.UnicodeEncoding]::new($false, $true))
}

# --- Zebar pack ---------------------------------------------------------------------
# The bar's height: barHeight, grown with the text size (Display panel) so bigger text
# still fits. Sizes at or under the default 12px keep barHeight as it is.
function Get-BarHeight($cfg) {
    $px = if ($null -ne $cfg.textSize) { [Math]::Max(9, [Math]::Min(20, [int]$cfg.textSize)) } else { 12 }
    [int][Math]::Round([int]$cfg.barHeight * [Math]::Max([double]1, $px / 12))
}

function Get-ZpackJson($p) {
    $ahk = $p.ahk
    # Only our own menu.ahk may drive the menu widget, not any script of that name. Zebar's
    # regex is Rust's, which rejects .NET's escaped spaces, so only the metacharacters are.
    $menuPath = (Join-Path $Code 'ahk\menu.ahk') -replace '([\\.+*?()|\[\]{}^$])', '\$1'
    $menuPrivilege = [ordered]@{ program = $ahk; argsRegex = "(?i).*$menuPath.*" }
    $widget = {
        param($name, $html, $zOrder, $focused, $transparent, $include, $privileges, $presets)
        [ordered]@{
            name = $name; htmlPath = $html; zOrder = $zOrder; shownInTaskbar = $false; focused = $focused
            resizable = $false; transparent = $transparent; includeFiles = $include
            caching = [ordered]@{ defaultDuration = 0; rules = @() }
            privileges = [ordered]@{ shellCommands = $privileges }
            presets = $presets
        }
    }
    # transparent: the bar can go clear (double-click; html.clear in bar.css).
    $bar = & $widget 'bar' './bar.html' 'top_most' $false $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf', 'icons/**/*.png') @(
        [ordered]@{ program = 'taskmgr'; argsRegex = '.*' },
        [ordered]@{ program = 'explorer'; argsRegex = 'ms-settings:.*' },
        $menuPrivilege
    ) @([ordered]@{
        name = 'default'; anchor = 'top_left'; offsetX = '0px'; offsetY = '0px'; width = '100%'; height = "$(Get-BarHeight $cfg)px"
        monitorSelection = [ordered]@{ type = 'all' }
        # Space is kept by GlazeWM's top gap; Zebar's appbar reservation is unreliable
        # with the taskbar hidden, and fighting Explorer over the work area flickers it.
        dockToEdge = [ordered]@{ enabled = $false; edge = 'top'; windowMargin = '0px' }
    })
    # One menu preset per monitor position (Zebar sorts monitors left->right, top->bottom);
    # menu.ahk opens the one under the cursor.
    $menuPresets = foreach ($i in 0..7) {
        [ordered]@{
            name = "m$i"; anchor = 'top_left'; offsetX = '0px'; offsetY = '0px'; width = '100%'; height = '100%'
            monitorSelection = [ordered]@{ type = 'index'; match = $i }
        }
    }
    $menu = & $widget 'menu' './menu.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf', '*.txt', 'thumbs/**/*') @($menuPrivilege) @($menuPresets)
    # The clock's calendar: the same per-monitor presets (c0..c7), transparent, and a click
    # outside the panel closes it. Every panel reads status.json (zebar/omarchy/style.js: a
    # theme change while it was hidden), so *.json is in each one's files.
    $calPresets = foreach ($i in 0..7) {
        [ordered]@{
            name = "c$i"; anchor = 'top_left'; offsetX = '0px'; offsetY = '0px'; width = '100%'; height = '100%'
            monitorSelection = [ordered]@{ type = 'index'; match = $i }
        }
    }
    $calendar = & $widget 'calendar' './calendar.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf') @($menuPrivilege) @($calPresets)
    # The bar's agent usage panel: the calendar's per-monitor presets (u0..u7). Unlike the
    # calendar it reads data files (agents.json, usage-anchor.json), so *.json is included.
    $usagePresets = foreach ($i in 0..7) {
        [ordered]@{
            name = "u$i"; anchor = 'top_left'; offsetX = '0px'; offsetY = '0px'; width = '100%'; height = '100%'
            monitorSelection = [ordered]@{ type = 'index'; match = $i }
        }
    }
    $usage = & $widget 'usage' './usage.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf') @($menuPrivilege) @($usagePresets)
    # The bar's Display and Tailscale panels (Quattro's omarchy.monitor / omarchy.tailscale):
    # the same per-monitor presets, d0..d7 and t0..t7. Both read state files (display.json,
    # tailscale*.json) that menu.ahk / winarchy.ahk write.
    $panelPresets = { param($prefix) foreach ($i in 0..7) {
            [ordered]@{
                name = "$prefix$i"; anchor = 'top_left'; offsetX = '0px'; offsetY = '0px'; width = '100%'; height = '100%'
                monitorSelection = [ordered]@{ type = 'index'; match = $i }
            }
        } }
    $display = & $widget 'display' './display.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf') @($menuPrivilege) @(& $panelPresets 'd')
    $tailscale = & $widget 'tailscale' './tailscale.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.txt', '*.ttf') @($menuPrivilege) @(& $panelPresets 't')
    # The world clock (Omarchy's omarchy.elsewhen): w0..w7. It keeps its cities in localStorage.
    $worldclock = & $widget 'worldclock' './worldclock.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf') @($menuPrivilege) @(& $panelPresets 'w')
    # The bar's Network, Audio and Bluetooth panels (Quattro's omarchy.network / audio /
    # bluetooth): n0..n7, a0..a7, b0..b7. They read state files that winarchy writes.
    $network = & $widget 'network' './network.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf') @($menuPrivilege) @(& $panelPresets 'n')
    $audio = & $widget 'audio' './audio.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf') @($menuPrivilege) @(& $panelPresets 'a')
    $bluetooth = & $widget 'bluetooth' './bluetooth.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf') @($menuPrivilege) @(& $panelPresets 'b')
    # The bar's battery icon on a laptop (Quattro's omarchy.power): p0..p7, reads power.json.
    $power = & $widget 'power' './power.html' 'top_most' $true $true @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf') @($menuPrivilege) @(& $panelPresets 'p')
    [ordered]@{
        '$schema' = 'https://github.com/glzr-io/zebar/raw/v3.0.0/resources/zpack-schema.json'
        name = 'omarchy'; version = '3.0.0'; description = 'Omarchy style top bar, menu and pickers for GlazeWM (winarchy)'
        tags = @('topbar'); previewImages = @(); repositoryUrl = ''
        widgets = @($bar, $menu, $calendar, $usage, $display, $tailscale, $worldclock, $network, $audio, $bluetooth, $power)
    } | ConvertTo-Json -Depth 12
}

# The APPS section of the keybindings viewer follows whichever launchers are active.
# The Print keys as "captureKeys" lays them out (ahk/winarchy.ahk, Capture).
function Get-CaptureKeysText($cfg) {
    $common = @(
        '  Print                         Screenshot (region, Snipping Tool)'
        '  Alt + Print                   Screen recording (Snipping Tool)'
    )
    $layout = if ($cfg.captureKeys -eq 'omarchy') {
        '  Super + Print                 Color picker (click copies #rrggbb)'
        '  Super + Ctrl + Print          Text capture: snip a region, its text is copied (OCR)'
        '  Shift + Print                 Full screenshot saved to Pictures\Screenshots'
    } else {
        '  Super + Print                 Full screenshot saved to Pictures\Screenshots'
        '  Super + Ctrl + Print          Color picker (click copies #rrggbb)'
        '  Super + Shift + Print         Text capture: snip a region, its text is copied (OCR)'
    }
    (@($common) + @($layout)) -join "`n"
}

# Keys your own Startup scripts have are marked "(your script)": winarchy leaves those to
# you. Your own apps list (keybindings-apps.txt, when launchers is off) is yours already.
function Get-KeybindingsText($cfg, $p) {
    $userKeys = @($p.userHotkeys.keys | Where-Object { $_ })
    $txt = (Get-Content -Raw (Join-Path $Code 'default\keybindings.txt')).Replace('{{ capture }}', (Get-CaptureKeysText $cfg).TrimEnd())
    $txt = Add-YieldMarks $txt $userKeys
    $appsFile = Join-Path $Data 'keybindings-apps.txt'
    $section = if (-not $cfg.launchers -and (Test-Path $appsFile)) { Get-Content -Raw $appsFile }
        else { Add-YieldMarks (Get-Content -Raw (Join-Path $Code 'default\keybindings-apps.txt')) $userKeys }
    $txt.Replace('{{ apps }}', $section.TrimEnd())
}

function Write-ZebarPack($p, $cfg) {
    New-Item -ItemType Directory -Force $Pack | Out-Null
    $src = Join-Path $Code 'zebar\omarchy'
    foreach ($f in Get-ChildItem $src -File) { Copy-Item -Force $f.FullName (Join-Path $Pack $f.Name) }
    Write-Utf8 (Join-Path $Pack 'zpack.json') (Get-ZpackJson $p)
    $clock24 = switch ($cfg.clock) { '24h' { $true } '12h' { $false } default { [bool]$p.clock24 } }
    $metric = switch ($cfg.units) { 'C' { $true } 'F' { $false } default { [bool]$p.metric } }
    $envJs = @(
        '// Generated by winarchy apply: machine paths + settings for the bar and menu.'
        "export const AHK = $($p.ahk | ConvertTo-Json);"
        "export const MENU = $((Join-Path $Code 'ahk\menu.ahk') | ConvertTo-Json);"
        "export const CLOCK_24H = $("$clock24".ToLower());"
        "export const METRIC = $("$metric".ToLower());"
        # The background picker plays the wallpaper reveal on its monitor (lib/transition.ps1).
        "export const REVEAL = $("$($cfg.backgroundTransition -ne 'none')".ToLower());"
        # Popups under the bar (calendar) sit barHeight + gap from the top.
        "export const BAR_HEIGHT = $(Get-BarHeight $cfg);"
        "export const GAP = $([int]$cfg.gap);"
    ) -join "`n"
    Write-Utf8 (Join-Path $Pack 'env.js') "$envJs`n"
    Write-Utf8 (Join-Path $Pack 'keybindings.txt') (Get-KeybindingsText $cfg $p)
    # Your own bar/menu CSS overrides survive updates.
    $user = Join-Path $Pack 'user.css'
    if (-not (Test-Path $user)) { Write-Utf8 $user "/* Your bar + menu CSS overrides (kept by winarchy apply/update). */`n" }
    # Zebar's client library is GPL-3.0, so it is fetched (pinned) rather than shipped;
    # it is saved locally so the bar never needs the network at login. A failed download
    # never stops apply (install would end before themes or the daemon): the next apply
    # tries again, and doctor names it meanwhile.
    $mjs = Join-Path $Pack 'zebar.mjs'
    if (-not (Test-Path $mjs)) {
        try { Save-ZebarClient $cfg.zebarClientVersion $Pack }
        catch { Log "Zebar client FAILED: $($_.Exception.Message) (the bar needs it; winarchy apply tries again)" }
    }
    Set-ZebarStartup
}

$ZebarSettings = Join-Path $env:USERPROFILE '.glzr\zebar\settings.json'

# The widgets Zebar opens when it starts, or $null when $cur needs no change. Zebar's own
# first run (settings.json missing) writes its starter bar (glzr-io.starter) as the only
# one: that generic bar then shows instead of winarchy's. So the starter is dropped,
# winarchy's bar comes first, and any other widget the person added stays.
function Get-ZebarStartupConfigs($cur) {
    $all = @($cur.startupConfigs | Where-Object { $_ })
    $keep = @($all | Where-Object { $_.pack -ne 'glzr-io.starter' -and -not ($_.pack -eq 'omarchy' -and $_.widget -eq 'bar') })
    $bar = [ordered]@{ pack = 'omarchy'; widget = 'bar'; preset = 'default' }
    $want = @($bar) + $keep
    $ours = @($all | Where-Object { $_.pack -eq 'omarchy' -and $_.widget -eq 'bar' })
    if ($cur -and $ours.Count -eq 1 -and $all.Count -eq $want.Count) { return $null }
    $want
}

# Writes Zebar's settings.json so it opens winarchy's bar (Get-ZebarStartupConfigs). Apply
# runs it, and install before GlazeWM + Zebar are even installed: with the file already
# there, Zebar never has a first run, so it never sets up its starter bar.
function Set-ZebarStartup {
    $cur = Read-Json $ZebarSettings
    $configs = Get-ZebarStartupConfigs $cur
    if ($null -eq $configs) { return }
    Save-File $ZebarSettings
    Write-Json $ZebarSettings ([ordered]@{
            '$schema' = 'https://github.com/glzr-io/zebar/raw/v3.3.1/resources/settings-schema.json'
            startupConfigs = @($configs)
        })
    if ($cur) { Log "Zebar settings: set to open winarchy's bar (it had $(@($cur.startupConfigs | ForEach-Object { "$($_.pack)/$($_.widget)" }) -join ', '))" }
}

# Fetches Zebar's client as $dir\zebar.mjs. esm.sh serves it as one self-contained file.
# If esm.sh is down or blocked, jsDelivr's build is used instead: that one imports its
# dependencies from "/npm/..." on jsDelivr, so each is saved beside it and the imports are
# pointed at the local copies. Nothing is written until all of it is here.
function Save-ZebarClient([string]$version, [string]$dir, [scriptblock]$fetch = { param($u) Get-WebText $u }) {
    $mjs = Join-Path $dir 'zebar.mjs'
    $bundle = "https://esm.sh/zebar@$version/es2022/zebar.bundle.mjs"
    try {
        Log "downloading Zebar client $bundle"
        $text = & $fetch $bundle
        if ($text -notmatch '\bcreateProvider\b') { throw 'not the Zebar client' }
        Write-Utf8 $mjs $text
        return
    } catch { Log "esm.sh: $($_.Exception.Message); trying jsDelivr" }

    $files = [ordered]@{}   # local name -> text
    $queue = [Collections.Generic.Queue[string]]::new()
    $root = "/npm/zebar@$version/+esm"
    $queue.Enqueue($root)
    $seen = @{ $root = $true }
    while ($queue.Count) {
        $path = $queue.Dequeue()
        if ($files.Count -gt 40) { throw 'jsDelivr: too many dependencies' }
        $text = & $fetch "https://cdn.jsdelivr.net$path"
        foreach ($m in [regex]::Matches($text, '"(/npm/[^"]+)"')) {
            $dep = $m.Groups[1].Value
            if (-not $seen[$dep]) { $seen[$dep] = $true; $queue.Enqueue($dep) }
        }
        $files[$path] = $text
    }
    if ($files[$root] -notmatch '\bcreateProvider\b') { throw 'jsDelivr: not the Zebar client' }
    # Top level, beside zebar.mjs, so the widgets' includeFiles ('*.mjs') already cover them.
    $local = { param($p) 'zebar-dep-' + ($p -replace '^/npm/', '' -replace '/\+esm$', '' -replace '[^A-Za-z0-9.-]', '_') + '.mjs' }
    $relink = { param($text) [regex]::Replace($text, '"(/npm/[^"]+)"', { param($m) '"./' + (& $local $m.Groups[1].Value) + '"' }) }
    # zebar.mjs goes last: it is what apply and doctor check for, so a half-saved set is retried.
    foreach ($path in @($files.Keys | Where-Object { $_ -ne $root })) {
        Write-Utf8 (Join-Path $dir (& $local $path)) (& $relink $files[$path])
    }
    Write-Utf8 $mjs (& $relink $files[$root])
}

function Get-WebText([string]$url) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("winarchy-" + [guid]::NewGuid() + '.part')
    try {
        Invoke-WebRequest $url -OutFile $tmp -TimeoutSec 60 -ErrorAction Stop
        [IO.File]::ReadAllText($tmp, [Text.UTF8Encoding]::new($false))
    } finally { Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue }
}

# --- autostart ----------------------------------------------------------------------
function New-Shortcut([string]$lnk, [string]$target, [string]$arguments, [string]$workDir, [int]$style = 1) {
    $sh = New-Object -ComObject WScript.Shell
    $s = $sh.CreateShortcut($lnk)
    $s.TargetPath = $target; $s.Arguments = $arguments; $s.WorkingDirectory = $workDir; $s.WindowStyle = $style
    $s.Save()
}

function Set-Autostart($p, $cfg) {
    $startup = $p.startup
    $lnk = Join-Path $startup 'winarchy.lnk'
    Save-File $lnk
    New-Shortcut $lnk $p.ahk "`"$Code\ahk\winarchy.ahk`"" "$Code\ahk"
    $shot = Join-Path $startup 'Screenshot to Clipboard.lnk'
    if ($cfg.screenshotAutoCopy) {
        Save-File $shot
        $shotArgs = "--headless `"$($p.powershell)`" -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Code\ps51\screenshot-to-clipboard.ps1`""
        New-Shortcut $shot (Join-Path $env:SystemRoot 'System32\conhost.exe') $shotArgs "$Code\ps51" 7
        # Working now, not from the next login.
        if (-not (Get-ScreenshotWatcher)) {
            Start-Process (Join-Path $env:SystemRoot 'System32\conhost.exe') -ArgumentList $shotArgs -WorkingDirectory "$Code\ps51" -WindowStyle Hidden
        }
    } elseif (Test-Path -LiteralPath $shot) {
        # Turned off: take it out of Startup (journaled, so uninstall puts back one you had
        # before winarchy) and stop the running copy.
        Save-File $shot
        Remove-Item -LiteralPath $shot -Force
        Stop-ScreenshotWatcher
    }
    # GlazeWM at login: the selected build (official, or the animation build).
    $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $want = "`"$($p.glazewm)`""
    if ($p.glazewm -and (Get-ItemProperty $run -ErrorAction SilentlyContinue).GlazeWM -ne $want) {
        Save-Reg $run 'GlazeWM'
        Set-ItemProperty $run -Name GlazeWM -Value $want
    }
}

# --- Windows Terminal profiles for the screensaver and About -------------------------
$ScreensaverProfile = '{5f6a2c1e-7a39-4b1f-9e0d-0a1c2e3f4b51}'
$AboutProfile = '{5f6a2c1e-7a39-4b1f-9e0d-0a1c2e3f4b52}'
$AgentProfile = '{5f6a2c1e-7a39-4b1f-9e0d-0a1c2e3f4b53}'
# Every other terminal winarchy opens (Sign in, Install, Doctor, Update, nvim, TUI apps).
# Pinned to elevate=false: with "Run as administrator" on in Terminal's defaults, a tab on
# the default profile is re-launched elevated, and that path quotes the whole command line
# as one file name (error 0x80070002).
$ShellProfile = '{5f6a2c1e-7a39-4b1f-9e0d-0a1c2e3f4b54}'

# Terminal writes its settings.json the first time it starts. On a PC where it never has
# there is none, and without one the profiles below would be skipped. Start one: Terminal
# adds its own profiles and defaults to it when it starts. Not journaled as a file, so
# uninstall leaves Terminal's later settings alone; the items in it are journaled.
function New-TerminalSettings($p) {
    if (-not $p.wt) { return $null }
    $file = Get-TerminalSettingsTarget
    if (-not $file) { return $null }
    if (-not (Test-Path -LiteralPath $file)) {
        New-Item -ItemType Directory -Force (Split-Path $file) | Out-Null
        Write-Json $file ([ordered]@{ '$schema' = 'https://aka.ms/terminal-profiles-schema'; profiles = [ordered]@{ defaults = [ordered]@{}; list = @() } })
        Log "Windows Terminal: no settings yet, started $file"
    }
    $p.wtSettings = $file
    try { Write-Json $PathsFile $p 6 } catch {}
    $file
}

# A font family Windows has (per-user or machine-wide): Terminal shows an error dialog
# for a face that isn't installed.
function Test-FontInstalled([string]$family) {
    foreach ($key in 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts') {
        $names = (Get-Item $key -ErrorAction SilentlyContinue).Property
        if ($names | Where-Object { $_ -like "$family*" }) { return $true }
    }
    $false
}

function Set-TerminalProfiles($p) {
    $file = $p.wtSettings
    if (-not $file -or -not (Test-Path $file)) { $file = New-TerminalSettings $p }
    if (-not $file) { return }
    $wt = Read-Json $file
    if (-not $wt) { return }
    $defaults = Get-TerminalDefaults $wt
    if (-not $wt.profiles.list) { $wt.profiles | Add-Member -Force -NotePropertyName list -NotePropertyValue @() }
    $font = Get-FontFamily
    # Every tab in the Nerd Font, unless one is set already (winarchy font changes it later):
    # the bar's glyphs and the prompt's icons are boxes in Terminal's own Cascadia.
    if (-not $defaults.font.face -and (Test-FontInstalled $font)) {
        Save-JsonProperty $file 'profiles.defaults.font.face'
        if (-not $defaults.font) { $defaults | Add-Member -Force -NotePropertyName font -NotePropertyValue ([pscustomobject]@{}) }
        $defaults.font | Add-Member -Force -NotePropertyName face -NotePropertyValue $font
    }
    $pwsh = $p.pwsh
    # No ttfx yet (it may still be building in the background): screensaver.ps1 then looks
    # in ~/.cargo/bin, where that build puts it.
    $ttfxArg = if ($p.ttfx) { " -Ttfx `"$($p.ttfx)`"" } else { '' }
    $want = @(
        [ordered]@{
            guid = $ScreensaverProfile; name = 'Omarchy Screensaver'; hidden = $true
            elevate = $false
            commandline = "`"$pwsh`" -NoProfile -ExecutionPolicy Bypass -File `"$Code\lib\screensaver.ps1`" -Text `"$Data\branding\screensaver.txt`"$ttfxArg"
            tabTitle = 'Omarchy Screensaver'; suppressApplicationTitle = $true
            background = '#000000'; opacity = 100; useAcrylic = $false; padding = '0'
            font = [ordered]@{ face = $font; size = 18 }; cursorColor = '#000000'; cursorShape = 'vintage'
            scrollbarState = 'hidden'; bellStyle = 'none'; closeOnExit = 'always'; startingDirectory = $Data
        },
        [ordered]@{
            guid = $AboutProfile; name = 'Omarchy About'; hidden = $true
            elevate = $false
            commandline = "`"$pwsh`" -NoProfile -ExecutionPolicy Bypass -File `"$Code\lib\about.ps1`""
            tabTitle = 'Omarchy About'; suppressApplicationTitle = $true
            padding = '14'; scrollbarState = 'hidden'; bellStyle = 'none'; closeOnExit = 'always'; startingDirectory = $Data
        },
        # Coding agents launched from the menu or the keybinding. Omarchy gives those
        # windows one fixed app-id so window rules can single them out; Windows has no
        # app-id, and every Windows Terminal window is the same process and class, so the
        # stable thing to match on is this title - which winarchy sets itself, so it is
        # not a localized string. Not hidden: it is a profile worth opening by hand.
        [ordered]@{
            guid = $AgentProfile; name = 'Omarchy Agent'
            elevate = $false
            commandline = "`"$pwsh`" -NoLogo -ExecutionPolicy Bypass -Command `"& '$($Code -replace "'", "''")\bin\winarchy.ps1' agent -Inline`""
            tabTitle = 'Omarchy Agent'; suppressApplicationTitle = $true
            font = [ordered]@{ face = $font }; padding = '8'; bellStyle = 'none'
        },
        [ordered]@{
            guid = $ShellProfile; name = 'Omarchy Shell'; hidden = $true
            elevate = $false
            commandline = "`"$pwsh`" -NoLogo"
            font = [ordered]@{ face = $font }; startingDirectory = '%USERPROFILE%'
        }
    )
    $list = @($wt.profiles.list | Where-Object { $_.guid -notin $ScreensaverProfile, $AboutProfile, $AgentProfile, $ShellProfile })
    foreach ($w in $want) { Save-JsonItem $file 'profiles.list' $w.name }
    $wt.profiles.list = @($list) + $want
    if ($pwsh) { Set-TerminalDefaultProfile $file $wt }
    Write-Json $file $wt
}

# New tabs open PowerShell 7, the shell winarchy's profile and commands are set up in -
# but only in place of the default Windows Terminal ships with (Windows PowerShell 5.1),
# or none: WSL, cmd or anything else there was the person's own pick. Done once: whatever
# the default is changed to afterwards stays. Uninstall puts the old default back unless
# it was changed again since.
$WindowsPowerShellProfile = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
$PowerShellCoreProfile = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
function Set-TerminalDefaultProfile([string]$file, $wt) {
    if (Test-Journaled "json|$file|defaultProfile") { return }
    $cur = $wt.defaultProfile
    if ($cur -and $cur -ne $WindowsPowerShellProfile) { return }
    # Windows Terminal adds PowerShell 7 to the list by itself, under the fixed guid (with
    # more than one install, the others get their own). Not listed yet: it is added, with
    # that guid, the next time Terminal starts. Listed but all hidden: the person hid it.
    $core = @($wt.profiles.list | Where-Object { $_.source -eq 'Windows.Terminal.PowershellCore' })
    $shown = @($core | Where-Object { -not $_.hidden })
    if ($core -and -not $shown) { return }
    $guid = if (-not $shown -or $shown.guid -contains $PowerShellCoreProfile) { $PowerShellCoreProfile } else { $shown[0].guid }
    Save-JsonProperty $file 'defaultProfile' $guid
    $wt | Add-Member -Force -NotePropertyName defaultProfile -NotePropertyValue $guid
}

# Omarchy's branding text (Style > Screensaver / About edit these).
function Initialize-Branding {
    $dir = Join-Path $Data 'branding'
    New-Item -ItemType Directory -Force $dir | Out-Null
    foreach ($pair in @(@('screensaver.txt', 'logo.txt'), @('about.txt', 'icon.txt'))) {
        $dst = Join-Path $dir $pair[0]
        $src = Join-Path $Themes "_templates\$($pair[1])"
        if (-not (Test-Path $dst) -and (Test-Path $src)) { Copy-Item $src $dst }
    }
}

# blockMinimize also turns off Aero Shake (dragging a window's title bar shakes it to
# minimize every other window) - the one other built-in way to end up with a minimized
# window besides the ones winarchy.ahk's hook already catches (it fires no minimize
# event of its own to catch; this is Explorer's own setting, restored on uninstall).
function Set-DisallowShaking($cfg) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $want = if ($cfg.blockMinimize -eq $false) { 0 } else { 1 }
    if ((Get-ItemProperty $key -Name DisallowShaking -ErrorAction SilentlyContinue).DisallowShaking -eq $want) { return }
    Save-Reg $key 'DisallowShaking'
    Set-ItemProperty $key -Name DisallowShaking -Value $want -Type DWord
}

# blockMinimize also turns off the minimize/maximize animation: a minimize that does get
# through (an app minimizing itself) is undone by winarchy.ahk, and without the animation
# that's a one-frame blink instead of the window shrinking away and growing back. Turning
# blockMinimize off puts back what was there; so does uninstall.
function Set-MinimizeAnimationPolicy($cfg) {
    $cur = Get-MinimizeAnimation
    if ($cfg.blockMinimize -eq $false) {
        $e = (Read-Journal).entries | Where-Object { $_.key -eq 'minanimate' } | Select-Object -First 1
        if ($e -and $cur -ne [int]$e.value) { Set-MinimizeAnimation ([int]$e.value) }
        return
    }
    if ($cur -eq 0) { return }
    [void](Add-JournalEntry @{ kind = 'minanimate'; key = 'minanimate'; value = $cur })
    Set-MinimizeAnimation 0
    Log 'minimize/maximize animation turned off (blockMinimize)'
}

# Show or hide the desktop icons right now, the way right-click > View > Show desktop icons
# does: that menu item is WM_COMMAND 0x7402 to the desktop's SHELLDLL_DefView, and it only
# toggles, so look at whether the icon list is visible first.
function Set-DesktopIconsVisible([bool]$show) {
    Add-NativeType Desk @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string name);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string name);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
'@
    $view = [Winarchy.Desk]::FindWindowEx([Winarchy.Desk]::FindWindow('Progman', $null), [IntPtr]::Zero, 'SHELLDLL_DefView', $null)
    if ($view -eq [IntPtr]::Zero) {
        $w = [IntPtr]::Zero
        do {
            $w = [Winarchy.Desk]::FindWindowEx([IntPtr]::Zero, $w, 'WorkerW', $null)
            if ($w -ne [IntPtr]::Zero) { $view = [Winarchy.Desk]::FindWindowEx($w, [IntPtr]::Zero, 'SHELLDLL_DefView', $null) }
        } while ($w -ne [IntPtr]::Zero -and $view -eq [IntPtr]::Zero)
    }
    if ($view -eq [IntPtr]::Zero) { return }
    $list = [Winarchy.Desk]::FindWindowEx($view, [IntPtr]::Zero, 'SysListView32', $null)
    if ($list -eq [IntPtr]::Zero -or [Winarchy.Desk]::IsWindowVisible($list) -eq $show) { return }
    [void][Winarchy.Desk]::PostMessage($view, 0x111, [IntPtr]0x7402, [IntPtr]::Zero)
}

# hideDesktopIcons (on for a new install): Explorer's "Show desktop icons" off. What the PC
# had is kept in the journal; turning it off here, or uninstalling, puts that back.
function Set-DesktopIconsPolicy($cfg) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $cur = [int](Get-ItemProperty $key -Name HideIcons -ErrorAction SilentlyContinue).HideIcons
    $e = (Read-Journal).entries | Where-Object { $_.key -eq 'deskicons' } | Select-Object -First 1
    if ($cfg.hideDesktopIcons -eq $true) {
        if (-not $e) { [void](Add-JournalEntry @{ kind = 'deskicons'; key = 'deskicons'; hidden = $cur }) }
        if ($cur -ne 1) { Set-ItemProperty $key -Name HideIcons -Value 1 -Type DWord }
        Set-DesktopIconsVisible $false
        return
    }
    if ($e -and $cur -ne [int]$e.hidden) {
        Set-ItemProperty $key -Name HideIcons -Value ([int]$e.hidden) -Type DWord
        Set-DesktopIconsVisible ([int]$e.hidden -eq 0)
    }
}

# The Omarchy screensaver replaces Windows' own (restored on uninstall).
function Set-WindowsScreensaver($cfg) {
    if (-not $cfg.screensaver.enabled) { return }
    $key = 'HKCU:\Control Panel\Desktop'
    $d = Get-ItemProperty $key
    if ($d.ScreenSaveActive -eq '0' -and -not $d.'SCRNSAVE.EXE') { return }
    Save-Reg $key 'ScreenSaveActive'
    Save-Reg $key 'SCRNSAVE.EXE'
    # SPI_SETSCREENSAVEACTIVE is refused on some builds (error 329), so switch it off in the
    # registry and drop the .scr path: Windows reads that when the screensaver would start.
    Set-ItemProperty $key -Name ScreenSaveActive -Value '0'
    Remove-ItemProperty $key -Name 'SCRNSAVE.EXE' -ErrorAction SilentlyContinue
    Initialize-Native
    [void][Winarchy.Native]::SystemParametersInfoInt(0x11, 0, [IntPtr]::Zero, 3)
    Log 'Windows screensaver turned off (the Omarchy one takes over)'
}

# --- restart what changed ---------------------------------------------------------
# AutoHotkey scripts of this project (never the user's own scripts elsewhere).
function Get-OmarchyAhk {
    # Our folders by any name: a script started through the pre-rename junctions
    # (omarchy-win) is the same script, and missing it leaves two copies running.
    $roots = foreach ($d in $Code, $Data) {
        $d
        try { $t = (Get-Item -LiteralPath $d -Force).LinkTarget; if ($t) { $t } } catch {}
        foreach ($alt in ($d -replace 'omarchy-win$', 'winarchy'), ($d -replace '(?<!omarchy-)winarchy$', 'omarchy-win')) {
            if ($alt -ne $d -and (Test-Path -LiteralPath $alt)) { $alt }
        }
    }
    Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" | Where-Object {
        $cmd = $_.CommandLine
        $cmd -match '(winarchy|menu|launchers)\.ahk' -and ($roots | Where-Object { $cmd -like "*$_\*" })
    }
}

function Restart-OmarchyAhk($p) {
    # Force-stop: the new instance takes over hiding the taskbar without it flashing.
    Get-OmarchyAhk | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-InteractiveProcess -FilePath $p.ahk -ArgumentList "`"$Code\ahk\winarchy.ahk`"" -WorkingDirectory "$Code\ahk"
}

function Stop-Zebar {
    Get-Process zebar -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-CimInstance Win32_Process -Filter "Name='msedgewebview2.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*com.glzr.zebar*" -or $_.CommandLine -like "*zebar\webview-cache*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Restart-Bar($p) {
    try { Set-ZebarStartup } catch {}
    Stop-Zebar
    Start-Sleep -Milliseconds 800
    if (-not $p.zebar) { return }
    # Zebar attaches to its parent's console: started from here it would log into this
    # terminal (winarchy update) and die when the tab closes. AutoHotkey has no console.
    if ($p.ahk) { Start-InteractiveProcess -FilePath $p.ahk -ArgumentList "`"$Code\ahk\menu.ahk`"", 'bar-start' }
    else { Start-Hidden $p.zebar @('startup') }
}

# Sets the open bar windows to $height px (scaled by each one's monitor DPI the way Zebar
# scales them: truncated), where they are. The page fills its window, so it follows.
function Resize-BarWindows([int]$height) {
    if (-not ('Winarchy.BarWindows' -as [type])) {
        Add-Type -Namespace Winarchy -Name BarWindows -MemberDefinition @'
delegate bool EnumProc(IntPtr h, IntPtr l);
[DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr l);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int n);
[DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] static extern uint GetDpiForWindow(IntPtr h);
[DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
struct RECT { public int L, T, R, B; }
public static int Resize(uint[] zebarPids, int height) {
    // Physical pixels, like Zebar's own placement (per-monitor aware v2).
    IntPtr old = SetThreadDpiAwarenessContext(new IntPtr(-4));
    int n = 0;
    try {
        EnumWindows((h, l) => {
            uint pid; GetWindowThreadProcessId(h, out pid);
            if (Array.IndexOf(zebarPids, pid) < 0) return true;
            var t = new System.Text.StringBuilder(64); GetWindowText(h, t, 64);
            if (t.ToString() != "Zebar - omarchy / bar") return true;
            uint dpi = GetDpiForWindow(h); if (dpi == 0) dpi = 96;
            RECT r; GetWindowRect(h, out r);
            int want = (int)(height * dpi / 96.0);
            if (r.B - r.T != want && SetWindowPos(h, IntPtr.Zero, 0, 0, r.R - r.L, want, 0x0216)) n++;  // NOMOVE|NOZORDER|NOACTIVATE|NOOWNERZORDER
            return true;
        }, IntPtr.Zero);
    } finally { if (old != IntPtr.Zero) SetThreadDpiAwarenessContext(old); }
    return n;
}
'@
    }
    $pids = [uint32[]]@(Get-Process zebar -ErrorAction SilentlyContinue | ForEach-Object Id)
    if (-not $pids) { return 0 }
    [Winarchy.BarWindows]::Resize($pids, $height)
}

# The bar's height changed (text size): GlazeWM's strip for it, winarchy.ini and Zebar's
# settings follow, and the open bars are resized where they are. Nothing restarts, so the
# bar never goes away. Zebar holds its widget settings in memory until it restarts, so it
# may reopen a bar at the old height (a monitor change): winarchy.ahk reads winarchy.ini
# again and puts it back (BarGuard).
function Update-BarHeight {
    $p = Get-Paths
    $cfg = Get-Config
    Write-ZebarPack $p $cfg
    Write-AhkIni $p $cfg
    $old = if (Test-Path $GlazeConfig) { Get-Content -Raw $GlazeConfig } else { '' }
    $monitors = Get-LayoutMonitorCount @($p.monitors).Count (Get-BoundMonitorCount $old)
    if ((Write-GlazeConfig $monitors) -and $p.glazewmCli -and (Get-GlazeWmProcess)) {
        & $p.glazewmCli command wm-reload-config | Out-Null
    }
    $height = Get-BarHeight $cfg
    $n = try { Resize-BarWindows $height } catch { Log "bar resize FAILED: $($_.Exception.Message)"; 0 }
    Log "bar height ${height}px ($n bar window(s) resized in place)"
}

function Invoke-Apply([switch]$MonitorsOnly, [switch]$NoRestart, [switch]$Resplit) {
    Invoke-ConfigMigration
    $p = Update-Paths
    $cfg = Get-Config
    $old = if (Test-Path $GlazeConfig) { Get-Content -Raw $GlazeConfig } else { '' }
    $monitors = Get-LayoutMonitorCount @($p.monitors).Count (Get-BoundMonitorCount $old) -Resplit:$Resplit
    $glazeChanged = Write-GlazeConfig $monitors
    if ($p.glazewmCli -and (Get-GlazeWmProcess)) {
        if ($glazeChanged) { & $p.glazewmCli command wm-reload-config | Out-Null }
        if ($cfg.glazewmManaged -ne $false) {
            try { Repair-WorkspaceMonitors $p.glazewmCli (Get-WorkspaceBindings (Get-Content -Raw $GlazeConfig)) }
            catch { Log "workspaces: repair FAILED: $($_.Exception.Message)" }
        }
    }
    if ($MonitorsOnly) { return }
    Initialize-Branding
    # Profiles first: the ini names Omarchy Shell only once it exists.
    try { Set-TerminalProfiles $p } catch { Log "terminal profiles FAILED: $($_.Exception.Message)" }
    Write-AhkIni $p $cfg
    try { Write-WebAppIni $p } catch { Log "web app keys FAILED: $($_.Exception.Message)" }
    Write-ZebarPack $p $cfg
    # Window animations on/off switches between the official GlazeWM and the animation build.
    Switch-GlazeWM $p -NoRestart:$NoRestart
    Set-Autostart $p $cfg
    Set-WindowsScreensaver $cfg
    try { Set-DisallowShaking $cfg } catch { Log "Aero Shake setting FAILED: $($_.Exception.Message)" }
    try { Set-MinimizeAnimationPolicy $cfg } catch { Log "minimize animation setting FAILED: $($_.Exception.Message)" }
    try { Set-DesktopIconsPolicy $cfg } catch { Log "desktop icons setting FAILED: $($_.Exception.Message)" }
    if (-not (Test-Path (Join-Path $Pack 'font.css'))) { Write-FontCss }
    try { [void](Update-FontList) } catch { Log "font list FAILED: $($_.Exception.Message)" }
    # Terminal apps' Start entries first, so the Apps list below has them.
    try { Sync-TuiShortcuts } catch { Log "terminal app shortcuts FAILED: $($_.Exception.Message)" }
    try { [void](Update-AppList) } catch { Log "app list FAILED: $($_.Exception.Message)" }
    try { [void](Update-Catalog) } catch { Log "catalog FAILED: $($_.Exception.Message)" }
    try { [void](Update-AgentList) } catch { Log "agent list FAILED: $($_.Exception.Message)" }
    # Extra agent accounts: folders, links into the primary home, the profile functions.
    try { Repair-AgentAccounts } catch { Log "agent accounts FAILED: $($_.Exception.Message)" }
    # Re-merge the usage records already on disk (no collectors, no network): turning an
    # agent off in config.json takes it off the bar at once, not at the next refresh.
    try { [void](Write-AgentUsageFile (Get-Config)) } catch { Log "agent usage FAILED: $($_.Exception.Message)" }
    # Herdr's config, shell shortcuts and keybindings list, when it is installed at all.
    try { Initialize-Herdr } catch { Log "herdr FAILED: $($_.Exception.Message)" }
    # The pickers' index.json format follows the code, so rebuild it here too (not only on sync).
    try { Update-Index } catch { Log "picker index FAILED: $($_.Exception.Message)" }
    try { Write-MenuFlags } catch { Log "menu flags FAILED: $($_.Exception.Message)" }
    if (-not (Test-Path (Join-Path $Pack 'theme.css'))) {
        try { Set-BarTheme (Read-Colors (Read-State).theme) } catch { Log "no theme yet: $($_.Exception.Message)" }
    }
    # So an install from before Omarchy's apps came to Windows has the file they read too.
    try { Set-OmarchyStateTheme (Read-State).theme } catch { Log "Omarchy apps' theme FAILED: $($_.Exception.Message)" }
    Write-Status (Read-State)
    if (-not $NoRestart) {
        Restart-Bar $p
        Restart-OmarchyAhk $p
    }
    Log "applied: $monitors monitor(s), AutoHotkey $($p.ahk), browser $($p.browserName)"
}

# menu-flags.json: what this PC has, for the menu rows Omarchy shows only `when` it does
# (Hibernate, the laptop display and touchpad rows).
function Write-MenuFlags {
    $power = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -ErrorAction SilentlyContinue
    Write-Json (Join-Path $Pack 'menu-flags.json') ([ordered]@{
        laptop = [bool](Get-Paths).battery
        hibernate = [int]$power.HibernateEnabled -eq 1
    })
}
