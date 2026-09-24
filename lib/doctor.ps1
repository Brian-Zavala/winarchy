# omarchy-win doctor: checks the moving parts and says what to do about each problem.

function Invoke-Doctor([switch]$Fix) {
    $p = if ($Fix) { Update-Paths } else { Get-Paths }
    $cfg = Get-Config
    $script:DoctorProblems = 0
    $check = {
        param([string]$name, [bool]$ok, [string]$hint)
        if ($ok) { Write-Host "  ok    $name" -ForegroundColor Green }
        else { $script:DoctorProblems++; Write-Host "  FAIL  $name" -ForegroundColor Red; if ($hint) { Write-Host "        -> $hint" -ForegroundColor Yellow } }
    }
    Write-Host 'omarchy-win doctor' -ForegroundColor Cyan

    Write-Host "`nApps"
    & $check "Windows 11 (build $($p.build))" ($p.build -ge 22000) 'Windows 11 is required.'
    & $check "AutoHotkey v2  $($p.ahk)" ([bool]$p.ahk) 'winget install -e --id AutoHotkey.AutoHotkey'
    & $check "PowerShell 7   $($p.pwsh)" ([bool]$p.pwsh) 'winget install -e --id Microsoft.PowerShell'
    & $check "GlazeWM        $($p.glazewm)" ([bool]$p.glazewm) 'winget install -e --id glzr-io.glazewm'
    & $check "Zebar          $($p.zebar)" ([bool]$p.zebar) 'reinstall GlazeWM (it bundles Zebar)'
    & $check "Flow Launcher  $($p.flow)" ([bool]$p.flow) 'winget install -e --id Flow-Launcher.Flow-Launcher'
    & $check 'JetBrainsMono Nerd Font' ([bool]$p.nerdFont) 'omarchy-win install (installs it), or install any Nerd Font'
    & $check "Terminal settings  $($p.wtSettings)" ([bool]$p.wtSettings) 'optional: install Windows Terminal for terminal theming'

    Write-Host "`nRunning"
    & $check 'GlazeWM' ([bool](Get-Process glazewm -ErrorAction SilentlyContinue)) "start it: `"$($p.glazewm)`""
    & $check 'Zebar (top bar)' ([bool](Get-Process zebar -ErrorAction SilentlyContinue)) 'omarchy-wm.ahk restarts it within 5 s; else run: omarchy-win apply'
    & $check 'Flow Launcher' ([bool](Get-Process Flow.Launcher -ErrorAction SilentlyContinue)) "start it: `"$($p.flow)`""
    $ahk = @(Get-OmarchyAhk | Where-Object { $_.CommandLine -like '*omarchy-wm.ahk*' })
    & $check 'omarchy-wm.ahk (keys, bar space, panels)' ($ahk.Count -eq 1) $(if ($ahk.Count -gt 1) { 'more than one copy is running: omarchy-win apply' } else { 'omarchy-win apply (starts it)' })
    $old = @($ahk | Where-Object { $_.CommandLine -notlike "*$Code*" })
    & $check 'running from this code folder' ($old.Count -eq 0) 'an old copy is running: omarchy-win apply'

    Write-Host "`nGenerated files"
    foreach ($f in @(
            @((Join-Path $Generated 'omarchy.ini'), 'AutoHotkey settings'),
            @((Join-Path $Pack 'zpack.json'), 'Zebar pack'),
            @((Join-Path $Pack 'env.js'), 'bar/menu paths'),
            @((Join-Path $Pack 'zebar.mjs'), 'Zebar client (offline copy)'),
            @((Join-Path $Pack 'theme.css'), 'theme colors'),
            @((Join-Path $Pack 'index.json'), 'picker index'),
            @($GlazeConfig, 'GlazeWM config'))) {
        & $check "$($f[1])  $($f[0])" (Test-Path $f[0]) 'omarchy-win apply'
    }
    $zpack = Read-Json (Join-Path $Pack 'zpack.json')
    $priv = @($zpack.widgets | ForEach-Object { $_.privileges.shellCommands.program }) | Where-Object { $_ -like '*AutoHotkey*' } | Select-Object -First 1
    & $check 'Zebar may run AutoHotkey (menu actions)' ($priv -and (Test-Path $priv)) 'omarchy-win apply (AutoHotkey moved)'
    $lnk = Join-Path $p.startup 'omarchy-wm.lnk'
    $target = if (Test-Path $lnk) { (New-Object -ComObject WScript.Shell).CreateShortcut($lnk).Arguments } else { '' }
    & $check 'starts at login (Startup\omarchy-wm.lnk)' ($target -like "*$Code*") 'omarchy-win apply'
    & $check 'omarchy-win on PATH' ((([Environment]::GetEnvironmentVariable('Path', 'User')) -split ';') -contains (Join-Path $Code 'bin')) 'omarchy-win install'

    Write-Host "`nScreen"
    Add-Type -AssemblyName System.Windows.Forms
    $bars = (Get-Process zebar -ErrorAction SilentlyContinue) -and $true
    foreach ($s in [System.Windows.Forms.Screen]::AllScreens) {
        $reserved = $s.WorkingArea.Top -gt $s.Bounds.Top
        & $check "$($s.DeviceName): bar strip kept free of windows" ($reserved -or -not $bars) 'omarchy-wm.ahk reserves it; if this persists run: omarchy-win apply'
    }
    $layout = Get-WorkspaceLayout @($p.monitors).Count $cfg.workspaces
    $yaml = if (Test-Path $GlazeConfig) { Get-Content -Raw $GlazeConfig } else { '' }
    $maxBound = ([regex]::Matches($yaml, 'bind_to_monitor:\s*(\d+)') | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
    & $check "workspaces fit $(@($p.monitors).Count) monitor(s)" ($null -eq $maxBound -or $maxBound -lt [Math]::Max(1, @($p.monitors).Count)) 'omarchy-win apply -MonitorsOnly'

    Write-Host "`nThemes"
    $themeDirs = @(Get-ChildItem $Themes -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'colors.toml') })
    & $check "$($themeDirs.Count) themes downloaded" ($themeDirs.Count -gt 0) 'omarchy-win sync'
    & $check "current theme: $((Read-State).theme)" (Test-Path (Join-Path $Themes "$((Read-State).theme)\colors.toml")) 'omarchy-win theme tokyo-night'

    Write-Host "`nRecent errors (today's log)"
    $fails = @(Get-Content $LogFile -ErrorAction SilentlyContinue | Where-Object { $_ -match 'FAILED|failed' } | Select-Object -Last 5)
    if ($fails) { $fails | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow } } else { Write-Host '  none' -ForegroundColor Green }

    if ($Fix -and $script:DoctorProblems) {
        Write-Host "`nFixing: re-applying configs and restarting the parts" -ForegroundColor Cyan
        Use-Lock { Invoke-Apply }
        if ($p.glazewm -and -not (Get-Process glazewm -ErrorAction SilentlyContinue)) { Start-Process $p.glazewm }
        if ($p.flow -and -not (Get-Process Flow.Launcher -ErrorAction SilentlyContinue)) { Start-Process $p.flow }
    }
    Write-Host ''
    if ($script:DoctorProblems) { Write-Host "$($script:DoctorProblems) problem(s). $(if (-not $Fix) { 'omarchy-win doctor -Fix tries the fixes above.' })" -ForegroundColor Yellow }
    else { Write-Host 'All good.' -ForegroundColor Green }
}
