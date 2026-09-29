# winarchy uninstall: replays the backup journal newest-first.

# Left behind by an uninstall that kept the settings; install reads it and restores them.
$RestoreFile = Join-Path $Data 'restore.json'

# The apps the person chose to install through winarchy (the menu's Install section, or
# Herdr at install time), as opposed to what winarchy itself runs on. Journals written
# before entries carried a source fall back to "a catalog row winarchy does not need".
function Get-UserApps($entries) {
    $core = Get-CoreWingetIds
    foreach ($e in $entries) {
        if ($e.kind -eq 'herdr') { [pscustomobject]@{ label = 'Herdr'; entry = $e }; continue }
        if ($e.kind -eq 'webapp') { [pscustomobject]@{ label = "$($e.label) (web app)"; entry = $e }; continue }
        if ($e.kind -eq 'port') { [pscustomobject]@{ label = $e.label; entry = $e }; continue }
        if ($e.kind -ne 'winget' -or $e.preinstalled) { continue }
        $item = $Catalog | ForEach-Object { $_.items } | Where-Object { $_.id -eq $e.id } | Select-Object -First 1
        $mine = if ($e.source) { $e.source -eq 'menu' } else { $item -and $core -notcontains $e.id }
        if ($mine) { [pscustomobject]@{ label = $(if ($item) { $item.label } else { $e.id }); entry = $e } }
    }
}

# Which of $apps to keep: all, none, or one by one.
function Read-KeepApps($apps) {
    Write-Host "`n    Apps you installed through winarchy: $(@($apps.label) -join ', ')"
    if ($script:AssumeYes) { Write-Host '    Keeping them (unattended).'; return @($apps) }
    $a = Read-Host '    Keep them? [Y]es, keep all / [n]o, remove all / [c]hoose each'
    if ($a -match '^(n|no)$') { return @() }
    if ($a -notmatch '^(c|choose)$') { return @($apps) }
    @($apps | Where-Object { Read-YesNo "Keep $($_.label)?" $true })
}

# One winget package out. --all-versions because packages can share an id (GlazeWM and Zebar
# are both glzr-io.glazewm), which plain `winget uninstall` refuses as "multiple versions".
# Machine-wide MSI installs need admin: when the normal try fails, one UAC prompt retries it
# elevated, and if that fails too this throws so the run says so instead of ending "Done.".
function Remove-WingetApp([string]$Id) {
    $args1 = '-e', '--id', $Id, '--all-versions', '--silent', '--accept-source-agreements', '--disable-interactivity'
    $global:LASTEXITCODE = 0
    winget uninstall @args1 | Out-Host
    if (-not $LASTEXITCODE) { return }
    Write-Host "  winget could not remove $Id without admin rights; asking Windows for permission (UAC)"
    $global:LASTEXITCODE = 0
    Invoke-Elevated "winget uninstall $($args1 -join ' ')"
}

function Invoke-Uninstall([switch]$KeepApps, [switch]$DryRun, [switch]$Purge, [switch]$Yes) {
    $script:AssumeYes = $Yes -or [bool]$env:WINARCHY_YES
    $dir = Get-JournalDir
    $j = Read-Journal
    Write-Host "Undoing winarchy using $dir ($(@($j.entries).Count) recorded changes)"
    $entries = @($j.entries)
    [array]::Reverse($entries)

    # The question before anything changes, so Ctrl+C still leaves the PC as it was.
    $userApps = @(Get-UserApps $entries)
    $keptApps = if ($KeepApps) { $userApps } elseif ($userApps) { @(Read-KeepApps $userApps) } else { @() }
    $keptKeys = @($keptApps | ForEach-Object { $_.entry.key })
    $userKeys = @($userApps | ForEach-Object { $_.entry.key })
    Write-Host ''
    # Settings are not asked about: they are a few small files, and kept they make a
    # reinstall come back as it was. -Purge is the clean slate, and takes them too.

    $script:UninstallFailures = [Collections.Generic.List[string]]::new()
    $step = {
        param([string]$msg, [scriptblock]$action)
        if ($DryRun) { Write-Host "[dry-run] $msg" -ForegroundColor Yellow; return }
        Write-Host "==> $msg" -ForegroundColor Cyan
        try { & $action } catch { $script:UninstallFailures.Add("$msg ($($_.Exception.Message))"); Write-Warning "  failed: $($_.Exception.Message)" }
    }
    $p = Get-Paths

    & $step 'Stop winarchy (taskbar shown, minimize buttons back)' {
        # A graceful close runs winarchy.ahk's OnExit: shows the taskbars, frees the bar strip,
        # puts back the minimize buttons blockMinimize took off. Force-stop only stragglers.
        $ids = @(Get-OmarchyAhk | ForEach-Object { [int]$_.ProcessId })
        if ($ids -and (Close-AhkGracefully $ids)) {
            for ($i = 0; $i -lt 30 -and (Get-Process -Id $ids -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Milliseconds 100 }
        }
        Get-OmarchyAhk | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        # Whatever a force-stop (now or any earlier crash) left without its button.
        $n = Restore-MinimizeBoxes
        if ($n) { Write-Host "  gave $n window(s) their minimize button back" }
    }
    & $step 'Exit GlazeWM (restores every window), stop Zebar and Flow Launcher' {
        if ($p.glazewmCli) { & $p.glazewmCli command wm-exit 2>$null; Start-Sleep -Seconds 2 }
        Get-Process glazewm, glazewm-watcher, zebar, Flow.Launcher -ErrorAction SilentlyContinue | Stop-Process -Force
        # GlazeWM never gives back title bars or rounded corners, even on a clean exit.
        $n = Restore-WindowFrames
        if ($n) { Write-Host "  gave $n window(s) their title bar and rounded corners back" }
    }

    # Herdr is an app like the winget ones - it just came from its own installer - so it and
    # the PATH entry its installer added are handled with the apps below, and keeping it
    # keeps both (a kept Herdr with its PATH entry gone would stop answering to `herdr`).
    $keptHerdrBins = @($keptApps | Where-Object { $_.entry.kind -eq 'herdr' } | ForEach-Object { $_.entry.bin })
    foreach ($e in $entries) {
        if ($e.kind -in 'winget', 'note', 'herdr', 'webapp', 'port') { continue }
        if ($e.kind -eq 'envpath' -and $keptHerdrBins -contains $e.dir) { continue }
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
    # Reminders are scheduled tasks that call winarchy's menu.ahk: with winarchy gone they
    # would only fail when they come due. Ours all carry the prefix (lib/system.ps1).
    $reminders = @(Get-ScheduledTask -TaskName 'winarchy-reminder-*' -ErrorAction SilentlyContinue)
    if ($reminders) {
        & $step "Remove $($reminders.Count) reminder(s) (Task Scheduler)" {
            $reminders | Unregister-ScheduledTask -Confirm:$false
        }
    }
    # The replay removed the screenshot auto-copy shortcut unless you had one before
    # winarchy; if it's gone, stop the running copy too (it runs from the code folder).
    if (-not (Test-Path -LiteralPath (Join-Path ([Environment]::GetFolderPath('Startup')) 'Screenshot to Clipboard.lnk'))) {
        & $step 'Stop screenshot auto-copy' { Stop-ScreenshotWatcher }
    }

    # What winarchy runs on (GlazeWM, Flow, AutoHotkey, ...) goes unless -KeepApps; the
    # person's own apps go only if they said so.
    foreach ($e in $entries | Where-Object { $_.kind -in 'winget', 'herdr', 'webapp', 'port' }) {
        $own = $userKeys -contains $e.key
        if ($own -and $keptKeys -contains $e.key) { continue }
        if (-not $own -and $KeepApps) { continue }
        if ($e.kind -eq 'herdr') { & $step 'Remove Herdr' { Restore-JournalEntry $e $dir }; continue }
        if ($e.kind -eq 'webapp') { & $step "Remove web app $($e.label)" { Restore-JournalEntry $e $dir }; continue }
        if ($e.kind -eq 'port') { & $step "Remove $($e.label)" { Restore-JournalEntry $e $dir }; continue }
        if ($e.preinstalled) { Write-Host "  keeping $($e.id) (it was installed before winarchy)"; continue }
        & $step "winget uninstall $($e.id)" { Remove-WingetApp $e.id }
    }
    if ($KeepApps) { Write-Host '  -KeepApps: GlazeWM, Flow Launcher and the rest stay installed (just not started).' }

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

    if (-not $Purge) {
        & $step "Save your settings for a reinstall ($RestoreFile)" {
            Write-Json $RestoreFile ([ordered]@{
                    savedAt = (Get-Date).ToString('s'); version = $version; theme = (Read-State).theme
                    keptApps = @($keptApps | ForEach-Object { $_.label })
                })
        }
    }

    if ($Purge) {
        $spare = @('backup')
        & $step "Delete your settings and the downloaded themes/backgrounds ($Data, keeping $($spare -join ', '))" {
            # Extra agent accounts link into ~/.claude and ~/.codex: those links go first, so
            # the recursive delete can never reach your own transcripts through one.
            if (Get-Command Clear-AccountLinks -ErrorAction SilentlyContinue) { try { Clear-AccountLinks $AccountsRoot } catch { Log "agent account links: $($_.Exception.Message)" } }
            Get-ChildItem $Data -Force | Where-Object Name -notin $spare | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            # A terminal that loaded winarchy's compiled helpers keeps those files open. They are
            # only a cache the next install rebuilds, so say so rather than fail the run.
            $left = @(Get-ChildItem $Data -Force | Where-Object Name -notin $spare | ForEach-Object { if ($_.PSIsContainer) { Get-ChildItem $_.FullName -Recurse -File -Force } else { $_ } })
            if ($left) { Write-Host "  $($left.Count) file(s) under $Data are in use by a program (close your other PowerShell windows, then delete the folder); a reinstall rebuilds them." }
        }
        & $step "Delete the winarchy code ($Code)" {
            # This shell must not sit inside the folder it deletes. The helper retries for a
            # while: an editor or terminal that had the folder open lets go when it closes.
            Set-Location $env:USERPROFILE
            $rm = "for /l %i in (1,1,15) do @(rmdir /s /q `"$Code`" 2>nul & if not exist `"$Code`" exit /b 0 & timeout /t 2 /nobreak >nul)"
            Start-Process cmd.exe -ArgumentList "/c $rm" -WindowStyle Hidden
        }
    } else {
        Write-Host "`nKept: $Data (themes, backgrounds, backups) and $Code. 'winarchy uninstall -Purge' removes them."
    }
    if ($keptApps) { Write-Host "Kept your apps: $(@($keptApps.label) -join ', ')." }
    if (-not $Purge) { Write-Host "Kept your settings in $Data. Reinstall any time: they are applied again automatically." }
    if ($script:UninstallFailures.Count) {
        Write-Host "Finished, but $($script:UninstallFailures.Count) step(s) failed:" -ForegroundColor Yellow
        $script:UninstallFailures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    } else { Write-Host 'Done.' -ForegroundColor Green }
}
