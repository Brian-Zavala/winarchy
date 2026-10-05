# Pester tests: every dependency is installed automatically - by install, by update (for
# PCs installed before a dependency existed) and by doctor -Fix - and only when missing.
# Nothing is installed for real: winget and the journal are mocked.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'journal', 'catalog', 'herdr', 'extras', 'setup', 'doctor') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    # The journal too: the real one in ~/.winarchy/backup is what uninstall replays.
    $BackupRoot = Join-Path $TestDrive 'backup'
    $Pack = Join-Path $TestDrive 'pack'
    New-Item -ItemType Directory -Force $Pack | Out-Null
}

Describe 'Install-Dependencies' {
    It 'runs every install step' {
        Mock Install-Prerequisites {}
        Mock Install-Apps {}
        Mock Install-Extras {}
        Mock Update-Paths {}
        Install-Dependencies
        Should -Invoke Install-Prerequisites -Times 1
        Should -Invoke Install-Apps -Times 1
        Should -Invoke Install-Extras -Times 1
    }
    It 'never installs Herdr: that stays the person''s choice' {
        (Get-Command Install-Dependencies).ScriptBlock.ToString() | Should -Not -Match 'Herdr'
    }
}

Describe 'Python as an extra' {
    BeforeEach {
        Mock Write-Step {}
        Mock Write-Ok {}
        Mock Save-Winget {}
        Mock Install-WingetPackage { $true }
        Mock Update-Paths { @{ btopDir = 'C:\btop'; ttfx = 'C:\ttfx.exe' } }
        Mock Get-Command { [pscustomobject]@{ Source = 'C:\fastfetch.exe' } } -ParameterFilter { $Name -eq 'fastfetch.exe' }
    }
    It 'is installed, and journaled as ours, when it is missing' {
        Mock Find-Python { $null }
        Install-Extras
        Should -Invoke Save-Winget -ParameterFilter { $id -eq 'Python.Python.3.13' -and $preinstalled -eq $false } -Times 1
        Should -Invoke Install-WingetPackage -ParameterFilter { $id -eq 'Python.Python.3.13' } -Times 1
    }
    It 'is left alone, and journaled as yours, when it is already there' {
        Mock Find-Python { 'C:\Python313\python.exe' }
        Install-Extras
        Should -Invoke Save-Winget -ParameterFilter { $id -eq 'Python.Python.3.13' -and $preinstalled -eq $true } -Times 1
        Should -Invoke Install-WingetPackage -ParameterFilter { $id -eq 'Python.Python.3.13' } -Times 0
    }
}

Describe 'Update installs what new code needs' {
    It 'runs `winarchy deps` in a fresh process after the pull, before applying' {
        $body = (Get-Command Invoke-Update).ScriptBlock.ToString()
        $pull = $body.IndexOf('pull --ff-only')
        $deps = $body.IndexOf("'deps'")
        $apply = $body.IndexOf("'apply'")
        $pull | Should -BeGreaterThan -1
        $deps | Should -BeGreaterThan $pull
        $apply | Should -BeGreaterThan $deps
        # A fresh process, not a call: this one still has the code from before the pull.
        $body | Should -Match '& \$p\.pwsh @deps'
    }
    It 'has a deps verb for it to run' {
        Get-Content -Raw (Join-Path $Code 'bin\winarchy.ps1') | Should -Match "'deps' \{\s+Install-Dependencies"
    }
}

Describe 'doctor -Fix' {
    It 'installs what is missing before re-applying' {
        $body = (Get-Command Invoke-Doctor).ScriptBlock.ToString()
        $body.IndexOf('Install-Dependencies') | Should -BeGreaterThan -1
        $body.IndexOf('Install-Dependencies') | Should -BeLessThan $body.IndexOf('Use-Lock { Invoke-Apply }')
    }
}
