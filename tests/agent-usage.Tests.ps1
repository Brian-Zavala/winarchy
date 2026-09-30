# Pester tests: the bar's agent usage (lib/agents/*.py collectors, lib/agents.ps1).
# The collectors run for real, on fixture data under $TestDrive: no network (no Claude
# sign-in means no limits probe), no real ~/.claude, and a fake Codex app-server.
# -Skip is decided while Pester discovers the tests, before BeforeAll has loaded anything.
BeforeDiscovery {
    $Verb = 'test'
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\common.ps1')
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\detect.ps1')
    $hasPython = [bool](Find-Python)
}

BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'journal', 'apply', 'agents', 'accounts') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    $script:python = Find-Python

    # Run one collector with the environment winarchy gives it, plus overrides; returns
    # the parsed record.
    function Invoke-Collector([string]$id, [hashtable]$envVars) {
        $saved = @{}
        # WINARCHY_TEST_PYTHON: the fake codex.cmd runs its server with this same interpreter.
        $all = @{ XDG_CACHE_HOME = (Join-Path $TestDrive 'cache'); PYTHONDONTWRITEBYTECODE = '1'; PYTHONIOENCODING = 'utf-8'
            WINARCHY_TEST_PYTHON = $script:python } + $envVars
        foreach ($k in $all.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k); [Environment]::SetEnvironmentVariable($k, $all[$k]) }
        try {
            $out = & $script:python (Join-Path $root "lib\agents\usage-$id.py") --force 2>$null
            $out | Out-String | ConvertFrom-Json
        } finally {
            foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) }
        }
    }

    # Omarchy's record contract, schemaVersion 1: what the panel and the bar read.
    function Assert-RecordV1($r, [string]$id) {
        $r.schemaVersion | Should -Be 1
        $r.id | Should -Be $id
        $r.name | Should -Not -BeNullOrEmpty
        $r.updatedAt | Should -Not -BeNullOrEmpty
        $r.PSObject.Properties.Name | Should -Contain 'ready'
        $r.PSObject.Properties.Name | Should -Contain 'limits'
        $r.PSObject.Properties.Name | Should -Contain 'usageStatusText'
        $r.PSObject.Properties.Name | Should -Contain 'authHelpText'
        @($r.recentDays).Count | Should -Be 7
    }
}

Describe 'Python' {
    It 'never picks the Microsoft Store stub' {
        Mock Find-First { $null }
        Mock Find-Program { $null }
        Mock Get-Command {
            @([pscustomobject]@{ Source = 'C:\Users\x\AppData\Local\Microsoft\WindowsApps\python.exe' },
              [pscustomobject]@{ Source = 'C:\Python313\python.exe' })
        } -ParameterFilter { $Name -contains 'python.exe' }
        Find-Python | Should -Be 'C:\Python313\python.exe'
    }
    It 'finds nothing rather than the stub when the stub is all there is' {
        Mock Find-First { $null }
        Mock Find-Program { $null }
        Mock Test-RealPython { $false }
        Mock Get-Command { @([pscustomobject]@{ Source = 'C:\Users\x\AppData\Local\Microsoft\WindowsApps\python.exe' }) } -ParameterFilter { $Name -contains 'python.exe' }
        Find-Python | Should -BeNullOrEmpty
    }
    It 'keeps a real Store Python, which lives under the same alias as the stub' {
        Mock Find-First { $null }
        Mock Find-Program { $null }
        Mock Test-RealPython { $true }
        Mock Get-Command { @([pscustomobject]@{ Source = 'C:\Users\x\AppData\Local\Microsoft\WindowsApps\python.exe' }) } -ParameterFilter { $Name -contains 'python.exe' }
        Find-Python | Should -Be 'C:\Users\x\AppData\Local\Microsoft\WindowsApps\python.exe'
    }
    It 'tells the stub from a real Python by running it' {
        Test-RealPython 'C:\nowhere\python.exe' | Should -BeFalse
        if ($script:python) { Test-RealPython $script:python | Should -BeTrue }
    }
}

Describe 'Collectors (need Python 3)' -Skip:(-not $hasPython) {
    It 'the Windows shims lock a file and read a pipe with a timeout' {
        $probe = @'
import sys, subprocess, tempfile, os
sys.path.insert(0, sys.argv[1])
from _compat import LineReader, lock_exclusive
with open(os.path.join(tempfile.gettempdir(), "winarchy-lock-test.lock"), "w") as h:
    lock_exclusive(h)
p = subprocess.Popen([sys.executable, "-c", "import time,sys; print('a', flush=True); time.sleep(1.0); print('b', flush=True)"], stdout=subprocess.PIPE, text=True)
r = LineReader(p.stdout)
print(repr(r.readline(5)), repr(r.readline(0.1)), repr(r.readline(5)), repr(r.readline(5)))
'@
        $out = $probe | & $script:python - (Join-Path $root 'lib\agents')
        # a line, then a timeout (None) while the child sleeps, then b, then EOF ('').
        $out | Should -Be "'a\n' None 'b\n' ''"
    }

    It 'claude: counts transcript usage by model and day, once per message' {
        $cfgDir = Join-Path $TestDrive 'claudehome'
        $proj = Join-Path $cfgDir 'projects\C--work'
        New-Item -ItemType Directory -Force $proj | Out-Null
        $today = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        $line = { param($id, $model, $in, $out) (@{ type = 'assistant'; timestamp = $today; sessionId = 's1'
            message = @{ id = $id; role = 'assistant'; model = $model; usage = @{ input_tokens = $in; output_tokens = $out } } } | ConvertTo-Json -Compress -Depth 5) }
        @(
            (& $line 'm1' 'claude-opus-5' 100 50)
            (& $line 'm2' 'claude-sonnet-5' 10 5)
            (& $line 'm1' 'claude-opus-5' 100 50)    # the same message logged twice
        ) | Set-Content (Join-Path $proj 'session.jsonl')
        $r = Invoke-Collector 'claude' @{ CLAUDE_CONFIG_DIR = $cfgDir }
        Assert-RecordV1 $r 'claude'
        $r.totalPrompts | Should -Be 2
        $r.todayTotalTokens | Should -Be 165
        $r.modelUsage.'claude-opus-5'.inputTokens | Should -Be 100
        $r.ready | Should -BeTrue
    }

    It 'claude: without a sign-in it says so and never probes the network' {
        $cfgDir = Join-Path $TestDrive 'claude-signed-out'
        New-Item -ItemType Directory -Force (Join-Path $cfgDir 'projects') | Out-Null
        $r = Invoke-Collector 'claude' @{ CLAUDE_CONFIG_DIR = $cfgDir }
        @($r.limits).Count | Should -Be 0
        $r.usageStatusText | Should -Be 'Waiting for auth'
        $r.ready | Should -BeFalse
    }

    It 'claude: the printed record never carries the sign-in token' {
        $cfgDir = Join-Path $TestDrive 'claude-creds'
        New-Item -ItemType Directory -Force (Join-Path $cfgDir 'projects') | Out-Null
        # Expired, so the collector stops before any request; the token must still not leak.
        @{ claudeAiOauth = @{ accessToken = 'sk-ant-oat-SECRET-TEST'; expiresAt = 1000; subscriptionType = 'pro'; rateLimitTier = 'default_claude_max_20x' } } |
            ConvertTo-Json | Set-Content (Join-Path $cfgDir '.credentials.json')
        $r = Invoke-Collector 'claude' @{ CLAUDE_CONFIG_DIR = $cfgDir }
        ($r | ConvertTo-Json -Depth 8) | Should -Not -Match 'SECRET'
        $r.tierLabel | Should -Be 'Max 20x'
        $r.usageStatusText | Should -Be 'Sign-in expired'
    }

    It 'codex: talks to the app-server through a .cmd shim, as npm installs it on Windows' {
        $fake = Join-Path $root 'tests\fixtures\fake-codex'
        $r = Invoke-Collector 'codex' @{ CODEX_HOME = (Join-Path $TestDrive 'codex'); PATH = "$fake;$env:PATH" }
        Assert-RecordV1 $r 'codex'
        $r.tierLabel | Should -Be 'pro'
        $r.usageStatusText | Should -BeNullOrEmpty
        @($r.limits).Count | Should -Be 2
        $r.limits[0].label | Should -Be '5h window'
        [double]$r.limits[0].percent | Should -Be 0.42
        $r.limits[1].label | Should -Be 'Weekly (7-day)'
    }

    It 'codex: an account/read that never answers costs nothing when the limits name the plan' {
        $fake = Join-Path $root 'tests\fixtures\fake-codex'
        $t = [Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-Collector 'codex' @{ CODEX_HOME = (Join-Path $TestDrive 'codex-hang'); PATH = "$fake;$env:PATH"; FAKE_CODEX_ACCOUNT_HANGS = '1' }
        $t.Elapsed.TotalSeconds | Should -BeLessThan 4
        $r.tierLabel | Should -Be 'pro'
        $r.usageStatusText | Should -BeNullOrEmpty
        @($r.limits).Count | Should -Be 2
    }

    It 'codex: account/read names the plan only when the limits leave it out' {
        $fake = Join-Path $root 'tests\fixtures\fake-codex'
        $r = Invoke-Collector 'codex' @{ CODEX_HOME = (Join-Path $TestDrive 'codex-noplan'); PATH = "$fake;$env:PATH"; FAKE_CODEX_NO_PLAN = '1' }
        $r.tierLabel | Should -Be 'plus'
        @($r.limits).Count | Should -Be 2
    }

    It 'codex: neither answer naming a plan still keeps the limits' {
        $fake = Join-Path $root 'tests\fixtures\fake-codex'
        $r = Invoke-Collector 'codex' @{ CODEX_HOME = (Join-Path $TestDrive 'codex-neither'); PATH = "$fake;$env:PATH"; FAKE_CODEX_NO_PLAN = '1'; FAKE_CODEX_ACCOUNT_HANGS = '1' }
        $r.tierLabel | Should -BeNullOrEmpty
        $r.usageStatusText | Should -BeNullOrEmpty
        @($r.limits).Count | Should -Be 2
    }

    It 'codex: with no Codex at all it reports that instead of failing' {
        # APPDATA too: the collector also looks in npm's global folder under it.
        $r = Invoke-Collector 'codex' @{ CODEX_HOME = (Join-Path $TestDrive 'codex-none'); PATH = "$env:SystemRoot\System32"; APPDATA = (Join-Path $TestDrive 'appdata') }
        Assert-RecordV1 $r 'codex'
        $r.usageStatusText | Should -Be 'Codex unavailable'
        @($r.limits).Count | Should -Be 0
    }

    It 'agy: counts prompt history and recent days accurately' {
        $cfgDir = Join-Path $TestDrive 'agyhome'
        New-Item -ItemType Directory -Force $cfgDir | Out-Null
        $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        @(
            @{ display = 'write a test'; timestamp = $nowMs; conversationId = 'c1' } | ConvertTo-Json -Compress
            @{ display = 'fix the test'; timestamp = $nowMs; conversationId = 'c1' } | ConvertTo-Json -Compress
        ) | Set-Content (Join-Path $cfgDir 'history.jsonl')
        @{ model = 'Gemini 3.8 Flash (High)' } | ConvertTo-Json | Set-Content (Join-Path $cfgDir 'settings.json')

        $r = Invoke-Collector 'agy' @{ ANTIGRAVITY_CONFIG_DIR = $cfgDir }
        Assert-RecordV1 $r 'agy'
        $r.totalPrompts | Should -Be 2
        $r.todayPrompts | Should -Be 2
        $r.tierLabel | Should -Be 'Gemini 3.8 Flash'
        $r.ready | Should -BeTrue
    }

    It 'agy: reports unavailable when not installed and no data exists' {
        $cfgDir = Join-Path $TestDrive 'agy-none'
        $r = Invoke-Collector 'agy' @{ ANTIGRAVITY_CONFIG_DIR = $cfgDir; PATH = "$env:SystemRoot\System32"; LOCALAPPDATA = (Join-Path $TestDrive 'localappdata'); APPDATA = (Join-Path $TestDrive 'appdata') }
        Assert-RecordV1 $r 'agy'
        $r.usageStatusText | Should -Be 'Antigravity unavailable'
        $r.ready | Should -BeFalse
    }
}

Describe 'agents.json (what the bar reads)' {
    BeforeEach {
        $script:dir = Join-Path $TestDrive "usage-$(New-Guid)"
        New-Item -ItemType Directory -Force $script:dir | Out-Null
        $AgentUsageDir = $script:dir
        $Pack = Join-Path $TestDrive 'pack'
        Mock Get-DefaultAgent { 'codex' }
        $rec = { param($id, $prompts, $limits) [ordered]@{ schemaVersion = 1; id = $id; name = $id; ready = $true; totalPrompts = $prompts; limits = @($limits) } }
        Write-Json (Join-Path $script:dir 'claude.json') (& $rec 'claude' 10 @())
        Write-Json (Join-Path $script:dir 'codex.json') (& $rec 'codex' 0 @(@{ label = 'Weekly'; percent = 0.2 }))
        Write-Json (Join-Path $script:dir 'fireworks.json') (& $rec 'fireworks' 0 @())
    }

    It 'shows only agents with usage or limits, the default first' {
        $shown = @(Write-AgentUsageFile @{ agentUsage = @{ enabled = $true } })
        $shown.id | Should -Be @('codex', 'claude')
        (Get-Content -Raw (Join-Path $Pack 'agents.json') | ConvertFrom-Json).agents.id | Should -Be @('codex', 'claude')
    }
    It 'leaves out an agent switched off in config.json' {
        $shown = @(Write-AgentUsageFile @{ agentUsage = @{ enabled = $true; providers = @{ claude = @{ enabled = $false } } } })
        $shown.id | Should -Be @('codex')
    }
    It 'shows nothing when the indicator is off, so the bar hides it' {
        @(Write-AgentUsageFile @{ agentUsage = @{ enabled = $false } }).Count | Should -Be 0
    }
    It 'picks up a record any collector wrote, with no list of agents to update' {
        Write-Json (Join-Path $script:dir 'newagent.json') ([ordered]@{ id = 'newagent'; name = 'New'; ready = $true; totalPrompts = 1; limits = @() })
        @(Write-AgentUsageFile @{ agentUsage = @{ enabled = $true } }).id | Should -Contain 'newagent'
    }
}

Describe 'Bar and panel wiring' {
    It 'puts the agent icon in #post and polls agents.json' {
        $bar = Get-Content -Raw (Join-Path $Code 'zebar\omarchy\bar.html')
        $bar | Should -Match '(?s)id="post".*id="agents".*</div>'
        $bar | Should -Match "'agents\.json': renderAgents"
        $bar | Should -Match "\`$\('agents'\)\.onclick = \(\) => act\('usage'\)"
    }
    It 'registers the usage panel with the data files it reads' {
        $cfg = @{ barHeight = 26 }   # Get-ZpackJson reads the bar height from its caller
        $z = Get-ZpackJson @{ ahk = 'C:\ahk.exe' } | ConvertFrom-Json
        $u = $z.widgets | Where-Object name -eq 'usage'
        $u.htmlPath | Should -Be './usage.html'
        $u.includeFiles | Should -Contain '*.json'
        @($u.presets).Count | Should -Be 8
    }
    It 'has the menu.ahk verbs the bar and panel send' {
        $ahk = Get-Content -Raw (Join-Path $Code 'ahk\menu.ahk')
        foreach ($verb in 'usage', 'usage-refresh', 'agent-make', 'agent-login') { $ahk | Should -Match "case `"$verb`":" }
    }
    It 'refreshes on a timer only when the indicator is on' {
        Get-Content -Raw (Join-Path $Code 'ahk\winarchy.ahk') | Should -Match '(?s)if Env\("agentUsage", "1"\) = "1" \{.*OmarchyCmd\("agent-usage"\)'
    }
}
