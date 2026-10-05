# More theme targets, after Omarchy v4's bin/omarchy-theme-set-{vscode,claude,browser}
# and its btop template. Each returns 'skipped' when its app isn't on this PC.

# --- VS Code ----------------------------------------------------------------------
# settings.json is JSONC (comments allowed), so one key is edited as text.
function Set-JsoncString([string]$file, [string]$key, [string]$value) {
    $text = if (Test-Path $file) { "$(Get-Content -Raw $file)" } else { '' }
    $json = ($value | ConvertTo-Json)   # quoted + escaped
    # Not after a // on its line: a commented-out copy of the key is left as it is.
    $pattern = '(?m)^((?:(?!//).)*?"' + [regex]::Escape($key) + '"\s*:\s*)"(?:[^"\\]|\\.)*"'
    if ($text -match $pattern) {
        $new = [regex]::Replace($text, $pattern, { param($m) $m.Groups[1].Value + $json }, 1)
    } elseif ($text -match '^\s*\{\s*\}\s*$' -or -not $text.Trim()) {
        $new = "{`n    `"$key`": $json`n}`n"
    } else {
        # The first { that starts a line: the file may open with a comment.
        $new = [regex]::Replace($text, '(?m)^(\s*)\{', { param($m) $m.Groups[1].Value + "{`n    `"$key`": $json," }, 1)
    }
    if ($new -ne $text) { Write-Utf8 $file $new }
}

function Get-JsoncString([string]$file, [string]$key) {
    if (-not (Test-Path $file)) { return $null }
    $m = [regex]::Match("$(Get-Content -Raw $file)", '(?m)^(?:(?!//).)*?"' + [regex]::Escape($key) + '"\s*:\s*"((?:[^"\\]|\\.)*)"')
    if ($m.Success) { $m.Groups[1].Value | ForEach-Object { ('"' + $_ + '"') | ConvertFrom-Json } } else { $null }
}

function Install-VSCodeLocalTheme($c) {
    $root = Join-Path $env:USERPROFILE '.vscode\extensions'
    $dir = Join-Path $root 'local.omarchy-theme-1.0.0'
    $tpl = Join-Path $Themes '_templates\vscode-theme.json.tpl'
    if (-not (Test-Path $tpl)) { throw 'vscode-theme.json.tpl missing: run winarchy sync' }
    Save-Dir $dir
    $ui = if ($c.mode -eq 'light') { 'vs' } else { 'vs-dark' }
    Write-Utf8 (Join-Path $dir 'themes\omarchy-color-theme.json') (Expand-Template (Get-Content -Raw $tpl) $c)
    Write-Json (Join-Path $dir 'package.json') ([ordered]@{
        name = 'omarchy-theme'; displayName = 'Omarchy'; description = 'Omarchy color theme (winarchy)'
        publisher = 'local'; version = '1.0.0'; engines = @{ vscode = '^1.70.0' }; categories = @('Themes')
        contributes = @{ themes = @([ordered]@{ label = 'Omarchy'; uiTheme = $ui; path = './themes/omarchy-color-theme.json' }) }
    })
    # Register it the way VS Code does for its own installs.
    $list = Join-Path $root 'extensions.json'
    $items = @(Read-Json $list | Where-Object { $_ -and $_.identifier.id -ne 'local.omarchy-theme' })
    $fwd = $dir -replace '\\', '/'   # VS Code stores "/c:/Users/..."
    $items += [ordered]@{
        identifier = @{ id = 'local.omarchy-theme' }; version = '1.0.0'
        location = [ordered]@{ '$mid' = 1; path = '/' + $fwd.Substring(0, 1).ToLower() + $fwd.Substring(1); scheme = 'file' }
        relativeLocation = 'local.omarchy-theme-1.0.0'
    }
    Save-File $list
    Write-Json $list @($items) 12
}

function Set-VSCodeTheme([string]$theme, $c) {
    $p = Get-Paths
    if (-not $p.vscode -or -not (Test-Path (Split-Path $p.vscodeSettings))) { return 'skipped' }
    $desc = Read-Json (Join-Path $Themes "$theme\vscode.json")
    if ($desc -and $desc.name -and $desc.extension -match '^[A-Za-z0-9._-]+$') {
        $name = $desc.name
        $root = Join-Path $env:USERPROFILE '.vscode\extensions'
        if (-not (Get-ChildItem $root -Directory -Filter "$($desc.extension)-*" -ErrorAction SilentlyContinue)) {
            Log "VS Code: installing theme extension $($desc.extension)"
            & $p.vscode --install-extension $desc.extension --force 2>&1 | Out-Null
        }
    } else {
        # Themes without a VS Code theme get Omarchy's generated one.
        Install-VSCodeLocalTheme $c
        $name = 'Omarchy'
    }
    Save-JsoncProperty $p.vscodeSettings 'workbench.colorTheme'
    Set-JsoncString $p.vscodeSettings 'workbench.colorTheme' $name
}

# --- Claude Code ------------------------------------------------------------------
# Claude Code watches ~/.claude/themes and re-reads a changed theme file live.
function Set-ClaudeTheme($c) {
    $dir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
    $tpl = Join-Path $Themes '_templates\claude.json.tpl'
    if (-not (Test-Path $dir) -or -not (Test-Path $tpl)) { return 'skipped' }
    $file = Join-Path $dir 'themes\omarchy.json'
    Save-File $file
    Write-Utf8 $file (Expand-Template (Get-Content -Raw $tpl) $c)
    $settings = Join-Path $dir 'settings.json'
    $s = Read-Json $settings
    if (-not $s) {
        # There but not parsing (half-written, or mid-save): left alone, since writing
        # only the theme would drop everything else in it.
        if ("$(Get-Content -Raw $settings -ErrorAction SilentlyContinue)".Trim()) { Log "Claude: $settings did not parse, theme left as it is"; return 'skipped' }
        $s = [pscustomobject]@{}
    }
    if ($s.theme -ne 'custom:omarchy') {
        Save-JsonProperty $settings 'theme'
        $s | Add-Member -Force -NotePropertyName theme -NotePropertyValue 'custom:omarchy'
        Write-Json $settings $s
    }
}

# --- Chromium browsers ------------------------------------------------------------
# BrowserThemeColor policy (Chrome/Brave then show "Managed by your organization").
# Policies are admin-only: an elevated task, set up once, applies the color (see
# ps51/browser-policy.ps1 for why that is safe).
# Set up under the old name (omarchy-win) before the rename: the admin-created task and
# folder keep working as they are (re-creating them would need another UAC prompt).
# Looked up on first use through the Task Scheduler COM API (~30 ms), not
# Get-ScheduledTask (~800 ms to load its module): every CLI call dot-sources this file.
# Returns @{ path; name; dir; task }, task = $null when it isn't registered.
function Get-BrowserTask {
    if ($script:BrowserTaskInfo) { return $script:BrowserTaskInfo }
    $info = @{ path = '\winarchy\'; name = 'browser-color'; dir = Join-Path $env:ProgramData 'winarchy'; task = $null }
    try {
        $svc = New-Object -ComObject Schedule.Service
        $svc.Connect()
        foreach ($n in 'winarchy', 'omarchy-win') {
            try { $task = $svc.GetFolder("\$n").GetTask('browser-color') } catch { continue }
            $info = @{ path = "\$n\"; name = 'browser-color'; dir = Join-Path $env:ProgramData $n; task = $task }
            break
        }
    } catch {}
    ($script:BrowserTaskInfo = $info)
}

function Test-ChromiumInstalled {
    [bool](@("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
             "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe") |
        Where-Object { Test-Path $_ })
}
function Test-BrowserTask { [bool](Get-BrowserTask).task }

function Invoke-BrowserTask([string]$color) {
    Write-Utf8 (Join-Path $Generated 'browser-color.txt') $color
    $task = (Get-BrowserTask).task
    if (-not $task) { throw 'the browser color task is not set up' }
    [void]$task.Run($null)
}

# One UAC prompt: admin-owned copy of the helper + a task this user may start.
function Enable-BrowserPolicy {
    if (-not (Test-ChromiumInstalled)) { Log 'no Chrome/Brave found: nothing to set up'; return }
    $p = Get-Paths
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $src = Join-Path $Code 'ps51\browser-policy.ps1'
    $bt = Get-BrowserTask
    $script = @"
`$ErrorActionPreference = 'Stop'
`$dir = $(ConvertTo-PsLiteral $bt.dir)
New-Item -ItemType Directory -Force `$dir | Out-Null
icacls `$dir /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
Copy-Item -Force $(ConvertTo-PsLiteral $src) (Join-Path `$dir 'browser-policy.ps1')
icacls (Join-Path `$dir 'browser-policy.ps1') /reset | Out-Null
`$ps = Join-Path `$env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
`$action = New-ScheduledTaskAction -Execute `$ps -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + (Join-Path `$dir 'browser-policy.ps1') + '"')
`$principal = New-ScheduledTaskPrincipal -UserId '$sid' -LogonType Interactive -RunLevel Highest
`$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskPath '$($bt.path)' -TaskName '$($bt.name)' -Action `$action -Principal `$principal -Settings `$settings -Force | Out-Null
`$svc = New-Object -ComObject Schedule.Service; `$svc.Connect()
`$svc.GetFolder('$($bt.path.TrimEnd([char]92))').GetTask('$($bt.name)').SetSecurityDescriptor('D:(A;;FA;;;BA)(A;;FA;;;SY)(A;;GRGX;;;$sid)', 0)
"@
    $tmp = Join-Path $env:TEMP 'omarchy-browser-setup.ps1'
    Set-Content -Encoding UTF8 $tmp $script
    Write-Host 'Windows will ask for admin permission once (browser policies are admin-only).'
    Start-Process $p.powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmp`""
    Remove-Item $tmp -ErrorAction SilentlyContinue
    $script:BrowserTaskInfo = $null   # look again
    if (-not (Test-BrowserTask)) { throw 'the browser color task was not created (permission declined?)' }
    [void](Add-JournalEntry @{ kind = 'browsertask'; key = 'browsertask'; dir = $bt.dir })
    Log 'browser color: ready'
    Set-BrowserTheme (Read-State).theme (Read-Colors (Read-State).theme)
}

function Disable-BrowserPolicy {
    if (Test-BrowserTask) {
        $bt = Get-BrowserTask
        try { Invoke-BrowserTask 'none'; Start-Sleep -Seconds 3 } catch {}
        $script = "Unregister-ScheduledTask -TaskPath '$($bt.path)' -TaskName '$($bt.name)' -Confirm:`$false; Remove-Item -Recurse -Force $(ConvertTo-PsLiteral $bt.dir) -ErrorAction SilentlyContinue"
        # -EncodedCommand, as Disable-GameHelper: quotes in a -Command "..." don't survive RunAs.
        Start-Process (Get-Paths).powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $(ConvertTo-EncodedCommand $script)"
        $script:BrowserTaskInfo = $null
    }
}

# --- Admin game helper (ahk\game-helper.ahk) ------------------------------------------
# Games set to "Run as administrator" are out of reach of winarchy.ahk and GlazeWM
# (no keys while one is in front, no closing it). One UAC prompt sets up an
# admin-only copy of AutoHotkey + the helper and a task that starts it at login with
# the highest privileges. Admin-only folder: nothing user-writable runs elevated.
function Get-GameHelper {
    $dir = Join-Path $env:ProgramData 'winarchy-games'
    $task = $null
    try {
        $svc = New-Object -ComObject Schedule.Service
        $svc.Connect()
        $task = $svc.GetFolder('\winarchy').GetTask('game-helper')
    } catch {}
    @{ path = '\winarchy\'; name = 'game-helper'; dir = $dir; task = $task
       script = Join-Path $dir 'game-helper.ahk'; source = Join-Path $Code 'ahk\game-helper.ahk' }
}

# The installed copy is older than the repo's (after winarchy update): game-setup again.
function Test-GameHelperCurrent {
    $gh = Get-GameHelper
    $gh.task -and (Test-Path $gh.script) -and
        (Get-FileHash $gh.script).Hash -eq (Get-FileHash $gh.source).Hash
}

function Enable-GameHelper {
    $p = Get-Paths
    if (-not $p.ahk) { throw 'AutoHotkey was not found (winarchy doctor)' }
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $gh = Get-GameHelper
    $script = @"
`$ErrorActionPreference = 'Stop'
`$dir = $(ConvertTo-PsLiteral $gh.dir)
Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" | Where-Object { `$_.CommandLine -like "*`$dir*" } | ForEach-Object { Stop-Process -Id `$_.ProcessId -Force }
New-Item -ItemType Directory -Force `$dir | Out-Null
icacls `$dir /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
Copy-Item -Force $(ConvertTo-PsLiteral $p.ahk) (Join-Path `$dir 'AutoHotkey64.exe')
Copy-Item -Force $(ConvertTo-PsLiteral $gh.source) (Join-Path `$dir 'game-helper.ahk')
foreach (`$f in 'AutoHotkey64.exe', 'game-helper.ahk') { icacls (Join-Path `$dir `$f) /reset | Out-Null }
`$action = New-ScheduledTaskAction -Execute (Join-Path `$dir 'AutoHotkey64.exe') -Argument ('"' + (Join-Path `$dir 'game-helper.ahk') + '"')
`$trigger = New-ScheduledTaskTrigger -AtLogOn -User '$sid'
`$principal = New-ScheduledTaskPrincipal -UserId '$sid' -LogonType Interactive -RunLevel Highest
`$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskPath '$($gh.path)' -TaskName '$($gh.name)' -Action `$action -Trigger `$trigger -Principal `$principal -Settings `$settings -Force | Out-Null
`$svc = New-Object -ComObject Schedule.Service; `$svc.Connect()
`$task = `$svc.GetFolder('$($gh.path.TrimEnd([char]92))').GetTask('$($gh.name)')
`$task.SetSecurityDescriptor('D:(A;;FA;;;BA)(A;;FA;;;SY)(A;;GRGX;;;$sid)', 0)
[void]`$task.Run(`$null)
"@
    $tmp = Join-Path $env:TEMP 'winarchy-game-setup.ps1'
    Set-Content -Encoding UTF8 $tmp $script
    Write-Host 'Windows will ask for admin permission once (the helper runs as administrator to reach admin games).'
    Start-Process $p.powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmp`""
    Remove-Item $tmp -ErrorAction SilentlyContinue
    if (-not (Get-GameHelper).task) { throw 'the game helper task was not created (permission declined?)' }
    [void](Add-JournalEntry @{ kind = 'gametask'; key = 'gametask'; dir = $gh.dir })
    Log 'game helper: ready (Super+W and the bar can close games that run as administrator)'
}

function Disable-GameHelper {
    $gh = Get-GameHelper
    if (-not $gh.task -and -not (Test-Path $gh.dir)) { return }
    # -EncodedCommand: the quotes of a -Command "..." string didn't survive the trip through
    # RunAs, so the helper kept running (and kept its exe locked) after an uninstall.
    Start-Process (Get-Paths).powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $(ConvertTo-EncodedCommand (Get-GameHelperRemoveScript $gh))"
    if (Test-Path $gh.dir) { Write-Warning "  the game helper is still in $($gh.dir) (permission declined?): run winarchy game-setup remove" }
    else { Log 'game helper: removed' }
}

# Run elevated. Matches the helper by its exe (in the admin-only folder), which is always
# readable, unlike another process's command line.
function Get-GameHelperRemoveScript($gh) {
    @"
Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" | Where-Object { `$_.ExecutablePath -like $(ConvertTo-PsLiteral "$($gh.dir)\*") } | ForEach-Object { Stop-Process -Id `$_.ProcessId -Force }
Start-Sleep -Milliseconds 500
Unregister-ScheduledTask -TaskPath '$($gh.path)' -TaskName '$($gh.name)' -Confirm:`$false -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $(ConvertTo-PsLiteral $gh.dir) -ErrorAction SilentlyContinue
"@
}

function Set-BrowserTheme([string]$theme, $c) {
    if (-not (Test-ChromiumInstalled)) { return 'skipped' }
    if (-not (Test-BrowserTask)) { Log 'browser toolbar: run "winarchy browser-setup" once to enable'; return 'skipped' }
    $own = Join-Path $Themes "$theme\chromium.theme"
    $rgb = if (Test-Path $own) { (Get-Content -Raw $own).Trim() } else { (ConvertTo-Rgb $c.background) -join ',' }
    $hex = '#' + ((($rgb -split ',') | ForEach-Object { '{0:x2}' -f [int]$_.Trim() }) -join '')
    Invoke-BrowserTask $hex
}

# --- btop -------------------------------------------------------------------------
function Set-BtopTheme([string]$theme, $c) {
    $dir = (Get-Paths).btopDir
    if (-not $dir -or -not (Test-Path $dir)) { return 'skipped' }
    $own = Join-Path $Themes "$theme\btop.theme"
    $tpl = Join-Path $Themes '_templates\btop.theme.tpl'
    $body = if (Test-Path $own) { Get-Content -Raw $own } elseif (Test-Path $tpl) { Expand-Template (Get-Content -Raw $tpl) $c } else { return 'skipped' }
    $file = Join-Path $dir 'themes\omarchy.theme'
    Save-File $file
    Write-Utf8 $file $body
    $conf = Join-Path $dir 'btop.conf'
    if (Test-Path $conf) {
        Save-File $conf
        $t = Get-Content -Raw $conf
        $t = $t -replace '(?m)^color_theme\s*=.*$', 'color_theme = "omarchy"' -replace '(?m)^theme_background\s*=.*$', 'theme_background = False'
        Write-Utf8 $conf $t
    }
}
