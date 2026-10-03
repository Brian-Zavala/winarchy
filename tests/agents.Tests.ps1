# Pester tests: launching coding agents (lib/agents.ps1). Nothing is started for real.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'agents', 'accounts') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    Add-Type -Namespace Win32 -Name Argv -MemberDefinition @'
[DllImport("shell32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr CommandLineToArgvW(string cmdLine, out int count);
[DllImport("kernel32.dll")] public static extern IntPtr LocalFree(IntPtr p);
'@
    # How Windows splits a command line back into arguments (after the exe name).
    function Split-CommandLine([string]$line) {
        $n = 0
        $ptr = [Win32.Argv]::CommandLineToArgvW("x.exe $line", [ref]$n)
        try { 1..($n - 1) | ForEach-Object { [Runtime.InteropServices.Marshal]::PtrToStringUni([Runtime.InteropServices.Marshal]::ReadIntPtr($ptr, $_ * [IntPtr]::Size)) } }
        finally { [void][Win32.Argv]::LocalFree($ptr) }
    }
}

Describe 'Join-ProcessArgs' {
    It 'round-trips spaces, quotes, backslashes and empty items' {
        $items = @('-p', 'Omarchy Agent', 'say "hi"', 'C:\dir with space\', 'a\\"b', '')
        Split-CommandLine (Join-ProcessArgs $items) | Should -Be $items
    }
}

Describe 'Start-AgentTerminal' {
    BeforeEach {
        Mock Get-Paths { @{ wt = 'wt.exe'; pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe' } }
        Mock Start-Process {}
    }
    It 'opens the "Omarchy Agent" profile in Windows Terminal, with the whole command intact' {
        Start-AgentTerminal @('claude', '--model', 'a b')
        Should -Invoke Start-Process -Times 1 -ParameterFilter {
            $a = @(Split-CommandLine $ArgumentList)
            $a[3] -eq 'Omarchy Agent' -and $a -contains 'C:\Program Files\PowerShell\7\pwsh.exe' -and $a[-1] -eq "claude --model 'a b'"
        }
    }
    It 'starts in your home folder when given none, not the folder that launched it' {
        Start-AgentTerminal @('claude')
        Should -Invoke Start-Process -ParameterFilter {
            $a = @(Split-CommandLine $ArgumentList)
            $a[[array]::IndexOf($a, '-d') + 1] -eq $HOME
        }
    }
    It 'escapes ; so Windows Terminal does not split it into a second tab' {
        Start-AgentTerminal @('claude', 'x;y')
        Should -Invoke Start-Process -ParameterFilter { @(Split-CommandLine $ArgumentList)[-1] -eq "claude 'x\;y'" }
    }
    It 'starts it in the folder it is given' {
        Start-AgentTerminal @('claude') -Dir 'C:\Users\me\.winarchy\themes'
        Should -Invoke Start-Process -ParameterFilter {
            $a = @(Split-CommandLine $ArgumentList)
            $i = [array]::IndexOf($a, '-d')
            $i -gt 0 -and $a[$i + 1] -eq 'C:\Users\me\.winarchy\themes' -and $i -lt [array]::IndexOf($a, 'C:\Program Files\PowerShell\7\pwsh.exe')
        }
    }
    It 'starts it in that folder without Windows Terminal too' {
        Mock Get-Paths { @{ pwsh = 'pwsh.exe' } }
        Start-AgentTerminal @('claude') -Dir 'C:\work'
        Should -Invoke Start-Process -ParameterFilter { $WorkingDirectory -eq 'C:\work' }
    }
}

Describe 'ConvertTo-PwshCommandLine (a prompt reaches the agent as written)' {
    It 'leaves plain words alone and single-quotes the rest' {
        ConvertTo-PwshCommandLine @('claude', '--permission-mode', 'auto', '--', 'fix it') | Should -Be "claude --permission-mode auto -- 'fix it'"
    }
    It 'keeps $, backticks, double quotes and apostrophes literal' {
        $prompt = "Ask what I'd like: `"`$HOME`" and ``n stay as they are; C:\it's here"
        $line = ConvertTo-PwshCommandLine @('claude', $prompt)
        # What PowerShell itself parses out of that line: the same prompt, as one argument.
        $ast = [Management.Automation.Language.Parser]::ParseInput($line, [ref]$null, [ref]$null)
        $words = $ast.EndBlock.Statements[0].PipelineElements[0].CommandElements
        $words.Count | Should -Be 2
        $words[1].Value | Should -BeExactly $prompt
    }
    It 'quotes a typographic apostrophe, which PowerShell also reads as a quote' {
        $prompt = "it" + [char]0x2019 + "s"
        $ast = [Management.Automation.Language.Parser]::ParseInput((ConvertTo-PwshCommandLine @('x', $prompt)), [ref]$null, [ref]$null)
        $ast.EndBlock.Statements[0].PipelineElements[0].CommandElements[1].Value | Should -BeExactly $prompt
    }
    It 'calls an exe path with spaces through &' {
        ConvertTo-PwshCommandLine @('C:\Program Files\x\agent.exe', 'go') | Should -Be "& 'C:\Program Files\x\agent.exe' go"
    }
}

Describe 'Invoke-AgentMake (the usage panel''s Make something tiles)' {
    BeforeEach { Mock Invoke-Agent {} }
    It 'starts the default agent for a <kind> in its folder, with a prompt pointing at its guide' -ForEach @(
        @{ kind = 'theme' }, @{ kind = 'plugin' }, @{ kind = 'app' }
    ) {
        $AgentMake[$kind].dir = Join-Path $TestDrive "make-$kind"
        Invoke-AgentMake $kind
        Test-Path (Join-Path $TestDrive "make-$kind") | Should -BeTrue
        Should -Invoke Invoke-Agent -Times 1 -ParameterFilter {
            $Pick -and $Dir -eq (Join-Path $TestDrive "make-$kind") -and $Prompt -like "*$(Join-Path $Code "agents\make\$kind.md")*"
        }
    }
    It 'has a guide for every tile' {
        foreach ($k in $AgentMake.Keys) { Test-Path (Join-Path $Code "agents\make\$k.md") | Should -BeTrue }
    }
    It 'refuses anything else' {
        { Invoke-AgentMake 'spaceship' } | Should -Throw '*usage: winarchy agent-make <theme|plugin|app>*'
        { Invoke-AgentMake '' } | Should -Throw '*usage*'
    }
    It 'remembers the tile when there is no default agent yet, for the one picked next' {
        $AgentMakePending = Join-Path $TestDrive 'pending.json'
        $AgentMake.theme.dir = Join-Path $TestDrive 'make-theme'
        Mock Get-DefaultAgent { $null }
        Invoke-AgentMake 'theme'
        Pop-AgentMakePending | Should -Be 'theme'
        Pop-AgentMakePending | Should -BeNullOrEmpty   # once
    }
    It 'remembers nothing when a default agent starts on it right away' {
        $AgentMakePending = Join-Path $TestDrive 'pending2.json'
        $AgentMake.app.dir = Join-Path $TestDrive 'make-app'
        Mock Get-DefaultAgent { 'claude' }
        Invoke-AgentMake 'app'
        Test-Path $AgentMakePending | Should -BeFalse
    }
    It 'forgets a tile from long ago' {
        $AgentMakePending = Join-Path $TestDrive 'pending3.json'
        Write-Json $AgentMakePending @{ kind = 'plugin'; at = (Get-Date).ToUniversalTime().AddHours(-1).ToString('o') }
        Pop-AgentMakePending | Should -BeNullOrEmpty
    }
}

Describe 'Invoke-AgentLogin (the usage panel''s Sign in)' {
    It 'knows how Claude Code and Codex sign in' {
        @($AgentLogin['claude']) | Should -Be @('claude', 'auth', 'login')
        @($AgentLogin['codex']) | Should -Be @('codex', 'login')
    }
    It 'runs the login, then refreshes that agent''s limits' {
        Mock Test-AgentInstalled { $true }
        Mock Update-AgentUsage {}
        function global:fake-login { $global:gotLogin = $args }
        $AgentLogin['fake'] = @('fake-login', 'now')
        try { Invoke-AgentLogin 'fake' } finally { $AgentLogin.Remove('fake'); Remove-Item function:global:fake-login }
        $global:gotLogin | Should -Be @('now')
        Should -Invoke Update-AgentUsage -Times 1 -ParameterFilter { $Force -and $Only -eq 'fake' }
    }
    It 'stops without refreshing when the sign-in fails or is cancelled' {
        Mock Test-AgentInstalled { $true }
        Mock Update-AgentUsage {}
        function global:fake-login { $global:LASTEXITCODE = 1 }
        $AgentLogin['fake'] = @('fake-login')
        $AgentTable['fake'] = @{ label = 'Fake' }
        try { { Invoke-AgentLogin 'fake' } | Should -Throw '*Fake sign-in did not finish*' }
        finally { $AgentLogin.Remove('fake'); $AgentTable.Remove('fake'); Remove-Item function:global:fake-login }
        Should -Invoke Update-AgentUsage -Times 0
    }
    It 'runs the login by its full path when PATH lacks it' {
        Mock Test-AgentInstalled { $true }
        Mock Update-AgentUsage {}
        function global:fake-login-by-path { $global:gotLogin = 'by path' }
        Mock Find-AgentExe { 'fake-login-by-path' }
        $AgentLogin['fake'] = @('fake-login', 'now')
        try { Invoke-AgentLogin 'fake' } finally { $AgentLogin.Remove('fake'); Remove-Item function:global:fake-login-by-path }
        $global:gotLogin | Should -Be 'by path'
    }
    It 'says how to install an agent that is missing' {
        Mock Test-AgentInstalled { $false }
        { Invoke-AgentLogin 'codex' } | Should -Throw '*winget install -e --id OpenAI.Codex*'
    }
    It 'refuses an agent it cannot sign in' {
        { Invoke-AgentLogin 'crush' } | Should -Throw '*usage: winarchy agent-login <claude|codex>*'
    }
    It 'tells the panel which agents can sign in (defaults.json)' {
        $Pack = Join-Path $TestDrive 'pack'
        Mock Get-DefaultAgent { 'claude' }
        Mock Test-AgentInstalled { $true }
        $list = @(Update-AgentList)
        ($list | Where-Object { $_.key -eq 'claude' }).login | Should -BeTrue
        ($list | Where-Object { $_.key -eq 'crush' }).login | Should -BeFalse
    }
}

Describe 'Invoke-Agent -Inline' {
    It 'runs a one-word agent command with no arguments (pi, not pi pi)' {
        Mock Get-DefaultAgent { 'pi' }
        Mock Test-AgentInstalled { $true }
        Mock Get-AgentCommand { 'fake-agent' }
        function global:fake-agent { $global:gotArgs = $args }
        Invoke-Agent -Inline
        $global:gotArgs.Count | Should -Be 0
        Remove-Item function:global:fake-agent
    }
}

Describe 'Agent shorthands (Omarchy default/bash/aliases)' {
    It 'maps c, cx and cy the way Omarchy does' {
        Resolve-AgentName 'c' | Should -Be 'opencode'
        Resolve-AgentName 'cx' | Should -Be 'claude'
        Resolve-AgentName 'cy' | Should -Be 'codex'
    }
    It 'runs the default agent for a in hdl' {
        . "$root\lib\herdr.ps1"
        Mock Get-DefaultAgent { 'codex' }
        Mock Get-AgentCommand { 'codex', '--yolo' }
        Get-HerdrAgentCommand 'a' | Should -Be 'codex --yolo'
        Should -Invoke Get-AgentCommand -ParameterFilter { $name -eq 'codex' }
    }
}
