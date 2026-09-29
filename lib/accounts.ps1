# Several Claude Code and Codex accounts on one PC: a port of Omarchy's account switching
# (bin/omarchy-agent-account-state and the omarchy-agent-account-* commands, on its
# agent-account-switching branch at 38db762).
#
# The login you already have stays where the CLI put it (~/.claude, ~/.codex, or the
# folder a user-wide CLAUDE_CONFIG_DIR / CODEX_HOME names) and is the primary account,
# "main". An added account gets a home of its own under
# %USERPROFILE%\.winarchy\state\omarchy\agents\accounts\<provider>\<id>\ that holds its
# own sign-in and joins everything else to the primary home, so conversations, skills and
# plugins stay one set. New sessions start as the active account: Winarchy's launches
# name its home in CLAUDE_CONFIG_DIR / CODEX_HOME, and so do the claude and codex
# functions in your PowerShell profile while you have more than one account.
#
# Upstream's Linux pieces, in Windows terms: junctions for its directory symlinks (no
# admin needed); copies for its file symlinks (Claude refuses to write settings through a
# link, and a hard link breaks on its write-then-rename); a named mutex for its flock.
# The registry's JSON is upstream's, so the collectors (lib/agents/usage-*.py) read it
# as they are.

$AccountProviders = [ordered]@{
    claude = @{
        name = 'Claude'; label = 'Claude Code'; var = 'CLAUDE_CONFIG_DIR'; folder = '.claude'
        sharedDirs = @('projects', 'skills', 'agents', 'commands', 'plugins', 'hooks', 'themes', 'output-styles', 'file-history', 'todos', 'plans')
        copiedFiles = @('settings.json', 'keybindings.json')
        # Keys copied from the primary's .claude.json into a new account's, so a second
        # login keeps MCP servers, folder trust and onboarding choices.
        carriedKeys = @('mcpServers', 'projects', 'theme', 'hasCompletedOnboarding', 'lastOnboardingVersion', 'editorMode')
    }
    codex = @{
        name = 'Codex'; label = 'Codex'; var = 'CODEX_HOME'; folder = '.codex'
        sharedDirs = @('sessions', 'archived_sessions', 'prompts', 'skills', 'rules', 'plugins')
        copiedFiles = @('config.toml', 'hooks.json', 'AGENTS.md')
        carriedKeys = @()
    }
}

$AccountStateHome = Join-Path $Data 'state'
$AccountsRoot = Join-Path $AccountStateHome 'omarchy\agents\accounts'
$AccountThreshold = 95
# Ids an account can't take: `use claude/next` cycles, a provider name is read as the
# provider, main is the primary, and Windows reserves its device names as folder names.
$AccountReservedIds = @('next', 'add', 'claude', 'codex', 'main', 'con', 'prn', 'aux', 'nul') +
    @(1..9 | ForEach-Object { "com$_"; "lpt$_" })

class AccountError : Exception { AccountError([string]$m) : base($m) {} }

# --- paths ---------------------------------------------------------------------------

function Test-AccountProvider([string]$p) { $p -and $AccountProviders.Contains($p.ToLowerInvariant()) }

function Get-AccountProvider([string]$p) {
    if (-not (Test-AccountProvider $p)) { throw [AccountError]::new('Name a provider: claude or codex') }
    $p.ToLowerInvariant()
}

# The primary is where the CLI keeps a login when nothing selects another: the user's own
# CLAUDE_CONFIG_DIR / CODEX_HOME if they set one for good, else ~/.claude / ~/.codex.
# Never this process's value, which may be an added account's.
function Get-AccountPrimaryHome([string]$p) {
    $spec = $AccountProviders[$p]
    foreach ($scope in 'User', 'Machine') {
        $v = [Environment]::GetEnvironmentVariable($spec.var, $scope)
        if ($v) { return [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($v)) }
    }
    Join-Path $env:USERPROFILE $spec.folder
}

function Test-AccountPrimaryCustom([string]$p) {
    [bool]([Environment]::GetEnvironmentVariable($AccountProviders[$p].var, 'User') -or [Environment]::GetEnvironmentVariable($AccountProviders[$p].var, 'Machine'))
}

function Get-AccountRegistryPath([string]$p) { Join-Path $AccountsRoot "$p.json" }

function Get-AccountHomeOf([string]$p, $account) {
    if ($account.home) { [string]$account.home } else { Get-AccountPrimaryHome $p }
}

# Claude keeps its account file beside the default config dir (~/.claude.json) and
# inside any other one.
function Get-ClaudeAccountFile([string]$dir) {
    $default = Join-Path $env:USERPROFILE '.claude'
    if ((Test-SamePath $dir $default) -and -not (Test-AccountPrimaryCustom 'claude')) { return Join-Path $env:USERPROFILE '.claude.json' }
    Join-Path $dir '.claude.json'
}

function Test-SamePath([string]$a, [string]$b) {
    if (-not $a -or -not $b) { return $false }
    try { [IO.Path]::GetFullPath($a).TrimEnd('\', '/') -eq [IO.Path]::GetFullPath($b).TrimEnd('\', '/') } catch { $false }
}

# --- identity ------------------------------------------------------------------------

function Get-AccountPlanLabel([string]$tier, [string]$subscription) {
    if ($tier -match '(?i)max_(\d+x)') { return "Max $($Matches[1])" }
    if ($subscription) { return $subscription.Substring(0, 1).ToUpperInvariant() + $subscription.Substring(1) }
    ''
}

function ConvertFrom-Jwt([string]$token) {
    try {
        $payload = $token.Split('.')[1].Replace('-', '+').Replace('_', '/')
        $payload += '=' * ((4 - $payload.Length % 4) % 4)
        [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json -AsHashtable
    } catch { @{} }
}

# Who a home is signed in as, from files the CLI wrote at login. Only display-safe fields;
# an empty accountId means nobody is signed in. -Probe asks `claude auth status` when the
# files say nothing: Claude may keep its sign-in in Windows' Credential Manager instead.
function Get-AccountIdentity([string]$p, [string]$dir, [switch]$Probe) {
    $id = [ordered]@{ accountId = ''; email = ''; org = ''; plan = '' }
    if ($p -eq 'claude') {
        $account = (Read-Json (Get-ClaudeAccountFile $dir) -AsHashtable)?.oauthAccount
        $login = (Read-Json (Join-Path $dir '.credentials.json') -AsHashtable)?.claudeAiOauth
        if ($account) {
            $id.accountId = [string]$account.accountUuid
            $id.email = [string]$account.emailAddress
            $id.org = [string]$account.organizationName
        }
        if ($login) { $id.plan = Get-AccountPlanLabel ([string]$login.rateLimitTier) ([string]$login.subscriptionType) }
        if (-not $id.accountId -and $Probe) {
            $status = Invoke-AgentWithHome 'claude' $dir @('auth', 'status') -Capture | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
            if ($status -and $status.loggedIn -and $status.email) {
                $id.accountId = "email:$($status.email)"
                $id.email = [string]$status.email
                $id.org = [string]$status.orgName
                $id.plan = Get-AccountPlanLabel '' ([string]$status.subscriptionType)
            }
        }
        return $id
    }
    $tokens = (Read-Json (Join-Path $dir 'auth.json') -AsHashtable)?.tokens
    if ($tokens) {
        $claims = ConvertFrom-Jwt ([string]$tokens.id_token)
        $openai = $claims['https://api.openai.com/auth']
        $id.accountId = [string]($tokens.account_id ?? $openai?.chatgpt_account_id)
        $id.email = [string]$claims.email
        $plan = [string]$openai?.chatgpt_plan_type
        if ($plan) { $id.plan = $plan.Substring(0, 1).ToUpperInvariant() + $plan.Substring(1) }
    }
    $id
}

# --- registry ------------------------------------------------------------------------

function ConvertTo-AccountSlug([string]$label) {
    ($label.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
}

function New-AccountPrimaryEntry([string]$p) {
    $e = [ordered]@{ id = 'main'; label = 'Main'; home = ''; primary = $true }
    $i = Get-AccountIdentity $p (Get-AccountPrimaryHome $p)
    foreach ($k in $i.Keys) { $e[$k] = $i[$k] }
    $e
}

# Upstream's normalized(): the primary is always there, the switch mode and threshold are
# in range, and `active` names an account that exists (with a home that does).
function ConvertTo-AccountRegistry([string]$p, $data) {
    $r = [ordered]@{ active = 'main'; switch = 'manual'; threshold = $AccountThreshold; alert = ''; accounts = @() }
    if ($data -is [Collections.IDictionary]) {
        foreach ($k in @($r.Keys)) { if ($data.Contains($k) -and $null -ne $data[$k]) { $r[$k] = $data[$k] } }
    }
    $accounts = [Collections.Generic.List[object]]::new()
    foreach ($a in @($r.accounts)) {
        if ($a -is [Collections.IDictionary] -and $a.id) {
            $o = [ordered]@{}
            foreach ($k in $a.Keys) { $o[$k] = $a[$k] }
            $accounts.Add($o)
        }
    }
    if (-not ($accounts | Where-Object { $_.primary })) { $accounts.Insert(0, (New-AccountPrimaryEntry $p)) }
    $r.accounts = @($accounts)
    if ($r.switch -notin 'manual', 'auto') { $r.switch = 'manual' }
    try { $r.threshold = [Math]::Max(50, [Math]::Min(100, [int]$r.threshold)) } catch { $r.threshold = $AccountThreshold }
    $current = Find-Account $r $r.active
    if (-not $current -or (-not $current.primary -and -not (Test-Path -LiteralPath (Get-AccountHomeOf $p $current)))) {
        $r.active = $r.accounts[0].id
    }
    $r
}

function Find-Account($registry, [string]$id) {
    if (-not $id) { return $null }
    @($registry.accounts) | Where-Object { $_.id -eq $id } | Select-Object -First 1
}

function Get-ActiveAccount($registry) { (Find-Account $registry $registry.active) ?? $registry.accounts[0] }

# The registry as it is on disk, or rebuilt from the homes when the file is unreadable
# (kept beside it as .bad, so nothing is lost). Missing entirely: just the primary.
function Read-AccountRegistry([string]$p) {
    $path = Get-AccountRegistryPath $p
    $data = $null
    if (Test-Path -LiteralPath $path) {
        try { $data = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json -AsHashtable -ErrorAction Stop }
        catch {
            Log "agent accounts: $p.json did not parse ($($_.Exception.Message)); kept as $p.json.bad and rebuilt from the homes"
            Move-Item -Force -LiteralPath $path "$path.bad" -ErrorAction SilentlyContinue
            $data = @{ accounts = @(Get-ChildItem -LiteralPath (Join-Path $AccountsRoot $p) -Directory -ErrorAction SilentlyContinue |
                Where-Object Name -notlike '.*' | ForEach-Object { @{ id = $_.Name; label = $_.Name; home = $_.FullName; primary = $false } }) }
        }
    }
    ConvertTo-AccountRegistry $p $data
}

function Save-AccountRegistry([string]$p, $registry) {
    New-Item -ItemType Directory -Force $AccountsRoot | Out-Null
    Write-Json (Get-AccountRegistryPath $p) $registry 8
}

# Every change is read-modify-write under one lock per provider, so the panel, the
# autoswitch after each usage refresh and a command typed at a prompt can't interleave.
# $change gets the registry; it is saved unless $change throws.
function Update-AccountRegistry([string]$p, [scriptblock]$change) {
    $m = [Threading.Mutex]::new($false, "Local\WinarchyAgentAccounts-$p")
    $got = $false
    try {
        try { $got = $m.WaitOne(30000) } catch [Threading.AbandonedMutexException] { $got = $true }
        if (-not $got) { throw [AccountError]::new("another change to the $($AccountProviders[$p].name) accounts is still running") }
        $registry = Read-AccountRegistry $p
        $out = & $change $registry
        Save-AccountRegistry $p $registry
        $out
    } finally {
        if ($got) { $m.ReleaseMutex() }
        $m.Dispose()
    }
}

# The account an id answers to, from its label: never another account's, a reserved word,
# or the folder of an account since renamed.
function New-AccountId([string]$p, $registry, [string]$label, $keep) {
    $base = ConvertTo-AccountSlug $label
    if (-not $base) { $base = 'account' }
    $id = $base; $n = 2
    while ($true) {
        $taken = Find-Account $registry $id
        if ($id -notin $AccountReservedIds -and (-not $taken -or ($keep -and $taken.id -eq $keep.id))) {
            if ($keep -or -not (Test-Path -LiteralPath (Join-Path $AccountsRoot "$p\$id"))) { return $id }
        }
        $id = "$base-$n"; $n++
    }
}

# claude/work -> claude, work (a bare provider means its active account).
function Resolve-AccountRef([string]$ref) {
    $p, $id = $ref -split '[/\\:]', 2
    $p = Get-AccountProvider $p
    [pscustomobject]@{ provider = $p; id = $id }
}

# --- homes ---------------------------------------------------------------------------

# A folder link: a junction on Windows (no admin needed), a symlink elsewhere (tests).
function New-AccountLink([string]$path, [string]$target) {
    $type = if ($IsWindows -or $null -eq $IsWindows) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $type -Path $path -Target $target -ErrorAction Stop | Out-Null
}

function Get-AccountLinkTarget([string]$path) {
    $i = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if (-not $i -or -not $i.LinkType) { return $null }
    @($i.Target)[0]
}

# Give an added account's home its links to the primary and its own copies. Safe to repeat,
# and repairing: a link to anywhere but the primary (the primary moved) is laid again, and
# a real folder or file in the way is left as it is, since the account made it.
function Connect-AccountHome([string]$p, [string]$dir) {
    $spec = $AccountProviders[$p]
    $primary = Get-AccountPrimaryHome $p
    New-Item -ItemType Directory -Force $dir | Out-Null
    foreach ($name in $spec.sharedDirs) {
        $src = Join-Path $primary $name
        $dst = Join-Path $dir $name
        try {
            New-Item -ItemType Directory -Force $src | Out-Null
            $target = Get-AccountLinkTarget $dst
            if ($target -and (Test-SamePath $target $src)) { continue }
            if ($target) { Remove-AccountLink $dst }
            elseif (Test-Path -LiteralPath $dst) { continue }
            New-AccountLink $dst $src
        } catch { Log "agent accounts: $dst not linked to $src ($($_.Exception.Message)); that account's transcripts stay out of the stats" }
    }
    foreach ($name in $spec.copiedFiles) {
        $src = Join-Path $primary $name
        $dst = Join-Path $dir $name
        if ((Test-Path -LiteralPath $src) -and -not (Test-Path -LiteralPath $dst)) { Copy-Item -LiteralPath $src $dst -ErrorAction SilentlyContinue }
    }
    if ($p -eq 'claude') {
        # The primary's CLAUDE.md, by import rather than a copy, so edits to it count everywhere.
        $md = Join-Path $dir 'CLAUDE.md'
        if (-not (Test-Path -LiteralPath $md)) { Write-Utf8 $md "@$(ConvertTo-HomeRelative (Join-Path $primary 'CLAUDE.md'))`n" }
    }
}

# ~/... with forward slashes for a path under the user's folder (how Claude imports read).
function ConvertTo-HomeRelative([string]$path) {
    $root = $env:USERPROFILE.TrimEnd('\', '/')
    if ($path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { return '~' + ($path.Substring($root.Length) -replace '\\', '/') }
    $path -replace '\\', '/'
}

function Remove-AccountLink([string]$path) {
    try { [IO.Directory]::Delete($path) } catch { [IO.File]::Delete($path) }
}

# Every link under a folder, deleted as a link and never followed: what makes deleting an
# account's home (or winarchy's whole data folder) safe for the primary's conversations.
function Clear-AccountLinks([string]$dir) {
    if (-not (Test-Path -LiteralPath $dir)) { return }
    $stack = [Collections.Generic.Stack[string]]::new()
    $stack.Push($dir)
    while ($stack.Count) {
        foreach ($i in Get-ChildItem -LiteralPath $stack.Pop() -Force -ErrorAction SilentlyContinue) {
            if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { Remove-AccountLink $i.FullName }
            elseif ($i.PSIsContainer) { $stack.Push($i.FullName) }
        }
    }
}

function Remove-AccountHome([string]$dir) {
    Clear-AccountLinks $dir
    Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
}

# Upstream's carry_settings: MCP servers, folder trust and onboarding follow a new login.
# System.Text.Json keeps the file exactly as Claude wrote it (paths that differ only in
# case, big numbers), which a PowerShell hashtable round trip would not.
function Copy-AccountCarriedKeys([string]$p, [string]$dir) {
    $keys = $AccountProviders[$p].carriedKeys
    if (-not $keys) { return }
    try {
        $srcFile = Get-ClaudeAccountFile (Get-AccountPrimaryHome $p)
        if (-not (Test-Path -LiteralPath $srcFile)) { return }
        $src = [Text.Json.Nodes.JsonNode]::Parse((Get-Content -Raw -LiteralPath $srcFile))
        $dstFile = Join-Path $dir '.claude.json'
        $dst = if (Test-Path -LiteralPath $dstFile) { [Text.Json.Nodes.JsonNode]::Parse((Get-Content -Raw -LiteralPath $dstFile)) } else { [Text.Json.Nodes.JsonObject]::new() }
        foreach ($k in $keys) {
            if ($src.AsObject().ContainsKey($k) -and -not $dst.AsObject().ContainsKey($k)) {
                $dst[$k] = [Text.Json.Nodes.JsonNode]::Parse($src[$k].ToJsonString())
            }
        }
        Write-Utf8 $dstFile $dst.ToJsonString()
    } catch { Log "agent accounts: settings not carried to $dir ($($_.Exception.Message))" }
}

# --- commands ------------------------------------------------------------------------

# Upstream's summary: each home asked who it is now, not trusted from when it was added.
function Get-AgentAccounts([string]$p) {
    $r = Read-AccountRegistry $p
    foreach ($a in $r.accounts) {
        $dir = Get-AccountHomeOf $p $a
        $i = Get-AccountIdentity $p $dir
        [pscustomobject]@{
            provider = $p; id = $a.id; label = $a.label; email = $i.email; plan = $i.plan; org = $i.org
            primary = [bool]$a.primary; active = $a.id -eq $r.active; home = $dir
            signedIn = [bool]$i.accountId; exists = [bool]($a.primary -or (Test-Path -LiteralPath $dir))
        }
    }
}

# The active account's home when it is not the primary: what a launch puts in
# CLAUDE_CONFIG_DIR / CODEX_HOME. A plain read, no lock: a launch must never wait.
function Get-AgentAccountHome([string]$p) {
    if (-not (Test-AccountProvider $p)) { return $null }
    $path = Get-AccountRegistryPath $p
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $r = Read-Json $path -AsHashtable
    if (-not $r) { return $null }
    $a = @($r.accounts) | Where-Object { $_.id -eq $r.active } | Select-Object -First 1
    if ($a -and -not $a.primary -and $a.home -and (Test-Path -LiteralPath $a.home)) { [string]$a.home }
}

# The environment a launch of this agent needs for the active account: nothing for the
# primary, nor when the variable is already set (a session started as another account,
# or the person's own choice, wins).
function Get-AgentLaunchEnv([string]$key) {
    if (-not (Test-AccountProvider $key)) { return @{} }
    $var = $AccountProviders[$key].var
    if ([Environment]::GetEnvironmentVariable($var, 'Process')) { return @{} }
    $dir = Get-AgentAccountHome $key
    if ($dir) { @{ $var = $dir } } else { @{} }
}

function Register-AgentAccount([string]$p, [string]$label, [string]$pending) {
    $pendingRoot = Join-Path $AccountsRoot "$p\.pending"
    if (-not (Test-SamePath (Split-Path $pending) $pendingRoot)) { throw [AccountError]::new("$pending is not a pending $($AccountProviders[$p].name) login") }
    $found = Get-AccountIdentity $p $pending -Probe
    if (-not $found.accountId) {
        Remove-AccountHome $pending
        throw [AccountError]::new("The login didn't finish, so no account was added.")
    }
    Update-AccountRegistry $p {
        param($r)
        foreach ($a in $r.accounts) {
            $i = Get-AccountIdentity $p (Get-AccountHomeOf $p $a)
            if ($i.accountId -and ($i.accountId -eq $found.accountId -or ($i.email -and $found.accountId -eq "email:$($i.email)"))) {
                Remove-AccountHome $pending
                throw [AccountError]::new("That's $($a.label) ($(if ($found.email) { $found.email } else { 'already added' })). Try again, and sign in as the other account in the private window.")
            }
        }
        $name = $label.Trim()
        if (-not $name) { $name = ($found.email -split '@')[0] }
        if (-not $name) { $name = 'Account' }
        $id = New-AccountId $p $r $name $null
        $dir = Join-Path $AccountsRoot "$p\$id"
        # Defender or the search indexer can hold a file of a folder just written for a moment.
        $deadline = (Get-Date).AddSeconds(5)
        while ($true) {
            try { Move-Item -LiteralPath $pending $dir -ErrorAction Stop; break }
            catch { if ((Get-Date) -gt $deadline) { throw }; Start-Sleep -Milliseconds 250 }
        }
        Copy-AccountCarriedKeys $p $dir
        $entry = [ordered]@{ id = $id; label = $name; home = $dir; primary = $false }
        foreach ($k in $found.Keys) { $entry[$k] = $found[$k] }
        $r.accounts = @($r.accounts) + $entry
        $entry
    }
}

function Use-AgentAccount([string]$p, [string]$target) {
    $result = Update-AccountRegistry $p {
        param($r)
        $previous = Get-ActiveAccount $r
        if (-not $target -or $target -eq 'next') {
            $ids = @($r.accounts | ForEach-Object id)
            $target = $ids[([array]::IndexOf($ids, $previous.id) + 1) % $ids.Count]
        }
        $a = Find-Account $r $target
        if (-not $a) { throw [AccountError]::new("No $($AccountProviders[$p].name) account named $target") }
        if (-not $a.primary -and -not (Test-Path -LiteralPath $a.home)) { throw [AccountError]::new("$($a.label)'s folder is gone; add it again (winarchy agent-account add $p)") }
        $r.active = $a.id
        $r.alert = ''
        if (-not $a.primary) { Connect-AccountHome $p $a.home }
        [pscustomobject]@{ previous = $previous; active = $a }
    }
    # The panel shows the switch at its next poll, not after the next collector run.
    try { Sync-AgentUsageActive $p } catch { Log "agent accounts: usage record not updated ($($_.Exception.Message))" }
    $result
}

function Rename-AgentAccount([string]$p, [string]$target, [string]$label) {
    $label = "$label".Trim()
    if (-not $label) { throw [AccountError]::new('Give the account a name') }
    Update-AccountRegistry $p {
        param($r)
        $a = Find-Account $r $target
        if (-not $a) { throw [AccountError]::new("No $($AccountProviders[$p].name) account named $target") }
        $newId = if ($a.primary) { 'main' } else { New-AccountId $p $r $label $a }
        if ($r.active -eq $a.id) { $r.active = $newId }
        $r.alert = ''
        $a.id = $newId
        $a.label = $label
        $a
    }
}

function Remove-AgentAccount([string]$p, [string]$target) {
    Update-AccountRegistry $p {
        param($r)
        $a = Find-Account $r $target
        if (-not $a) { throw [AccountError]::new("No $($AccountProviders[$p].name) account named $target") }
        if ($a.primary) { throw [AccountError]::new("$($a.label) is the login in $(Get-AccountPrimaryHome $p); it can't be removed here.") }
        # Only the account's own folder goes, never a link's target.
        if ($a.home -and (Test-SamePath (Split-Path $a.home) (Join-Path $AccountsRoot $p))) { Remove-AccountHome $a.home }
        $r.accounts = @($r.accounts | Where-Object { $_.id -ne $a.id })
        if ($r.active -eq $a.id) { $r.active = 'main' }
        $a
    }
    try { Sync-AgentUsageActive $p } catch {}
}

function Set-AgentAccountMode([string]$p, [string]$mode, [string]$threshold) {
    if ($mode -notin 'manual', 'auto') { throw [AccountError]::new('Switch mode is manual or auto') }
    Update-AccountRegistry $p {
        param($r)
        $r.switch = $mode
        if ($threshold) {
            $t = 0
            if (-not [int]::TryParse($threshold, [ref]$t)) { throw [AccountError]::new('The threshold is a percentage between 50 and 100') }
            $r.threshold = [Math]::Max(50, [Math]::Min(100, $t))
        }
        $r.alert = ''
        [pscustomobject]@{ switch = $r.switch; threshold = $r.threshold }
    }
    try { Sync-AgentUsageActive $p } catch {}
}

# The stored usage record, made to agree with the registry at once: which account is
# active, the top level describing it (as the collector would), and the switch mode.
function Sync-AgentUsageActive([string]$p) {
    $file = Join-Path $AgentUsageDir "$p.json"
    $rec = Read-Json $file -AsHashtable
    if (-not $rec) { return }
    $r = Read-AccountRegistry $p
    if (@($rec.accounts).Count) {
        $rec.accounts = @(@($rec.accounts) | Where-Object { Find-Account $r $_.id })
        foreach ($a in $rec.accounts) { $a.active = $a.id -eq $r.active }
        $cur = @($rec.accounts) | Where-Object active | Select-Object -First 1
        if ($cur) {
            $rec.limits = @($cur.limits)
            $rec.tierLabel = $cur.plan
            $rec.usageStatusText = $cur.usageStatusText
            $rec.authHelpText = $cur.authHelpText
            if ($cur.resetCredits) { $rec.resetCredits = $cur.resetCredits } else { $rec.Remove('resetCredits') }
        }
        if (@($rec.accounts).Count -lt 2) { $rec.Remove('accounts'); $rec.Remove('accountSwitch') }
        else { $rec.accountSwitch = [ordered]@{ mode = $r.switch; threshold = $r.threshold } }
    }
    Write-Json $file $rec 12
    [void](Write-AgentUsageFile (Get-Config))
}

# --- repair (apply, install, update) -------------------------------------------------

# What apply keeps true, so a fresh install, an update or a reinstall needs no step of its
# own: the folder exists, each registry is whole, an account whose folder is gone is
# dropped, links point at the primary (it may have moved), a sign-in abandoned more than
# an hour ago is cleared, and the profile's claude/codex functions exist exactly while
# some provider has more than one account.
function Repair-AgentAccounts {
    New-Item -ItemType Directory -Force $AccountsRoot | Out-Null
    $multi = $false
    foreach ($p in $AccountProviders.Keys) {
        $pending = Join-Path $AccountsRoot "$p\.pending"
        foreach ($d in Get-ChildItem -LiteralPath $pending -Directory -Force -ErrorAction SilentlyContinue) {
            if ($d.LastWriteTime -lt (Get-Date).AddHours(-1)) { Remove-AccountHome $d.FullName }
        }
        if (-not (Test-Path -LiteralPath (Get-AccountRegistryPath $p))) { continue }
        $r = Update-AccountRegistry $p {
            param($r)
            $gone = @($r.accounts | Where-Object { -not $_.primary -and -not (Test-Path -LiteralPath $_.home) })
            foreach ($a in $gone) { Log "agent accounts: $p/$($a.id)'s folder is gone ($($a.home)); dropped" }
            $r.accounts = @($r.accounts | Where-Object { $_ -notin $gone })
            if (-not (Find-Account $r $r.active)) { $r.active = 'main' }
            foreach ($a in $r.accounts) { if (-not $a.primary) { Connect-AccountHome $p $a.home } }
            $r
        }
        if (@($r.accounts).Count -gt 1) { $multi = $true }
    }
    if ($multi) { [void](Set-AccountProfile) } else { Remove-AccountProfile }
}

# --- PowerShell profile: claude and codex as the active account ----------------------

$AccountProfileBegin = '# >>> winarchy agent accounts >>>'
$AccountProfileEnd = '# <<< winarchy agent accounts <<<'

function Get-AccountProfileBlock {
    $root = $AccountsRoot -replace "'", "''"
    $fn = foreach ($p in $AccountProviders.Keys) {
        $var = $AccountProviders[$p].var
        # A function or alias of your own by that name keeps its meaning.
        "if (-not (Get-Command $p -CommandType Function, Alias -ErrorAction SilentlyContinue)) {"
        "    function global:$p {"
        "        `$exe = Get-Command $p -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1"
        "        if (-not `$exe) { Write-Error '$p is not installed'; return }"
        "        `$dir = if (-not `$env:$var) { Get-WinarchyAgentHome $p }"
        "        if (`$dir) { `$env:$var = `$dir }"
        # Piped input goes through; otherwise the console stays the agent's stdin.
        "        try { if (`$MyInvocation.ExpectingInput) { `$input | & `$exe @args } else { & `$exe @args } }"
        "        finally { if (`$dir) { Remove-Item Env:$var -ErrorAction SilentlyContinue } }"
        '    }'
        '}'
    }
    @(
        $AccountProfileBegin
        "# claude and codex start as the account the agents panel (or winarchy agent-account use)"
        "# made active. Written by winarchy while you have more than one; it takes it out again."
        'function global:Get-WinarchyAgentHome([string]$p) {'
        "    try { `$r = Get-Content -Raw -LiteralPath (Join-Path '$root' `"`$p.json`") -ErrorAction Stop | ConvertFrom-Json } catch { return }"
        '    $a = @($r.accounts) | Where-Object { $_.id -eq $r.active } | Select-Object -First 1'
        '    if ($a -and -not $a.primary -and $a.home -and (Test-Path -LiteralPath $a.home)) { $a.home }'
        '}'
        $fn
        $AccountProfileEnd
    ) -join "`r`n"
}

# The file is a parameter only so tests never touch the real profile.
function Set-AccountProfile([string]$file = $PROFILE.CurrentUserAllHosts) {
    if (-not $file) { return 'skipped' }
    $block = Get-AccountProfileBlock
    $old = if (Test-Path -LiteralPath $file) { Get-Content -Raw -LiteralPath $file } else { '' }
    $pattern = "(?s)\r?\n?" + [regex]::Escape($AccountProfileBegin) + ".*?" + [regex]::Escape($AccountProfileEnd)
    $new = if ($old -match $pattern) { [regex]::Replace($old, $pattern, { param($m) "`r`n$block" }) }
           else { ($old.TrimEnd() + "`r`n`r`n$block`r`n").TrimStart() }
    if ($new -eq $old) { return 'unchanged' }
    # First write only: the journal keeps the profile as it was, so uninstall restores it.
    Save-File $file
    Write-Utf8 $file $new
    Log "agent accounts: claude and codex functions written to $file"
    'written'
}

function Remove-AccountProfile([string]$file = $PROFILE.CurrentUserAllHosts) {
    if (-not $file -or -not (Test-Path -LiteralPath $file)) { return }
    $old = Get-Content -Raw -LiteralPath $file
    $pattern = "(?s)\r?\n?" + [regex]::Escape($AccountProfileBegin) + ".*?" + [regex]::Escape($AccountProfileEnd) + "\r?\n?"
    if ($old -notmatch $pattern) { return }
    Write-Utf8 $file ([regex]::Replace($old, $pattern, "`r`n"))
}

# --- signing in ----------------------------------------------------------------------

# Run the agent's CLI with one home selected. -Capture returns its output instead of
# handing it the console (for `claude auth status`).
function Invoke-AgentWithHome([string]$p, [string]$dir, [string[]]$arguments, [hashtable]$extraEnv = @{}, [switch]$Capture) {
    $exe = Find-AgentExe $AgentTable[$p].cmd
    if (-not $exe) { throw [AccountError]::new("$($AccountProviders[$p].label) is not installed. Install it with: $($AgentTable[$p].hint)") }
    $vars = @{ $AccountProviders[$p].var = $dir } + $extraEnv
    $saved = @{}
    foreach ($k in $vars.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k, 'Process') }
    try {
        foreach ($k in $vars.Keys) { [Environment]::SetEnvironmentVariable($k, $vars[$k], 'Process') }
        $global:LASTEXITCODE = 0
        if ($Capture) { & $exe @arguments 2>$null | Out-String }
        else { & $exe @arguments }
    } finally {
        foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k], 'Process') }
    }
}

# A .cmd for Claude's BROWSER: it opens the sign-in page in a private window, so the
# browser's own signed-in account isn't picked up. Claude runs BROWSER as a program with
# the URL as its one argument; %~1 takes it unquoted and it is quoted again for start.
# No browser with a private mode: a .cmd that opens nothing, and the URL Claude prints is
# the way in.
function New-PrivateBrowserShim([string]$dir) {
    New-Item -ItemType Directory -Force $dir | Out-Null
    $shim = Join-Path $dir "browser-$([guid]::NewGuid().ToString('N').Substring(0, 8)).cmd"
    $b = Find-Browser
    $flag = if ($b.exe) { Get-BrowserPrivateFlag $b.exe }
    $body = if ($b.exe -and $flag) { "@start `"`" `"$($b.exe)`" $flag `"%~1`"" } else { '@exit /b 0' }
    Set-Content -LiteralPath $shim -Value "@echo off`r`n$body`r`n" -Encoding ascii -NoNewline
    [pscustomobject]@{ path = $shim; private = [bool]($b.exe -and $flag) }
}

function Open-PrivateUrl([string]$url) {
    $b = Find-Browser
    $flag = if ($b.exe) { Get-BrowserPrivateFlag $b.exe }
    if (-not ($b.exe -and $flag)) { return $false }
    Start-Process -FilePath $b.exe -ArgumentList $flag, $url
    $true
}

# Sign a home in. The primary uses the normal browser; an added account (or one being
# added) signs in privately: Claude through the BROWSER shim, Codex with a device code,
# since Codex ignores BROWSER on Windows and its browser flow would reuse whoever the
# browser is signed in as.
function Invoke-AccountSignIn([string]$p, [string]$dir, [switch]$Private) {
    $spec = $AccountProviders[$p]
    if (-not $Private) {
        Write-Host "Sign in to $($spec.label) in the browser window that opens."
        # The primary: the person's own variable (a user-wide one) or none at all.
        $primaryVar = if (Test-AccountPrimaryCustom $p) { Get-AccountPrimaryHome $p }
        if ($p -eq 'codex') { New-Item -ItemType Directory -Force $dir | Out-Null }
        $saved = [Environment]::GetEnvironmentVariable($spec.var, 'Process')
        try {
            [Environment]::SetEnvironmentVariable($spec.var, $primaryVar, 'Process')
            $exe = Find-AgentExe $AgentTable[$p].cmd
            $global:LASTEXITCODE = 0
            if ($p -eq 'claude') { & $exe auth login } else { & $exe login }
        } finally { [Environment]::SetEnvironmentVariable($spec.var, $saved, 'Process') }
        return
    }
    Write-Host "Sign in as the account you're adding in the private window that opens."
    Write-Host "If a private window was already open, close it first, or the site may reuse whoever it has signed in."
    Write-Host "Don't log out of the $($spec.label) CLI to do this: logging out revokes the saved sign-in."
    if ($p -eq 'claude') {
        $shim = New-PrivateBrowserShim (Join-Path $AccountsRoot "$p\.pending")
        try {
            if (-not $shim.private) { Write-Host 'No browser with a private mode was found: open the address Claude prints below in a private window.' }
            Invoke-AgentWithHome $p $dir @('auth', 'login') @{ BROWSER = $shim.path }
        } finally { Remove-Item -LiteralPath $shim.path -Force -ErrorAction SilentlyContinue }
        return
    }
    New-Item -ItemType Directory -Force $dir | Out-Null
    $url = 'https://auth.openai.com/codex/device'
    if (-not (Open-PrivateUrl $url)) { Write-Host "Open $url in a private window." }
    Write-Host 'Enter the code below on that page.'
    Invoke-AgentWithHome $p $dir @('login', '--device-auth')
    if ($LASTEXITCODE) {
        Write-Host 'If Codex refused a device code: turn on device code sign-in in ChatGPT (Settings > Security), or ask your workspace admin, then try again.'
    }
}

# winarchy agent-account add [claude|codex] [label]: the panel's + (in a terminal).
function Add-AgentAccount([string]$provider, [string]$label) {
    if (-not $provider) {
        $installed = @($AccountProviders.Keys | Where-Object { Test-AgentInstalled $_ })
        $provider = if ($installed.Count -eq 1) { $installed[0] }
            else { (Read-Host 'Add a Claude Code or a Codex account? (claude/codex)').Trim() }
    }
    $p = Get-AccountProvider $provider
    $spec = $AccountProviders[$p]
    if (-not (Test-AgentInstalled $p)) {
        $item = if ($p -eq 'claude') { 'claude-code' } else { 'codex' }
        if ((Get-Command Install-CatalogItem -ErrorAction SilentlyContinue) -and (Read-Host "$($spec.label) isn't installed. Install it now? (Y/n)") -notmatch '^(n|no)$') {
            Install-CatalogItem $item
        }
        if (-not (Test-AgentInstalled $p)) { throw [AccountError]::new("$($spec.label) is not installed. Install it with: $($AgentTable[$p].hint)") }
    }
    # One sign-in per provider at a time: Codex's browser login holds one port, and two
    # pending homes would race to register.
    $m = [Threading.Mutex]::new($false, "Local\WinarchyAgentAccountAdd-$p")
    $got = $false
    try { $got = $m.WaitOne(0) } catch [Threading.AbandonedMutexException] { $got = $true }
    if (-not $got) { $m.Dispose(); throw [AccountError]::new("Another $($spec.label) sign-in is still running; finish that one first.") }
    try {
        $primary = Get-AccountPrimaryHome $p
        if (-not (Get-AccountIdentity $p $primary).accountId) {
            # The first account: the CLI's own login, where it keeps it.
            Invoke-AccountSignIn $p $primary
            $i = Get-AccountIdentity $p $primary -Probe
            if (-not $i.accountId) { throw [AccountError]::new("The $($spec.label) sign-in didn't finish.") }
            if (-not (Get-DefaultAgent)) { [void](Set-DefaultAgent $p) }
            Write-Ok "Signed in to $($spec.label)$(if ($i.email) { " as $($i.email)" })."
        } else {
            if (-not $label) { $label = (Read-Host "Name this account, e.g. Work (Enter: its email's name)").Trim() }
            $pendingRoot = Join-Path $AccountsRoot "$p\.pending"
            $pending = Join-Path $pendingRoot "login-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
            try {
                Connect-AccountHome $p $pending
                Invoke-AccountSignIn $p $pending -Private
                $entry = Register-AgentAccount $p $label $pending
                Write-Ok "Added $($entry.label)$(if ($entry.email) { " ($($entry.email))" }). Use it from the agents panel, or: winarchy agent-account use $p/$($entry.id)"
            } finally {
                if (Test-Path -LiteralPath $pending) { Remove-AccountHome $pending }
            }
        }
    } finally { $m.ReleaseMutex(); $m.Dispose() }
    Repair-AgentAccounts
    [void](Update-AgentUsage -Force -Only $p -NoRetry)
}

# winarchy agent-login claude/work: sign an account in again, in its own home.
function Invoke-AccountReauth([string]$p, [string]$id) {
    $r = Read-AccountRegistry $p
    $a = Find-Account $r $id
    if (-not $a) { throw [AccountError]::new("No $($AccountProviders[$p].name) account named $id") }
    if ($a.primary) { Invoke-AccountSignIn $p (Get-AccountPrimaryHome $p) }
    else {
        if (-not (Test-Path -LiteralPath $a.home)) { throw [AccountError]::new("$($a.label)'s folder is gone; add it again (winarchy agent-account add $p)") }
        Invoke-AccountSignIn $p $a.home -Private
    }
    if ($LASTEXITCODE) { throw [AccountError]::new("The $($AccountProviders[$p].label) sign-in did not finish (exit $LASTEXITCODE)") }
}

# --- autoswitch ----------------------------------------------------------------------

function ConvertTo-AccountTime([string]$s) {
    if (-not $s) { return $null }
    $t = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse($s, $Invariant, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$t)) { return $t }
    $null
}

# A window counts until its reset passes; one that says nothing counts.
function Test-AccountWindowOpen($limit, [DateTimeOffset]$now) {
    $t = ConvertTo-AccountTime ([string]$limit.resetsAt)
    -not $t -or $t -gt $now
}

# How spent an account is: its fullest window that hasn't reset, in percent. A reset
# window counts as empty even when the numbers are stale. $null when nothing is known.
function Get-AccountPeak($limits, [DateTimeOffset]$now) {
    $known = @(@($limits) | Where-Object { $_ -and $null -ne $_.percent -and "$($_.percent)" -as [double] -ne $null })
    if (-not $known) { return $null }
    $open = @($known | Where-Object { Test-AccountWindowOpen $_ $now } | ForEach-Object { [double]$_.percent * 100 })
    if ($open) { ($open | Measure-Object -Maximum).Maximum } else { 0.0 }
}

function Get-AccountNextReset($limits, [DateTimeOffset]$now) {
    $times = @(@($limits) | ForEach-Object { ConvertTo-AccountTime ([string]$_.resetsAt) } | Where-Object { $_ -and $_ -gt $now } | Sort-Object)
    if ($times) { $times[0] } else { $null }
}

# When an account over the threshold drops back under it: once every window holding it
# there has reset, the latest of those resets. $null when one of them never says.
function Get-AccountAvailableAt($limits, [double]$threshold, [DateTimeOffset]$now) {
    $latest = $null
    foreach ($l in @($limits)) {
        if (-not $l -or $null -eq $l.percent) { continue }
        if ([double]$l.percent * 100 -lt $threshold -or -not (Test-AccountWindowOpen $l $now)) { continue }
        $t = ConvertTo-AccountTime ([string]$l.resetsAt)
        if (-not $t) { return $null }
        if (-not $latest -or $t -gt $latest) { $latest = $t }
    }
    $latest
}

function Format-AccountDuration([TimeSpan]$d) {
    $m = [Math]::Max(1, [int][Math]::Floor($d.TotalMinutes))
    $h = [Math]::Floor($m / 60); $m %= 60
    $days = [Math]::Floor($h / 24); $h %= 24
    if ($days) { "${days}d ${h}h" } elseif ($h) { "${h}h ${m}m" } else { "${m}m" }
}

# The whole switching policy, with no I/O (upstream's decide()): from the registry and
# each account's limits, what should happen. $null for nothing, else an action of
# clear / switch / notify / exhausted. Only the active account crossing the threshold
# starts anything, so auto mode never flaps back; `alert` remembers the last notice.
function Get-AccountSwitchDecision($registry, [hashtable]$usage, [DateTimeOffset]$now) {
    $threshold = [double]$registry.threshold
    $current = Get-ActiveAccount $registry
    $peak = Get-AccountPeak $usage[$current.id] $now
    if ($null -eq $peak -or $peak -lt $threshold) {
        if ($registry.alert) { return @{ action = 'clear' } }
        return $null
    }
    $candidates = foreach ($a in $registry.accounts) {
        if ($a.id -eq $current.id) { continue }
        $level = Get-AccountPeak $usage[$a.id] $now
        if ($null -eq $level -or $level -ge $threshold) { continue }
        $reset = Get-AccountNextReset $usage[$a.id] $now
        [pscustomobject]@{ level = $level; reset = $(if ($reset) { $reset } else { [DateTimeOffset]::MaxValue }); account = $a }
    }
    $best = @($candidates | Sort-Object level, reset) | Select-Object -First 1
    if ($best) {
        $action = if ($registry.switch -eq 'auto') { 'switch' } else { 'notify' }
        $alert = "${action}:$($current.id):$($best.account.id)"
        if ($registry.alert -eq $alert) { return $null }
        return @{ action = $action; alert = $alert; from = $current; to = $best.account; fromPeak = $peak; toPeak = $best.level }
    }
    $alert = "exhausted:$($current.id)"
    if ($registry.alert -eq $alert -or @($registry.accounts).Count -lt 2) { return $null }
    # Only when every account is known to be over: one signed out or unchecked might have room.
    if (@($registry.accounts | Where-Object { $null -eq (Get-AccountPeak $usage[$_.id] $now) })) { return $null }
    $soonest = $null
    foreach ($a in $registry.accounts) {
        $t = Get-AccountAvailableAt $usage[$a.id] $threshold $now
        if ($t -and (-not $soonest -or $t -lt $soonest.at)) { $soonest = @{ at = $t; account = $a } }
    }
    @{ action = 'exhausted'; alert = $alert; from = $current; fromPeak = $peak; soonest = $soonest }
}

# Each account's limits from its stored usage record. One nobody is signed in to is left
# out, so it is never a candidate; one whose token merely expired stays in (a session
# refreshes it), unless what's known of it is more than a day old.
function Get-AccountUsage([string]$p) {
    $rec = Read-Json (Join-Path $AgentUsageDir "$p.json") -AsHashtable
    $out = @{}
    $dayAgo = [DateTimeOffset]::UtcNow.AddDays(-1).ToUnixTimeMilliseconds()
    foreach ($a in @($rec.accounts)) {
        if (-not $a -or -not $a.id -or $a.usageStatusText -eq 'Waiting for auth') { continue }
        if ($a.stale -and $a.fetchedAt -and [double]$a.fetchedAt -lt $dayAgo) { continue }
        $out[[string]$a.id] = $a.limits
    }
    $out
}

# A short on-screen notice (menu.ahk agent-notice), from a hidden refresh.
function Send-AgentNotice([string]$text) {
    Log "agent accounts: $text"
    $p = Get-Paths
    if ($p.ahk) { try { Start-Process -FilePath $p.ahk -ArgumentList "`"$Code\ahk\menu.ahk`"", 'agent-notice', "`"$($text -replace '"', "'")`"" } catch {} }
}

# After a usage refresh: $true when the active account changed (its limits need collecting).
function Invoke-AgentAutoswitch([string]$p, [DateTimeOffset]$now = [DateTimeOffset]::UtcNow) {
    if (-not (Test-Path -LiteralPath (Get-AccountRegistryPath $p))) { return $false }
    $name = $AccountProviders[$p].name
    $usage = Get-AccountUsage $p
    $notice = $null
    $switched = Update-AccountRegistry $p {
        param($r)
        if (@($r.accounts).Count -lt 2) { return $false }
        $d = Get-AccountSwitchDecision $r $usage $now
        if (-not $d) { return $false }
        if ($d.action -eq 'clear') { $r.alert = ''; return $false }
        $r.alert = $d.alert
        $src = $d.from
        if ($d.action -eq 'exhausted') {
            $when = if ($d.soonest) { " $($d.soonest.account.label) resets in $(Format-AccountDuration ($d.soonest.at - $now))." } else { '' }
            Set-Variable -Scope 1 -Name notice -Value "All $name accounts are over $($r.threshold)%. Staying on $($src.label).$when"
            return $false
        }
        $head = "$($src.label) is at $([Math]::Round($d.fromPeak))% of a $name limit."
        if ($d.action -eq 'switch') {
            $r.active = $d.to.id
            if (-not $d.to.primary) { Connect-AccountHome $p $d.to.home }
            Set-Variable -Scope 1 -Name notice -Value "$head New $name sessions now use $($d.to.label) ($([Math]::Round($d.toPeak))%). Running sessions stay on $($src.label)."
            return $true
        }
        Set-Variable -Scope 1 -Name notice -Value "$head $($d.to.label) is at $([Math]::Round($d.toPeak))%. Switch with Use in the agents panel."
        $false
    }
    if ($notice) { Send-AgentNotice $notice }
    [bool]$switched
}

# --- CLI -----------------------------------------------------------------------------

function Invoke-AgentAccountCommand([string]$command, [string]$a1, [string]$a2, [string]$a3, [switch]$Json, [switch]$Yes) {
    switch ($command) {
        { $_ -in '', 'list' } {
            $rows = @(foreach ($p in $(if ($a1) { Get-AccountProvider $a1 } else { $AccountProviders.Keys })) { Get-AgentAccounts $p })
            if ($Json) { return $rows | ConvertTo-Json -Depth 4 }
            foreach ($a in $rows) {
                $mark = if ($a.active) { '*' } else { ' ' }
                $who = if ($a.email) { $a.email } elseif (-not $a.signedIn) { '(not signed in)' } else { '' }
                "$mark $("$($a.provider)/$($a.id)".PadRight(20)) $($a.label.PadRight(14)) $who$(if ($a.plan) { "  $($a.plan)" })"
            }
            return
        }
        'add' { Add-AgentAccount $a1 $a2; return }
        'use' {
            $ref = Resolve-AccountRef $a1
            $res = Use-AgentAccount $ref.provider $ref.id
            $name = $AccountProviders[$ref.provider].name
            "New $name sessions use $($res.active.label).$(if ($res.previous.id -ne $res.active.id) { " Running sessions stay on $($res.previous.label)." })"
            return
        }
        'rename' {
            $ref = Resolve-AccountRef $a1
            $a = Rename-AgentAccount $ref.provider $ref.id $a2
            "Renamed: $($ref.provider)/$($a.id) ($($a.label))"
            return
        }
        'remove' {
            $ref = Resolve-AccountRef $a1
            $a = Find-Account (Read-AccountRegistry $ref.provider) $ref.id
            if (-not $a) { throw [AccountError]::new("No $($AccountProviders[$ref.provider].name) account named $($ref.id)") }
            if (-not $Yes -and (Read-Host "Forget the $($AccountProviders[$ref.provider].name) account $($a.label)? You'd have to sign in again to add it back. (y/N)") -notmatch '^(y|yes)$') { return 'Kept.' }
            [void](Remove-AgentAccount $ref.provider $ref.id)
            Repair-AgentAccounts
            "Removed $($a.label). Its sign-in is not revoked."
            return
        }
        'mode' {
            $p = Get-AccountProvider $a1
            $m = Set-AgentAccountMode $p $a2 $a3
            "$($AccountProviders[$p].name): $(if ($m.switch -eq 'auto') { "switches by itself at $($m.threshold)%" } else { "switch by hand (a notice at $($m.threshold)%)" })"
            return
        }
        default { throw [AccountError]::new('usage: winarchy agent-account list | add [claude|codex] [name] | use <provider>/<id|next> | rename <provider>/<id> <name> | remove <provider>/<id> | mode <provider> <manual|auto> [threshold]') }
    }
}
