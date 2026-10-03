# Pester tests: Herdr (lib/herdr.ps1) and the coding agents (lib/agents.ps1).
# The layouts run against a faked Herdr CLI, so no Herdr, no server and no window is needed.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'journal', 'agents', 'accounts', 'herdr') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'

    # Pester runs a mock's body in its own scope, so the fake keeps its state in globals
    # (reset for every test, removed in AfterAll) rather than in $script: variables.
    # A fake `herdr`: records every call, and answers a split with a fresh pane id the way
    # Herdr 0.9.1 does (.result.pane.pane_id), and a tab create with .result.root_pane.pane_id.
    function Use-FakeHerdr {
        $global:HerdrFakeCalls = [Collections.Generic.List[object]]::new()
        $global:HerdrFakeNext = 1
        Mock Invoke-HerdrCli {
            $global:HerdrFakeCalls.Add(@($CliArgs))
            switch ($CliArgs[0] + ' ' + $CliArgs[1]) {
                'pane split' { $global:HerdrFakeNext++; return [pscustomobject]@{ result = [pscustomobject]@{ pane = [pscustomobject]@{ pane_id = "w1:p$global:HerdrFakeNext" } } } }
                'tab create' { $global:HerdrFakeNext++; return [pscustomobject]@{ result = [pscustomobject]@{ root_pane = [pscustomobject]@{ pane_id = "w1:p$global:HerdrFakeNext" } } } }
                default { return [pscustomobject]@{ result = [pscustomobject]@{ type = 'ok' } } }
            }
        }
        Mock Get-Paths { @{ pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe'; nvim = 'nvim' } }
        Mock Get-Config { @{ apps = @{ editor = 'auto'; agent = 'claude' }; themeTargets = @{ herdr = 'auto' } } }
        $env:HERDR_PANE_ID = 'w1:p1'; $env:HERDR_TAB_ID = 'w1:t1'; $env:HERDR_WORKSPACE_ID = 'w1'
    }
    # The leading comma keeps a lone call whole: returned bare, a single match would be
    # unrolled into its separate strings.
    function Get-Splits { , @($global:HerdrFakeCalls | Where-Object { $_[0] -eq 'pane' -and $_[1] -eq 'split' }) }
    function Get-Runs { , @($global:HerdrFakeCalls | Where-Object { $_[0] -eq 'pane' -and $_[1] -eq 'run' }) }
}

AfterAll {
    Remove-Variable HerdrFakeCalls, HerdrFakeNext -Scope Global -ErrorAction SilentlyContinue
    Remove-Item Env:HERDR_PANE_ID, Env:HERDR_TAB_ID, Env:HERDR_WORKSPACE_ID -ErrorAction SilentlyContinue
}

Describe 'Herdr theme' {
    BeforeEach { Mock Get-Config { @{ themeTargets = @{ herdr = 'auto' } } } }
    It 'uses the Herdr built-in whose name matches the Omarchy theme' {
        Get-HerdrTheme 'tokyo-night' | Should -Be 'tokyo-night'
        Get-HerdrTheme 'gruvbox' | Should -Be 'gruvbox'
    }
    It 'falls back to the terminal palette for a theme Herdr has no built-in for' {
        Get-HerdrTheme 'matte-black' | Should -Be 'terminal'
    }
    It 'lets config.json pin a theme' {
        Mock Get-Config { @{ themeTargets = @{ herdr = 'dracula' } } }
        Get-HerdrTheme 'tokyo-night' | Should -Be 'dracula'
    }
}

Describe 'Herdr config' {
    BeforeEach {
        $script:out = Join-Path $TestDrive 'config.toml'
        $env:HERDR_CONFIG_PATH = $script:out
        Mock Save-File {}
        Mock Get-Paths { @{ pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe' } }
        Mock Get-Config { @{ themeTargets = @{ herdr = 'auto' } } }
        Mock Get-HerdrTemplateFile { Join-Path $Code 'templates\herdr.toml.tpl' }
    }
    AfterEach { Remove-Item Env:HERDR_CONFIG_PATH -ErrorAction SilentlyContinue }

    It 'fills in every placeholder' {
        [void](Write-HerdrConfig 'tokyo-night')
        # (The header comment says "Every {{ ... }} is filled in", so match real placeholders.)
        Get-Content -Raw $script:out | Should -Not -Match '\{\{\s*[a-z_]+\s*\}\}'
    }
    It 'keeps Omarchy''s prefix and tmux-shaped keys' {
        [void](Write-HerdrConfig 'tokyo-night')
        $t = Get-Content -Raw $script:out
        $t | Should -Match 'prefix = "ctrl\+space"'
        $t | Should -Match 'split_horizontal = \["prefix\+h", "alt\+enter"\]'
    }
    It 'points panes at PowerShell 7 as a TOML literal string (a basic one would eat the backslashes)' {
        [void](Write-HerdrConfig 'tokyo-night')
        Get-Content -Raw $script:out | Should -Match "default_shell = 'C:\\Program Files\\PowerShell\\7\\pwsh\.exe'"
    }
    It 'leaves a built-in theme''s own colours alone' {
        [void](Write-HerdrConfig 'tokyo-night')
        $t = Get-Content -Raw $script:out
        $t | Should -Match 'name = "tokyo-night"'
        $t | Should -Not -Match '\[theme\.custom\]'
        $t | Should -Not -Match '(?m)^accent ='
    }
    It 'gives the terminal theme Omarchy''s dark panel and blue accent' {
        [void](Write-HerdrConfig 'matte-black')
        $t = Get-Content -Raw $script:out
        $t | Should -Match 'name = "terminal"'
        $t | Should -Match '(?s)\[theme\.custom\].*panel_bg = "black"'
        $t | Should -Match '(?m)^accent = "blue"'
    }
}

Describe 'Herdr layouts (hdl / hds / hdlm / hsl)' {
    BeforeEach { Use-FakeHerdr }

    It 'refuses outside a Herdr pane' {
        Remove-Item Env:HERDR_PANE_ID
        { Invoke-HerdrLayout 'claude' } | Should -Throw '*not inside Herdr*'
    }
    It 'hdl: terminal off the bottom at 85%, agent on the right at 70%, then runs both' {
        Invoke-HerdrLayout 'claude'
        $s = Get-Splits
        $s.Count | Should -Be 2
        $s[0][2..6] -join ' ' | Should -Be 'w1:p1 --direction down --ratio 0.85'
        $s[1][2..6] -join ' ' | Should -Be 'w1:p1 --direction right --ratio 0.7'
        $s | ForEach-Object { $_ | Should -Contain '--no-focus' }
        $r = Get-Runs
        $r.Count | Should -Be 2
        $r[0][2] | Should -Be 'w1:p3'                       # the agent pane
        $r[0][3] | Should -Match '^claude --permission-mode auto$'
        $r[1][2] | Should -Be 'w1:p1'                       # the editor pane
    }
    It 'hdl with a second agent splits the agent pane in half' {
        Invoke-HerdrLayout 'claude' 'codex'
        $s = Get-Splits
        $s.Count | Should -Be 3
        $s[2][2..6] -join ' ' | Should -Be 'w1:p3 --direction down --ratio 0.5'
        (Get-Runs)[0][3] | Should -Match '^codex --approve-for-me$'
    }
    It 'hds: a 2x2 of four panes' {
        Invoke-HerdrSquare
        (Get-Splits).Count | Should -Be 3
        (Get-Runs).Count | Should -Be 3
    }
    It 'hsl: 7 panes make 3 even columns of 3, 2 and 2' {
        Invoke-HerdrSwarm 7 'claude'
        $s = Get-Splits
        $right = @($s | Where-Object { $_[4] -eq 'right' })
        $right.Count | Should -Be 2
        $right[0][6] | Should -Be '0.3333'                  # 1/3 off the first column
        $right[1][6] | Should -Be '0.5'                     # then half of what is left
        @($s | Where-Object { $_[4] -eq 'down' }).Count | Should -Be 4
        (Get-Runs).Count | Should -Be 7
        (Get-Runs) | ForEach-Object { $_[3] | Should -Be 'claude' }
    }
    It 'hsl: one pane needs no split' {
        Invoke-HerdrSwarm 1 'claude'
        (Get-Splits).Count | Should -Be 0
        (Get-Runs).Count | Should -Be 1
    }
    It 'hdlm: reuses this tab for the first folder and makes a tab for each other one' {
        $dir = Join-Path $TestDrive 'projects'
        foreach ($d in 'alpha', 'beta', 'gamma') { New-Item -ItemType Directory -Force (Join-Path $dir $d) | Out-Null }
        Push-Location $dir
        try { Invoke-HerdrMulti 'claude' } finally { Pop-Location }
        @($global:HerdrFakeCalls | Where-Object { $_[0] -eq 'tab' -and $_[1] -eq 'create' }).Count | Should -Be 2
        $r = Get-Runs
        $r.Count | Should -Be 3
        $r[0][2] | Should -Be 'w1:p1'
        # Named outright, not `winarchy`: in 5.1 that resolves to a .ps1 it cannot parse.
        $r | ForEach-Object { $_[3] | Should -Match 'pwsh\.exe.*-File .*winarchy\.ps1.* herdr layout claude' }
    }
    It 'hdlm: skips dot-folders, and does nothing with no folders, as Omarchy''s does' {
        $dir = Join-Path $TestDrive 'dots'
        New-Item -ItemType Directory -Force (Join-Path $dir '.git') | Out-Null
        Push-Location $dir
        try { Invoke-HerdrMulti 'claude' } finally { Pop-Location }
        (Get-Runs).Count | Should -Be 0
    }
    It 'hds: runs plain opencode when it is installed' {
        Mock Find-AgentExe { 'opencode.cmd' } -ParameterFilter { $cmd -eq 'opencode' }
        Invoke-HerdrSquare
        (Get-Runs)[-1][3] | Should -Be '& opencode.cmd'
    }
    It 'hds: runs it by its full path, which PATH may not have yet' {
        Mock Find-AgentExe { 'C:\Users\Jo Doe\AppData\Roaming\npm\opencode.cmd' } -ParameterFilter { $cmd -eq 'opencode' }
        Invoke-HerdrSquare
        (Get-Runs)[-1][3] | Should -Be "& 'C:\Users\Jo Doe\AppData\Roaming\npm\opencode.cmd'"
    }
    It 'hdl: calls a quoted editor path, which on its own would only be a string' {
        Mock Get-Config { @{ apps = @{ editor = 'C:\Program Files\Neovim\bin\nvim.exe' } } }
        Get-EditorCommand 'C:\x' | Should -Be "& 'C:\Program Files\Neovim\bin\nvim.exe' ."
        Mock Get-Config { @{ apps = @{ editor = 'nvim' } } }
        Get-EditorCommand 'C:\x' | Should -Be 'nvim .'
    }
}

Describe 'Herdr shell shortcuts' {
    BeforeEach { Mock Save-File {}; $script:prof = Join-Path $TestDrive 'profile.ps1' }

    It 'adds hdl, hds, hdlm and hsl to a profile that did not exist' {
        Set-HerdrProfile $script:prof | Should -Be 'written'
        $t = Get-Content -Raw $script:prof
        foreach ($fn in 'hdl', 'hds', 'hdlm', 'hsl') { $t | Should -Match "function $fn " }
    }
    It 'is idempotent' {
        [void](Set-HerdrProfile $script:prof)
        Set-HerdrProfile $script:prof | Should -Be 'unchanged'
        ([regex]::Matches((Get-Content -Raw $script:prof), [regex]::Escape($HerdrProfileBegin))).Count | Should -Be 1
    }
    It 'keeps whatever else is in the profile, and removes only its own block' {
        Set-Content $script:prof "Set-Alias ll Get-ChildItem`r`n"
        [void](Set-HerdrProfile $script:prof)
        Remove-HerdrProfile $script:prof
        $t = Get-Content -Raw $script:prof
        $t | Should -Match 'Set-Alias ll Get-ChildItem'
        $t | Should -Not -Match 'hdl'
    }
}

Describe 'Herdr agent integrations' {
    BeforeEach {
        # A fake herdr.exe: status prints what the real one does, install records the target.
        $global:HerdrInstalls = [Collections.Generic.List[string]]::new()
        Mock Get-HerdrExe {
            {
                $global:LASTEXITCODE = 0
                if ($args[1] -eq 'status') {
                    'claude: current (v10) (C:\Users\me\.claude\hooks\herdr-agent-state.ps1)'
                    'codex: not installed (C:\Users\me\.codex\herdr-agent-state.ps1)'
                    'cursor: not installed (C:\Users\me\.cursor\herdr-agent-state.ps1)'
                    'letta (experimental): not installed (C:\Users\me\.letta\hooks\herdr-agent-session.ps1)'
                } elseif ($args[1] -eq 'install') { $global:HerdrInstalls.Add($args[2]) }
            }
        }
        # On PATH: claude, codex and Cursor's CLI; not letta, and not a `cursor` command.
        Mock Get-Command { if ($Name -in 'claude', 'codex', 'cursor-agent') { [pscustomobject]@{ Name = $Name } } }
        Mock Log {}
    }
    AfterAll { Remove-Variable HerdrInstalls -Scope Global -ErrorAction SilentlyContinue }

    It 'reads which agents are found and which are linked' {
        $a = @(Get-HerdrAgents)
        $a.target | Should -Be @('claude', 'codex', 'cursor', 'letta')
        ($a | Where-Object found).target | Should -Be @('claude', 'codex', 'cursor')
        ($a | Where-Object linked).target | Should -Be @('claude')
    }
    It 'links every agent on PATH that is not linked yet, and nothing else' {
        Sync-HerdrIntegrations | Should -Be @('codex', 'cursor')
        $global:HerdrInstalls | Should -Be @('codex', 'cursor')
    }
    It 'turns Herdr''s own first-run panel off, since the config is rewritten on apply' {
        Get-Content -Raw (Join-Path $Code 'templates\herdr.toml.tpl') | Should -Match '(?m)^onboarding = false\s*$'
    }
    It 'says hello once, from the first Herdr pane' {
        $t = Get-HerdrProfileBlock
        $t | Should -Match ([regex]::Escape($HerdrWelcomeMark))
        $t | Should -Match 'HERDR_PANE_ID.*winarchy herdr welcome'
    }
}

Describe 'Herdr keybindings list' {
    It 'renders bindings the way Omarchy''s viewer does' {
        ConvertTo-HerdrCombo '"prefix+h"' | Should -Be 'Prefix + H'
        ConvertTo-HerdrCombo '["prefix+h", "alt+enter"]' | Should -Be 'Prefix + H / Alt + Enter'
    }
    It 'ignores prose in the default config that only looks like an assignment' {
        ConvertTo-HerdrCombo '"popup" opens a session-modal terminal' | Should -BeNullOrEmpty
    }
    It 'always leaves two spaces between the key and its label, however long the key' {
        foreach ($combo in 'Z', ('X' * 28), ('X' * 29), ('X' * 40)) {
            (Format-HerdrKeyRow $combo 'Label').Trim() -split '\s{2,}' | Should -HaveCount 2
        }
    }
}

Describe 'Coding agents' {
    It 'gives every agent a command, flags, a prompt form and an install hint' {
        foreach ($key in $AgentTable.Keys) {
            $a = $AgentTable[$key]
            $a.label | Should -Not -BeNullOrEmpty
            $a.cmd | Should -Not -BeNullOrEmpty
            $a.prompt | Should -BeOfType [scriptblock]
            $a.hint | Should -Not -BeNullOrEmpty
        }
    }
    It 'resolves Omarchy''s short names and spellings' {
        Resolve-AgentName 'c' | Should -Be 'opencode'
        Resolve-AgentName 'cx' | Should -Be 'claude'
        Resolve-AgentName 'cy' | Should -Be 'codex'
        Resolve-AgentName 'Claude-Code' | Should -Be 'claude'
        Resolve-AgentName 'gemini' | Should -Be 'agy'
        Resolve-AgentName 'nonsense' | Should -BeNullOrEmpty
    }
    It 'starts each agent with its own unattended flags' {
        (Get-AgentCommand 'claude') -join ' ' | Should -Be 'claude --permission-mode auto'
        (Get-AgentCommand 'codex') -join ' ' | Should -Be 'codex --approve-for-me'
        (Get-AgentCommand 'cursor') -join ' ' | Should -Be 'cursor-agent --yolo --trust'
    }
    It 'passes a prompt the way each agent wants it' {
        (Get-AgentCommand 'claude' -Prompt 'fix it') | Should -Be @('claude', '--permission-mode', 'auto', '--', 'fix it')
        (Get-AgentCommand 'cursor' -Prompt 'fix it') | Should -Be @('cursor-agent', '--yolo', '--trust', 'agent', '--', 'fix it')
        # --yolo belongs to crush's interactive command only; `crush run` never prompts.
        (Get-AgentCommand 'crush' -Prompt 'fix it') | Should -Be @('crush', 'run', 'fix it')
    }
    It 'defaults to Claude Code once it is installed' {
        Mock Get-Config { @{ apps = @{ agent = 'auto' } } }
        Mock Test-AgentInstalled { $name -eq 'claude' }
        Get-DefaultAgent | Should -Be 'claude'
    }
    It 'chooses nothing by itself while Claude Code is missing, so the chooser opens' {
        Mock Get-Config { @{ apps = @{ agent = 'auto' } } }
        Mock Test-AgentInstalled { $false }
        Get-DefaultAgent | Should -BeNullOrEmpty
    }
    It 'keeps the agent you picked, installed or not' {
        Mock Get-Config { @{ apps = @{ agent = 'codex' } } }
        Mock Test-AgentInstalled { $true }
        Get-DefaultAgent | Should -Be 'codex'
        Should -Invoke Test-AgentInstalled -Times 0
    }
}

Describe 'Menu wiring' {
    It 'adds Herdr and the agent to the menu' {
        $m = Get-Content -Raw (Join-Path $Code 'zebar\omarchy\menu.json') | ConvertFrom-Json
        @($m.trigger.items | Where-Object { $_.action -contains 'herdr' }).Count | Should -Be 1
        @($m.trigger.items | Where-Object { $_.action -contains 'agent' }).Count | Should -Be 1
        @($m.learn.items | Where-Object route -eq 'herdr-keys').Count | Should -Be 1
        @($m.'setup-default'.items | Where-Object route -eq 'agent').Count | Should -Be 1
        @($m.'setup-config'.items | Where-Object { $_.action -contains 'herdr-config' }).Count | Should -Be 1
    }
    It 'names both generated routes in menu.js, or menu.ahk open <route> falls back to root' {
        $js = Get-Content -Raw (Join-Path $Code 'zebar\omarchy\menu.js')
        $js | Should -Match "'herdr-keys', 'agent', 'timezone'\]\.includes"
    }
    It 'has menu.ahk verbs for every action the rows send' {
        $ahk = Get-Content -Raw (Join-Path $Code 'ahk\menu.ahk')
        foreach ($verb in 'herdr', 'agent', 'default-agent', 'apply-herdr') { $ahk | Should -Match "case `"$verb`":" }
        $ahk | Should -Match 'case "herdr-config": file := HerdrTemplate\(\)'
    }
    It 'reloads Herdr when its template is saved' {
        Get-Content -Raw (Join-Path $Code 'ahk\winarchy.ahk') | Should -Match 'herdr\.toml\.tpl", "apply-herdr"'
    }
}

Describe 'themeTargets.herdr' {
    It 'false keeps Herdr on its plain terminal palette, even for a theme Herdr has' {
        Mock Get-Config { @{ themeTargets = @{ herdr = $false } } }
        Get-HerdrTheme 'tokyo-night' | Should -Be 'terminal'
    }
    It 'auto follows a theme Herdr has' {
        Mock Get-Config { @{ themeTargets = @{ herdr = 'auto' } } }
        Get-HerdrTheme 'tokyo-night' | Should -Be 'tokyo-night'
    }
}
