# winarchy uninstall: replays the backup journal newest-first.

# What in ~/.winarchy is the person's own doing rather than a download or a cache: kept
# when they ask to keep their settings, and put back to work by the next install.
$SettingsItems = 'config.json', 'state.json', 'glazewm.yaml.tpl', 'herdr.toml.tpl',
    'keybindings-apps.txt', 'herdr-welcomed', 'branding', 'restore.json'
# Left behind by an uninstall that kept the settings; install reads it and restores them.
$RestoreFile = Join-Path $Data 'restore.json'

# The apps the person chose to install through winarchy (the menu's Install section, or
# Herdr at install time), as opposed to what winarchy itself runs on. Journals written
# before entries carried a source fall back to "a catalog row winarchy does not need".
function Get-UserApps($entries) {
    $core = Get-CoreWingetIds
    foreach ($e in $entries) {
        if ($e.kind -eq 'herdr') { [pscustomobject]@{ label = 'Herdr'; entry = $e }; continue }
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

function Invoke-Uninstall([switch]$KeepApps, [switch]$DryRun, [switch]$Purge, [switch]$Yes) {
    $script:AssumeYes = $Yes -or [bool]$env:WINARCHY_YES
    $dir = Get-JournalDir
    $j = Read-Journal
    Write-Host "Undoing winarchy using $dir ($(@($j.entries).Count) recorded changes)"
    $entries = @($j.entries)
    [array]::Reverse($entries)

    # Both questions before anything changes, so Ctrl+C still leaves the PC as it was.
    $userApps = @(Get-UserApps $entries)
    $keptApps = if ($KeepApps) { $userApps } elseif ($userApps) { @(Read-KeepApps $userApps) } else { @() }
    $keptKeys = @($keptApps | ForEach-Object { $_.entry.key })
    $userKeys = @($userApps | ForEach-Object { $_.entry.key })
    Write-Host ''
    $keepSettings = Read-YesNo 'Keep your settings (theme, background, font, config.json, your own templates) so reinstalling winarchy puts them back?' $true
    Write-Host ''

    $step = {
        param([string]$msg, [scriptblock]$action)
        if ($DryRun) { Write-Host "[dry-run] $msg" -ForegroundColor Yellow; return }
        Write-Host "==> $msg" -ForegroundColor Cyan
        try { & $action } catch { Write-Warning "  failed: $($_.Exception.Message)" }
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
        if ($e.kind -in 'winget', 'note', 'herdr') { continue }
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
    # The replay removed the screenshot auto-copy shortcut unless you had one before
    # winarchy; if it's gone, stop the running copy too (it runs from the code folder).
    if (-not (Test-Path -LiteralPath (Join-Path ([Environment]::GetFolderPath('Startup')) 'Screenshot to Clipboard.lnk'))) {
        & $step 'Stop screenshot auto-copy' { Stop-ScreenshotWatcher }
    }

    # What winarchy runs on (GlazeWM, Flow, AutoHotkey, ...) goes unless -KeepApps; the
    # person's own apps go only if they said so.
    foreach ($e in $entries | Where-Object { $_.kind -in 'winget', 'herdr' }) {
        $own = $userKeys -contains $e.key
        if ($own -and $keptKeys -contains $e.key) { continue }
        if (-not $own -and $KeepApps) { continue }
        if ($e.kind -eq 'herdr') { & $step 'Remove Herdr' { Restore-JournalEntry $e $dir }; continue }
        if ($e.preinstalled) { Write-Host "  keeping $($e.id) (it was installed before winarchy)"; continue }
        & $step "winget uninstall $($e.id)" { winget uninstall -e --id $e.id --silent --accept-source-agreements | Out-Host }
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

    if ($keepSettings) {
        & $step "Save your settings for a reinstall ($RestoreFile)" {
            Write-Json $RestoreFile ([ordered]@{
                    savedAt = (Get-Date).ToString('s'); version = $version; theme = (Read-State).theme
                    keptApps = @($keptApps | ForEach-Object { $_.label })
                })
        }
    } else {
        & $step 'Delete your settings (a reinstall starts from the defaults)' {
            foreach ($name in $SettingsItems) { Remove-Item -LiteralPath (Join-Path $Data $name) -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    if ($Purge) {
        $spare = @('backup') + $(if ($keepSettings) { $SettingsItems })
        & $step "Delete downloaded themes/backgrounds$(if (-not $keepSettings) { ' and settings' }) ($Data, keeping $($spare -join ', '))" {
            Get-ChildItem $Data -Force | Where-Object Name -notin $spare | Remove-Item -Recurse -Force
        }
        & $step "Delete the winarchy code ($Code)" {
            Start-Process cmd.exe -ArgumentList "/c timeout /t 3 >nul & rmdir /s /q `"$Code`"" -WindowStyle Hidden
        }
    } else {
        Write-Host "`nKept: $Data (themes, backgrounds, backups) and $Code. 'winarchy uninstall -Purge' removes them."
    }
    if ($keptApps) { Write-Host "Kept your apps: $(@($keptApps.label) -join ', ')." }
    if ($keepSettings) { Write-Host "Kept your settings in $Data. Reinstall any time: they are applied again automatically." }
    Write-Host 'Done.' -ForegroundColor Green
}
