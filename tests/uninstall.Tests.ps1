# Pester tests: uninstall asks about the person's apps and settings, and a reinstall
# puts kept settings back (lib/uninstall.ps1, lib/setup.ps1).
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'journal', 'catalog', 'herdr', 'extras', 'setup') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Everything lives in the test drive: never the real ~/.winarchy.
    $Data = Join-Path $TestDrive 'data'
    $StateFile = Join-Path $Data 'state.json'
    $ConfigFile = Join-Path $Data 'config.json'
    $Themes = Join-Path $Data 'themes'
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    # The journal too: the real one in ~/.winarchy/backup is what uninstall replays.
    $BackupRoot = Join-Path $TestDrive 'backup'
    . "$root\lib\uninstall.ps1"

    # Nothing here may touch the running desktop: these stand in for the commands that
    # would stop processes, run winget or restore real settings.
    function Get-OmarchyAhk {}
    function Close-AhkGracefully { $false }
    function Restore-MinimizeBoxes { 0 }
    function Restore-WindowFrames { 0 }
    function Stop-ScreenshotWatcher {}
    function Get-Paths { @{} }
    function Get-Process {}
    function Stop-Process {}
    function winget { $script:WingetCalls.Add(($args -join ' ')); $global:LASTEXITCODE = [int]$script:WingetExit }
    function Invoke-Elevated([string]$Script) { $script:ElevatedCalls.Add($Script); if ($script:ElevatedFails) { throw 'the elevated step failed (exit 1603)' } }
    function Restore-JournalEntry($e, $dir) {
        if ($script:FailKey -and $e.key -eq $script:FailKey) { throw 'it is in use' }
        $script:Restored.Add("$($e.kind)|$($e.id)$($e.dir)")
        if ($null -ne $script:RestoredFrom) { $script:RestoredFrom.Add("$($e.key)@$(Split-Path $dir -Leaf)") }
    }
    # Winarchy's login entries: a Startup folder and Run key of the tests' own, never the
    # real ones, and no task scheduler, PATH, UAC or Explorer restart.
    $script:Places = @{ startup = Join-Path $TestDrive 'Startup'; run = 'TestRegistry:\Run' }
    function Get-AutostartPlaces { $script:Places }
    function Get-GameHelper { @{ task = $script:GameTask } }
    function Disable-GameHelper { $script:GameHelperRemoved++; if (-not $script:GameTaskSticks) { $script:GameTask = $null } }
    function Test-BrowserTask { [bool]$script:BrowserTask }
    function Disable-BrowserPolicy {}
    function Get-UserPathRaw { $script:FakePath }
    function Set-UserPathRaw([string]$value) { $script:FakePath = $value }
    function Show-TaskbarAgain { $script:TaskbarShown++ }
    $script:GameTask = $null
    $script:FakePath = 'C:\other'
    # The lock screen as Windows reports it, and what uninstall set it to: never the real one.
    function Get-LockScreenImage { $script:LockImage }
    function Set-LockScreenImage([string]$Path) { $script:LockSet.Add($Path); if (-not $script:LockStuck) { $script:LockImage = $Path } }
    $script:LockImage = $null
    # The same for the desktop wallpaper: a run on a PC showing a winarchy background used
    # to put Windows' own picture on the real desktop.
    function Get-CurrentWallpaper { $script:Wallpaper }
    function Restore-DefaultWallpaper { $script:WallpaperResets++ }
    $script:Wallpaper = $null
    $script:WallpaperResets = 0
    # Real reminders on this PC are the person's: the tests see only these.
    function Get-ScheduledTask { @($script:FakeTasks) }
    function Unregister-ScheduledTask { process { $script:Unregistered.Add($_.TaskName) } }
    $script:FakeTasks = @()

    # Under $BackupRoot, the only place uninstall replays, and the only journal there.
    function New-TestJournal([object[]]$entries) {
        Remove-Item $BackupRoot -Recurse -Force -ErrorAction SilentlyContinue
        $script:JournalDir = Join-Path $BackupRoot ([guid]::NewGuid())
        $script:JournalCache = $null
        New-Item -ItemType Directory $script:JournalDir | Out-Null
        Write-Json (Join-Path $script:JournalDir 'journal.json') ([ordered]@{ entries = @($entries) }) 8
    }
    function New-TestData {
        Remove-Item $Data -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force (Join-Path $Themes 'nord'), (Join-Path $Data 'branding'), (Join-Path $Data 'backup') | Out-Null
        Set-Content (Join-Path $Themes 'nord\colors.toml') 'x'
        Write-Json $ConfigFile @{ hideTaskbar = $false; launchers = $true }
        Write-Json $StateFile @{ theme = 'nord'; font = 'FiraCode Nerd Font' }
        Set-Content (Join-Path $Data 'glazewm.yaml.tpl') 'mine'
        Set-Content (Join-Path $Data 'branding\about.txt') 'mine'
    }
    $journal = @(
        @{ kind = 'winget'; key = 'winget|AutoHotkey.AutoHotkey'; id = 'AutoHotkey.AutoHotkey'; preinstalled = $false }
        @{ kind = 'winget'; key = 'winget|glzr-io.glazewm'; id = 'glzr-io.glazewm'; preinstalled = $false }
        @{ kind = 'winget'; key = 'winget|Python.Python.3.13'; id = 'Python.Python.3.13'; preinstalled = $false }
        @{ kind = 'envpath'; key = 'envpath|C:\herdr'; dir = 'C:\herdr' }
        @{ kind = 'herdr'; key = 'herdr'; bin = 'C:\herdr' }
        @{ kind = 'winget'; key = 'winget|Anysphere.Cursor'; id = 'Anysphere.Cursor'; preinstalled = $false; source = 'menu' }
        # Written before entries carried a source: still recognised as the person's.
        @{ kind = 'winget'; key = 'winget|Valve.Steam'; id = 'Valve.Steam'; preinstalled = $false }
        @{ kind = 'winget'; key = 'winget|Spotify.Spotify'; id = 'Spotify.Spotify'; preinstalled = $true; source = 'menu' }
    )
}

Describe 'Uninstall keeps what the person chooses' {
BeforeEach {
    $script:WingetCalls = [Collections.Generic.List[string]]::new()
    $script:ElevatedCalls = [Collections.Generic.List[string]]::new()
    $script:WingetExit = 0
    $script:ElevatedFails = $false
    $script:Restored = [Collections.Generic.List[string]]::new()
    $script:Unregistered = [Collections.Generic.List[string]]::new()
    $script:FakeTasks = @()
    $script:LockImage = $null
    $script:LockSet = [Collections.Generic.List[string]]::new()
    $script:LockStuck = $false
    $env:WINARCHY_YES = $null
    # An earlier -Yes run leaves this set, and Read-YesNo would stop asking.
    $script:AssumeYes = $false
}

Describe 'Get-UserApps' {
    It 'finds the apps the person picked, not what winarchy runs on' {
        $apps = @(Get-UserApps $journal)
        ($apps.label | Sort-Object) -join ',' | Should -Be 'Cursor,Herdr,Steam'
    }
    It 'counts Python as winarchy''s own when the extras installed it' {
        @(Get-UserApps $journal).entry.id | Should -Not -Contain 'Python.Python.3.13'
    }
}

Describe 'Uninstall' {
    It 'unattended: keeps the person''s apps and settings, removes winarchy''s own' {
        New-TestData; New-TestJournal $journal
        Invoke-Uninstall -Yes 6>$null
        $script:WingetCalls -join ';' | Should -Match 'AutoHotkey\.AutoHotkey'
        $script:WingetCalls -join ';' | Should -Match 'glzr-io\.glazewm'
        $script:WingetCalls -join ';' | Should -Not -Match 'Cursor|Steam|Spotify'
        $script:Restored | Should -Not -Contain 'herdr|'
        $script:Restored | Should -Not -Contain 'envpath|C:\herdr'
        (Read-Json (Join-Path $Data 'restore.json')).keptApps | Sort-Object | Should -Be @('Cursor', 'Herdr', 'Steam')
        Test-Path $ConfigFile | Should -BeTrue
    }
    It 'removes all of them when told no, and keeps the settings without asking' {
        New-TestData; New-TestJournal $journal
        Mock Read-Host { 'n' }
        Invoke-Uninstall 6>$null
        Should -Invoke Read-Host -Times 1 -Exactly
        $script:WingetCalls -join ';' | Should -Match 'Anysphere\.Cursor'
        $script:WingetCalls -join ';' | Should -Match 'Valve\.Steam'
        $script:WingetCalls -join ';' | Should -Not -Match 'Spotify'
        $script:Restored | Should -Contain 'herdr|'
        $script:Restored | Should -Contain 'envpath|C:\herdr'
        foreach ($n in 'config.json', 'state.json', 'glazewm.yaml.tpl', 'branding', 'restore.json') { Test-Path (Join-Path $Data $n) | Should -BeTrue }
        Test-Path (Join-Path $Themes 'nord\colors.toml') | Should -BeTrue
    }
    It 'asks about each app with "choose"' {
        New-TestData; New-TestJournal $journal
        $script:answers = [Collections.Generic.Queue[string]]::new([string[]]@('c', 'y', 'n', 'y'))
        Mock Read-Host { $script:answers.Dequeue() }
        Invoke-Uninstall 6>$null
        # Order is newest first: Steam (keep), Cursor (remove), Herdr (keep).
        $script:WingetCalls -join ';' | Should -Match 'Anysphere\.Cursor'
        $script:WingetCalls -join ';' | Should -Not -Match 'Valve\.Steam'
        $script:Restored | Should -Not -Contain 'herdr|'
    }
    It 'takes out the reminders still set, which would fail once winarchy is gone' {
        New-TestData; New-TestJournal $journal
        $script:FakeTasks = @([pscustomobject]@{ TaskName = 'winarchy-reminder-1' }, [pscustomobject]@{ TaskName = 'winarchy-reminder-2' })
        Invoke-Uninstall -Yes 6>$null
        @($script:Unregistered) | Should -Be @('winarchy-reminder-1', 'winarchy-reminder-2')
    }
    It 'removes web apps with the other apps you chose to remove' {
        New-TestData; New-TestJournal (@($journal) + @(@{ kind = 'webapp'; key = 'webapp|hey'; label = 'HEY'; path = 'C:\nowhere\HEY.lnk' }))
        Mock Read-Host { 'n' }
        Invoke-Uninstall 6>$null
        $script:Restored | Should -Contain 'webapp|'
    }
    It '-Purge takes the settings too, leaving only the backups' {
        New-TestData; New-TestJournal $journal
        function Start-Process {}
        Invoke-Uninstall -Yes -Purge 6>$null
        @((Get-ChildItem $Data -Force).Name) | Should -Be @('backup')
    }
    It 'removes every version of a package (GlazeWM and Zebar share one id)' {
        New-TestData; New-TestJournal $journal
        Invoke-Uninstall -Yes 6>$null
        @($script:WingetCalls | Where-Object { $_ -match 'glzr-io\.glazewm' }) | Should -Match '--all-versions'
        $script:ElevatedCalls.Count | Should -Be 0
    }
    It 'retries a failed winget removal elevated, once, and finishes clean if that works' {
        New-TestData; New-TestJournal $journal
        $script:WingetExit = 1603
        $out = Invoke-Uninstall -Yes 6>&1 | Out-String
        $script:ElevatedCalls.Count | Should -BeGreaterThan 0
        $script:ElevatedCalls[0] | Should -Match 'winget uninstall .*--all-versions'
        $out | Should -Not -Match 'step\(s\) failed'
    }
    It 'says so, instead of "Done.", when the elevated retry fails too' {
        New-TestData; New-TestJournal $journal
        $script:WingetExit = 1603; $script:ElevatedFails = $true
        $out = Invoke-Uninstall -Yes 3>$null 6>&1 | Out-String
        $out | Should -Match 'step\(s\) failed'
        $out | Should -Match 'glzr-io\.glazewm'
        $out | Should -Not -Match 'Done\.'
    }
    It '-DryRun changes nothing' {
        New-TestData; New-TestJournal $journal
        Invoke-Uninstall -Yes -DryRun 6>$null
        $script:WingetCalls.Count | Should -Be 0
        Test-Path (Join-Path $Data 'restore.json') | Should -BeFalse
        Test-Path (Join-Path $script:JournalDir 'journal.json') | Should -BeTrue
    }
}

Describe 'Uninstall leaves no winarchy lock screen' {
    BeforeEach {
        $script:WingetCalls = [Collections.Generic.List[string]]::new()
        $script:Restored = [Collections.Generic.List[string]]::new()
        $script:LockSet = [Collections.Generic.List[string]]::new()
        $script:LockStuck = $false
        $script:WingetExit = 0
        $script:FakeTasks = @()
        Mock Get-DefaultLockScreenImage { 'C:\Windows\Web\Screen\img100.jpg' }
        New-TestData; New-TestJournal @()
        $own = Join-Path $TestDrive 'Pictures\mine.jpg'
        New-Item -ItemType File -Force $own | Out-Null
    }
    It 'puts Windows'' wallpaper back only when the desktop shows a winarchy background' {
        $script:WallpaperResets = 0
        $script:Wallpaper = 'C:\Users\x\Pictures\mine.jpg'
        Invoke-Uninstall -Yes 6>$null
        $script:WallpaperResets | Should -Be 0
        $script:Wallpaper = Join-Path $Data 'wallpapers\nord\1.jpg'
        # The first run marked its journal undone: a second needs one of its own.
        New-TestJournal @()
        Invoke-Uninstall -Yes 6>$null
        $script:WallpaperResets | Should -Be 1
        $script:Wallpaper = $null
    }
    It 'puts Windows'' picture back when the lock screen still shows a winarchy background' {
        $script:LockImage = Join-Path $Data 'wallpapers\tokyo-night\0-winding-road.jpg'
        $out = Invoke-Uninstall -Yes 6>&1 | Out-String
        @($script:LockSet) | Should -Be @('C:\Windows\Web\Screen\img100.jpg')
        $out | Should -Match 'Done\.'
    }
    It 'counts the older omarchy-win backgrounds and backup copies as winarchy''s' {
        Test-WinarchyImage 'C:\Users\x\.omarchy-win\wallpapers\a.jpg' | Should -BeTrue
        Test-WinarchyImage 'D:\old\.winarchy-backup\wallpapers\a.jpg' | Should -BeTrue
        Test-WinarchyImage (Join-Path $Code 'themes\nord\backgrounds\1.png') | Should -BeTrue
        Test-WinarchyImage $own | Should -BeFalse
        Test-WinarchyImage 'C:\Windows\Web\Screen\img100.jpg' | Should -BeFalse
    }
    It 'leaves a lock screen picture of your own alone' {
        $script:LockImage = $own
        Invoke-Uninstall -Yes 6>$null
        $script:LockSet.Count | Should -Be 0
    }
    It 'says so, instead of "Done.", when Windows keeps winarchy''s picture' {
        $script:LockImage = Join-Path $Data 'wallpapers\nord\1.jpg'
        $script:LockStuck = $true
        $out = Invoke-Uninstall -Yes 3>$null 6>&1 | Out-String
        $out | Should -Match 'step\(s\) failed'
        $out | Should -Match 'Settings > Personalization > Lock screen'
        $out | Should -Not -Match 'Done\.'
    }
    It '-DryRun only says it would' {
        $script:LockImage = Join-Path $Data 'wallpapers\nord\1.jpg'
        $out = Invoke-Uninstall -Yes -DryRun 6>&1 | Out-String
        $script:LockSet.Count | Should -Be 0
        $out | Should -Match '\[dry-run\] Restore default Windows lock screen'
    }
    It 'restores your own original, but never a winarchy picture or one that is gone' {
        Restore-LockScreen $own
        Restore-LockScreen (Join-Path $Data 'wallpapers\nord\1.jpg')
        Restore-LockScreen (Join-Path $TestDrive 'Pictures\deleted.jpg')
        Restore-LockScreen
        @($script:LockSet) | Should -Be @($own, 'C:\Windows\Web\Screen\img100.jpg', 'C:\Windows\Web\Screen\img100.jpg', 'C:\Windows\Web\Screen\img100.jpg')
    }
    It 'records no original when the lock screen is already winarchy''s (an earlier uninstall left it)' {
        $script:LockImage = Join-Path $Data 'wallpapers\nord\1.jpg'
        New-Item -ItemType File -Force $script:LockImage | Out-Null
        Save-LockScreen
        $e = @((Read-Journal).entries | Where-Object kind -eq 'lockscreen')
        $e.Count | Should -Be 1
        Test-WinarchyImage $e[0].path | Should -BeFalse
    }
}

Describe 'Uninstall replays every journal not undone yet' {
    BeforeEach {
        New-TestData
        Remove-Item $BackupRoot -Recurse -Force -ErrorAction SilentlyContinue
        $script:JournalDir = $null; $script:JournalCache = $null
        $script:RestoredFrom = [Collections.Generic.List[string]]::new()
        function New-BackupJournal([string]$name, [object[]]$entries) {
            $d = Join-Path $BackupRoot $name
            New-Item -ItemType Directory -Force $d | Out-Null
            Write-Json (Join-Path $d 'journal.json') ([ordered]@{ entries = @($entries) }) 8
            $d
        }
    }
    AfterEach { $script:RestoredFrom = $null }
    It 'takes back what an older journal recorded, after one marked undone left a newer one behind' {
        # The install's journal, and the one started after it was marked undone (with the
        # same wallpaper recorded again, by then already winarchy's).
        $old = New-BackupJournal '20261002-223616' @(
            @{ kind = 'wallpaper'; key = 'wallpaper'; path = 'C:\mine.jpg' }
            @{ kind = 'file'; key = 'file|C:\Startup\winarchy.lnk'; path = 'C:\Startup\winarchy.lnk'; existed = $false }
        )
        $new = New-BackupJournal '20261002-234822' @(
            @{ kind = 'wallpaper'; key = 'wallpaper'; path = 'C:\winarchy-own.jpg' }
            @{ kind = 'lockscreen'; key = 'lockscreen'; path = $null }
        )
        Invoke-Uninstall -Yes 6>$null
        @($script:RestoredFrom) | Should -Be @('lockscreen@20261002-234822', 'file|C:\Startup\winarchy.lnk@20261002-223616', 'wallpaper@20261002-223616')
        foreach ($d in $old, $new) {
            Test-Path (Join-Path $d 'journal.json') | Should -BeFalse
            @(Get-ChildItem $d -Filter 'journal-undone-*.json').Count | Should -Be 1
        }
    }
    It 'keeps what failed to come back recorded, in the same folder, for the next uninstall' {
        $script:FailKey = 'file|C:\Startup\winarchy.lnk'
        try {
            $d = New-BackupJournal '20261002-223616' @(
                @{ kind = 'wallpaper'; key = 'wallpaper'; path = 'C:\mine.jpg' }
                @{ kind = 'file'; key = 'file|C:\Startup\winarchy.lnk'; path = 'C:\Startup\winarchy.lnk'; existed = $true; copy = 'winarchy.lnk' }
            )
            $out = Invoke-Uninstall -Yes 3>$null 6>&1 | Out-String
            $out | Should -Not -Match 'Done\.'
            @(Get-ChildItem $d -Filter 'journal-undone-*.json').Count | Should -Be 1
            $left = Read-Json (Join-Path $d 'journal.json')
            @($left.entries.key) | Should -Be @('file|C:\Startup\winarchy.lnk')
            $left.entries[0].copy | Should -Be 'winarchy.lnk'
        } finally { $script:FailKey = $null }
    }
    It 'leaves a journal that does not parse alone, and says so' {
        $bad = Join-Path $BackupRoot '20261002-223616'
        New-Item -ItemType Directory -Force $bad | Out-Null
        Set-Content (Join-Path $bad 'journal.json') '{ "entries": [ { "kind": "wallp' -NoNewline
        $good = New-BackupJournal '20261002-234822' @(@{ kind = 'lockscreen'; key = 'lockscreen'; path = $null })
        $out = Invoke-Uninstall -Yes 3>$null 6>&1 | Out-String
        $out | Should -Match 'could not be read'
        Test-Path (Join-Path $bad 'journal.json') | Should -BeTrue
        @(Get-ChildItem $bad -Filter 'journal-undone-*.json').Count | Should -Be 0
        Test-Path (Join-Path $good 'journal.json') | Should -BeFalse
    }
    It 'never takes a journal folder from outside the backup folder' {
        New-BackupJournal '20261002-223616' @() | Out-Null
        $script:JournalDir = Join-Path $TestDrive "elsewhere-$([guid]::NewGuid())"
        New-Item -ItemType Directory $script:JournalDir | Out-Null
        Write-Json (Join-Path $script:JournalDir 'journal.json') ([ordered]@{ entries = @() })
        try { @(Get-LiveJournalDirs) | Should -Be @((Join-Path $BackupRoot '20261002-223616')) }
        finally { $script:JournalDir = $null }
    }
    It 'counts a key a newer live journal has as recorded, and finds it there' {
        New-BackupJournal '20261002-223616' @(@{ kind = 'wallpaper'; key = 'wallpaper'; path = 'C:\mine.jpg' }) | Out-Null
        $new = New-BackupJournal '20261002-234822' @(@{ kind = 'taskbar'; key = 'taskbar'; autoHide = $false; stuckRects3 = 'AA==' })
        Test-Journaled 'taskbar' | Should -BeTrue
        Add-JournalEntry @{ kind = 'taskbar'; key = 'taskbar'; autoHide = $true; stuckRects3 = 'AQ==' } | Should -BeFalse
        (Get-JournalEntry 'taskbar').stuckRects3 | Should -Be 'AA=='
        Remove-JournalEntry 'taskbar' | Should -BeTrue
        @((Read-Json (Join-Path $new 'journal.json')).entries).Count | Should -Be 0
        Test-Journaled 'taskbar' | Should -BeFalse
    }
    It '-DryRun leaves every journal as it was' {
        $d = New-BackupJournal '20261002-223616' @(@{ kind = 'wallpaper'; key = 'wallpaper'; path = 'C:\mine.jpg' })
        Invoke-Uninstall -Yes -DryRun 6>$null
        Test-Path (Join-Path $d 'journal.json') | Should -BeTrue
    }
}

Describe 'Uninstall removes what starts winarchy at login, journal or not' {
    BeforeAll {
        function New-TestShortcut([string]$path, [string]$target, [string]$arguments) {
            $s = (New-Object -ComObject WScript.Shell).CreateShortcut($path)
            $s.TargetPath = $target; $s.Arguments = $arguments; $s.Save()
        }
    }
    BeforeEach {
        New-TestData; New-TestJournal @()
        $script:WingetCalls = [Collections.Generic.List[string]]::new()
        $script:Restored = [Collections.Generic.List[string]]::new()
        $script:FakeTasks = @()
        $script:LockImage = $null
        $script:GameHelperRemoved = 0
        $script:GameTaskSticks = $false
        $script:TaskbarShown = 0
        $startup = $script:Places.startup
        Remove-Item $startup -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force $startup | Out-Null
        $notepad = Join-Path $env:SystemRoot 'notepad.exe'
        New-TestShortcut (Join-Path $startup 'winarchy.lnk') $notepad ''
        New-TestShortcut (Join-Path $startup 'Screenshot to Clipboard.lnk') $notepad "-File `"$Code\ps51\screenshot-to-clipboard.ps1`""
        New-TestShortcut (Join-Path $startup 'Mine.lnk') $notepad 'C:\notes.txt'
        Remove-Item 'TestRegistry:\Run' -Recurse -ErrorAction SilentlyContinue
        New-Item 'TestRegistry:\Run' | Out-Null
        Set-ItemProperty 'TestRegistry:\Run' -Name GlazeWM -Value "`"$Data\glazewm-animations\glazewm.exe`""
        Set-ItemProperty 'TestRegistry:\Run' -Name Steam -Value '"C:\Program Files (x86)\Steam\steam.exe" -silent'
        Set-ItemProperty 'TestRegistry:\Run' -Name OwnGlazeWM -Value '"C:\Program Files\glzr.io\GlazeWM\glazewm.exe"'
        $script:GameTask = 'registered'
        $script:BrowserTask = $false
        $script:FakePath = "C:\other;$Code\bin\"
    }
    AfterEach { $script:BrowserTask = $false }
    It 'finds the PATH entry from before the rename (omarchy-win) too' {
        $old = Join-Path $env:LOCALAPPDATA 'omarchy-win\bin'
        $script:FakePath = "C:\other;$old"
        @(Get-WinarchyAutostart | Where-Object kind -eq 'path').dir | Should -Be @($old)
    }
    It 'does not call the browser colour task a login entry' {
        $script:BrowserTask = $true
        function Disable-BrowserPolicy {}
        $out = Invoke-Uninstall -Yes 3>$null 6>&1 | Out-String
        $out | Should -Match 'browser colour task is still there'
        $out | Should -Not -Match 'browser colour task is still there and starts winarchy at login'
    }
    It 'asks for admin rights once for the game task, not again after the replay tried it' {
        $script:GameTaskSticks = $true
        New-TestJournal @(@{ kind = 'gametask'; key = 'gametask'; dir = 'C:\x' })
        function Restore-JournalEntry($e, $dir) { if ($e.kind -eq 'gametask') { Disable-GameHelper } }
        Invoke-Uninstall -Yes 3>$null 6>$null
        $script:GameHelperRemoved | Should -Be 1
    }
    It 'takes out the shortcuts, Run values, task and PATH entry that point into winarchy' {
        $out = Invoke-Uninstall -Yes 6>&1 | Out-String
        @((Get-ChildItem $script:Places.startup).Name) | Should -Be @('Mine.lnk')
        $run = Get-ItemProperty 'TestRegistry:\Run'
        $run.PSObject.Properties.Name | Should -Not -Contain 'GlazeWM'
        $run.Steam | Should -Not -BeNullOrEmpty
        $run.OwnGlazeWM | Should -Not -BeNullOrEmpty
        $script:GameHelperRemoved | Should -Be 1
        $script:FakePath | Should -Be 'C:\other'
        $out | Should -Match 'Done\.'
    }
    It 'says so, instead of "Done.", when one is still there afterwards' {
        $script:GameTaskSticks = $true
        $out = Invoke-Uninstall -Yes 3>$null 6>&1 | Out-String
        $out | Should -Match 'step\(s\) failed'
        $out | Should -Match 'admin game helper task is still there and starts winarchy at login'
        $out | Should -Not -Match 'Done\.'
    }
    It '-DryRun lists them and removes nothing' {
        $out = Invoke-Uninstall -Yes -DryRun 6>&1 | Out-String
        $out | Should -Match '\[dry-run\] Remove Startup\\winarchy\.lnk'
        $out | Should -Match '\[dry-run\] Remove Run\\GlazeWM'
        @(Get-ChildItem $script:Places.startup).Count | Should -Be 3
        $script:GameHelperRemoved | Should -Be 0
        $script:FakePath | Should -Match 'winarchy|bin'
    }
    It 'shows the taskbar again when winarchy hid it and no journal said how it was' {
        Write-Json $ConfigFile @{ hideTaskbar = $true }
        Invoke-Uninstall -Yes 6>$null
        $script:TaskbarShown | Should -Be 1
    }
    It 'restarts Explorer only when it changed the taskbar' {
        . "$root\lib\uninstall.ps1"   # the real Show-TaskbarAgain, in this test only
        function Restore-Taskbar($t) { $script:TaskbarRestored = $t }
        $script:TaskbarRestored = $null
        foreach ($script:B8 in 2, 3) {
            $script:RestartExplorer = $false
            Mock Get-ItemProperty { [pscustomobject]@{ Settings = [byte[]](0, 0, 0, 0, 0, 0, 0, 0, $script:B8, 0) } }
            Show-TaskbarAgain
            $script:RestartExplorer | Should -Be ($script:B8 -eq 3)
        }
        [Convert]::FromBase64String($script:TaskbarRestored.stuckRects3)[8] | Should -Be 2
    }
    It 'leaves that to the journal when it recorded the taskbar' {
        Write-Json $ConfigFile @{ hideTaskbar = $true }
        New-TestJournal @(@{ kind = 'taskbar'; key = 'taskbar'; autoHide = $false; stuckRects3 = 'AA==' })
        Invoke-Uninstall -Yes 6>$null
        $script:TaskbarShown | Should -Be 0
        $script:Restored | Should -Contain 'taskbar|'
    }
}

Describe 'Reinstall answers' {
    It 'asks nothing already answered when restoring' {
        New-TestData
        Mock Read-Host { throw 'asked' }
        $p = @{ input = @{ count = 1 }; startup = $TestDrive; pictures = $TestDrive }
        $cfg = Get-InstallAnswers $p -Restoring 6>$null
        $cfg.hideTaskbar | Should -BeFalse
        $cfg.launchers | Should -BeTrue
    }
    It 'still asks a question that was never answered' {
        New-TestData
        Write-Json $ConfigFile @{ launchers = $true }
        Mock Read-Host { 'n' }
        $p = @{ input = @{ count = 2 }; startup = $TestDrive; pictures = $TestDrive }
        $cfg = Get-InstallAnswers $p -Restoring 6>$null
        $cfg.takeOverWinSpace | Should -BeFalse
        Should -Invoke Read-Host -Times 1 -Exactly
    }
    It 'does not ask about the taskbar: the top bar replaces it' {
        New-TestData
        Remove-Item $ConfigFile
        Mock Read-Host { throw 'asked' }
        $p = @{ input = @{ count = 1 }; startup = $TestDrive; pictures = $TestDrive }
        $cfg = Get-InstallAnswers $p 6>$null
        $cfg.Contains('hideTaskbar') | Should -BeFalse
        (Get-Config).hideTaskbar | Should -BeTrue
    }
    It 'stops on a config.json that does not parse, rather than replace it' {
        New-TestData
        Set-Content $ConfigFile '{ "backgroundDirs": ["C:\Art"] }'
        Mock Read-Host { 'y' }
        $p = @{ input = @{ count = 1 }; startup = $TestDrive; pictures = $TestDrive }
        { Get-InstallAnswers $p -Restoring 6>$null } | Should -Throw '*not valid JSON*'
        Get-Content -Raw $ConfigFile | Should -Match 'C:\\Art'
    }
    It 'treats a config.json copied in before install like a restore' {
        $src = Get-Content -Raw (Join-Path $root 'lib\setup.ps1')
        $src | Should -Match '\$restoring = -not \$script:FreshInstall'
        $src | Should -Match '\$null = Read-UserConfig'
    }
}

Describe 'Taskbar toggle' {
    BeforeEach {
        New-TestData
        $Generated = Join-Path $TestDrive 'generated'
        $script:AutoHide = [Collections.Generic.List[string]]::new()
        $script:Applied = 0
        function Set-TaskbarAutoHide([int]$state = 3) { $script:AutoHide.Add("$state") }
        function Invoke-Apply { $script:Applied++ }
        function Use-Lock([scriptblock]$body) { & $body }
    }
    It 'hides it, and brings it back with the auto-hide it had before winarchy' {
        # Explorer's StuckRects3 from before install: byte 8 is 2, auto-hide off.
        $before = [byte[]](0, 0, 0, 0, 0, 0, 0, 0, 2, 0)
        New-TestJournal @(@{ kind = 'taskbar'; key = 'taskbar'; autoHide = $false; stuckRects3 = [Convert]::ToBase64String($before) })
        Invoke-Taskbar 'toggle'
        (Get-Config).hideTaskbar | Should -BeTrue
        Invoke-Taskbar 'toggle'
        (Get-Config).hideTaskbar | Should -BeFalse
        @($script:AutoHide) | Should -Be @('3', '2')
        $script:Applied | Should -Be 2
        Invoke-Taskbar 'status' | Should -Be 'taskbar: shown'
    }
    It 'leaves auto-hide alone when winarchy never changed it' {
        New-TestJournal @()
        Invoke-Taskbar 'off'
        $script:AutoHide.Count | Should -Be 0
        (Get-Config).hideTaskbar | Should -BeFalse
    }
}
}
