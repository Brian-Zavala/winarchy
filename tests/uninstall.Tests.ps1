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
    function winget { $script:WingetCalls.Add(($args -join ' ')) }
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
    It 'removes all of them and the settings when told no' {
        New-TestData; New-TestJournal $journal
        Mock Read-Host { 'n' }
        Invoke-Uninstall 6>$null
        $script:WingetCalls -join ';' | Should -Match 'Anysphere\.Cursor'
        $script:WingetCalls -join ';' | Should -Match 'Valve\.Steam'
        $script:WingetCalls -join ';' | Should -Not -Match 'Spotify'
        $script:Restored | Should -Contain 'herdr|'
        $script:Restored | Should -Contain 'envpath|C:\herdr'
        foreach ($n in 'config.json', 'state.json', 'glazewm.yaml.tpl', 'branding', 'restore.json') { Test-Path (Join-Path $Data $n) | Should -BeFalse }
        Test-Path (Join-Path $Themes 'nord\colors.toml') | Should -BeTrue
    }
    It 'asks about each app with "choose"' {
        New-TestData; New-TestJournal $journal
        $script:answers = [Collections.Generic.Queue[string]]::new([string[]]@('c', 'y', 'n', 'y', 'y'))
        Mock Read-Host { $script:answers.Dequeue() }
        Invoke-Uninstall 6>$null
        # Order is newest first: Steam (keep), Cursor (remove), Herdr (keep); then settings.
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
    It '-Purge with settings kept leaves only the backups and the settings' {
        New-TestData; New-TestJournal $journal
        function Start-Process {}
        Invoke-Uninstall -Yes -Purge 6>$null
        (Get-ChildItem $Data -Force).Name | Sort-Object | Should -Be @('backup', 'branding', 'config.json', 'glazewm.yaml.tpl', 'restore.json', 'state.json')
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
        $p = @{ input = @{ count = 1 }; startup = $TestDrive; pictures = $TestDrive }
        $cfg = Get-InstallAnswers $p -Restoring 6>$null
        $cfg.hideTaskbar | Should -BeFalse
        Should -Invoke Read-Host -Times 1 -Exactly
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
}
