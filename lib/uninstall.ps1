# winarchy uninstall: replays the backup journal newest-first.

function Invoke-Uninstall([switch]$KeepApps, [switch]$DryRun, [switch]$Purge) {
    $dir = Get-JournalDir
    $j = Read-Journal
    Write-Host "Undoing winarchy using $dir ($(@($j.entries).Count) recorded changes)"
    $step = {
        param([string]$msg, [scriptblock]$action)
        if ($DryRun) { Write-Host "[dry-run] $msg" -ForegroundColor Yellow; return }
        Write-Host "==> $msg" -ForegroundColor Cyan
        try { & $action } catch { Write-Warning "  failed: $($_.Exception.Message)" }
    }
    $p = Get-Paths

    & $step 'Stop winarchy (bar space released, taskbar shown)' {
        # A graceful close runs winarchy.ahk's OnExit: shows the taskbars, frees the bar strip.
        Get-OmarchyAhk | ForEach-Object {
            $proc = Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
            if ($proc) { [void]$proc.CloseMainWindow() }
        }
        Start-Sleep -Seconds 1
        Get-OmarchyAhk | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    }
    & $step 'Exit GlazeWM (restores every window), stop Zebar and Flow Launcher' {
        if ($p.glazewmCli) { & $p.glazewmCli command wm-exit 2>$null; Start-Sleep -Seconds 2 }
        Get-Process glazewm, glazewm-watcher, zebar, Flow.Launcher -ErrorAction SilentlyContinue | Stop-Process -Force
    }

    $entries = @($j.entries)
    [array]::Reverse($entries)
    # Herdr is an app like the winget ones - it just came from its own installer - so it and
    # the PATH entry its installer added are handled with the apps below, and -KeepApps
    # keeps both (a kept Herdr with its PATH entry gone would stop answering to `herdr`).
    $herdrBins = @($entries | Where-Object kind -eq 'herdr' | ForEach-Object { $_.bin })
    foreach ($e in $entries) {
        if ($e.kind -in 'winget', 'note', 'herdr') { continue }
        if ($KeepApps -and $e.kind -eq 'envpath' -and $herdrBins -contains $e.dir) { continue }
        $what = switch ($e.kind) {
            'reg' { "registry $($e.path)\$($e.name)" }
            'file' { "file $($e.path)" }
            'dir' { "move $($e.path) into the backup folder" }
            'json' { "$([IO.Path]::GetFileName($e.path)): $($e.pointer)" }
            'jsonItem' { "$([IO.Path]::GetFileName($e.path)): remove $($e.array) '$($e.name)'" }
            'envpath' { "PATH: remove $($e.dir)" }
            default { $e.kind }
        }
        & $step "Restore $what" { Restore-JournalEntry $e $dir }
    }

    if (-not $KeepApps) {
        foreach ($e in $entries | Where-Object { $_.kind -eq 'winget' }) {
            if ($e.preinstalled) { Write-Host "  keeping $($e.id) (it was installed before winarchy)"; continue }
            & $step "winget uninstall $($e.id)" { winget uninstall -e --id $e.id --silent --accept-source-agreements | Out-Host }
        }
        foreach ($e in $entries | Where-Object { $_.kind -eq 'herdr' }) {
            & $step 'Remove Herdr' { Restore-JournalEntry $e $dir }
        }
    } else { Write-Host '  -KeepApps: apps stay installed (just not started).' }

    if ($script:RestartExplorer -and -not $DryRun) {
        & $step 'Restart Explorer (taskbar settings)' {
            Stop-Process -Name explorer -Force
            Start-Sleep -Seconds 3
            if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
        }
    }
    foreach ($e in $entries | Where-Object { $_.kind -eq 'note' }) { Write-Host "  note: $($e.text)" }
    # Done with this journal: a later install starts a new one instead of reusing
    # install-day originals that no longer describe this PC. Its copies stay in $dir.
    if (-not $DryRun) {
        Rename-Item (Join-Path $dir 'journal.json') "journal-undone-$(Get-Date -Format 'yyyyMMdd-HHmmss').json" -ErrorAction SilentlyContinue
        $script:JournalDir = $null; $script:JournalCache = $null
    }

    if ($Purge) {
        & $step "Delete downloaded themes/backgrounds and settings ($Data, keeping backup\)" {
            Get-ChildItem $Data -Force | Where-Object Name -ne 'backup' | Remove-Item -Recurse -Force
        }
        & $step "Delete the winarchy code ($Code)" {
            Start-Process cmd.exe -ArgumentList "/c timeout /t 3 >nul & rmdir /s /q `"$Code`"" -WindowStyle Hidden
        }
    } else {
        Write-Host "`nKept: $Data (themes, backgrounds, backups) and $Code. 'winarchy uninstall -Purge' removes them."
    }
    Write-Host 'Done.' -ForegroundColor Green
}
