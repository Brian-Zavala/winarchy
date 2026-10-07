# Pester tests: games are left alone by GlazeWM (the ignore rules winarchy apply writes).
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'apply', 'animations') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
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

Describe 'Add-ConfigGame (Super+Ctrl+G / winarchy game-add)' {
    BeforeAll { Mock Log {} }
    BeforeEach {
        $ConfigFile = Join-Path $TestDrive ([guid]::NewGuid())
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
    }
    It 'adds a game to a config.json that does not exist yet' {
        Add-ConfigGame 'Townfall-Win64-Shipping.exe'
        (Read-Json $ConfigFile -AsHashtable).games | Should -Be @('Townfall-Win64-Shipping')
    }
    It 'keeps your other keys and games, and never adds one twice' {
        Write-Json $ConfigFile @{ gap = 4; games = @('Existing') }
        Add-ConfigGame 'Existing'
        Add-ConfigGame 'New.exe'
        $cfg = Read-Json $ConfigFile -AsHashtable
        $cfg.gap | Should -Be 4
        $cfg.games | Should -Be @('Existing', 'New')
    }
    It 'does nothing with an empty name' {
        Add-ConfigGame ''
        Test-Path $ConfigFile | Should -BeFalse
    }
    It 'stamps its own write, so winarchy.ahk does not re-apply everything over the game' {
        Add-ConfigGame 'Game'
        Test-Path (Join-Path $Generated 'config.selfwrite') | Should -BeTrue
    }
    It 'refuses to touch a config.json with a JSON error, and says where' {
        Set-Content $ConfigFile '{ "gameDirs": ["C:\Games"], "gap": 4 }'
        { Add-ConfigGame 'Game' } | Should -Throw '*not valid JSON*'
        Get-Content -Raw $ConfigFile | Should -BeLike '*"C:\Games"*'
    }
}

Describe 'Register-Game (winarchy game-add)' {
    BeforeAll {
        Mock Log {}
        Mock Get-Paths { @{} }
        Mock Write-AhkIni {}
        Mock Invoke-Apply {}
    }
    BeforeEach {
        $ConfigFile = Join-Path $TestDrive ([guid]::NewGuid())
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
    }
    It 'rewrites winarchy.ini at once: the admin helper only closes games listed there' {
        Register-Game 'CollegeFB27.exe' -NoGlaze
        (Read-Json $ConfigFile -AsHashtable).games | Should -Be @('CollegeFB27')
        Should -Invoke Write-AhkIni -Times 1
        Should -Invoke Invoke-Apply -Times 0
    }
    It 'reloads GlazeWM''s rules without -NoGlaze' {
        Register-Game 'Game'
        Should -Invoke Invoke-Apply -Times 1 -ParameterFilter { $MonitorsOnly }
    }
}

Describe 'Games found by winarchy.ahk' {
    BeforeAll { $wm = Get-Content -Raw "$root\ahk\winarchy.ahk" }
    It 'clears hidden menus and panels, and lists admin games for the helper, once found' {
        $wm | Should -Match '(?s)IsGame\(hwnd\) \{.*SetTimer CloseHiddenWidgets, -10.*OmarchyCmd\("game-add", name, "-NoRestart"\).*\n\}'
    }
    It 'says so when the admin helper refuses to close a game' {
        $wm | Should -Match '(?s)CloseGame\(.*SendMessage\(0x5556'
    }
}

Describe 'config.json with a JSON error' {
    BeforeAll { Mock Log {}; Mock Write-Warning {} }
    BeforeEach {
        $ConfigFile = Join-Path $TestDrive ([guid]::NewGuid())
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
        Set-Content $ConfigFile '{ "gap": 4, }x'
    }
    It 'is read as the defaults, with a warning' {
        (Get-Config).gap | Should -Not -Be 4
        Should -Invoke Write-Warning -Times 1
    }
    It 'is never overwritten' {
        { Set-ConfigValue 'animations.enabled' $true } | Should -Throw
        Get-Content -Raw $ConfigFile | Should -Match '"gap": 4, }x'
    }
}

Describe 'Set-ConfigValue' {
    BeforeEach {
        $ConfigFile = Join-Path $TestDrive ([guid]::NewGuid())
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
    }
    It 'writes a top-level key as itself, not nested in its own name' {
        Set-ConfigValue 'gap' 6
        $c = Read-Json $ConfigFile -AsHashtable
        $c.gap | Should -Be 6
        $c.Keys | Should -Be @('gap')
    }
}
