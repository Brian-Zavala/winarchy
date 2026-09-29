# Pester tests: several accounts per agent (lib/accounts.ps1). Homes and the registry live
# in $TestDrive; nothing signs in and no real CLI runs.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'agents') { . "$root\lib\$f.ps1" }
    $Code = $root
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    $savedProfile = $env:USERPROFILE
    $env:USERPROFILE = Join-Path $TestDrive 'user'
    $AccountStateHome = Join-Path $TestDrive 'state'
    $AccountsRoot = Join-Path $AccountStateHome 'omarchy\agents\accounts'
    $Pack = Join-Path $TestDrive 'pack'
    $AgentUsageDir = Join-Path $TestDrive 'usage'
    New-Item -ItemType Directory -Force $Pack, $AgentUsageDir | Out-Null
    function Get-DefaultAgent { 'claude' }
    # Anything that would talk to a CLI answers from the folder alone.
    Mock Get-AccountIdentity { @{} }
}
AfterAll { $env:USERPROFILE = $savedProfile }

Describe 'account ids' {
    It 'slugs the label, skips reserved and device names, and never comes back empty' {
        $r = ConvertTo-AccountRegistry 'claude' $null
        New-AccountId 'claude' $r 'Work Stuff!' $null | Should -Be 'work-stuff'
        New-AccountId 'claude' $r 'Main' $null | Should -Be 'main-2'
        New-AccountId 'claude' $r 'CON' $null | Should -Be 'con-2'
        New-AccountId 'claude' $r 'Ünï' $null | Should -Be 'n'
        New-AccountId 'claude' $r '日本' $null | Should -Be 'account'
    }
    It 'reads provider/id references' {
        $ref = Resolve-AccountRef 'Claude/work'
        $ref.provider | Should -Be 'claude'
        $ref.id | Should -Be 'work'
    }
}

Describe 'the registry' {
    BeforeEach { Remove-Item -Recurse -Force $AccountStateHome -ErrorAction SilentlyContinue }
    It 'always has the primary, a valid mode, a clamped threshold and an active account that exists' {
        $r = ConvertTo-AccountRegistry 'claude' @{ switch = 'sideways'; threshold = 12; active = 'ghost'; accounts = @() }
        $r.accounts[0].id | Should -Be 'main'
        $r.accounts[0].primary | Should -BeTrue
        $r.switch | Should -Be 'manual'
        $r.threshold | Should -Be 50
        $r.active | Should -Be 'main'
    }
    It 'keeps a file that does not parse as .bad and rebuilds from the homes' {
        New-Item -ItemType Directory -Force (Join-Path $AccountsRoot 'claude\work') | Out-Null
        Set-Content (Join-Path $AccountsRoot 'claude.json') '{ not json'
        $r = Read-AccountRegistry 'claude'
        Test-Path (Join-Path $AccountsRoot 'claude.json.bad') | Should -BeTrue
        @($r.accounts.id) | Should -Be @('main', 'work')
    }
}

Describe 'account homes' {
    BeforeAll {
        $primary = Join-Path $env:USERPROFILE '.claude'
        New-Item -ItemType Directory -Force (Join-Path $primary 'projects') | Out-Null
        Set-Content (Join-Path $primary 'projects\keep.jsonl') 'mine'
        Set-Content (Join-Path $primary 'settings.json') '{"theme":"dark"}'
    }
    BeforeEach {
        Remove-Item -Recurse -Force $AccountStateHome -ErrorAction SilentlyContinue
        $work = Join-Path $AccountsRoot 'claude\work'
        Connect-AccountHome 'claude' $work
        Save-AccountRegistry 'claude' ([ordered]@{ active = 'main'; switch = 'manual'; threshold = 95; alert = ''; accounts = @(
                    [ordered]@{ id = 'main'; label = 'Main'; home = ''; primary = $true },
                    [ordered]@{ id = 'work'; label = 'Work'; home = $work; primary = $false }) })
    }
    It 'links shared folders to the primary, copies settings and imports CLAUDE.md' {
        Get-AccountLinkTarget (Join-Path $work 'projects') | Should -Not -BeNullOrEmpty
        Get-Content (Join-Path $work 'projects\keep.jsonl') | Should -Be 'mine'
        (Get-Item (Join-Path $work 'settings.json')).LinkType | Should -BeNullOrEmpty
        Get-Content -Raw (Join-Path $work 'CLAUDE.md') | Should -Match '^@~/\.claude/CLAUDE\.md'
        { Connect-AccountHome 'claude' $work } | Should -Not -Throw
    }
    It 'switches, cycles with next, and renames' {
        (Use-AgentAccount 'claude' 'work').active.id | Should -Be 'work'
        Get-AgentAccountHome 'claude' | Should -Be $work
        (Use-AgentAccount 'claude' 'next').active.id | Should -Be 'main'
        (Rename-AgentAccount 'claude' 'work' 'Side Gig').id | Should -Be 'side-gig'
        { Use-AgentAccount 'claude' 'ghost' } | Should -Throw '*No Claude account named ghost*'
    }
    It 'puts the home in the launch environment only for an added account, and never over an explicit one' {
        Get-AgentLaunchEnv 'claude' | Should -BeNullOrEmpty
        [void](Use-AgentAccount 'claude' 'work')
        (Get-AgentLaunchEnv 'claude').CLAUDE_CONFIG_DIR | Should -Be $work
        $env:CLAUDE_CONFIG_DIR = 'C:\mine'
        try { Get-AgentLaunchEnv 'claude' | Should -BeNullOrEmpty } finally { Remove-Item Env:CLAUDE_CONFIG_DIR }
    }
    It 'removes an account without touching what its links point at' {
        [void](Use-AgentAccount 'claude' 'work')
        { Remove-AgentAccount 'claude' 'main' } | Should -Throw
        [void](Remove-AgentAccount 'claude' 'work')
        Test-Path $work | Should -BeFalse
        Get-Content (Join-Path $primary 'projects\keep.jsonl') | Should -Be 'mine'
        (Read-AccountRegistry 'claude').active | Should -Be 'main'
    }
    It 'clears links before a purge, so a recursive delete keeps the primary intact' {
        Clear-AccountLinks $AccountsRoot
        Remove-Item -Recurse -Force $AccountStateHome
        Get-Content (Join-Path $primary 'projects\keep.jsonl') | Should -Be 'mine'
    }
    It 'repair drops a vanished home and writes the profile functions only while there are several' {
        $prof = Join-Path $TestDrive 'profile.ps1'
        Mock Set-AccountProfile { Set-Content $prof 'block' }
        Mock Remove-AccountProfile { Remove-Item $prof -ErrorAction SilentlyContinue }
        Repair-AgentAccounts
        Test-Path $prof | Should -BeTrue
        Clear-AccountLinks $work; Remove-Item -Recurse -Force $work
        Repair-AgentAccounts
        @((Read-AccountRegistry 'claude').accounts).Count | Should -Be 1
        Test-Path $prof | Should -BeFalse
    }
}

Describe 'the profile block' {
    It 'parses, and wraps claude and codex' {
        $block = Get-AccountProfileBlock
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseInput($block, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
        $block | Should -Match 'function global:claude'
        $block | Should -Match 'ExpectingInput'
    }
}

Describe 'launch lines' {
    It 'set the account home first, quoted so it arrives as written' {
        $line = ConvertTo-PwshCommandLine @('claude', 'hi') -Env @{ CLAUDE_CONFIG_DIR = "C:\it's here" }
        $line | Should -Be "`$env:CLAUDE_CONFIG_DIR='C:\it''s here'; claude hi"
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseInput($line, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }
}
