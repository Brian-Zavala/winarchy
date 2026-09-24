# omarchy-win apply: renders every generated file from templates + config.json +
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

function Write-GlazeConfig([int]$monitorCount) {
    $cfg = Get-Config
    if ($cfg.glazewmManaged -eq $false) { Log 'GlazeWM config: not managed (glazewmManaged=false)'; return $false }
    $tplFile = Join-Path $Data 'glazewm.yaml.tpl'
    if (-not (Test-Path $tplFile)) { $tplFile = Join-Path $Code 'templates\glazewm.yaml.tpl' }
    $old = if (Test-Path $GlazeConfig) { Get-Content -Raw $GlazeConfig } else { '' }
    # Keep what the toggles/theme last set: gaps on/off and the focused border colour.
    $gap = [int]$cfg.gap
    if ($old -match "inner_gap:\s*'0px'\s*# gaps") { $gap = 0 }
    $border = if ($old -match "color:\s*'(#[0-9A-Fa-f]{6})'\s*# theme:focused-border") { $Matches[1] } else {
        try { (Read-Colors (Read-State).theme).accent } catch { '#7aa2f7' }
    }
    $values = @{
        gap = "$gap"; focused_border = $border
        workspaces = ConvertTo-WorkspacesYaml (Get-WorkspaceLayout $monitorCount $cfg.workspaces)
    }
    $yaml = Expand-Template (Get-Content -Raw $tplFile) $values
    if ($yaml -eq $old) { return $false }
    if ($old) { Save-File $GlazeConfig }
    Write-Utf8 $GlazeConfig $yaml
    Log "GlazeWM config written ($monitorCount monitor(s))"
    $true
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
    $ini = [ordered]@{
        paths  = [ordered]@{
            code = $Code; data = $Data; pack = $Pack; log = $LogFile; glazeConfig = $GlazeConfig
            ahk = $p.ahk; pwsh = $p.pwsh; powershell = $p.powershell
            glazewm = $p.glazewm; glazewmCli = $p.glazewmCli; zebar = $p.zebar; flow = $p.flow
            terminal = $terminal; wt = $p.wt; editor = $editor; files = $cfg.apps.files
            browser = $browser; browserPrivate = $p.browserPrivate
        }
        config = [ordered]@{
            flowHotkey = $p.flowHotkey
            takeOverWinSpace = [int][bool]$cfg.takeOverWinSpace
            launchers = [int][bool]$cfg.launchers
            hideTaskbar = [int][bool]$cfg.hideTaskbar
            gap = [int]$cfg.gap
            syncAtLogin = [int][bool]$cfg.syncAtLogin
        }
    }
    $text = foreach ($section in $ini.Keys) {
        "[$section]"
        foreach ($k in $ini[$section].Keys) { "$k=$($ini[$section][$k])" }
        ''
    }
    New-Item -ItemType Directory -Force $Generated | Out-Null
    [IO.File]::WriteAllLines((Join-Path $Generated 'omarchy.ini'), [string[]]$text, [Text.UnicodeEncoding]::new($false, $true))
}

# --- Zebar pack ---------------------------------------------------------------------
function Get-ZpackJson($p) {
    $ahk = $p.ahk
    $menuPrivilege = [ordered]@{ program = $ahk; argsRegex = '.*menu\.ahk.*' }
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
    $bar = & $widget 'bar' './bar.html' 'top_most' $false $false @('*.html', '*.css', '*.mjs', '*.js', '*.json', '*.ttf') @(
        [ordered]@{ program = 'taskmgr'; argsRegex = '.*' },
        [ordered]@{ program = 'explorer'; argsRegex = 'ms-settings:.*' },
        $menuPrivilege
    ) @([ordered]@{
        name = 'default'; anchor = 'top_left'; offsetX = '0px'; offsetY = '0px'; width = '100%'; height = '26px'
        monitorSelection = [ordered]@{ type = 'all' }
        # Space is reserved by omarchy-wm.ahk (work area), not Zebar's appbar.
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
    [ordered]@{
        '$schema' = 'https://github.com/glzr-io/zebar/raw/v3.0.0/resources/zpack-schema.json'
        name = 'omarchy'; version = '3.0.0'; description = 'Omarchy style top bar, menu and pickers for GlazeWM (omarchy-win)'
        tags = @('topbar'); previewImages = @(); repositoryUrl = ''
        widgets = @($bar, $menu)
    } | ConvertTo-Json -Depth 12
}

# The APPS section of the keybindings viewer follows whichever launchers are active.
function Get-KeybindingsText($cfg) {
    $txt = Get-Content -Raw (Join-Path $Code 'default\keybindings.txt')
    $apps = Join-Path $Data 'keybindings-apps.txt'
    $section = if (-not $cfg.launchers -and (Test-Path $apps)) { Get-Content -Raw $apps } else { Get-Content -Raw (Join-Path $Code 'default\keybindings-apps.txt') }
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
        '// Generated by omarchy-win apply: machine paths + settings for the bar and menu.'
        "export const AHK = $($p.ahk | ConvertTo-Json);"
        "export const MENU = $((Join-Path $Code 'ahk\menu.ahk') | ConvertTo-Json);"
        "export const CLOCK_24H = $("$clock24".ToLower());"
        "export const METRIC = $("$metric".ToLower());"
    ) -join "`n"
    Write-Utf8 (Join-Path $Pack 'env.js') "$envJs`n"
    Write-Utf8 (Join-Path $Pack 'keybindings.txt') (Get-KeybindingsText $cfg)
    # Your own bar/menu CSS overrides survive updates.
    $user = Join-Path $Pack 'user.css'
    if (-not (Test-Path $user)) { Write-Utf8 $user "/* Your bar + menu CSS overrides (kept by omarchy-win apply/update). */`n" }
    # Zebar's client library is GPL-3.0, so it is fetched (pinned) rather than shipped;
    # it is saved locally so the bar never needs the network at login.
    $mjs = Join-Path $Pack 'zebar.mjs'
    if (-not (Test-Path $mjs)) {
        $url = "https://esm.sh/zebar@$($cfg.zebarClientVersion)/es2022/zebar.bundle.mjs"
        Log "downloading Zebar client $url"
        Invoke-WebRequest $url -OutFile "$mjs.part" -TimeoutSec 60
        Move-Item -Force "$mjs.part" $mjs
    }
    $settings = Join-Path $env:USERPROFILE '.glzr\zebar\settings.json'
    $want = [ordered]@{
        '$schema' = 'https://github.com/glzr-io/zebar/raw/v3.3.1/resources/settings-schema.json'
        startupConfigs = @([ordered]@{ pack = 'omarchy'; widget = 'bar'; preset = 'default' })
    }
    $cur = Read-Json $settings
    if (-not $cur -or -not ($cur.startupConfigs | Where-Object { $_.pack -eq 'omarchy' -and $_.widget -eq 'bar' })) {
        if ($cur) { Save-File $settings }
        Write-Json $settings $want
    }
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
    $lnk = Join-Path $startup 'omarchy-wm.lnk'
    Save-File $lnk
    New-Shortcut $lnk $p.ahk "`"$Code\ahk\omarchy-wm.ahk`"" "$Code\ahk"
    $shot = Join-Path $startup 'Screenshot to Clipboard.lnk'
    if ($cfg.screenshotAutoCopy) {
        Save-File $shot
        New-Shortcut $shot (Join-Path $env:SystemRoot 'System32\conhost.exe') "--headless `"$($p.powershell)`" -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Code\ps51\screenshot-to-clipboard.ps1`"" "$Code\ps51" 7
    }
    $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if ($p.glazewm -and -not ((Get-ItemProperty $run -ErrorAction SilentlyContinue).PSObject.Properties.Name -contains 'GlazeWM')) {
        Save-Reg $run 'GlazeWM'
        Set-ItemProperty $run -Name GlazeWM -Value "`"$($p.glazewm)`""
    }
}

# --- restart what changed ---------------------------------------------------------
# AutoHotkey scripts of this project (never the user's own scripts elsewhere).
function Get-OmarchyAhk {
    Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" | Where-Object {
        $_.CommandLine -match '(omarchy-wm|menu|launchers)\.ahk' -and
        ($_.CommandLine -like "*$Code*" -or $_.CommandLine -like "*$Data*")
    }
}

function Restart-OmarchyAhk($p) {
    # Force-stop: the new instance takes over hiding the taskbar without it flashing.
    Get-OmarchyAhk | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Process -FilePath $p.ahk -ArgumentList "`"$Code\ahk\omarchy-wm.ahk`"" -WorkingDirectory "$Code\ahk"
}

function Restart-Bar($p) {
    Get-Process zebar -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 800
    if ($p.zebar) { Start-Hidden $p.zebar @('startup') }
}

function Invoke-Apply([switch]$MonitorsOnly, [switch]$NoRestart) {
    $p = Update-Paths
    $cfg = Get-Config
    $monitors = @($p.monitors).Count
    $glazeChanged = Write-GlazeConfig $monitors
    if ($glazeChanged -and $p.glazewmCli -and (Get-Process glazewm -ErrorAction SilentlyContinue)) {
        & $p.glazewmCli command wm-reload-config | Out-Null
    }
    if ($MonitorsOnly) { return }
    Write-AhkIni $p $cfg
    Write-ZebarPack $p $cfg
    Set-Autostart $p $cfg
    if (-not (Test-Path (Join-Path $Pack 'theme.css'))) {
        try { Set-BarTheme (Read-Colors (Read-State).theme) } catch { Log "no theme yet: $($_.Exception.Message)" }
    }
    Write-Status (Read-State)
    if (-not $NoRestart) {
        Restart-Bar $p
        Restart-OmarchyAhk $p
    }
    Log "applied: $monitors monitor(s), AutoHotkey $($p.ahk), browser $($p.browserName)"
}
