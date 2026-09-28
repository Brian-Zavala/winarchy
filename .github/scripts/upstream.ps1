# The upstream workflow: check Omarchy for changes since the reviewed commit, write the
# report into docs/upstream.md and default/upstream.json, and hand the workflow whether
# anything changed and the report for the pull request (GITHUB_OUTPUT).
$ErrorActionPreference = 'Stop'
$Verb = 'upstream'
. "$PSScriptRoot\..\..\lib\common.ps1"
. "$PSScriptRoot\..\..\lib\upstream.ps1"

$r = Invoke-UpstreamCheck -Json -Write | ConvertFrom-Json
$r.report
$body = Join-Path ([IO.Path]::GetTempPath()) 'upstream-report.md'
$note = "`n---`n`nPorting a change is a reviewed step: see [agents/skills/upstream-sync.md](agents/skills/upstream-sync.md). Merging this pull request marks these commits as reviewed.`n"
[IO.File]::WriteAllText($body, "Omarchy changed since Winarchy last reviewed it.`n`n" + $r.report + $note)
if ($env:GITHUB_OUTPUT) {
    Add-Content $env:GITHUB_OUTPUT "changed=$($r.changed.ToString().ToLower())"
    Add-Content $env:GITHUB_OUTPUT "body=$body"
    Add-Content $env:GITHUB_OUTPUT "head=$($r.head)"
}
