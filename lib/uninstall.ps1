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

# The desktop wallpaper as Windows has it, and Windows' own picture put back. Their own
# functions so the tests can stand in for them: the real ones change the running desktop.
function Get-CurrentWallpaper { (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -ErrorAction SilentlyContinue).WallPaper }

function Restore-DefaultWallpaper {
    $default = "$env:SystemRoot\Web\Wallpaper\Windows\img0.jpg"
    if (Test-Path $default) {
        Initialize-Native
        [void][Winarchy.Native]::SystemParametersInfo(0x14, 0, $default, 3)
    }
}

# Where winarchy's login entries live. Its own function so the tests can point it at
# their own folder and registry key: the real ones start winarchy on this PC.
function Get-AutostartPlaces {
    @{ startup = [Environment]::GetFolderPath('Startup'); run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' }
}

# What would start winarchy at the next login, found on the PC instead of in the journal:
# a journal that was lost, or marked undone without being undone, once left all of this
# behind, and the next reboot brought winarchy back. Only what is winarchy's for sure:
# a shortcut or Run value pointing into its folders, its own tasks, its PATH entry.
function Get-WinarchyAutostart {
    $places = Get-AutostartPlaces
    $roots = @($Code, $Data, (Join-Path $env:LOCALAPPDATA 'omarchy-win'), (Join-Path $env:USERPROFILE '.omarchy-win')) |
        Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') + '\' }
    $ours = { param([string]$s) @($roots | Where-Object { $s.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -ge 0 }).Count -gt 0 }
    $sh = $null
    foreach ($lnk in @(Get-ChildItem -LiteralPath $places.startup -Filter '*.lnk' -File -ErrorAction SilentlyContinue)) {
        $sh ??= New-Object -ComObject WScript.Shell
        $s = try { $sh.CreateShortcut($lnk.FullName) } catch { $null }
        if ($lnk.Name -in 'winarchy.lnk', 'omarchy-wm.lnk' -or ($s -and (& $ours "$($s.TargetPath) $($s.Arguments)"))) {
            [pscustomobject]@{ kind = 'startup'; what = "Startup\$($lnk.Name)"; path = $lnk.FullName }
        }
    }
    $run = Get-ItemProperty $places.run -ErrorAction SilentlyContinue
    if ($run) {
        foreach ($v in $run.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' -and (& $ours "$($_.Value)") }) {
            [pscustomobject]@{ kind = 'run'; what = "Run\$($v.Name)"; name = $v.Name }
        }
    }
    if ((Get-GameHelper).task) { [pscustomobject]@{ kind = 'gametask'; what = 'the admin game helper task' } }
    # No logon trigger: it only sets the browser colour, so it is left behind, not a login entry.
    if (Test-BrowserTask) { [pscustomobject]@{ kind = 'browsertask'; what = 'the browser colour task'; notAtLogin = $true } }
    # The bin folder of each, the one from before the rename (omarchy-win) too.
    $bins = @($roots | ForEach-Object { $_ + 'bin' })
    $onPath = @((Get-UserPathRaw) -split ';' | Where-Object { $_ } | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') })
    foreach ($bin in @($onPath | Where-Object { $bins -contains $_ } | Select-Object -Unique)) {
        [pscustomobject]@{ kind = 'path'; what = "PATH entry $bin"; dir = $bin }
    }
}

function Remove-WinarchyAutostartItem($item) {
    switch ($item.kind) {
        'startup' { Remove-Item -LiteralPath $item.path -Force }
        'run' { Remove-ItemProperty (Get-AutostartPlaces).run -Name $item.name }
        'gametask' { Disable-GameHelper }
        'browsertask' { Disable-BrowserPolicy }
        'path' { [void](Edit-UserPath $item.dir -Remove) }
    }
}

# Winarchy hid the taskbar, and no journal said how it was before: show it (auto-hide
# off, Windows' default) and restart Explorer so the tray icons come back with it.
function Show-TaskbarAgain {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
    $cur = (Get-ItemProperty $key -ErrorAction SilentlyContinue).Settings
    if ($cur -and $cur[8] -eq 3) {
        $shown = [byte[]]$cur.Clone(); $shown[8] = 2   # ABS_ALWAYSONTOP
        Restore-Taskbar @{ autoHide = $false; stuckRects3 = [Convert]::ToBase64String($shown) }
        # Only then: restarting Explorer closes every Explorer window.
        $script:RestartExplorer = $true
    }
}

function Invoke-Uninstall([switch]$KeepApps, [switch]$DryRun, [switch]$Purge, [switch]$Yes) {
    $script:AssumeYes = $Yes -or [bool]$env:WINARCHY_YES
    # Every journal not undone yet, newest first, each one's entries newest first. When two
    # recorded the same thing, the older one holds the real original: only it is replayed.
    $dirs = @(Get-LiveJournalDirs)
    $seen = [Collections.Generic.HashSet[string]]::new()
    $kept = @{}
    # A journal that doesn't parse is neither replayed nor marked undone: what it recorded
    # is still on the PC.
    $unread = @()
    foreach ($d in $dirs[($dirs.Count - 1)..0]) {
        if (-not $d) { continue }
        $j = Read-Json (Join-Path $d 'journal.json') -AsHashtable
        if (-not $j) { $unread += $d; continue }
        $kept[$d] = @($j.entries | Where-Object { $_ -and $seen.Add("$($_.key)") })
    }
    # Each entry with the journal folder its copies are in.
    $items = foreach ($d in $dirs) {
        $mine = @($kept[$d]); [array]::Reverse($mine)
        foreach ($e in $mine) { [pscustomobject]@{ e = $e; dir = $d } }
    }
    $items = @($items)
    $entries = @($items | ForEach-Object { $_.e })
    if ($dirs.Count -le 1) {
        Write-Host "Undoing winarchy using $(if ($dirs) { $dirs[0] } else { '(no journal)' }) ($($entries.Count) recorded changes)"
    } else {
        Write-Host "Undoing winarchy using $($dirs.Count) journals ($($entries.Count) recorded changes):"
        foreach ($d in $dirs) { Write-Host "  $d" }
    }

    # The question before anything changes, so Ctrl+C still leaves the PC as it was.
    $userApps = @(Get-UserApps $entries)
    $keptApps = if ($KeepApps) { $userApps } elseif ($userApps) { @(Read-KeepApps $userApps) } else { @() }
    $keptKeys = @($keptApps | ForEach-Object { $_.entry.key })
    $userKeys = @($userApps | ForEach-Object { $_.entry.key })
    Write-Host ''
    # Settings are not asked about: they are a few small files, and kept they make a
    # reinstall come back as it was. -Purge is the clean slate, and takes them too.

    $script:UninstallFailures = [Collections.Generic.List[string]]::new()
    foreach ($d in $unread) { $script:UninstallFailures.Add("$d\journal.json could not be read, so nothing it recorded was undone (it is left as it is)") }
    # The journal entries whose step failed: they stay recorded (see the end).
    $notUndone = [Collections.Generic.List[object]]::new()
    $step = {
        param([string]$msg, [scriptblock]$action, $journalItem)
        if ($DryRun) { Write-Host "[dry-run] $msg" -ForegroundColor Yellow; return }
        Write-Host "==> $msg" -ForegroundColor Cyan
        try { & $action } catch {
            $script:UninstallFailures.Add("$msg ($($_.Exception.Message))"); Write-Warning "  failed: $($_.Exception.Message)"
            if ($journalItem) { $notUndone.Add($journalItem) }
        }
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
    foreach ($it in $items) {
        $e = $it.e; $dir = $it.dir
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
        & $step "Restore $what" { Restore-JournalEntry $e $dir } $it
    }
    # Reminders are scheduled tasks that call winarchy's menu.ahk: with winarchy gone they
    # would only fail when they come due. Ours all carry the prefix (lib/system.ps1).
    $reminders = @(Get-ScheduledTask -TaskName 'winarchy-reminder-*' -ErrorAction SilentlyContinue)
    if ($reminders) {
        & $step "Remove $($reminders.Count) reminder(s) (Task Scheduler)" {
            $reminders | Unregister-ScheduledTask -Confirm:$false
        }
    }
    # Whatever still starts winarchy at login after the replay (see Get-WinarchyAutostart).
    $leftover = @(try { Get-WinarchyAutostart } catch { Write-Warning "  could not look for winarchy's login entries: $($_.Exception.Message)"; @() })
    $replayed = @($items | ForEach-Object { $_.e.kind })
    foreach ($item in $leftover) {
        # The replay already tried this task (and asked for admin rights): not a second time.
        if ($item.kind -in 'gametask', 'browsertask' -and $replayed -contains $item.kind) { continue }
        & $step "Remove $($item.what) ($(if ($DryRun) { 'if the journal leaves it' } else { 'the journal left it' }))" { Remove-WinarchyAutostartItem $item }
    }
    if ((Get-Config).hideTaskbar -and -not @($entries | Where-Object { $_.kind -eq 'taskbar' }).Count) {
        & $step 'Show the taskbar again (no journal recorded how it was)' { Show-TaskbarAgain }
    }
    # The replay removed the screenshot auto-copy shortcut unless you had one before
    # winarchy; if it's gone, stop the running copy too (it runs from the code folder).
    if (-not (Test-Path -LiteralPath (Join-Path (Get-AutostartPlaces).startup 'Screenshot to Clipboard.lnk'))) {
        & $step 'Stop screenshot auto-copy' { Stop-ScreenshotWatcher }
    }

    # Whatever the journal had (or didn't: a journal from before backgrounds, a restore that
    # failed), the lock screen must not keep one of winarchy's backgrounds: Windows keeps
    # its own copy of the picture, so it would outlive the uninstall and even -Purge.
    if (Test-WinarchyImage (Get-LockScreenImage)) {
        & $step 'Restore default Windows lock screen' {
            Restore-LockScreen
            if (Test-WinarchyImage (Get-LockScreenImage)) {
                throw "it still shows winarchy's background; pick another in Settings > Personalization > Lock screen"
            }
        }
    }

    $curWp = Get-CurrentWallpaper
    if ($curWp -and ($curWp -like "*$Data*" -or $curWp -like "*winarchy*")) {
        & $step 'Restore default Windows wallpaper' { Restore-DefaultWallpaper }
    }

    # What winarchy runs on (GlazeWM, Flow, AutoHotkey, ...) goes unless -KeepApps; the
    # person's own apps go only if they said so.
    foreach ($it in $items | Where-Object { $_.e.kind -in 'winget', 'herdr', 'webapp', 'port' }) {
        $e = $it.e; $dir = $it.dir
        $own = $userKeys -contains $e.key
        if ($own -and $keptKeys -contains $e.key) { continue }
        if (-not $own -and $KeepApps) { continue }
        if ($e.kind -eq 'herdr') { & $step 'Remove Herdr' { Restore-JournalEntry $e $dir } $it; continue }
        if ($e.kind -eq 'webapp') { & $step "Remove web app $($e.label)" { Restore-JournalEntry $e $dir } $it; continue }
        if ($e.kind -eq 'port') { & $step "Remove $($e.label)" { Restore-JournalEntry $e $dir } $it; continue }
        if ($e.preinstalled) { Write-Host "  keeping $($e.id) (it was installed before winarchy)"; continue }
        & $step "winget uninstall $($e.id)" { Remove-WingetApp $e.id } $it
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
    # Done with these journals: a later install starts a new one instead of reusing
    # install-day originals that no longer describe this PC. Their copies stay where they are.
    if (-not $DryRun) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        foreach ($d in @($dirs | Where-Object { $_ -and $unread -notcontains $_ })) {
            $file = Join-Path $d 'journal.json'
            try { Rename-Item $file "journal-undone-$stamp.json" -ErrorAction Stop } catch { continue }
            # What failed is still as winarchy left it: recorded again, in the same folder as
            # its copies, so the next uninstall tries it again.
            $left = @($notUndone | Where-Object { $_.dir -eq $d } | ForEach-Object { $_.e })
            if ($left) {
                [array]::Reverse($left)
                Write-Json $file ([ordered]@{ created = (Get-Date).ToString('s'); computer = $env:COMPUTERNAME; entries = $left }) 8
            }
        }
        $script:JournalDir = $null; $script:JournalCache = $null
        # Still there after all that: the next login starts winarchy again, so say so.
        foreach ($item in @(try { Get-WinarchyAutostart } catch { @() })) {
            $script:UninstallFailures.Add("$($item.what) is still there$(if (-not $item.notAtLogin) { ' and starts winarchy at login' })")
        }
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
