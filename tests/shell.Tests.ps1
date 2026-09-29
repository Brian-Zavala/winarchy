# Pester tests: Omarchy's shell setup in the PowerShell profile (lib/shell.ps1). Only a
# profile file in the test drive is ever written.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'journal', 'herdr', 'shell') { . "$root\lib\$f.ps1" }
    $Code = $root
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    Mock Save-File {}
}

Describe 'Profile block' {
    BeforeEach {
        # Named as the real one: uninstall recognises profiles by name.
        $dir = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory $dir | Out-Null
        $script:file = Join-Path $dir 'profile.ps1'
    }
    It 'adds itself once, after what is there, and replaces itself in place' {
        Set-Content $script:file '# mine'
        Set-ShellProfile $script:file | Should -Be 'written'
        Set-ShellProfile $script:file | Should -Be 'unchanged'
        $t = Get-Content -Raw $script:file
        $t | Should -Match '^# mine'
        ([regex]::Matches($t, [regex]::Escape($ShellProfileBegin))).Count | Should -Be 1
    }
    It 'comes out again, leaving the rest and the Herdr block' {
        Set-Content $script:file "# mine`r`n$(Get-HerdrProfileBlock)"
        Set-ShellProfile $script:file | Out-Null
        Remove-ShellProfile $script:file
        $t = Get-Content -Raw $script:file
        $t | Should -Not -Match ([regex]::Escape($ShellProfileBegin))
        $t | Should -Match ([regex]::Escape($HerdrProfileBegin))
        $t | Should -Match '# mine'
    }
    It 'never redefines ls, cat or cd, and checks every name before taking it' {
        $block = Get-ShellProfileBlock
        $block | Should -Not -Match 'function global:(ls|cat|cd|gcm|h|r)\b'
        foreach ($m in [regex]::Matches($block, 'function global:(\S+)')) {
            $block | Should -Match ("free " + [regex]::Escape($m.Groups[1].Value) + "\)") -Because $m.Groups[1].Value
        }
    }
    It 'parses as PowerShell' {
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseInput((Get-ShellProfileBlock), [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }
    It 'is taken out by uninstall with the profile''s other winarchy parts' {
        Set-ShellProfile $script:file | Out-Null
        Restore-PartOwnedFile @{ path = $script:file; existed = $false } $TestDrive | Should -BeTrue
        Test-Path $script:file | Should -BeFalse
    }
}
