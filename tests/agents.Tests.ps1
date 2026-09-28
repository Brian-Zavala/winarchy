# Pester tests: launching coding agents (lib/agents.ps1). Nothing is started for real.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'agents') { . "$root\lib\$f.ps1" }
    $Code = $root
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
            $a[3] -eq 'Omarchy Agent' -and $a[4] -eq 'C:\Program Files\PowerShell\7\pwsh.exe' -and $a[-1] -eq 'claude --model "a b"'
        }
    }
    It 'escapes ; so Windows Terminal does not split it into a second tab' {
        Start-AgentTerminal @('x;y')
        Should -Invoke Start-Process -ParameterFilter { @(Split-CommandLine $ArgumentList)[-1] -eq 'x\;y' }
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
