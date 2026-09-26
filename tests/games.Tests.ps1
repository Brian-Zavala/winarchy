# Pester tests: games are left alone by GlazeWM (the ignore rules winarchy apply writes).
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'apply', 'animations') { . "$root\lib\$f.ps1" }
    $Code = $root
}

Describe 'Game ignore rules' {
    It 'takes process names from Game Bar''s list and config.games' {
        $exes = 'C:\Games\Crash Bandicoot 4\Lava\Binaries\Win64\CrashBandicoot4.exe', 'G:\Cuphead\Cuphead.exe', $null
        $names = Get-GameProcesses @{ games = @('MyGame.exe', 'cuphead') } $exes
        $names | Should -Be @('CrashBandicoot4', 'Cuphead', 'MyGame')
    }
    It 'never lists apps winarchy manages' {
        Get-GameProcesses @{} @('C:\Windows\explorer.exe', 'C:\x\WindowsTerminal.exe', 'C:\x\Game.exe') | Should -Be @('Game')
    }
    It 'lists nothing with gameMode off' {
        Get-GameProcesses @{ gameMode = $false; games = @('MyGame') } @('C:\x\Game.exe') | Should -BeNullOrEmpty
    }
    It 'writes YAML match entries, quotes escaped' {
        $y = ConvertTo-GamesYaml @('CrashBandicoot4', "Tom's")
        $y | Should -Match "(?m)^      - window_process: \{ equals: 'CrashBandicoot4' \}$"
        $y | Should -Match "equals: 'Tom''s'"
        ConvertTo-GamesYaml @() | Should -Match '^\s+#'
    }
    It 'fills the template''s ignore list' {
        $tpl = Get-Content -Raw "$root\templates\glazewm.yaml.tpl"
        $tpl | Should -Match '\{\{ games \}\}'
        $yaml = Expand-Template $tpl @{ gap = '10'; gap_top = '36'; focused_border = '#7aa2f7'; workspaces = ''; animations = ''; games = (ConvertTo-GamesYaml @('CrashBandicoot4')) }
        $yaml | Should -Match "Playnite\.FullscreenApp' \}\s+- window_title: \{ equals: 'Steam Big Picture Mode' \}\s+- window_process: \{ equals: 'CrashBandicoot4' \}"
    }
}
