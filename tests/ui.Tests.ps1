# Pester tests: the installer's look (lib/ui.ps1) and Log's tidy console mode.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'ui') { . "$root\lib\$f.ps1" }
    $LogFile = Join-Path $TestDrive 'winarchy.log'
}

Describe 'Installer UI' {
    It 'draws every banner row the same width' {
        $widths = @(Get-UiBannerRows | ForEach-Object Length | Sort-Object -Unique)
        $widths.Count | Should -Be 1
    }
    It 'falls back to ASCII outside Windows Terminal' {
        $saved = $env:WT_SESSION, $env:TERM_PROGRAM, $env:WINARCHY_UNICODE
        try {
            $env:WT_SESSION = $null; $env:TERM_PROGRAM = $null; $env:WINARCHY_UNICODE = $null
            (Get-UiGlyphs).step | Should -Be '==>'
            $env:WT_SESSION = 'x'
            (Get-UiGlyphs).ok | Should -Be ([string][char]0x2713)
        } finally { $env:WT_SESSION, $env:TERM_PROGRAM, $env:WINARCHY_UNICODE = $saved }
    }
    It 'blends colours end to end' {
        Get-UiBlend 0x000000 0xffffff 0 | Should -Be 0x000000
        Get-UiBlend 0x000000 0xffffff 1 | Should -Be 0xffffff
    }
    It 'keeps the full timestamped line in the log file while the console gets a bullet' {
        $script:UiPretty = $true
        try { Log 'hello' 6>$null } finally { $script:UiPretty = $false }
        Get-Content $LogFile -Raw | Should -Match '\d\d:\d\d:\d\d \[test\] hello'
    }
    It 'shows the clock only once it runs' {
        $script:UiClock = $null
        Get-UiClock | Should -Be ''
        Start-UiClock
        try { Get-UiClock | Should -Match '^\d+:\d\d$' } finally { $script:UiPretty = $false; $script:UiClock = $null }
    }
}
