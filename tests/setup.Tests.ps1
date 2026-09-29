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
