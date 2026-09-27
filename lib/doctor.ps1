# winarchy doctor: checks the moving parts and says what to do about each problem.

function Invoke-Doctor([switch]$Fix) {
    $p = if ($Fix) { Update-Paths } else { Get-Paths }
    $cfg = Get-Config
    $script:DoctorProblems = 0
    $check = {
        param([string]$name, [bool]$ok, [string]$hint)
        if ($ok) { Write-Host "  ok    $name" -ForegroundColor Green }
        else { $script:DoctorProblems++; Write-Host "  FAIL  $name" -ForegroundColor Red; if ($hint) { Write-Host "        -> $hint" -ForegroundColor Yellow } }
    }
    Write-Host 'winarchy doctor' -ForegroundColor Cyan

    Write-Host "`nApps"
    & $check "Windows 11 (build $($p.build))" ($p.build -ge 22000) 'Windows 11 is required.'
    & $check "AutoHotkey v2  $($p.ahk)" ([bool]$p.ahk) 'winget install -e --id AutoHotkey.AutoHotkey'
    & $check "PowerShell 7   $($p.pwsh)" ([bool]$p.pwsh) 'winget install -e --id Microsoft.PowerShell'
    & $check "GlazeWM        $($p.glazewm)" ([bool]$p.glazewm) 'winget install -e --id glzr-io.glazewm'
    & $check "Zebar          $($p.zebar)" ([bool]$p.zebar) 'reinstall GlazeWM (it bundles Zebar)'
    & $check "Flow Launcher  $($p.flow)" ([bool]$p.flow) 'winget install -e --id Flow-Launcher.Flow-Launcher'
    & $check 'JetBrainsMono Nerd Font' ([bool]$p.nerdFont) 'winarchy install (installs it), or install any Nerd Font'
    & $check "Terminal settings  $($p.wtSettings)" ([bool]$p.wtSettings) 'optional: install Windows Terminal for terminal theming'

    Write-Host "`nRunning"
    & $check 'GlazeWM' ([bool](Get-GlazeWmProcess)) "start it: `"$($p.glazewm)`""
    $build = Get-AnimationBuild
    $running = Get-GlazeWmProcess | Select-Object -First 1
    if ($running) { $running = Get-GlazeWMPath $running $p }
    $which = if ($p.glazewm -ne $p.glazewmOfficial) { "animation build $($build.commit.Substring(0, 12)) (experimental)" } else { 'official' }
    & $check "GlazeWM build: $which" (-not $running -or $running -eq $p.glazewm) "the other build is running: winarchy apply"
    if ((Get-Config).animations.enabled -and -not $build) { & $check 'window animations are on, but the animation build is missing' $false 'winarchy animations build' }
    # Only a signed binary in a secure folder may ask for uiAccess, so our own build can't:
    # Windows then hides every key from its hook while an elevated window is in front, and
    # workspace switching (Super+1..0 are GlazeWM's own keys) dies over a game run as
    # administrator. The admin game helper stands in for those keys, so it stops being
    # optional as soon as the animation build is the one running.
    if ($running -and $running -ne $p.glazewmOfficial -and -not (Get-GameHelper).task) {   # installed but stale: the check below says so
        & $check 'workspace keys work over admin windows (animation build + game helper)' `
            ([bool](Test-GameHelperCurrent)) `
            'winarchy game-setup (one admin prompt), or winarchy animations off'
    }
    & $check 'Zebar (top bar)' ([bool](Get-Process zebar -ErrorAction SilentlyContinue)) 'winarchy.ahk restarts it within 5 s; else run: winarchy apply'
    if ($cfg.autoTiling.enabled) {
        $autotileRunning = [bool](Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -like '*autotile-watch.ps1*' })
        & $check 'auto-tiling watcher' $autotileRunning 'winarchy apply (GlazeWM starts it); if it keeps dying, winarchy autotile off then on'
    }
    & $check 'Flow Launcher' ([bool](Get-Process Flow.Launcher -ErrorAction SilentlyContinue)) "start it: `"$($p.flow)`""
    $ahk = @(Get-OmarchyAhk | Where-Object { $_.CommandLine -like '*winarchy.ahk*' })
    & $check 'winarchy.ahk (keys, bar space, panels)' ($ahk.Count -eq 1) $(if ($ahk.Count -gt 1) { 'more than one copy is running: winarchy apply' } else { 'winarchy apply (starts it)' })
    $old = @($ahk | Where-Object { $_.CommandLine -notlike "*$Code*" })
    & $check 'running from this code folder' ($old.Count -eq 0) 'an old copy is running: winarchy apply'
    # Games set to "Run as administrator" need the admin game helper to be closed by Super+W / the bar.
    $gh = Get-GameHelper
    if ($gh.task) {
        & $check 'admin game helper (closes admin games; carries the workspace keys over them)' (Test-GameHelperCurrent) 'winarchy game-setup (the installed copy is out of date)'
    } else {
        $games = @(Get-GameProcesses (Get-Config))
        $admin = @((Get-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' -ErrorAction SilentlyContinue).PSObject.Properties |
            Where-Object { $_.Value -match 'RUNASADMIN' -and $games -contains [IO.Path]::GetFileNameWithoutExtension($_.Name) })
        if ($admin) { & $check "admin game helper: $($admin.Count) game(s) run as administrator" $false 'winarchy game-setup (one admin prompt), so Super+W and the bar can close them' }
    }

    Write-Host "`nGenerated files"
    foreach ($f in @(
            @((Join-Path $Generated 'winarchy.ini'), 'AutoHotkey settings'),
            @((Join-Path $Pack 'zpack.json'), 'Zebar pack'),
            @((Join-Path $Pack 'env.js'), 'bar/menu paths'),
            @((Join-Path $Pack 'zebar.mjs'), 'Zebar client (offline copy)'),
            @((Join-Path $Pack 'theme.css'), 'theme colors'),
            @((Join-Path $Pack 'index.json'), 'picker index'),
            @((Join-Path $Pack 'apps.json'), 'Apps list'),
            @((Join-Path $Pack 'catalog.json'), 'Install/Remove catalog'),
            @($GlazeConfig, 'GlazeWM config'))) {
        & $check "$($f[1])  $($f[0])" (Test-Path $f[0]) 'winarchy apply'
    }
    $zpack = Read-Json (Join-Path $Pack 'zpack.json')
    $priv = @($zpack.widgets | ForEach-Object { $_.privileges.shellCommands.program }) | Where-Object { $_ -like '*AutoHotkey*' } | Select-Object -First 1
    & $check 'Zebar may run AutoHotkey (menu actions)' ($priv -and (Test-Path $priv)) 'winarchy apply (AutoHotkey moved)'
    $lnk = Join-Path $p.startup 'winarchy.lnk'
    $target = if (Test-Path $lnk) { (New-Object -ComObject WScript.Shell).CreateShortcut($lnk).Arguments } else { '' }
    & $check 'starts at login (Startup\winarchy.lnk)' ($target -like "*$Code*") 'winarchy apply'
    & $check 'winarchy on PATH' ((([Environment]::GetEnvironmentVariable('Path', 'User')) -split ';') -contains (Join-Path $Code 'bin')) 'winarchy install'

    # Herdr is optional, so this section only appears once it is installed: nothing here
    # is wrong on a machine that never asked for it.
    if (Test-HerdrInstalled) {
        Write-Host "`nHerdr"
        & $check "herdr  $(Get-HerdrExe)" $true ''
        $herdrConfig = Get-HerdrConfigPath
        & $check "config  $herdrConfig" (Test-Path $herdrConfig) 'winarchy herdr config'
        if (Test-Path $herdrConfig) {
            # Herdr validates its own config and names anything it had to ignore, which is
            # what a hand-edited template gets wrong.
            $issues = @(& (Get-HerdrExe) config check 2>&1 | Where-Object { $_ -notmatch '^config: ok' })
            & $check "config is valid$(if ($issues) { " ($($issues.Count) issue(s))" })" (-not $issues) "$($issues -join '; ')"
        }
        & $check "theme: $(Get-HerdrTheme (Read-State).theme)" $true ''
        & $check 'Herdr keybindings list (Learn > Herdr)' (Test-Path (Join-Path $Pack 'herdr-keys.txt')) 'winarchy herdr keys'
        $profileFile = $PROFILE.CurrentUserAllHosts
        $hasBlock = (Test-Path -LiteralPath $profileFile) -and
            ((Get-Content -Raw -LiteralPath $profileFile) -match [regex]::Escape($HerdrProfileBegin))
        & $check "hdl / hds / hdlm / hsl in $profileFile" $hasBlock 'winarchy herdr shortcuts'
    }
    # The bar's agent usage runs Omarchy's collectors, which are Python. Without it the
    # indicator simply never appears, which looks the same as "no agent used yet" - so
    # say which it is, but only to someone who has an agent whose usage it would show.
    if ($cfg.agentUsage.enabled -ne $false -and @(Get-AgentState | Where-Object installed).Count) {
        Write-Host "`nAgent usage (bar)"
        & $check "Python 3  $($p.python)" ([bool]$p.python) 'winget install -e --id Python.Python.3.13, then: winarchy apply (the "python" in WindowsApps is only a Store shortcut and does not count)'
        $usage = Read-Json (Join-Path $Pack 'agents.json')
        if ($p.python) {
            $names = @($usage.agents | ForEach-Object name)
            & $check "agents shown in the bar: $(if ($names) { $names -join ', ' } else { 'none yet' })" $true ''
            foreach ($a in @($usage.agents | Where-Object usageStatusText)) {
                & $check "$($a.name): $($a.usageStatusText)" $false $a.authHelpText
            }
        }
    }
    $agent = Get-DefaultAgent
    if ($agent -and -not (Test-AgentInstalled $agent)) {
        & $check "default agent '$agent' is installed" $false "$($AgentTable[$agent].hint), or pick another: winarchy default-agent <name>"
    }

    Write-Host "`nScreen"
    $yaml = if (Test-Path $GlazeConfig) { Get-Content -Raw $GlazeConfig } else { '' }
    $top = if ($yaml -match "'(\d+)px'\s*# gaps:top") { [int]$Matches[1] } else { 0 }
    & $check "bar strip kept free of windows (GlazeWM top gap $top px)" ($top -ge [int]$cfg.barHeight) 'winarchy apply'
    # Screensaver health: the effects engine must not be crash-looping.
    $crashes = @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = 'Application Error'; StartTime = (Get-Date).AddHours(-1) } -MaxEvents 500 -ErrorAction SilentlyContinue |
        Where-Object { $_.Message -match 'ttfx' }).Count
    & $check "screensaver effects engine: $crashes crash(es) in the last hour" ($crashes -eq 0) 'winarchy update (older versions crash-looped ttfx on Windows)'
    $bindings = @(Get-WorkspaceBindings $yaml)
    if ($bindings -and $cfg.glazewmManaged -ne $false -and $p.glazewmCli -and (Get-GlazeWmProcess)) {
        $live = try { (& $p.glazewmCli query monitors | ConvertFrom-Json).data.monitors } catch { $null }
        if ($live) {
            $off = @(Get-MisplacedWorkspaces $live $bindings | ForEach-Object name)
            & $check "workspaces on their monitors$(if ($off) { " (not: $($off -join ', '))" })" (-not $off) 'winarchy apply -MonitorsOnly'
        }
    }
    # Bound to a monitor that is off or gone: fine while it sleeps (they return with it).
    $bound = Get-BoundMonitorCount $yaml
    $connected = @($p.monitors).Count
    if ($bound -gt [Math]::Max(1, $connected)) {
        Write-Host "  note  workspaces are split over $bound monitors, $connected connected; they open on the focused one until it's back" -ForegroundColor DarkGray
        Write-Host "        -> removed a monitor for good? winarchy apply -MonitorsOnly -Resplit" -ForegroundColor DarkGray
    }

    Write-Host "`nThemes"
    $themeDirs = @(Get-ChildItem $Themes -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'colors.toml') })
    & $check "$($themeDirs.Count) themes downloaded" ($themeDirs.Count -gt 0) 'winarchy sync'
    & $check "current theme: $((Read-State).theme)" (Test-Path (Join-Path $Themes "$((Read-State).theme)\colors.toml")) 'winarchy theme tokyo-night'

    Write-Host "`nRecent errors (today's log)"
    $fails = @(Get-Content $LogFile -ErrorAction SilentlyContinue | Where-Object { $_ -match 'FAILED|failed' } | Select-Object -Last 5)
    if ($fails) { $fails | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow } } else { Write-Host '  none' -ForegroundColor Green }

    if ($Fix -and $script:DoctorProblems) {
        Write-Host "`nFixing: installing anything missing, re-applying configs, restarting the parts" -ForegroundColor Cyan
        # A missing app or dependency (AutoHotkey, GlazeWM, Python, ...) is the fix most
        # problems above point at; each step only installs what is not there.
        Install-Dependencies
        Use-Lock { Invoke-Apply }
        if ($p.glazewm -and -not (Get-GlazeWmProcess)) { Start-Process $p.glazewm }
        if ($p.flow -and -not (Get-Process Flow.Launcher -ErrorAction SilentlyContinue)) { Start-Process $p.flow }
    }
    Write-Host ''
    if ($script:DoctorProblems) { Write-Host "$($script:DoctorProblems) problem(s). $(if (-not $Fix) { 'winarchy doctor -Fix tries the fixes above.' })" -ForegroundColor Yellow }
    else { Write-Host 'All good.' -ForegroundColor Green }
}
