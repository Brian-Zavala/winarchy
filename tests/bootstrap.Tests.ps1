# Pester tests: the one-line bootstrap (install.ps1) passes -Yes on as a real argument and only
# treats a folder with files in it as an existing copy.
BeforeAll {
    $script:lines = Get-Content (Join-Path (Split-Path -Parent $PSScriptRoot) 'install.ps1')
    function Get-BootstrapLine([string]$Prefix) { ($script:lines | Where-Object { $_ -like "$Prefix*" } | Select-Object -First 1) }
}

Describe 'install.ps1' {
    It 'keeps -Yes a one-item array: a bare string would be splatted one character at a time' {
        $env:WINARCHY_YES = '1'
        try {
            Invoke-Expression (Get-BootstrapLine '$yes =')
            , $yes | Should -BeOfType [object[]]
            @($yes) | Should -Be @('-Yes')
        } finally { $env:WINARCHY_YES = $null }
    }
    It 'passes nothing without WINARCHY_YES' {
        $env:WINARCHY_YES = $null
        Invoke-Expression (Get-BootstrapLine '$yes =')
        @($yes).Count | Should -Be 0
    }
    It 'does not count an empty leftover folder as an installed copy' {
        $dest = Join-Path $TestDrive 'winarchy'
        New-Item -ItemType Directory (Join-Path $dest 'ps51') | Out-Null
        Invoke-Expression (Get-BootstrapLine '$hasFiles =')
        $hasFiles | Should -BeFalse
        Set-Content (Join-Path $dest 'ps51\x.ps1') 'x'
        Invoke-Expression (Get-BootstrapLine '$hasFiles =')
        $hasFiles | Should -BeTrue
    }
}

Describe 'install.ps1 on Windows PowerShell 5.1' {
    It 'parses in 5.1, the PowerShell every Windows 11 PC has' {
        $ps51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        if (-not (Test-Path $ps51)) { Set-ItResult -Skipped -Because 'no Windows PowerShell here'; return }
        $file = Join-Path (Split-Path -Parent $PSScriptRoot) 'install.ps1'
        $out = & $ps51 -NoProfile -NonInteractive -Command "`$e = `$null; [void][Management.Automation.Language.Parser]::ParseFile('$file', [ref]`$null, [ref]`$e); `$e | ForEach-Object { `$_.Message }"
        $out | Should -BeNullOrEmpty
    }
    It 'reads git output as text, so stderr cannot end it under ErrorActionPreference Stop' {
        Get-BootstrapLine '    try { & git @args 2>&1' | Should -Not -BeNullOrEmpty
        @($script:lines | Where-Object { $_ -match '^\s+git -C|\(git -C' }).Count | Should -Be 0
    }
}
