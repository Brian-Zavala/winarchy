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
    openclaw = @{
        label = 'OpenClaw'; cmd = 'openclaw'; args = @('tui')
        # Omarchy's launcher attaches the terminal UI to the running gateway and has no
        # permission prompts to skip; --message seeds the session and keeps it interactive.
        prompt = { param($p) @('tui', '--message', $p) }
        promptReplacesArgs = $true
        hint = 'npm install -g openclaw'
    }
    hermes = @{
        label = 'Hermes'; cmd = 'hermes'; args = @('--yolo')
        prompt = { param($p) @('chat', '--yolo', '--tui', "--query=$p") }
        promptReplacesArgs = $true
        hint = 'https://hermes.build'
    }
}

# Omarchy's shell shorthands (default/bash/aliases: c = opencode, cx = claude,
# cy = codex), which `hdl c` runs, plus the spellings Omarchy's default-agent accepts.
# `a` is the default agent (omarchy-agent --inline); Get-HerdrAgentCommand handles it.
$AgentAlias = @{
    c = 'opencode'; cx = 'claude'; cy = 'codex'; 'claude-code' = 'claude'
    'open-code' = 'opencode'; 'github-copilot' = 'copilot'
    cursor = 'cursor-agent'; 'oh-my-pi' = 'omp'; openrouter = 'ori'
    antigravity = 'agy'; 'antigravity-cli' = 'agy'; gemini = 'agy'; 'gemini-cli' = 'agy'
    'muse-code' = 'muse'; musecode = 'muse'
}

# How each agent signs in again, the commands the usage collectors' help text names:
# the usage panel's "Sign in" runs one in a terminal (winarchy agent-login).
$AgentLogin = [ordered]@{
    claude = @('claude', 'auth', 'login')
    codex = @('codex', 'login')
}

# The usage panel's "Make something" tiles, as on Omarchy's agents panel: each starts the
# default agent with a starter prompt, in the folder the thing it makes lives in. Omarchy's
# prompts point at its skill's guides; ours point at agents\make\<kind>.md ({0}).
$AgentMake = [ordered]@{
    theme = @{
        dir = $Themes
        prompt = "Make me a new Winarchy theme. Ask me what look or inspiration I have in mind, then build it following the guide in {0} and switch to it."
    }
    plugin = @{
        dir = Join-Path $env:USERPROFILE '.glzr\zebar'
        prompt = "Make me a new Winarchy bar plugin, which on Windows is a Zebar widget pack. Ask me what I'd like it to do, then build it following the guide in {0} and start it."
    }
    app = @{
        dir = Join-Path $Data 'apps'
        prompt = "Make me a new app for my Winarchy desktop. Ask me what it should do, then build it following the guide in {0} and add it so it shows up in Start and the app launcher."
    }
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
    # login: the usage panel offers "Sign in" (winarchy agent-login) for these.
    $agents = @(Get-AgentState | ForEach-Object {
        [ordered]@{ key = $_.key; label = $_.label; icon = $glyph; installed = $_.installed; current = $_.current; login = $AgentLogin.Contains($_.key) }
    })
    Write-Json (Join-Path $Pack 'defaults.json') ([ordered]@{ agents = $agents })
    $agents
}

# Omarchy picks no agent for you; Winarchy picks Claude Code once it is installed, so the
# agent key, the Herdr layouts and the agents panel's tiles work from the start. Any agent
# you pick replaces it. With nothing picked and no Claude Code, the menu leaves every
# entry unchecked and the launch keybinding opens the chooser.
$AutoAgent = 'claude'

function Get-DefaultAgent {
    $name = (Get-Config).apps.agent
    if (-not $name -or $name -eq 'auto') {
        if (Test-AgentInstalled $AutoAgent) { return $AutoAgent }
        return $null
    }
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
# otherwise it gets its own terminal window, started in -Dir if given. -Pick opens the
# chooser when no default is set, because a keypress that opens nothing explains nothing.
function Invoke-Agent([switch]$Inline, [switch]$Pick, [string]$Prompt, [string]$Dir) {
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
        if ($Dir) { Push-Location -LiteralPath $Dir }
        try { & $cmd[0] @rest } finally { if ($Dir) { Pop-Location } }
        return
    }
    # Omarchy gives agent windows one app-id so window rules can single them out; our
    # equivalent is the dedicated Windows Terminal profile that apply writes.
    Start-AgentTerminal $cmd -Dir $Dir
}

# A "Make something" tile: the default agent, asked to make a theme, plugin or app.
function Invoke-AgentMake([string]$kind) {
    $key = if ($kind) { $kind.ToLowerInvariant() }
    if (-not $key -or -not $AgentMake.Contains($key)) { throw "usage: winarchy agent-make <$($AgentMake.Keys -join '|')>" }
    $m = $AgentMake[$key]
    New-Item -ItemType Directory -Force $m.dir | Out-Null
    $guide = Join-Path $Code "agents\make\$key.md"
    Invoke-Agent -Pick -Prompt ($m.prompt -f $guide) -Dir $m.dir
}

# The usage panel's "Sign in": the agent's own login, here in the terminal, then fresh
# limits, so the panel (which polls agents.json) drops its sign-in warning.
function Invoke-AgentLogin([string]$id) {
    $key = if ($id) { $id.ToLowerInvariant() }
    if (-not $key -or -not $AgentLogin.Contains($key)) { throw "usage: winarchy agent-login <$($AgentLogin.Keys -join '|')>" }
    $cmd = @($AgentLogin[$key])
    if (-not (Test-AgentInstalled $key)) {
        throw "$($AgentTable[$key].label) is not installed. Install it with: $($AgentTable[$key].hint)"
    }
    $rest = @($cmd | Select-Object -Skip 1)
    & $cmd[0] @rest
    [void](Update-AgentUsage -Force -Only $key -NoRetry)
    "$($AgentTable[$key].label): limits refreshed"
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

# The command as one line of PowerShell for pwsh -Command. Anything but a plain word goes
# in single quotes, where PowerShell expands nothing ($, backticks and " are literal), so a
# prompt arrives exactly as written; a quoted exe needs the call operator.
function ConvertTo-PwshCommandLine([string[]]$cmd) {
    $quoted = @($cmd | ForEach-Object {
        if ($_ -match '^[\w\-.\\/:=+]+$') { $_ }
        else { "'" + [Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($_) + "'" }
    })
    if ($quoted.Count -and $quoted[0] -ne $cmd[0]) { $quoted[0] = "& $($quoted[0])" }
    $quoted -join ' '
}

function Start-AgentTerminal([string[]]$cmd, [string]$Dir) {
    $p = Get-Paths
    $line = ConvertTo-PwshCommandLine $cmd
    if ($p.wt) {
        # The profile supplies the look and the fixed "Omarchy Agent" title that window
        # rules can match, so no --title here: that would undo it. wt splits tabs on ;
        # even inside quotes, so those are escaped.
        $where = if ($Dir) { @('-d', $Dir) } else { @() }
        Start-Process $p.wt -ArgumentList (Join-ProcessArgs (@('-w', 'new', '-p', 'Omarchy Agent') + $where + @(($p.pwsh ?? 'pwsh'), '-NoExit', '-NoLogo', '-Command', ($line -replace ';', '\;'))))
    } else {
        $where = if ($Dir) { @{ WorkingDirectory = $Dir } } else { @{} }
        Start-Process ($p.pwsh ?? 'pwsh') -ArgumentList (Join-ProcessArgs @('-NoExit', '-NoProfile', '-Command', $line)) @where
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
    # Upstream's collector asks for an early retry when the limits probe reached no server
    # at all - the first run after login often beats the network. Once, a minute later,
    # and only its records are returned, or every agent would be listed twice.
    if ($retry -and -not $NoRetry) {
        [void](Write-AgentUsageFile $cfg)
        Start-Sleep -Seconds 60
        return Update-AgentUsage -LimitsOnly -NoRetry
    }
    Write-AgentUsageFile $cfg
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
