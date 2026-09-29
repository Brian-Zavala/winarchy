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
    function Restore-JournalEntry($e, $dir) { $script:Restored.Add("$($e.kind)|$($e.id)$($e.dir)") }
    # Real reminders on this PC are the person's: the tests see only these.
    function Get-ScheduledTask { @($script:FakeTasks) }
    function Unregister-ScheduledTask { process { $script:Unregistered.Add($_.TaskName) } }
    $script:FakeTasks = @()

    function New-TestJournal([object[]]$entries) {
        $script:JournalDir = Join-Path $TestDrive ([guid]::NewGuid())
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
