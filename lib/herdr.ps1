# Herdr: the terminal multiplexer Omarchy Quattro uses instead of tmux, plus the four
# agent layouts Omarchy builds on top of it (default/bash/fns/herdr).
#
#   herdr workspace = tmux session    herdr tab = tmux window    herdr pane = tmux pane
#
# Herdr has a JSON CLI, and that is what the layouts are made of: a split prints the new
# pane's id, so a layout is a sequence of splits that remembers the ids it was handed.
# Verified against Herdr 0.9.1 on Windows: `herdr pane split <id> --direction right|down
# --ratio <f> --cwd <dir> --no-focus` prints .result.pane.pane_id, `herdr tab create
# --workspace <id> --cwd <dir> --no-focus` prints .result.root_pane.pane_id, and every
# pane gets HERDR_PANE_ID / HERDR_TAB_ID / HERDR_WORKSPACE_ID.
#
# There is no winget or scoop package: Herdr installs from its own script, so the install
# is bespoke and journalled by hand (see Install-Herdr).

$HerdrBin = Join-Path $env:LOCALAPPDATA 'Programs\Herdr\bin'
$HerdrInstallUrl = 'https://herdr.dev/install.ps1'

# Herdr reads %APPDATA%\herdr\config.toml on Windows (checked with `herdr config check`),
# and HERDR_CONFIG_PATH overrides it.
function Get-HerdrConfigPath {
    if ($env:HERDR_CONFIG_PATH) { return $env:HERDR_CONFIG_PATH }
    Join-Path $env:APPDATA 'herdr\config.toml'
}

function Get-HerdrExe {
    Find-First @((Join-Path $HerdrBin 'herdr.exe'), (Find-Program herdr.exe))
}

function Test-HerdrInstalled { [bool](Get-HerdrExe) }

# --- the JSON CLI -------------------------------------------------------------------
# Every call goes through here so a Herdr that is missing, or one that answers with an
# error object, reads the same way at every call site.
function Invoke-HerdrCli([string[]]$CliArgs) {
    $exe = Get-HerdrExe
    if (-not $exe) { throw 'Herdr is not installed. Omarchy menu > Install > Terminal > Herdr, or: winarchy herdr install' }
    $out = & $exe @CliArgs 2>&1
    $text = ($out | Out-String).Trim()
    if (-not $text) { return $null }
    $json = try { $text | ConvertFrom-Json } catch { $null }
    if (-not $json) {
        if ($LASTEXITCODE -ne 0) { throw "herdr $($CliArgs -join ' '): $text" }
        return $null
    }
    if ($json.error) { throw "herdr $($CliArgs -join ' '): $($json.error.message)" }
    $json
}

function Test-HerdrRunning {
    if (-not (Test-HerdrInstalled)) { return $false }
    try { [bool](Invoke-HerdrCli @('status', 'server', '--json')).running } catch { $false }
}

# Split a pane and return the new pane's id (Omarchy's _herdr_split).
function Split-HerdrPane([string]$pane, [string]$direction, [double]$ratio, [string]$cwd) {
    $r = Invoke-HerdrCli @('pane', 'split', $pane, '--direction', $direction,
        '--ratio', $ratio.ToString('0.####', $Invariant), '--cwd', $cwd, '--no-focus')
    $id = $r.result.pane.pane_id
    if (-not $id) { throw 'herdr pane split did not return a pane id' }
    $id
}

function Invoke-HerdrPane([string]$pane, [string]$command) {
    [void](Invoke-HerdrCli @('pane', 'run', $pane, $command))
}

# --- config -------------------------------------------------------------------------
# Your own copy wins, exactly as it does for the GlazeWM template: once
# ~/.winarchy/herdr.toml.tpl exists winarchy renders that instead, and winarchy.ahk
# re-renders and reloads Herdr when you save it.
function Get-HerdrTemplateFile {
    $user = Join-Path $Data 'herdr.toml.tpl'
    if (Test-Path $user) { return $user }
    Join-Path $Code 'templates\herdr.toml.tpl'
}

# Herdr's built-in themes. An Omarchy theme whose name is one of these is used directly;
# every other theme falls back to "terminal", which draws Herdr in the terminal's own
# palette - and winarchy themes Windows Terminal, so Herdr follows the theme either way.
$HerdrThemes = @('catppuccin', 'catppuccin-latte', 'tokyo-night', 'dracula', 'nord',
    'gruvbox', 'one-dark', 'solarized', 'kanagawa', 'rose-pine', 'vesper')

function Get-HerdrTheme([string]$theme) {
    $cfg = Get-Config
    $pick = $cfg.themeTargets.herdr
    # A theme name in config.json pins Herdr to it; true/"auto" matches on the name.
    if ($pick -is [string] -and $pick -notin @('auto', 'true', 'false')) { return $pick }
    # false: Herdr does not follow the theme, and keeps its plain terminal palette.
    if ($pick -eq $false -or $pick -eq 'false') { return 'terminal' }
    if ($theme -and $HerdrThemes -contains $theme) { return $theme }
    'terminal'
}

function Write-HerdrConfig([string]$theme) {
    if (-not $theme) { $theme = (Read-State).theme }
    $file = Get-HerdrConfigPath
    $tpl = Get-HerdrTemplateFile
    if (-not (Test-Path $tpl)) { Log "herdr: no template at $tpl"; return 'skipped' }
    $name = Get-HerdrTheme $theme
    # Omarchy overrides panel_bg only for the terminal theme, where the active tab is
    # drawn as panel_bg text on the accent colour and so needs a dark value to read.
    # A real built-in theme brings its own, and overriding it would break it.
    $custom = if ($name -eq 'terminal') {
        @(
            ''
            '[theme.custom]'
            '# The active tab is accent-background text, so panel_bg has to be dark for it to'
            "# read - the same colours as Omarchy's tmux status-left (fg=black, bg=blue)."
            'panel_bg = "black"'
        ) -join "`n"
    } else { '' }
    $accent = if ($name -eq 'terminal') {
        '# tmux accented its status bar with ANSI blue' + "`n" + 'accent = "blue"'
    } else {
        "# The built-in `"$name`" theme brings its own accent."
    }
    # TOML literal string (single quotes): a Windows path is full of backslashes, and a
    # basic string would read them as escapes.
    $shell = (Get-Paths).pwsh
    if (-not $shell) { $shell = 'pwsh.exe' }
    $vars = @{
        herdr_theme = $name; herdr_theme_custom = $custom; herdr_accent = $accent
        herdr_shell = $shell
    }
    Save-File $file
    Write-Utf8 $file (Expand-Template (Get-Content -Raw $tpl) $vars)
    Log "herdr: config written ($name)"
    $name
}

# Omarchy's omarchy-restart-herdr: a reload is a no-op when nothing is running, which is
# the normal case, so this never fails just because Herdr is closed.
function Invoke-HerdrReload {
    if (-not (Test-HerdrRunning)) { return 'not running' }
    $r = Invoke-HerdrCli @('server', 'reload-config')
    foreach ($d in @($r.result.diagnostics)) { if ($d) { Log "herdr config: $d" } }
    if ($r.result.status -ne 'applied') { throw "herdr could not reload its config: $($r.result.status)" }
    'applied'
}

# The theme target (themeTargets.herdr): rewrite the config with the new theme and let a
# running Herdr pick it up.
function Set-HerdrTheme([string]$theme) {
    if (-not (Test-HerdrInstalled)) { return 'skipped' }
    if ((Write-HerdrConfig $theme) -eq 'skipped') { return 'skipped' }
    [void](Invoke-HerdrReload)
}

# --- install -------------------------------------------------------------------------
# Herdr publishes no winget package, so this runs its official installer, the way
# Install-Extras runs ttfx's. The installer prepends its bin directory to the user PATH,
# which the journal's envpath entry takes back out on uninstall.
function Install-Herdr {
    if (Test-HerdrInstalled) {
        Write-Ok "Herdr: $(Get-HerdrExe)"
        [void](Initialize-Herdr)
        return
    }
    Write-Step 'Herdr'
    Write-Ok 'Herdr has no winget package: installing from its own script (herdr.dev).'
    Write-Ok 'The binary is not code-signed, so Windows may show a SmartScreen warning.'
    [void](Add-JournalEntry @{ kind = 'envpath'; key = "envpath|$HerdrBin"; dir = $HerdrBin })
    [void](Add-JournalEntry @{ kind = 'herdr'; key = 'herdr|install'; bin = $HerdrBin; packages = (Join-Path $env:USERPROFILE '.herdr') })
    $script = Invoke-RestMethod $HerdrInstallUrl -TimeoutSec 120
    & ([scriptblock]::Create($script))
    # The installer only changes PATH for future shells: find it where it lands.
    if (-not (Test-HerdrInstalled)) {
        throw "Herdr did not install. Try it by hand: irm $HerdrInstallUrl | iex"
    }
    Write-Ok "Herdr: $(Get-HerdrExe)"
    [void](Initialize-Herdr)
}

# Stop a running server and delete what the installer wrote. Shared by the menu's Remove
# and by `winarchy uninstall` replaying the journal, which is why it touches no journal of
# its own: a replay must not rewrite the journal it is reading.
function Remove-HerdrFiles([string]$bin, [string]$packages) {
    $exe = Get-HerdrExe
    if ($exe) {
        # A running server holds its own binary open, so it has to go first.
        try { if (Test-HerdrRunning) { [void](Invoke-HerdrCli @('server', 'stop')) } }
        catch { Log "herdr stop: $($_.Exception.Message)" }
    }
    foreach ($dir in @($bin, $packages)) {
        # bin is .../Programs/Herdr/bin: the whole Herdr folder is what the installer made.
        if ($dir -and (Split-Path -Leaf $dir) -eq 'bin') { $dir = Split-Path $dir }
        if ($dir -and (Test-Path -LiteralPath $dir)) {
            Write-Host "  removing $dir"
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# The menu's Remove > Terminal > Herdr. Herdr did not come from winget, so this is the
# mirror of Install-Herdr rather than a `winget uninstall`: stop the server, take the shell
# shortcuts back out, delete what the installer wrote, and undo its PATH entry.
# Left alone on purpose: %APPDATA%\herdr, which holds the config and the saved sessions.
# `winarchy uninstall` restores the config file itself from the journal.
function Uninstall-Herdr {
    Remove-HerdrProfile
    Remove-HerdrFiles (Join-Path $env:LOCALAPPDATA 'Programs\Herdr') (Join-Path $env:USERPROFILE '.herdr')
    $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($cur) {
        $new = (@($cur -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ne $HerdrBin.TrimEnd('\') }) -join ';')
        if ($new -ne $cur) {
            [Environment]::SetEnvironmentVariable('Path', $new, 'User')
            Send-SettingChange 'Environment'
        }
    }
    # Both recordings described an install that is now gone, so drop them: leaving them
    # would make `winarchy uninstall` try to undo it a second time.
    [void](Remove-JournalEntry 'herdr|install')
    [void](Remove-JournalEntry "envpath|$HerdrBin")
    Remove-Item (Join-Path $Pack 'herdr-keys.txt') -ErrorAction SilentlyContinue
    Write-Ok 'Herdr removed (your config and saved sessions in %APPDATA%\herdr were kept).'
}

# Everything that has to be true for Herdr to feel like part of winarchy, and that is
# safe to redo: the config, the shell shortcuts, the keybindings list. Called by install,
# by apply, and after the catalog installs Herdr.
function Initialize-Herdr {
    if (-not (Test-HerdrInstalled)) { return }
    try { [void](Write-HerdrConfig) } catch { Log "herdr config FAILED: $($_.Exception.Message)" }
    try { [void](Set-HerdrProfile) } catch { Log "herdr profile FAILED: $($_.Exception.Message)" }
    try { [void](Update-HerdrKeys) } catch { Log "herdr keybindings FAILED: $($_.Exception.Message)" }
    try { [void](Sync-HerdrIntegrations) } catch { Log "herdr integrations FAILED: $($_.Exception.Message)" }
    try { [void](Invoke-HerdrReload) } catch { Log "herdr reload FAILED: $($_.Exception.Message)" }
}

# --- agent integrations --------------------------------------------------------------
# An integration is a hook Herdr puts in an agent's own config so the agent reports its
# state (working, waiting, done) and its session, which is what lets a restored pane
# resume the conversation. Herdr's settings > integrations lists an agent as found when
# its command is on PATH, and `herdr integration install <target>` links it without
# asking anything. Linking everything found is what that panel would have you click
# through, so winarchy does it on apply and each time the menu starts Herdr.
#
# Targets whose command is not simply their own name; the rest are looked up as is.
$HerdrAgentCommands = @{
    cursor            = @('cursor-agent')
    'antigravity-cli' = @('agy', 'antigravity')
    kilo              = @('kilo', 'kilocode')
}

# One row per target Herdr knows: found (command on PATH) and linked (hook installed and
# current). `herdr integration status` prints "claude: current (v10) (<hook path>)".
function Get-HerdrAgents {
    $exe = Get-HerdrExe
    if (-not $exe) { return }
    foreach ($line in (& $exe integration status 2>$null)) {
        if ($line -notmatch '^([\w-]+)[^:]*:\s*(.+?)\s*\(') { continue }
        $target = $Matches[1]
        $state = $Matches[2]
        $cmds = if ($HerdrAgentCommands.Contains($target)) { $HerdrAgentCommands[$target] } else { @($target) }
        [pscustomobject]@{
            target = $target
            found  = [bool]($cmds | Where-Object { Get-Command $_ -CommandType Application, ExternalScript -ErrorAction SilentlyContinue })
            linked = $state -match '^current'
        }
    }
}

# Link every agent on PATH that is not linked yet (or whose hook is out of date).
# Returns the targets it linked.
function Sync-HerdrIntegrations {
    $exe = Get-HerdrExe
    if (-not $exe) { return }
    foreach ($a in @(Get-HerdrAgents | Where-Object { $_.found -and -not $_.linked })) {
        $out = & $exe integration install $a.target 2>&1
        if ($LASTEXITCODE) { Log "herdr: could not link $($a.target): $($out -join ' ')"; continue }
        Log "herdr: linked $($a.target)"
        $a.target
    }
}

# --- first-run welcome ---------------------------------------------------------------
# Shown once, in the first Herdr pane (the shortcuts block in the profile calls it), in
# place of Herdr's own first-run panel: which agents are here and that they are linked.
$HerdrWelcomeMark = Join-Path $Data 'herdr-welcomed'

function Show-HerdrWelcome {
    New-Item -ItemType File -Force $HerdrWelcomeMark | Out-Null
    try { [void](Sync-HerdrIntegrations) } catch { Log "herdr integrations FAILED: $($_.Exception.Message)" }
    $agents = @(Get-HerdrAgents)
    $prefix = 'ctrl+space'
    $cfg = Get-HerdrConfigPath
    if ((Test-Path $cfg) -and ((Get-Content -Raw $cfg) -match '(?m)^\s*prefix\s*=\s*"([^"]+)"')) { $prefix = $Matches[1] }
    Write-Host ''
    Write-Host '  Welcome to Herdr' -ForegroundColor Cyan
    Write-Host "  Workspaces, tabs and panes for your agents, like tmux. Prefix $prefix, then ? for every key."
    Write-Host '  Layouts: hdl (editor + agent + terminal)  hds (2x2)  hdlm (one per folder)  hsl (swarm)'
    Write-Host ''
    $linked = @($agents | Where-Object { $_.found })
    if ($linked) {
        Write-Host '  Your agents, linked to Herdr (live status, and sessions that resume after a restart):'
        foreach ($a in $linked) {
            if ($a.linked) { Write-Host "    ✓ $($a.target)" -ForegroundColor Green }
            else { Write-Host "    ✗ $($a.target) (could not link: see $LogFile)" -ForegroundColor Yellow }
        }
    } else {
        Write-Host '  No coding agents found on this PC yet.'
    }
    $others = @($agents | Where-Object { -not $_.found } | ForEach-Object { $_.target })
    if ($others) {
        Write-Host "  Also supported: $($others -join ', ')." -ForegroundColor DarkGray
        Write-Host '  Install any of them and winarchy links it the next time Herdr starts.' -ForegroundColor DarkGray
    }
    Write-Host ''
    Write-Host '  This shows once. See it again: winarchy herdr welcome' -ForegroundColor DarkGray
    Write-Host ''
}

# --- the four layouts ----------------------------------------------------------------
# Omarchy's hdl / hds / hdlm / hsl. They run inside a Herdr pane, which is how they know
# which pane to build around: HERDR_PANE_ID is set for every pane and stays right even
# when focus moves.
function Get-HerdrContext {
    $pane = $env:HERDR_PANE_ID
    if (-not $pane) { throw 'not inside Herdr: start herdr first, then run this in one of its panes.' }
    @{ pane = $pane; tab = $env:HERDR_TAB_ID; workspace = $env:HERDR_WORKSPACE_ID; cwd = (Get-Location).Path }
}

function Rename-HerdrTab([string]$tab, [string]$name) {
    if (-not $tab -or -not $name) { return }
    try { [void](Invoke-HerdrCli @('tab', 'rename', $tab, $name)) } catch { Log "herdr tab rename: $($_.Exception.Message)" }
}

# The command that starts one agent inside a pane. The pane's shell is PowerShell, so
# this is a PowerShell command line, and it goes through `winarchy agent -Inline` so the
# unattended flags stay in one place (lib/agents.ps1).
function Get-HerdrAgentCommand([string]$agent) {
    $key = if ($agent -eq 'a') { Get-DefaultAgent } else { Resolve-AgentName $agent }
    # Something that isn't one of ours is run as typed: Omarchy takes any command here.
    if (-not $key) { return $agent }
    $cmd = Get-AgentCommand $key
    ($cmd | ForEach-Object { if ($_ -match '[\s"]') { "'" + ($_ -replace "'", "''") + "'" } else { $_ } }) -join ' '
}

# hdl: editor left, agent right (30%), a terminal along the bottom (15%).
function Invoke-HerdrLayout([string]$agent, [string]$agent2) {
    if (-not $agent) { throw 'usage: winarchy herdr layout <agent> [<second agent>]   (winarchy agent list)' }
    $ctx = Get-HerdrContext
    $editor = $ctx.pane
    Rename-HerdrTab $ctx.tab (Split-Path -Leaf $ctx.cwd)
    # Bottom terminal first: splitting the editor pane at 85% leaves the top 85% as the
    # editor, and every later split measures against that.
    [void](Split-HerdrPane $editor 'down' 0.85 $ctx.cwd)
    $aiPane = Split-HerdrPane $editor 'right' 0.7 $ctx.cwd
    if ($agent2) {
        $ai2 = Split-HerdrPane $aiPane 'down' 0.5 $ctx.cwd
        Invoke-HerdrPane $ai2 (Get-HerdrAgentCommand $agent2)
    }
    Invoke-HerdrPane $aiPane (Get-HerdrAgentCommand $agent)
    Invoke-HerdrPane $editor (Get-EditorCommand $ctx.cwd)
}

# hds: a 2x2 of editor, diff watch, terminal and opencode.
function Invoke-HerdrSquare {
    $ctx = Get-HerdrContext
    $editor = $ctx.pane
    Rename-HerdrTab $ctx.tab (Split-Path -Leaf $ctx.cwd)
    $terminal = Split-HerdrPane $editor 'down' 0.5 $ctx.cwd
    $diff = Split-HerdrPane $editor 'right' 0.5 $ctx.cwd
    $agentPane = Split-HerdrPane $terminal 'right' 0.5 $ctx.cwd
    Invoke-HerdrPane $editor (Get-EditorCommand $ctx.cwd)
    Invoke-HerdrPane $diff (Get-DiffWatchCommand)
    # Omarchy runs plain opencode here (no unattended flags); without it, the default agent.
    $agent = if (Test-AgentInstalled 'opencode') { 'opencode' } else { Get-HerdrAgentCommand ((Get-DefaultAgent) ?? 'opencode') }
    Invoke-HerdrPane $agentPane $agent
}

# hdlm: one hdl tab per subdirectory of the current directory.
function Invoke-HerdrMulti([string]$agent, [string]$agent2) {
    if (-not $agent) { throw 'usage: winarchy herdr multi <agent> [<second agent>]   (winarchy agent list)' }
    $ctx = Get-HerdrContext
    if ($ctx.workspace) {
        try { [void](Invoke-HerdrCli @('workspace', 'rename', $ctx.workspace, (Split-Path -Leaf $ctx.cwd))) }
        catch { Log "herdr workspace rename: $($_.Exception.Message)" }
    }
    # Omarchy's "$base_dir"/*/ glob: no dot-folders, and no folders means nothing to do.
    $dirs = @(Get-ChildItem -LiteralPath $ctx.cwd -Directory | Where-Object { -not $_.Name.StartsWith('.') } | Sort-Object Name)
    $first = $true
    foreach ($dir in $dirs) {
        $call = "$(Get-WinarchyCli) herdr layout $(Format-PwshArg $agent)"
        if ($agent2) { $call += " $(Format-PwshArg $agent2)" }
        if ($first) {
            # The current tab takes the first project, as Omarchy's does.
            Invoke-HerdrPane $ctx.pane "Set-Location $(Format-PwshArg $dir.FullName); $call"
            $first = $false
            continue
        }
        $r = Invoke-HerdrCli @('tab', 'create', '--workspace', $ctx.workspace, '--cwd', $dir.FullName, '--no-focus')
        $pane = $r.result.root_pane.pane_id
        if (-not $pane) { throw 'herdr tab create did not return a pane id' }
        Invoke-HerdrPane $pane $call
    }
}

# hsl: the same command in every pane of a grid, ceil(sqrt(n)) columns wide.
function Invoke-HerdrSwarm([int]$count, [string]$command) {
    if ($count -lt 1 -or -not $command) { throw 'usage: winarchy herdr swarm <pane count> <command>' }
    $ctx = Get-HerdrContext
    Rename-HerdrTab $ctx.tab (Split-Path -Leaf $ctx.cwd)
    $cols = 1
    while ($cols * $cols -lt $count) { $cols++ }
    # Columns come from splitting the rightmost one off at 1/(n-k+1) each time, which
    # leaves them even and in left-to-right order.
    $columns = @($ctx.pane)
    for ($k = 1; $k -lt $cols; $k++) {
        $columns += Split-HerdrPane $columns[-1] 'right' (1 / ($cols - $k + 1)) $ctx.cwd
    }
    $panes = @()
    for ($i = 0; $i -lt $cols; $i++) {
        $rows = [Math]::Floor($count / $cols)
        if ($i -lt ($count % $cols)) { $rows++ }
        $last = $columns[$i]
        $panes += $last
        for ($j = 1; $j -lt $rows; $j++) {
            $last = Split-HerdrPane $last 'down' (1 / ($rows - $j + 1)) $ctx.cwd
            $panes += $last
        }
    }
    foreach ($pane in $panes) { Invoke-HerdrPane $pane $command }
}

# How to call winarchy from a command we hand to a pane. Not the bare name: in any
# PowerShell `winarchy` resolves to bin\winarchy.ps1 ahead of the .cmd shim, and that
# script needs PowerShell 7, so both the interpreter and the script are named outright.
# Our config points Herdr's panes at PowerShell 7 anyway, but a pane can be any shell the
# user configured, and a generated command should not depend on that.
function Get-WinarchyCli {
    $exe = (Get-Paths).pwsh
    if (-not $exe) { $exe = 'pwsh.exe' }
    "& $(Format-PwshArg $exe) -NoProfile -File $(Format-PwshArg (Join-Path $Code 'bin\winarchy.ps1'))"
}

function Format-PwshArg([string]$value) {
    if ($value -match "^[A-Za-z0-9._\-]+$") { return $value }
    "'" + ($value -replace "'", "''") + "'"
}

# $EDITOR . in Omarchy. Ours is whatever config.json's apps.editor resolved to, and a GUI
# editor would return at once and leave the pane empty, so only a terminal editor is run
# in the pane.
function Get-EditorCommand([string]$cwd) {
    $p = Get-Paths
    $editor = (Get-Config).apps.editor
    if (-not $editor -or $editor -eq 'auto') { $editor = $p.nvim }
    if ($editor -and $editor -match '(?i)\b(nvim|vim|hx|helix|nano|micro)(\.exe)?$') {
        return "$(Format-PwshArg $editor) ."
    }
    # No terminal editor: leave a shell rather than a pane that flashes and closes.
    "Write-Host 'Editor pane: set a terminal editor in config.json (apps.editor), e.g. nvim.'"
}

# Omarchy runs `hunk diff --watch`; hunk is Linux-only, so this is git's own watch loop.
# Omarchy watches the diff with `hunk diff --watch`; without hunk, a git loop does it.
function Get-DiffWatchCommand {
    if (Get-Command hunk -CommandType Application -ErrorAction SilentlyContinue) { return 'hunk diff --watch' }
    'while ($true) { Clear-Host; git --no-pager diff --stat; git --no-pager diff | Select-Object -First 400; Start-Sleep 2 }'
}

# --- shell shortcuts -----------------------------------------------------------------
# Omarchy defines hdl/hds/hdlm/hsl as bash functions it sources. The equivalent here is a
# block in the user's PowerShell profile, delimited so re-running replaces it in place
# and uninstall (which restored the file) leaves nothing behind.
$HerdrProfileBegin = '# >>> winarchy herdr shortcuts >>>'
$HerdrProfileEnd = '# <<< winarchy herdr shortcuts <<<'

function Get-HerdrProfileBlock {
    @(
        $HerdrProfileBegin
        "# Omarchy's Herdr layouts (default/bash/fns/herdr), for use inside a Herdr pane."
        '# Written by winarchy; edit winarchy''s config, not this block: it is replaced on apply.'
        'function hdl { winarchy herdr layout @args }      # editor + agent + terminal'
        'function hds { winarchy herdr square @args }      # 2x2 editor / diff / terminal / agent'
        'function hdlm { winarchy herdr multi @args }      # one hdl tab per subdirectory'
        'function hsl { winarchy herdr swarm @args }       # N panes running the same command'
        '# The first Herdr pane ever opened says hello, once.'
        "if (`$env:HERDR_PANE_ID -and -not (Test-Path '$($HerdrWelcomeMark -replace "'", "''")')) { winarchy herdr welcome }"
        $HerdrProfileEnd
    ) -join "`r`n"
}

# The file is a parameter only so tests never touch the real profile.
function Set-HerdrProfile([string]$file = $PROFILE.CurrentUserAllHosts) {
    if (-not $file) { return 'skipped' }
    $block = Get-HerdrProfileBlock
    $old = if (Test-Path -LiteralPath $file) { Get-Content -Raw -LiteralPath $file } else { '' }
    $pattern = "(?s)\r?\n?" + [regex]::Escape($HerdrProfileBegin) + ".*?" + [regex]::Escape($HerdrProfileEnd)
    $new = if ($old -match $pattern) { [regex]::Replace($old, $pattern, "`r`n$block") }
           else { ($old.TrimEnd() + "`r`n`r`n$block`r`n").TrimStart() }
    if ($new -eq $old) { return 'unchanged' }
    # First write only: the journal keeps the profile as it was, so uninstall restores it.
    Save-File $file
    Write-Utf8 $file $new
    Log "herdr: shortcuts written to $file"
    'written'
}

function Remove-HerdrProfile([string]$file = $PROFILE.CurrentUserAllHosts) {
    if (-not $file -or -not (Test-Path -LiteralPath $file)) { return }
    $old = Get-Content -Raw -LiteralPath $file
    $pattern = "(?s)\r?\n?" + [regex]::Escape($HerdrProfileBegin) + ".*?" + [regex]::Escape($HerdrProfileEnd) + "\r?\n?"
    if ($old -notmatch $pattern) { return }
    Write-Utf8 $file ([regex]::Replace($old, $pattern, "`r`n"))
}

# --- keybindings list ----------------------------------------------------------------
# Learn > Herdr, in the same format as default/keybindings.txt so the menu's viewer
# renders it with no new machinery. Herdr has no command that dumps resolved bindings, so
# this reads the two files that decide them, exactly as omarchy-menu-herdr-keybindings
# does: `herdr --default-config`, where every action is a commented default, overridden
# by whatever our config.toml sets.
function Get-HerdrKeysText {
    $exe = Get-HerdrExe
    if (-not $exe) { return $null }
    $defaults = [ordered]@{}
    $order = @()
    $section = $false
    foreach ($line in (& $exe --default-config 2>$null)) {
        $t = $line -replace '^\s*#\s*', ''
        if ($t -match '^\[\[keys\.command\]\]') { $section = $false; continue }
        if ($t -match '^\[') { $section = $t -match '^\[keys\]'; continue }
        if (-not $section) { continue }
        if ($t -notmatch '^([a-z_]+)\s*=\s*(.+)$') { continue }
        $action = $Matches[1]; $value = $Matches[2]
        if ($order -notcontains $action) { $order += $action }
        $combo = ConvertTo-HerdrCombo $value
        if ($combo) { $defaults[$action] = $combo }
    }
    # Our config.toml (or the user's) overrides them; an action set to nothing is unbound.
    $file = Get-HerdrConfigPath
    if (Test-Path $file) {
        $section = $false
        foreach ($line in (Get-Content $file)) {
            if ($line -match '^\s*#') { continue }
            if ($line -match '^\[\[keys\.command\]\]') { $section = $false; continue }
            if ($line -match '^\[') { $section = $line -match '^\[keys\]'; continue }
            if (-not $section) { continue }
            if ($line -notmatch '^\s*([a-z_]+)\s*=\s*(.+)$') { continue }
            $action = $Matches[1]
            if ($order -notcontains $action) { $order += $action }
            $combo = ConvertTo-HerdrCombo $Matches[2]
            if ($combo) { $defaults[$action] = $combo } else { $defaults.Remove($action) }
        }
    }
    $prefix = $defaults['prefix']
    $out = @(
        'HERDR KEYBINDINGS (Omarchy''s tmux-shaped config)'
        '====================================================================='
        ''
        'PREFIX'
        Format-HerdrKeyRow $(if ($prefix) { $prefix } else { '(unbound)' }) 'Press this first, then the key below'
        ''
        'HERDR'
    )
    foreach ($action in $order) {
        if ($action -eq 'prefix' -or -not $defaults.Contains($action)) { continue }
        $out += Format-HerdrKeyRow $defaults[$action] (Format-HerdrAction $action)
    }
    ($out -join "`n") + "`n"
}

# The viewer splits each line on the first run of two or more spaces, so a combo wider
# than the column still needs two spaces after it rather than running into its label.
function Format-HerdrKeyRow([string]$combo, [string]$label) {
    # Pad to the column, then always two more: padding alone leaves a single space when the
    # combo stops one short of the column, and one space reads as part of the key.
    ('  ' + $combo).PadRight(30) + '  ' + $label
}

# "prefix+h" / ["prefix+h", "alt+enter"] -> "Prefix + H / Alt + Enter". Anything that is
# not a bare string or an array of them is prose from the default config, not a binding.
function ConvertTo-HerdrCombo([string]$value) {
    $value = ($value -replace '(?<!\\)#.*$', '').Trim()
    $keys = [regex]::Matches($value, '"([^"]*)"|''([^'']*)''') | ForEach-Object {
        if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Groups[2].Value }
    }
    if (-not $keys) { return $null }
    # Whatever is left once the quoted runs are gone must be only brackets and commas.
    $rest = [regex]::Replace($value, '"[^"]*"|''[^'']*''', '')
    if ($rest -notmatch '^[\s\[\],]*$') { return $null }
    (@($keys | Where-Object { $_ } | ForEach-Object {
        (($_ -split '\+') | ForEach-Object { $Invariant.TextInfo.ToTitleCase($_) }) -join ' + '
    }) -join ' / ')
}

function Format-HerdrAction([string]$action) {
    $navigate = $action -match '^navigate_'
    $text = $action -replace '^navigate_', '' -replace '_', ' '
    $text = $Invariant.TextInfo.ToTitleCase($text)
    if ($navigate) { "$text (navigate mode)" } else { $text }
}

function Update-HerdrKeys {
    $text = Get-HerdrKeysText
    if (-not $text) { return }
    Write-Utf8 (Join-Path $Pack 'herdr-keys.txt') $text
}

# --- CLI ------------------------------------------------------------------------------
function Invoke-Herdr([string]$action, [string]$arg, [string]$arg2) {
    switch ($action) {
        'install' { Install-Herdr }
        'layout' { Invoke-HerdrLayout $arg $arg2 }
        'square' { Invoke-HerdrSquare }
        'multi' { Invoke-HerdrMulti $arg $arg2 }
        'swarm' { Invoke-HerdrSwarm ([int]$arg) $arg2 }
        'config' { [void](Write-HerdrConfig); [void](Invoke-HerdrReload); Get-HerdrConfigPath }
        'reload' { Invoke-HerdrReload }
        'keys' { Update-HerdrKeys; Get-HerdrKeysText }
        'shortcuts' { Set-HerdrProfile }
        'link' { Sync-HerdrIntegrations }
        'welcome' { Show-HerdrWelcome }
        { $_ -in '', 'status' } {
            "herdr:      $(if (Test-HerdrInstalled) { Get-HerdrExe } else { 'not installed' })"
            if (Test-HerdrInstalled) {
                "config:     $(Get-HerdrConfigPath)"
                "theme:      $(Get-HerdrTheme (Read-State).theme)"
                "server:     $(if (Test-HerdrRunning) { 'running' } else { 'not running' })"
                "shortcuts:  hdl, hds, hdlm, hsl in $($PROFILE.CurrentUserAllHosts)"
            }
        }
        default { throw "usage: winarchy herdr [status|install|layout|square|multi|swarm|config|reload|keys|shortcuts|link|welcome]" }
    }
}
