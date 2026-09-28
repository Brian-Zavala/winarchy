# Versioning: every push to main is a release (the `version` job in .github/workflows/ci.yml).
# The version is semver in the `version` file; a push bumps the patch, or the minor/major
# when one of its commit messages says [minor] / [major]. The CHANGELOG's Unreleased
# section, when it has entries, becomes that version's section and its release notes.

function Get-VersionFile {
    foreach ($name in 'version', 'VERSION') {
        $f = Join-Path $Code $name
        if (Test-Path -LiteralPath $f) { return $f }
    }
    Join-Path $Code 'version'
}

function Get-NextVersion([string]$current, [string[]]$messages) {
    if ($current.Trim() -notmatch '^v?(\d+)\.(\d+)\.(\d+)$') { throw "not a version: '$current'" }
    $major, $minor, $patch = [int]$Matches[1], [int]$Matches[2], [int]$Matches[3]
    $all = $messages -join "`n"
    if ($all -match '\[major\]') { return "$($major + 1).0.0" }
    if ($all -match '\[minor\]') { return "$major.$($minor + 1).0" }
    "$major.$minor.$($patch + 1)"
}

# The Unreleased section becomes "## <version> — <date>" under a fresh, empty Unreleased.
# Returns the new text and the section's entries (the release notes), or $null notes when
# there was nothing under Unreleased, in which case the text is left as it was.
function Update-ChangelogRelease([string]$text, [string]$version, [string]$date) {
    $nl = if ($text -match "`r`n") { "`r`n" } else { "`n" }
    $m = [regex]::Match($text, '(?ms)^## Unreleased[ \t]*\r?\n(.*?)(?=^## |\z)')
    if (-not $m.Success) { return @{ text = $text; notes = $null } }
    $notes = $m.Groups[1].Value.Trim()
    if (-not $notes) { return @{ text = $text; notes = $null } }
    $section = "## Unreleased$nl$nl## $version — $date$nl$nl$notes$nl$nl"
    @{ text = $text.Substring(0, $m.Index) + $section + $text.Substring($m.Index + $m.Length); notes = $notes }
}

# Release notes when the CHANGELOG has none: the pushed commits' subject lines.
function Format-CommitNotes([string[]]$subjects) {
    (@($subjects | Where-Object { $_ -and $_ -notmatch '^Version \d' } | ForEach-Object { "- $_" }) -join "`n")
}

# The repo description: what Winarchy is, its version and the Omarchy release it tracks.
function Get-RepoDescription([string]$version, [string]$omarchyRelease) {
    "Omarchy's look, keys and themes on Windows 11: GlazeWM tiling, the Omarchy bar and menu, 22 themes, Herdr and coding agents. Unofficial. v$version · tracks Omarchy $omarchyRelease"
}
