# Pester tests: install and update run with nobody at the keyboard (lib/setup.ps1).
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'catalog', 'herdr', 'extras', 'setup') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    # updates.json lives in the bar's folder: keep the real one out of it.
    $Pack = Join-Path $TestDrive 'pack'
    New-Item -ItemType Directory -Force $Pack | Out-Null
    $pwshExe = (Get-Process -Id $PID).Path
}

Describe 'winget arguments' {
    It 'never lets winget or the installer ask anything' {
        $a = Get-WingetArgs 'upgrade' 'Git.Git' $null
        $a[0..3] | Should -Be @('upgrade', '-e', '--id', 'Git.Git')
        foreach ($flag in '--silent', '--disable-interactivity', '--accept-source-agreements', '--accept-package-agreements') {
            $a | Should -Contain $flag
        }
        $a | Should -Not -Contain '--scope'
    }
    It 'asks for a scope only when given one' {
        $a = Get-WingetArgs 'install' 'AutoHotkey.AutoHotkey' 'user'
        $a[-2..-1] | Should -Be @('--scope', 'user')
    }
    It 'updates rustup without updating the toolchains it manages' {
        $a = Get-WingetArgs 'upgrade' 'Rustlang.Rustup' $null
        $a[-2..-1] | Should -Be @('--override', '-y -q --no-update-default-toolchain')
        Get-WingetArgs 'install' 'Rustlang.Rustup' $null | Should -Not -Contain '--override'
        Get-WingetArgs 'upgrade' 'Git.Git' $null | Should -Not -Contain '--override'
    }
    It 'quotes what would otherwise split into two arguments' {
        ConvertTo-ArgString @('install', 'a b', '') | Should -Be 'install "a b" ""'
    }
}

Describe 'Invoke-Unattended' {
    It 'hands a prompt end-of-input instead of letting it wait' {
        $r = Invoke-Unattended $pwshExe @('-NoProfile', '-Command', 'if ($null -eq [Console]::In.ReadLine()) { exit 3 } else { exit 4 }') 60
        $r.Code | Should -Be 3
        $r.Ok | Should -BeFalse
    }
    It 'stops something that never finishes, and says so' {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-Unattended $pwshExe @('-NoProfile', '-Command', 'Start-Sleep 120') 2
        $sw.Elapsed.TotalSeconds | Should -BeLessThan 30
        $r.Ok | Should -BeFalse
        $r.Code | Should -BeNullOrEmpty
        $r.Reason | Should -Match 'without finishing'
    }
    It 'passes a clean exit through' {
        (Invoke-Unattended $pwshExe @('-NoProfile', '-Command', 'exit 0') 60).Ok | Should -BeTrue
    }
}

Describe 'A UAC prompt waiting behind the terminal' {
    BeforeAll { function Write-Warn([string]$msg) {} }
    It 'says nothing while no prompt is open' {
        Mock Get-Process { }
        Mock Write-Warn { }
        $shown = @{}
        Show-ParkedUac $shown
        Should -Invoke Write-Warn -Times 0
    }
    It 'says once that Windows is asking, whether or not the prompt can be brought up' {
        # A pid with no windows: the notice still shows, and nothing is switched to.
        Mock Get-Process { [pscustomobject]@{ Id = 1 } } -ParameterFilter { $Name -eq 'consent' }
        Mock Write-Warn { }
        $shown = @{}
        Show-ParkedUac $shown
        Show-ParkedUac $shown
        Should -Invoke Write-Warn -Times 1 -ParameterFilter { $msg -match 'UAC' }
    }
    It 'says it again for the next prompt' {
        Mock Write-Warn { }
        $shown = @{ notice = $true }
        Mock Get-Process { }
        Show-ParkedUac $shown
        Mock Get-Process { [pscustomobject]@{ Id = 1 } } -ParameterFilter { $Name -eq 'consent' }
        Show-ParkedUac $shown
        Should -Invoke Write-Warn -Times 1
    }
}

Describe 'Invoke-Winget' {
    It 'counts "already current" as done' {
        Mock Invoke-Unattended { [pscustomobject]@{ Ok = $false; Code = -1978335189; Reason = 'exit code 0x8A15002B' } }
        $r = Invoke-Winget 'upgrade' 'Git.Git' $null
        $r.Ok | Should -BeTrue
        $r.Reason | Should -BeNullOrEmpty
    }
}

Describe 'Install-WingetPackage' {
    BeforeAll { Mock Write-Host {} }
    It 'falls back to the default scope when the per-user one failed' {
        Mock Invoke-Winget { [pscustomobject]@{ Ok = -not $scope; Code = $(if ($scope) { 1 } else { 0 }) } }
        Install-WingetPackage 'AutoHotkey.AutoHotkey' 'AutoHotkey v2' 'user' | Should -BeTrue
        Should -Invoke Invoke-Winget -Times 2 -Exactly
    }
    It 'does not start it a second time after the watchdog stopped it' {
        Mock Invoke-Winget { [pscustomobject]@{ Ok = $false; Code = $null; Reason = 'stopped after 15 min without finishing' } }
        Install-WingetPackage 'AutoHotkey.AutoHotkey' 'AutoHotkey v2' 'user' | Should -BeFalse
        Should -Invoke Invoke-Winget -Times 1 -Exactly
    }
}

Describe 'Packages without a silent installer' {
    It 'knows which catalog rows have none' {
        Test-WingetUnattended 'Blizzard.BattleNet' | Should -BeFalse
        Test-WingetUnattended 'Git.Git' | Should -BeTrue
    }
    It 'assumes winget can silence a package the catalog does not list' {
        Test-WingetUnattended 'glzr-io.glazewm' | Should -BeTrue
    }
    It 'only marks rows with the one value the code understands' {
        foreach ($group in $Catalog) {
            foreach ($item in $group.items) { if ($item.ContainsKey('silent')) { $item.silent | Should -Be 'none' } }
        }
    }
}

Describe 'Invoke-Update' {
    BeforeAll {
        $updFile = Join-Path $Pack 'updates.json'
        function Set-Pending([string[]]$ids) {
            Write-Json $updFile ([ordered]@{ checked = 'then'; items = @($ids | ForEach-Object { [ordered]@{ name = $_; from = '1'; to = '2' } }) })
        }
    }
    BeforeEach {
        $global:TestPullExit = 0
        Mock git {
            $global:LASTEXITCODE = 0
            switch -Regex ($args -join ' ') {
                '\bremote$' { 'origin' }
                'rev-parse' { 'abc123' }
                'pull' { $global:LASTEXITCODE = $global:TestPullExit; if ($global:TestPullExit) { 'fatal: Not possible to fast-forward, aborting.' } }
                'rev-list' { '17' }
            }
        }
        Mock Get-Paths { @{ pwsh = { $global:LASTEXITCODE = 0 } } }
        Mock Test-HerdrInstalled { $false }
        Mock Get-CimInstance {}
        Mock Invoke-UpdateCheck {}
        Mock Invoke-Winget { [pscustomobject]@{ Ok = $true; Code = 0 } }
        Mock Get-GitInUse {}
        Mock Get-PackageInUse {}
        $global:TestState = @{ adminApps = @() }
        Mock Read-State { $global:TestState }
        Mock Save-State { $global:TestState = $s }
        Mock Wait-KeyToClose {}
        Mock Write-Host {}
        Mock Log {}
    }
    AfterAll { Remove-Variable TestPullExit -Scope Global -ErrorAction SilentlyContinue }

    It 'upgrades each pending app unattended, then closes by itself' {
        Set-Pending 'Git.Git'
        Invoke-Update
        Should -Invoke Invoke-Winget -Times 1 -Exactly -ParameterFilter { $verb -eq 'upgrade' -and $id -eq 'Git.Git' }
        Should -Invoke Wait-KeyToClose -Times 0 -Exactly
    }
    It 'never starts an installer that has no silent mode, and says why' {
        Set-Pending 'Blizzard.BattleNet', 'Git.Git'
        Invoke-Update
        Should -Invoke Invoke-Winget -Times 0 -Exactly -ParameterFilter { $id -eq 'Blizzard.BattleNet' }
        Should -Invoke Invoke-Winget -Times 1 -Exactly -ParameterFilter { $id -eq 'Git.Git' }
        Should -Invoke Log -ParameterFilter { $msg -match 'unfinished: Blizzard\.BattleNet' }
        Should -Invoke Wait-KeyToClose -Times 1 -Exactly
    }
    It 'reports a pull that cannot fast-forward, and still updates the apps' {
        $global:TestPullExit = 1
        Set-Pending 'Git.Git'
        Invoke-Update
        Should -Invoke Log -ParameterFilter { $msg -match "unfinished: winarchy code not updated.*17 commit\(s\) of its own" }
        Should -Invoke Invoke-Winget -Times 1 -Exactly -ParameterFilter { $id -eq 'Git.Git' }
        Should -Invoke Wait-KeyToClose -Times 1 -Exactly
    }
    It 'reports an app that did not upgrade' {
        Mock Invoke-Winget { [pscustomobject]@{ Ok = $false; Code = 1; Reason = 'exit code 0x00000001' } }
        Set-Pending 'Git.Git'
        Invoke-Update
        Should -Invoke Log -ParameterFilter { $msg -match 'unfinished: Git\.Git did not update \(exit code' }
        Should -Invoke Wait-KeyToClose -Times 1 -Exactly
    }
    It 'skips Git while its own bash.exe is running, and says what to close' {
        Mock Get-GitInUse { 'bash.exe', 'bash.exe' }
        Set-Pending 'Git.Git'
        Invoke-Update
        Should -Invoke Invoke-Winget -Times 0 -Exactly -ParameterFilter { $id -eq 'Git.Git' }
        Should -Invoke Log -ParameterFilter { $msg -match 'unfinished: Git\.Git not updated: still in use by bash\.exe\.' }
    }
    It 'retries an app that needs administrator rights once, elevated, in one batch' {
        Mock Test-Elevated { $false }
        Mock Invoke-Winget { [pscustomobject]@{ Ok = $false; Code = -2147009240; Reason = 'exit code 0x80073D28' } } -ParameterFilter { $id -in 'Microsoft.WSL', 'Other.App' }
        Mock Invoke-WingetElevated { $r = @{}; foreach ($i in $ids) { $r[$i] = [pscustomobject]@{ Ok = $true; Code = 0 } }; $r }
        Set-Pending 'Microsoft.WSL', 'Git.Git', 'Other.App'
        Invoke-Update
        Should -Invoke Invoke-WingetElevated -Times 1 -Exactly -ParameterFilter { ($ids -join ',') -eq 'Microsoft.WSL,Other.App' }
        Should -Invoke Wait-KeyToClose -Times 0 -Exactly
    }
    It 'remembers an app that needed administrator rights and goes straight to elevated next time' {
        Mock Test-Elevated { $false }
        Mock Invoke-Winget { [pscustomobject]@{ Ok = $false; Code = -2147009240; Reason = 'x' } } -ParameterFilter { $id -eq 'Microsoft.WSL' }
        Mock Invoke-WingetElevated { $r = @{}; foreach ($i in $ids) { $r[$i] = [pscustomobject]@{ Ok = $true; Code = 0 } }; $r }
        Set-Pending 'Microsoft.WSL'
        Invoke-Update
        $global:TestState.adminApps | Should -Contain 'Microsoft.WSL'
        Set-Pending 'Microsoft.WSL'
        Invoke-Update
        Should -Invoke Invoke-Winget -Times 1 -Exactly -ParameterFilter { $id -eq 'Microsoft.WSL' }
        Should -Invoke Invoke-WingetElevated -Times 2 -Exactly
    }
    It 'names the programs still running when an upgrade fails' {
        Mock Invoke-Winget { [pscustomobject]@{ Ok = $false; Code = 1; Reason = 'exit code 0x00000001' } }
        Mock Get-PackageInUse { 'Spotify.exe', 'Spotify.exe' }
        Set-Pending 'Spotify.Spotify'
        Invoke-Update
        Should -Invoke Log -ParameterFilter { $msg -match 'Spotify\.Spotify did not update .*still running: Spotify\.exe - close it' }
    }
    It 'counts a restart-required install as updated, and says to restart' {
        Mock Invoke-Winget { [pscustomobject]@{ Ok = $true; Code = 0x8A150109; Reboot = $true } }
        Set-Pending 'Git.Git'
        Invoke-Update
        Should -Invoke Log -ParameterFilter { $msg -match 'Git\.Git updated, but Windows must restart' }
        Should -Invoke Log -Times 0 -Exactly -ParameterFilter { $msg -match 'did not update' }
    }
    It 'explains the winget codes people actually hit' {
        Get-WingetReason 0x8A150101 | Should -Match 'is running'
        Get-WingetReason 0x8A150103 | Should -Match 'is running'
        Get-WingetReason 0x8A150105 | Should -Be 'the disk is full'
        Get-WingetReason 0x8A15010A | Should -Match 'restart'
    }
    It 'explains an app that is running' {
        Get-WingetReason -2147009278 | Should -Match 'is running'
        Get-WingetReason 1 | Should -Be 'exit code 0x00000001'
    }
    It 'keeps what did not update on the bar icon even when the fresh check misses it' {
        Mock Test-Elevated { $false }
        Mock Invoke-Winget { [pscustomobject]@{ Ok = $false; Code = -2147009240; Reason = 'exit code 0x80073D28' } } -ParameterFilter { $id -eq 'Microsoft.WSL' }
        Mock Invoke-WingetElevated { @{ 'Microsoft.WSL' = [pscustomobject]@{ Ok = $false; Code = $null; Reason = 'the administrator prompt was declined' } } }
        Mock Invoke-UpdateCheck { Write-Json $updFile ([ordered]@{ checked = 'now'; items = @() }) }
        Set-Pending 'Microsoft.WSL', 'Git.Git'
        Invoke-Update
        Should -Invoke Log -ParameterFilter { $msg -match 'unfinished: Microsoft\.WSL did not update \(the administrator prompt was declined\)' }
        @((Read-Json $updFile).items | ForEach-Object name) | Should -Be @('Microsoft.WSL')
    }
    It 'does not ask for elevation for an ordinary failure' {
        Mock Test-Elevated { $false }
        Mock Invoke-Winget { [pscustomobject]@{ Ok = $false; Code = 1; Reason = 'exit code 0x00000001' } }
        Mock Invoke-WingetElevated {}
        Set-Pending 'Git.Git'
        Invoke-Update
        Should -Invoke Invoke-WingetElevated -Times 0 -Exactly
    }
    It 'puts the list back for the bar when the run dies before the fresh check' {
        Mock Invoke-UpdateCheck { throw 'boom' }
        Set-Pending 'Git.Git', 'Spotify.Spotify'
        { Invoke-Update } | Should -Throw '*boom*'
        @((Read-Json $updFile).items).Count | Should -Be 2
    }
}

Describe 'Invoke-Winget' {
    It 'waits for another installation instead of failing, then gives up' {
        $global:Calls = 0
        Mock Invoke-Unattended { $global:Calls++; [pscustomobject]@{ Ok = $false; Code = 0x8A150102; Reason = 'x' } }
        Mock Start-Sleep {}
        $r = Invoke-Winget upgrade 'Some.App' $null
        $global:Calls | Should -Be 4
        $r.Ok | Should -BeFalse
        $r.Reason | Should -Match 'another installation'
        Remove-Variable Calls -Scope Global
    }
    It 'treats an MSI restart code as success' {
        Mock Invoke-Unattended { [pscustomobject]@{ Ok = $false; Code = 3010; Reason = 'x' } }
        $r = Invoke-Winget upgrade 'Some.App' $null
        $r.Ok | Should -BeTrue
        $r.Reboot | Should -BeTrue
    }
}

Describe 'Theme download during the app installs' {
    It 'starts after ~/.glzr is journaled and before the apps install' {
        $body = (Get-Command Invoke-Install).ScriptBlock.ToString()
        $saveDir = $body.IndexOf("Save-Dir (Join-Path `$env:USERPROFILE '.glzr')")
        $start = $body.IndexOf('Start-ThemeDownload')
        $deps = $body.IndexOf('Install-Dependencies')
        $saveDir | Should -BeGreaterThan -1
        $start | Should -BeGreaterThan $saveDir
        $deps | Should -BeGreaterThan $start
    }
    It 'waits for it, then fetches what it missed, before a theme is set' {
        $body = (Get-Command Invoke-Install).ScriptBlock.ToString()
        $wait = $body.IndexOf('Wait-ThemeDownload')
        $sync = $body.IndexOf('Use-Lock { Invoke-Sync }')
        $wait | Should -BeGreaterThan $body.IndexOf('Install-Dependencies')
        $sync | Should -BeGreaterThan $wait
        $body.IndexOf('Invoke-ThemeSet') | Should -BeGreaterThan $sync
    }
    It 'stops a download that hangs' {
        $ThemeDownloadProgress = Join-Path $TestDrive 'theme-download.json'
        Mock Write-Ok {}
        Mock Log {}
        $state = @{ killed = $false }
        $proc = [pscustomobject]@{ HasExited = $false }
        $proc | Add-Member ScriptMethod WaitForExit { param($ms) $false }
        $proc | Add-Member ScriptMethod Kill { param($tree) $state.killed = $true }.GetNewClosure()
        Wait-ThemeDownload $proc 0
        $state.killed | Should -BeTrue
    }
    It 'runs in the background with no lock and makes the thumbnails too' {
        Get-Content -Raw (Join-Path $Code 'bin\winarchy.ps1') | Should -Match "'sync' \{ if \(\`$Background\) \{ Save-OmarchyFiles \`$ThemeDownloadProgress; New-MissingThumbs \}"
    }
}

Describe 'Zebar settings before GlazeWM installs' {
    BeforeAll {
        # From lib/apply.ps1 and lib/journal.ps1, which this file does not load.
        function Set-ZebarStartup {} ; function Save-Winget {}
    }
    It 'are written before the GlazeWM + Zebar installer runs' {
        $script:order = [Collections.Generic.List[string]]::new()
        Mock Write-Step {}
        Mock Write-Ok {}
        Mock Save-Winget {}
        Mock Update-Paths {}
        Mock Get-Paths { @{} }
        Mock Add-Unfinished {}
        Mock Set-ZebarStartup { $script:order.Add('zebar') }
        Mock Install-WingetPackage { $script:order.Add($id); $true }
        Install-Apps
        $script:order -join ',' | Should -Be 'zebar,glzr-io.glazewm,Flow-Launcher.Flow-Launcher'
    }
}

Describe 'PATH on a fresh PC' {
    BeforeEach { $script:savedPath = $env:Path }
    AfterEach { $env:Path = $script:savedPath }
    It 'picks up what an install added to the registry, keeping what only this process has' {
        Mock Get-UserPathRaw { '' }
        $own = Join-Path $TestDrive 'process-only'
        $env:Path = "$own;$env:SystemRoot\System32"
        Update-ProcessPath
        $parts = $env:Path -split ';'
        $parts | Should -Contain $own
        @($parts | Where-Object { $_.TrimEnd('\') -eq "$env:SystemRoot\System32" }).Count | Should -Be 1
        foreach ($d in ([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })) { $parts | Should -Contain $d }
    }
    It 'adds to the user PATH as stored, keeping %VARS% unexpanded' {
        Mock Get-UserPathRaw { '%USERPROFILE%\bin;C:\Tools' }
        Mock Set-UserPathRaw { $script:written = $value }
        Edit-UserPath 'C:\winarchy\bin' | Should -BeTrue
        $script:written | Should -Be '%USERPROFILE%\bin;C:\Tools;C:\winarchy\bin'
    }
    It 'adds to an empty user PATH without a stray separator' {
        Mock Get-UserPathRaw { '' }
        Mock Set-UserPathRaw { $script:written = $value }
        Edit-UserPath 'C:\winarchy\bin' | Should -BeTrue
        $script:written | Should -Be 'C:\winarchy\bin'
    }
    It 'takes an entry out, however it was written, and leaves the rest as stored' {
        Mock Get-UserPathRaw { "%USERPROFILE%\bin;$env:USERPROFILE\herdr\;C:\Tools" }
        Mock Set-UserPathRaw { $script:written = $value }
        Edit-UserPath "$env:USERPROFILE\herdr" -Remove | Should -BeTrue
        $script:written | Should -Be '%USERPROFILE%\bin;C:\Tools'
        Mock Get-UserPathRaw { 'C:\Tools' }
        Edit-UserPath "$env:USERPROFILE\herdr" -Remove | Should -BeFalse
    }
}

Describe 'Preflight' {
    BeforeEach {
        Mock Write-Step {}; Mock Write-Ok {}
        $script:savedAllow = $env:WINARCHY_ALLOW_ELEVATED
        $env:WINARCHY_ALLOW_ELEVATED = $null
    }
    AfterEach { $env:WINARCHY_ALLOW_ELEVATED = $script:savedAllow }
    It 'refuses to install from an elevated terminal' {
        Mock Test-Elevated { $true }
        { Test-Preflight } | Should -Throw '*Running as administrator*'
    }
    It 'lets WINARCHY_ALLOW_ELEVATED override that' {
        Mock Test-Elevated { $true }
        $env:WINARCHY_ALLOW_ELEVATED = '1'
        { Test-Preflight } | Should -Not -Throw
    }
}

Describe 'Updating a zip install' {
    BeforeEach {
        $script:realCode = $Code
        $Code = Join-Path $TestDrive "code-$([guid]::NewGuid().ToString('N').Substring(0, 6))"
        New-Item -ItemType Directory -Force (Join-Path $Code 'lib') | Out-Null
        Set-Content (Join-Path $Code 'VERSION') '0.1.0'
        Set-Content (Join-Path $Code 'lib\gone.ps1') 'old'
        Set-Content (Join-Path $Code 'mine.txt') 'not winarchy''s'
        Set-Content (Join-Path $Code '.winarchy-files') @('VERSION', 'lib\gone.ps1')
        $src = Join-Path $TestDrive "zip-$([guid]::NewGuid().ToString('N').Substring(0, 6))"
        New-Item -ItemType Directory -Force (Join-Path $src 'winarchy-main\lib') | Out-Null
        Set-Content (Join-Path $src 'winarchy-main\VERSION') '0.2.0'
        Set-Content (Join-Path $src 'winarchy-main\lib\new.ps1') 'new'
        $script:zip = "$src.zip"
        Compress-Archive (Join-Path $src 'winarchy-main') $script:zip
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'git' }
        Mock Invoke-WebRequest { Copy-Item $script:zip $OutFile }
        Mock Write-Ok {}; Mock Write-Done {}
    }
    It 'replaces the files, drops only the ones winarchy put there, and says the version moved' {
        Update-CodeFromZip | Should -BeTrue
        Get-Content (Join-Path $Code 'VERSION') | Should -Be '0.2.0'
        Test-Path (Join-Path $Code 'lib\new.ps1') | Should -BeTrue
        Test-Path (Join-Path $Code 'lib\gone.ps1') | Should -BeFalse
        Test-Path (Join-Path $Code 'mine.txt') | Should -BeTrue
        Get-Content (Join-Path $Code '.winarchy-files') | Should -Contain 'lib\new.ps1'
        Should -Invoke Invoke-WebRequest -ParameterFilter { $Uri -like '*/archive/refs/heads/main.zip' }
    }
}

Describe 'Gaming step (the admin game helper is on by default)' {
    BeforeAll {
        # lib/targets.ps1 is not loaded here: stand-ins so they can be mocked.
        function Get-GameHelper {}
        function Test-GameHelperCurrent {}
        function Enable-GameHelper {}
    }
    BeforeEach {
        $global:TestCfg = @{ gameMode = $true; gameHelper = $true }
        $global:TestState = @{}
        $global:TestTask = $null
        $global:TestCurrent = $false
        Mock Get-Config { $global:TestCfg }
        Mock Read-State { $global:TestState }
        Mock Save-State { $global:TestState = $s }
        Mock Get-GameHelper { @{ task = $global:TestTask } }
        Mock Test-GameHelperCurrent { $global:TestCurrent }
        Mock Enable-GameHelper {}
        Mock Write-Host {}
        Mock Log {}
        $script:Unfinished.Clear()
    }
    AfterAll { Remove-Variable TestCfg, TestTask, TestCurrent -Scope Global -ErrorAction SilentlyContinue }

    It 'sets the helper up during the install, without asking' {
        Invoke-GamingStep
        Should -Invoke Enable-GameHelper -Times 1 -Exactly
        $global:TestState.gameHelperOffered | Should -BeTrue
        $script:Unfinished.Count | Should -Be 0
    }
    It 'leaves a helper that is already current alone' {
        $global:TestTask = 'task'; $global:TestCurrent = $true
        Invoke-GamingStep
        Should -Invoke Enable-GameHelper -Times 0 -Exactly
    }
    It 'skips it when <name> is off in the settings' -ForEach @(@{ name = 'gameHelper' }, @{ name = 'gameMode' }) {
        $global:TestCfg[$name] = $false
        Invoke-GamingStep
        Should -Invoke Enable-GameHelper -Times 0 -Exactly
    }
    It 'a declined admin prompt does not stop the install, and says how to try again' {
        Mock Enable-GameHelper { throw 'the game helper task was not created (permission declined?)' }
        { Invoke-GamingStep } | Should -Not -Throw
        $script:Unfinished[0] | Should -Match 'winarchy game-setup'
    }
    It 'update brings an out-of-date helper up to date' {
        $global:TestTask = 'task'; $global:TestState.gameHelperOffered = $true
        Invoke-GamingStep -Update
        Should -Invoke Enable-GameHelper -Times 1 -Exactly
    }
    It 'update sets it up once on a PC installed before the gaming step' {
        Invoke-GamingStep -Update
        Invoke-GamingStep -Update
        Should -Invoke Enable-GameHelper -Times 1 -Exactly
    }
    It 'update does not ask again after a declined prompt' {
        $global:TestState.gameHelperOffered = $true
        Invoke-GamingStep -Update
        Should -Invoke Enable-GameHelper -Times 0 -Exactly
    }
    It 'update says nothing when there is nothing to do' {
        $global:TestTask = 'task'; $global:TestCurrent = $true
        Invoke-GamingStep -Update
        Should -Invoke Write-Host -Times 0 -Exactly
    }
}
