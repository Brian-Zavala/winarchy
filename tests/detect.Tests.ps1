# Pester tests: detection works on a fresh PC where nothing is installed yet.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'keys', 'animations') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
}

Describe 'Update-Paths' {
    It 'does not throw when GlazeWM and btop4win are nowhere to be found' {
        $PathsFile = Join-Path $TestDrive 'paths.json'
        $saved = $env:ProgramFiles
        $env:ProgramFiles = Join-Path $TestDrive 'ProgramFiles'
        try {
            Mock Find-Program { $null }
            Mock Get-MonitorLayout { @() }
            Mock Get-UserHotkeys { [ordered]@{ keys = @(); files = @(); dynamic = 0 } }
            $p = Update-Paths
            $p.glazewmOfficial | Should -BeNullOrEmpty
            $p.glazewmCliOfficial | Should -BeNullOrEmpty
            Test-Path $PathsFile | Should -BeTrue
        } finally { $env:ProgramFiles = $saved }
    }
}
