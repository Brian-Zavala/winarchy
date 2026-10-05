# Pester tests: no test file may reach the real backup journal in ~/.winarchy/backup.
# lib/journal.ps1 sets $BackupRoot from $Data as it loads, so a file that points $Data at
# the test drive afterwards still has the real one. On 2026-10-02 a test that ran
# Invoke-Uninstall twice marked a real install journal undone without undoing anything,
# and the uninstall that followed left winarchy starting at every login.
BeforeDiscovery {
    $root = Split-Path -Parent $PSScriptRoot
    $files = @(Get-ChildItem "$root\tests" -Filter *.Tests.ps1 |
        Where-Object { (Get-Content -Raw $_.FullName) -match "foreach \(\`$f in [^)]*'journal'" } |
        ForEach-Object { @{ name = $_.Name; path = $_.FullName } })
}

Describe '<name>' -ForEach $files {
    It 'points $BackupRoot at the test drive after loading the libraries' {
        $text = Get-Content -Raw $path
        $load = [regex]::Match($text, "foreach \(\`$f in [^)]*'journal'")
        $redirect = [regex]::Match($text, "(?m)^\s*\`$BackupRoot = Join-Path \`$TestDrive ")
        $redirect.Success | Should -BeTrue
        $redirect.Index | Should -BeGreaterThan $load.Index
    }
}

Describe 'The journal-loading test files' {
    It 'are found (the pattern above still matches how tests load libraries)' {
        $root = Split-Path -Parent $PSScriptRoot
        @(Get-ChildItem "$root\tests" -Filter *.Tests.ps1 | Where-Object { (Get-Content -Raw $_.FullName) -match "foreach \(\`$f in [^)]*'journal'" }).Count |
            Should -BeGreaterThan 5
    }
}
