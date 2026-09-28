# AI coding agents: which ones are installed, which is the default, and how to start one
# so it does not stop to ask. A port of Omarchy's bin/omarchy-agent and
# bin/omarchy-default-agent.
#
# The per-agent flags below are the whole point of this file. Every agent spells
# "run unattended" differently, and several spell "here is a prompt" differently again,
# so the table is copied from Omarchy rather than guessed.

# label  what the menu shows
# cmd    the executable, and what `apps.agent` in config.json holds
# args   the unattended flags for an interactive session
# prompt {} -> the arguments that seed a session with a prompt and keep it interactive
# hint   how to install it, shown when it is picked but missing
$AgentTable = [ordered]@{
    claude = @{
        label = 'Claude Code'; cmd = 'claude'; args = @('--permission-mode', 'auto')
        prompt = { param($p) @('--', $p) }
        hint = 'npm install -g @anthropic-ai/claude-code'
    }
    codex = @{
        label = 'Codex'; cmd = 'codex'; args = @('--approve-for-me')
        prompt = { param($p) @('--', $p) }
        hint = 'npm install -g @openai/codex'
    }
    copilot = @{
        label = 'GitHub Copilot'; cmd = 'copilot'; args = @('--allow-all')
        prompt = { param($p) @('--interactive', $p) }
        hint = 'npm install -g @github/copilot'
    }
    opencode = @{
        label = 'OpenCode'; cmd = 'opencode'; args = @('--auto')
        prompt = { param($p) @('--prompt', $p) }
        hint = 'npm install -g opencode-ai'
    }
    crush = @{
        label = 'Crush'; cmd = 'crush'; args = @('--yolo')
        # --yolo belongs to the interactive command only; `crush run` never prompts.
        prompt = { param($p) @('run', $p) }
        promptReplacesArgs = $true
        hint = 'winget install -e --id CharmBracelet.crush'
    }
    'cursor-agent' = @{
        label = 'Cursor CLI'; cmd = 'cursor-agent'; args = @('--yolo', '--trust')
        # --yolo covers commands only; workspace trust has its own flag. The agent
        # subcommand is named outright so a one-word prompt (update, login, help) is not
        # run as a subcommand, and -- keeps a prompt starting with a dash an argument.
        prompt = { param($p) @('agent', '--', $p) }
        hint = 'https://cursor.com/cli'
    }
    grok = @{
        label = 'Grok'; cmd = 'grok'; args = @('--permission-mode', 'bypassPermissions')
        prompt = { param($p) @('--', $p) }
        hint = 'npm install -g @xai-official/grok'
    }
    agy = @{
        label = 'Antigravity'; cmd = 'agy'; args = @('--dangerously-skip-permissions')
        prompt = { param($p) @('--prompt-interactive', $p) }
        hint = 'npm install -g antigravity-cli'
    }
    muse = @{
        label = 'Muse Code'; cmd = 'muse'; args = @('--approval-mode', 'never')
        prompt = { param($p) @('--', $p) }
        hint = 'https://ai.meta.com/muse/'
    }
    omp = @{
        label = 'Oh My Pi'; cmd = 'omp'; args = @('--auto-approve')
        prompt = { param($p) @('--', $p) }
        hint = 'npm install -g oh-my-pi'
    }
    ori = @{
        label = 'Ori'; cmd = 'ori'; args = @('code')
        # Ori is a harness launcher and `ori code` is the agent it runs. A prompt alone
        # means one headless turn, so --interactive is what keeps the session open.
        prompt = { param($p) @('code', '--interactive', '--prompt', $p) }
        promptReplacesArgs = $true
        hint = 'npm install -g @openrouter/ori'
    }
    pi = @{
        label = 'Pi'; cmd = 'pi'; args = @()
        prompt = { param($p) @($p) }
        hint = 'npm install -g @pi-labs/pi'
    }
    hermes = @{
        label = 'Hermes'; cmd = 'hermes'; args = @('--yolo')
        prompt = { param($p) @('chat', '--yolo', '--tui', "--query=$p") }
        promptReplacesArgs = $true
        hint = 'https://hermes.build'
    }
}

# What `hdl c` and `hdl cx` mean, plus the spellings Omarchy's default-agent accepts.
$AgentAlias = @{
    c = 'claude'; 'claude-code' = 'claude'; cx = 'codex'
    'open-code' = 'opencode'; 'github-copilot' = 'copilot'
    cursor = 'cursor-agent'; 'oh-my-pi' = 'omp'; openrouter = 'ori'
    antigravity = 'agy'; 'antigravity-cli' = 'agy'; gemini = 'agy'; 'gemini-cli' = 'agy'
    'muse-code' = 'muse'; musecode = 'muse'
}

function Resolve-AgentName([string]$name) {
    if (-not $name) { return $null }
    $n = $name.Trim().ToLowerInvariant()
    if ($AgentAlias.ContainsKey($n)) { $n = $AgentAlias[$n] }
    if ($AgentTable.Contains($n)) { return $n }
    $null
}

function Test-AgentInstalled([string]$name) {
    $a = $AgentTable[$name]
    if (-not $a) { return $false }
    [bool](Get-Command $a.cmd -ErrorAction SilentlyContinue)
}

# Every agent, with whether it is here and whether it is the default: the menu's
# Setup > Default Agent list, and `winarchy agent list`.
function Get-AgentState {
    $current = Get-DefaultAgent
    foreach ($key in $AgentTable.Keys) {
        [ordered]@{
            key = $key; label = $AgentTable[$key].label; cmd = $AgentTable[$key].cmd
            installed = (Test-AgentInstalled $key); current = ($key -eq $current)
        }
    }
}

# defaults.json for the menu's Setup > Default Agent list. Written by apply and whenever
# the default changes, the same way catalog.json and apps.json are: the widget gets a
# finished list and hands back only a key.
function Update-AgentList {
    $glyph = [char]::ConvertFromUtf32(0xF06A9)
    $agents = @(Get-AgentState | ForEach-Object {
        [ordered]@{ key = $_.key; label = $_.label; icon = $glyph; installed = $_.installed; current = $_.current }
    })
    Write-Json (Join-Path $Pack 'defaults.json') ([ordered]@{ agents = $agents })
    $agents
}

# Omarchy picks no agent for you, and neither do we: with nothing set the menu leaves
# every entry unchecked and the launch keybinding opens the chooser.
function Get-DefaultAgent {
    $name = (Get-Config).apps.agent
    if ($name -eq 'auto') { $name = $null }
    Resolve-AgentName $name
}

function Set-DefaultAgent([string]$name) {
    $key = Resolve-AgentName $name
    if (-not $key) { throw "unknown agent '$name' (winarchy agent list shows them)" }
    Set-ConfigValue 'apps.agent' $key
    [void](Update-AgentList)
    if (-not (Test-AgentInstalled $key)) {
        Write-Ok "$($AgentTable[$key].label) is now the default, but is not installed yet:"
        Write-Ok "    $($AgentTable[$key].hint)"
    } else { Write-Ok "default agent: $($AgentTable[$key].label)" }
    $key
}

# The command line for one agent, as an array: exe first, then arguments.
function Get-AgentCommand([string]$name, [string]$Prompt) {
    $key = Resolve-AgentName $name
    if (-not $key) { throw "unknown agent '$name' (winarchy agent list shows them)" }
    $a = $AgentTable[$key]
    $flags = @($a.args)
    if ($Prompt) {
        $extra = @(& $a.prompt $Prompt)
        $flags = if ($a.promptReplacesArgs) { $extra } else { $flags + $extra }
    }
    @($a.cmd) + $flags
}

# Launch the default agent. -Inline runs it here (this is what a Herdr pane wants);
# otherwise it gets its own terminal window. -Pick opens the chooser when no default is
# set, because a keypress that opens nothing explains nothing.
function Invoke-Agent([switch]$Inline, [switch]$Pick, [string]$Prompt) {
    $key = Get-DefaultAgent
    if (-not $key) {
        if ($Pick) { Open-MenuRoute 'agent'; return }
        throw 'no default agent yet. Pick one with: winarchy default-agent <name>   (winarchy agent list)'
    }
    if (-not (Test-AgentInstalled $key)) {
        throw "$($AgentTable[$key].label) is not installed. Install it with: $($AgentTable[$key].hint)"
    }
    $cmd = @(Get-AgentCommand $key -Prompt $Prompt)
    if ($Inline) {
        $rest = @($cmd | Select-Object -Skip 1)
        & $cmd[0] @rest
        return
    }
    # Omarchy gives agent windows one app-id so window rules can single them out; our
    # equivalent is the dedicated Windows Terminal profile that apply writes.
    Start-AgentTerminal $cmd
}

# The menu widget is opened through menu.ahk, which is what the bar and the keybindings
# use: there is no other way in, and it puts the menu on the monitor under the cursor.
function Open-MenuRoute([string]$route) {
    $p = Get-Paths
    if (-not $p.ahk) { throw "no default agent yet, and AutoHotkey is missing so the chooser cannot open. Pick one with: winarchy default-agent <name>" }
    Start-Process -FilePath $p.ahk -ArgumentList "`"$Code\ahk\menu.ahk`"", 'open', $route
}

# Start-Process joins an argument array with bare spaces, so every item is quoted here
# the way CommandLineToArgvW reads it back.
function Join-ProcessArgs([string[]]$items) {
    ($items | ForEach-Object {
        if ($_ -and $_ -notmatch '[\s"]') { $_ }
        else { '"' + (($_ -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"' }
    }) -join ' '
}

function Start-AgentTerminal([string[]]$cmd) {
    $p = Get-Paths
    $line = ($cmd | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
    if ($p.wt) {
        # The profile supplies the look and the fixed "Omarchy Agent" title that window
        # rules can match, so no --title here: that would undo it. wt splits tabs on ;
        # even inside quotes, so those are escaped.
        Start-Process $p.wt -ArgumentList (Join-ProcessArgs @('-w', 'new', '-p', 'Omarchy Agent', ($p.pwsh ?? 'pwsh'), '-NoExit', '-NoLogo', '-Command', ($line -replace ';', '\;')))
    } else {
        Start-Process ($p.pwsh ?? 'pwsh') -ArgumentList (Join-ProcessArgs @('-NoExit', '-NoProfile', '-Command', $line))
    }
}

# --- usage: the bar's agent indicator --------------------------------------------------
# A port of Omarchy's shell/plugins/agents data side (bin/omarchy-agent-usage-update).
# Each lib/agents/usage-<id>.py prints one display-ready JSON record for one agent; this
# runs them all, keeps each record in ~/.winarchy/agents/usage/<id>.json, and merges the
# ones worth showing into the pack's agents.json, which the bar polls. The bar only ever
# draws that file. Adding an agent is adding a collector: nothing here names one.

$AgentUsageDir = Join-Path $Data 'agents\usage'

function Get-AgentCollectors {
    foreach ($f in Get-ChildItem (Join-Path $Code 'lib\agents') -Filter 'usage-*.py' -File -ErrorAction SilentlyContinue) {
        @{ id = $f.BaseName -replace '^usage-', ''; path = $f.FullName }
    }
}

# config.json agentUsage: enabled (the whole indicator) and providers.<id>.enabled (one
# agent), the same switches as Omarchy's widget settings. Everything is on by default:
# an agent with no usage on this machine shows nothing anyway.
function Test-AgentUsageEnabled($cfg, [string]$id) {
    if ($cfg.agentUsage.enabled -eq $false) { return $false }
    $providers = $cfg.agentUsage.providers
    -not ($providers -and $providers[$id] -and $providers[$id].enabled -eq $false)
}

# An agent appears only when it has something to say: usage recorded on this machine, or
# limits its service reported. That is what lets the indicator ship on by default - with
# no agent in use it is not on the bar at all, and it arrives by itself the first time a
# scan finds usage.
function Test-AgentRecordShown($record) {
    if (-not $record -or -not $record.ready) { return $false }
    ([long]$record.totalPrompts -gt 0) -or (@($record.limits).Count -gt 0)
}

function Update-AgentUsage([switch]$Force, [switch]$LimitsOnly, [string]$Only, [switch]$NoRetry) {
    $cfg = Get-Config
    New-Item -ItemType Directory -Force $AgentUsageDir | Out-Null
    $python = (Get-Paths).python
    # Installed since the last detect: look again rather than wait for the next apply.
    if (-not $python -or -not (Test-Path -LiteralPath $python)) { $python = Find-Python }
    if (-not $python) {
        Log 'agent usage: no Python 3, so no records (winarchy doctor explains)'
        Write-AgentUsageFile $cfg
        return
    }
    $flags = @(if ($Force) { '--force' } elseif ($LimitsOnly) { '--limits-only' })
    # All collectors at once, as upstream backgrounds them: the Codex one can spend a few
    # seconds waiting on its app-server, and nothing else should wait behind it.
    $running = foreach ($c in Get-AgentCollectors) {
        if ($Only -and $c.id -ne $Only) { continue }
        if (-not (Test-AgentUsageEnabled $cfg $c.id)) { continue }
        $psi = [Diagnostics.ProcessStartInfo]::new($python)
        $psi.ArgumentList.Add($c.path)
        foreach ($f in $flags) { $psi.ArgumentList.Add($f) }
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
        # The collectors' own scan caches, under winarchy's data folder instead of ~/.cache.
        $psi.Environment['XDG_CACHE_HOME'] = Join-Path $Data 'cache'
        $psi.Environment['PYTHONIOENCODING'] = 'utf-8'
        $psi.Environment['PYTHONDONTWRITEBYTECODE'] = '1'
        try {
            $proc = [Diagnostics.Process]::Start($psi)
            @{ id = $c.id; proc = $proc; out = $proc.StandardOutput.ReadToEndAsync(); err = $proc.StandardError.ReadToEndAsync() }
        } catch { Log "agent usage: $($c.id) could not start: $($_.Exception.Message)" }
    }
    $retry = $false
    foreach ($r in @($running)) {
        if (-not $r.proc.WaitForExit(60000)) {
            try { $r.proc.Kill($true) } catch {}
            Log "agent usage: $($r.id) collector timed out"
            continue
        }
        $text = $r.out.Result.Trim()
        $record = try { $text | ConvertFrom-Json } catch { $null }
        # The same check as upstream's `jq -e .`: a collector that printed nothing usable
        # keeps its last good record rather than replacing it with a broken one.
        if ($r.proc.ExitCode -ne 0 -or -not $record -or $record.id -ne $r.id) {
            $why = ($r.err.Result -split "`r?`n" | Where-Object { $_ } | Select-Object -Last 1)
            Log "agent usage: $($r.id) collector failed (exit $($r.proc.ExitCode))$(if ($why) { ": $why" })"
            continue
        }
        Write-Utf8 (Join-Path $AgentUsageDir "$($r.id).json") $text
        if ($record.retryAdvised) { $retry = $true }
    }
    Write-AgentUsageFile $cfg
    # Upstream's collector asks for an early retry when the limits probe reached no server
    # at all - the first run after login often beats the network. Once, a minute later.
    if ($retry -and -not $NoRetry) {
        Start-Sleep -Seconds 60
        Update-AgentUsage -LimitsOnly -NoRetry
    }
}

# Merge every record on disk - whoever wrote it, so a collector added later needs no
# change here - into the one file the bar reads. The default agent comes first.
function Write-AgentUsageFile($cfg) {
    $default = Get-DefaultAgent
    $records = @(Get-ChildItem $AgentUsageDir -Filter '*.json' -File -ErrorAction SilentlyContinue | ForEach-Object {
        try { Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json } catch { $null }
    } | Where-Object { $_ -and (Test-AgentUsageEnabled $cfg $_.id) -and (Test-AgentRecordShown $_) })
    $ordered = @($records | Sort-Object @{ Expression = { $_.id -ne $default } }, id)
    Write-Json (Join-Path $Pack 'agents.json') ([ordered]@{
        updatedAt = (Get-Date).ToUniversalTime().ToString('o')
        default = $default
        agents = $ordered
    }) 12
    $ordered
}
