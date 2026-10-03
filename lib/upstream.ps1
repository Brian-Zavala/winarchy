# Keeping up with Omarchy: what changed upstream since it was last reviewed, and which part
# of Winarchy each change touches. The daily upstream workflow runs it and opens a pull
# request with the report; porting a change stays a reviewed step
# (agents/skills/upstream-sync.md). `winarchy dev upstream` runs the same thing locally.

$UpstreamFile = Join-Path $Code 'default\upstream.json'
$UpstreamLog = Join-Path $Code 'docs\upstream.md'

# Upstream path -> the Winarchy area it maps to and the files to look at. First match wins;
# review = $null means upstream-only (its tests, its installer's Linux steps): listed, not flagged.
$UpstreamWatch = @(
    @{ match = '^manual/(\d\d)-'; area = 'Manual'; review = { param($m) @(Get-ChildItem (Join-Path $Code 'manual') -Filter "$($m[1])-*.md" -ErrorAction SilentlyContinue | ForEach-Object { "manual/$($_.Name)" }) + @(if (-not (Test-Path (Join-Path $Code "manual\$($m[1])-*.md"))) { "(new upstream chapter $($m[1]))" }) } }
    @{ match = '^README\.md$'; area = 'Manual'; review = { 'README.md' } }
    @{ match = '^default/hypr/bindings/'; area = 'Keys'; review = { 'ahk/winarchy.ahk', 'ahk/launchers.ahk', 'ahk/game-helper.ahk', 'templates/glazewm.yaml.tpl', 'default/keybindings.txt' } }
    @{ match = '^default/omarchy/omarchy-menu\.jsonc$|^bin/omarchy-menu'; area = 'Menu'; review = { 'zebar/omarchy/menu.json', 'zebar/omarchy/menu.js', 'ahk/menu.ahk' } }
    @{ match = '^config/herdr/|^default/bash/fns/herdr$|^default/bash/aliases$'; area = 'Herdr and shell'; review = { 'lib/herdr.ps1', 'templates/herdr.toml.tpl', 'lib/agents.ps1' } }
    @{ match = '^bin/omarchy-agent-usage-'; area = 'Agent usage'; review = { 'lib/agents/' } }
    @{ match = '^bin/omarchy-agent-account'; area = 'Agent accounts'; review = { 'lib/accounts.ps1' } }
    @{ match = '^bin/omarchy-(agent|default-agent)'; area = 'Coding agents'; review = { 'lib/agents.ps1' } }
    @{ match = '^themes/|^default/themed/|^bin/omarchy-theme'; area = 'Theming'; review = { 'lib/render.ps1', 'lib/themes.ps1', 'lib/targets.ps1' } }
    @{ match = '^config/omarchy/shell\.json$|^shell/plugins/bar/'; area = 'Top bar'; review = { 'zebar/omarchy/bar.html', 'zebar/omarchy/bar.css' } }
    @{ match = '^shell/plugins/panels/'; area = 'Bar panels'; review = { 'zebar/omarchy/' } }
    @{ match = '^shell/'; area = 'Shell (bar, menu, OSD)'; review = { 'zebar/omarchy/' } }
    @{ match = '^bin/omarchy$|^docs/cli-router\.md$'; area = 'CLI'; review = { 'bin/winarchy.ps1', 'lib/cli.ps1' } }
    @{ match = '^default/fonts/omarchy/|^(logo|icon)\.txt$|^etc/fastfetch/'; area = 'Branding'; review = { 'lib/about.ps1', 'lib/apply.ps1' } }
    @{ match = '^bin/omarchy-(install|remove)-'; area = 'Install / Remove'; review = { 'lib/catalog.ps1' } }
    @{ match = '^bin/omarchy-toggle-|^default/hypr/toggles/'; area = 'Toggles'; review = { 'ahk/winarchy.ahk', 'ahk/menu.ahk' } }
    @{ match = '^bin/omarchy-(launch|cmd)-'; area = 'Launchers'; review = { 'ahk/launchers.ahk', 'ahk/menu.ahk' } }
    @{ match = '^default/hypr/'; area = 'Window manager'; review = { 'templates/glazewm.yaml.tpl', 'ahk/winarchy.ahk' } }
    @{ match = '^AGENTS\.md$|^docs/'; area = 'Conventions'; review = { 'AGENTS.md', 'docs/' } }
    @{ match = '^bin/'; area = 'Other commands'; review = { 'lib/' } }
    @{ match = '^(test|install|migrations|iso|autostart)/|^boot\.sh$'; area = 'Upstream only'; review = $null }
)

function Get-UpstreamArea([string]$path) {
    foreach ($w in $UpstreamWatch) {
        $m = [regex]::Match($path, $w.match)
        if ($m.Success) {
            $groups = @($m.Groups | ForEach-Object Value)
            return @{ area = $w.area; review = @(if ($w.review) { & $w.review $groups }) }
        }
    }
    @{ area = 'Other'; review = @() }
}

function Invoke-GitHubApi([string]$path) {
    $headers = @{ Accept = 'application/vnd.github+json'; 'User-Agent' = 'winarchy' }
    $token = $env:GITHUB_TOKEN ?? $env:GH_TOKEN
    if ($token) { $headers.Authorization = "Bearer $token" }
    Invoke-RestMethod "https://api.github.com/$path" -Headers $headers -TimeoutSec 60
}

# The report, as markdown: the new release if there is one, the changed areas with the
# Winarchy files to review, and the commits. $compare is GitHub's compare API response.
function ConvertTo-UpstreamReport($compare, $state, [string]$latestRelease, [string]$date, [string]$branch) {
    $commits = @($compare.commits)
    $head = if ($commits) { $commits[-1].sha } else { $state.reviewedCommit }
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add("## $date")
    $lines.Add('')
    if (-not $branch) { $branch = $state.branch }
    $lines.Add("$($compare.total_commits) new commit(s) on $($state.repo)@$branch, [$($state.reviewedCommit.Substring(0, 7))...$($head.Substring(0, 7))]($($compare.html_url)).")
    if ($compare.total_commits -gt $commits.Count) {
        $lines.Add('')
        $lines.Add("Only the first $($commits.Count) commits and $(@($compare.files).Count) files fit in one comparison: follow the link for the rest.")
    }
    if ($branch -ne $state.branch) {
        $lines.Add('')
        $lines.Add("**Omarchy's development branch moved: $($state.branch) -> $branch.** Winarchy follows it from here, and the README says so.")
    }
    if ($latestRelease -and $latestRelease -ne $state.release) {
        $lines.Add('')
        $lines.Add("**New Omarchy release: $latestRelease** (Winarchy tracked $($state.release)). Themes and backgrounds follow it; check its notes: https://github.com/$($state.repo)/releases/tag/$latestRelease")
    }
    $byArea = [ordered]@{}
    foreach ($f in @($compare.files)) {
        $a = Get-UpstreamArea $f.filename
        if (-not $byArea.Contains($a.area)) { $byArea[$a.area] = @{ files = [Collections.Generic.List[string]]::new(); review = [Collections.Generic.List[string]]::new() } }
        $byArea[$a.area].files.Add($f.filename)
        foreach ($r in $a.review) { if (-not $byArea[$a.area].review.Contains($r)) { $byArea[$a.area].review.Add($r) } }
    }
    if ($byArea.Count) {
        $lines.Add('')
        $lines.Add('| Area | Upstream files | Winarchy files to review |')
        $lines.Add('|---|---|---|')
        foreach ($k in $byArea.PSBase.Keys) {
            $files = $byArea[$k].files
            $shown = (@($files | Select-Object -First 6 | ForEach-Object { "``$_``" }) -join '<br>') + $(if ($files.Count -gt 6) { "<br>and $($files.Count - 6) more" })
            $review = if ($byArea[$k].review.Count) { (@($byArea[$k].review | ForEach-Object { if ($_ -like '(*') { $_ } else { "``$_``" } }) -join '<br>') } else { '-' }
            $lines.Add("| $k | $shown | $review |")
        }
    }
    if ($commits) {
        $lines.Add('')
        $lines.Add('Commits:')
        $lines.Add('')
        foreach ($c in $commits) { $lines.Add("- [$($c.sha.Substring(0, 7))]($($c.html_url)) $(($c.commit.message -split "`n")[0])") }
    }
    @{ text = ($lines -join "`n") + "`n"; head = $head; areas = @($byArea.PSBase.Keys) }
}

function Invoke-UpstreamCheck([string]$Since, [switch]$Json, [switch]$Write) {
    $state = Read-Json $UpstreamFile
    if (-not $state) { throw "no $UpstreamFile" }
    $from = if ($Since) { $Since } else { $state.reviewedCommit }
    # Winarchy follows Omarchy's default branch, its development line (quattro for v4).
    $branch = try { (Invoke-GitHubApi "repos/$($state.repo)").default_branch } catch { $null }
    if (-not $branch) { $branch = $state.branch }
    $compare = Invoke-GitHubApi "repos/$($state.repo)/compare/$from...$branch"
    $release = try { (Invoke-GitHubApi "repos/$($state.repo)/releases/latest").tag_name } catch { $null }
    $state.reviewedCommit = $from
    $date = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
    $report = ConvertTo-UpstreamReport $compare $state $release $date $branch
    $changed = [bool]$compare.total_commits -or ($release -and $release -ne $state.release) -or $branch -ne $state.branch
    if ($Json) {
        [ordered]@{ changed = $changed; branch = $branch; commits = $compare.total_commits; head = $report.head; release = $release; areas = $report.areas; report = $report.text } | ConvertTo-Json -Depth 5
    } else { $report.text }
    if (-not $Write -or -not $changed) { return }

    $log = if (Test-Path $UpstreamLog) { Get-Content -Raw $UpstreamLog } else { "# Upstream`n`nWhat changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).`n" }
    $at = $log.IndexOf("`n## ")
    $log = if ($at -ge 0) { $log.Substring(0, $at + 1) + $report.text + "`n" + $log.Substring($at + 1) } else { $log.TrimEnd() + "`n`n" + $report.text }
    Write-Utf8 $UpstreamLog $log

    $new = [ordered]@{ repo = $state.repo; branch = $branch; reviewedCommit = $report.head; reviewedAt = $date; release = $state.release }
    if ($release -and $release -ne $state.release) {
        $new.release = $release
        # The themes and backgrounds come from the release Winarchy tracks.
        $cfgFile = Join-Path $Code 'default\config.json'
        $cfg = Get-Content -Raw $cfgFile
        Write-Utf8 $cfgFile ($cfg -replace '("omarchyTag":\s*")[^"]*(")', "`${1}$release`${2}")
    }
    $readme = Join-Path $Code 'README.md'
    if (Test-Path $readme) {
        $t = Get-Content -Raw $readme
        # Digits and inner dots only: the sentence's own full stop stays.
        $n = $t -replace 'Tracks Omarchy v\d+(\.\d+)*', "Tracks Omarchy $($new.release)"
        $n = $n -replace "\[``[^``]+``\]\(https://github\.com/$([regex]::Escape($state.repo))/tree/[^)]+\)", "[``$branch``](https://github.com/$($state.repo)/tree/$branch)"
        if ($n -ne $t) { Write-Utf8 $readme $n }
    }
    Write-Utf8 $UpstreamFile (($new | ConvertTo-Json) + "`n")
}
