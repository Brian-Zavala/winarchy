# The `version` job of ci.yml: bump the version for the commits just pushed, move the
# CHANGELOG's Unreleased entries under it, and hand the version and the release notes to
# the next steps (GITHUB_OUTPUT). Committing, tagging and the release are the workflow's.
param([string]$Before, [string]$After = 'HEAD')

$ErrorActionPreference = 'Stop'
$Verb = 'release'
. "$PSScriptRoot\..\..\lib\common.ps1"
. "$PSScriptRoot\..\..\lib\release.ps1"

$file = Get-VersionFile
$current = if (Test-Path $file) { (Get-Content -Raw $file).Trim() } else { '0.1.0' }

# Everything since the last release, so pushes whose tests failed (never released) count
# too. Without that tag, the pushed range; a new branch or a force push has no usable
# "before", so the last commit alone.
$range = if (git -C $Code rev-parse -q --verify "refs/tags/v$current" 2>$null) { "v$current..$After" }
    elseif ($Before -and $Before -notmatch '^0+$' -and (git -C $Code cat-file -t $Before 2>$null)) { "$Before..$After" }
    else { "$After~1..$After" }
$messages = @(git -C $Code log --format='%B%x00' $range) -join "`n" -split "`0" | Where-Object { $_.Trim() }
$subjects = @(git -C $Code log --format='%s' $range | Where-Object { $_ -notmatch '^Version \d+\.\d+\.\d+ \[skip ci\]$' })
$version = Get-NextVersion $current $messages
[IO.File]::WriteAllText($file, "$version`n")

$changelog = Join-Path $Code 'CHANGELOG.md'
$date = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
$r = if (Test-Path $changelog) { Update-ChangelogRelease (Get-Content -Raw $changelog) $version $date } else { @{ notes = $null } }
if ($r.notes) { [IO.File]::WriteAllText($changelog, $r.text) }
$notes = if ($r.notes) { $r.notes } else { Format-CommitNotes $subjects }
if (-not $notes) { $notes = '- Maintenance.' }
$notesFile = Join-Path ([IO.Path]::GetTempPath()) 'release-notes.md'
[IO.File]::WriteAllText($notesFile, $notes + "`n")

$upstream = Read-Json (Join-Path $Code 'default\upstream.json')
$tracks = if ($upstream.release) { $upstream.release } else { (Read-Json (Join-Path $Code 'default\config.json')).omarchyTag }

"$current -> $version ($range)"
if ($env:GITHUB_OUTPUT) {
    Add-Content $env:GITHUB_OUTPUT "version=$version"
    Add-Content $env:GITHUB_OUTPUT "notes=$notesFile"
    Add-Content $env:GITHUB_OUTPUT "file=$([IO.Path]::GetRelativePath($Code, $file).Replace('\', '/'))"
    Add-Content $env:GITHUB_OUTPUT "description=$(Get-RepoDescription $version $tracks)"
}
