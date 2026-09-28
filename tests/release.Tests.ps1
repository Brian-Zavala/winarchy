# Pester tests: the version bump and release notes every push to main gets (lib/release.ps1).
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'release') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
}

Describe 'Get-NextVersion' {
    It 'bumps the patch by default' { Get-NextVersion '0.1.9' @('Fix a thing') | Should -Be '0.1.10' }
    It 'bumps the minor for [minor]' { Get-NextVersion '0.1.9' @('Fix', "New menu`n`n[minor]") | Should -Be '0.2.0' }
    It 'bumps the major for [major], over [minor]' { Get-NextVersion '0.4.2' @('[minor] a', '[major] b') | Should -Be '1.0.0' }
    It 'reads a v prefix and a trailing newline' { Get-NextVersion "v1.2.3`n" @() | Should -Be '1.2.4' }
    It 'refuses something that is not a version' { { Get-NextVersion 'abc' @() } | Should -Throw }
}

Describe 'Update-ChangelogRelease' {
    It 'moves the Unreleased entries under the new version, and leaves a fresh Unreleased' {
        $text = "# Changelog`n`n## Unreleased`n`n- One`n- Two`n`n## 0.1.0 — 2026-01-01`n`n- Old`n"
        $r = Update-ChangelogRelease $text '0.1.1' '2026-09-28'
        $r.notes | Should -Be "- One`n- Two"
        $r.text | Should -Be "# Changelog`n`n## Unreleased`n`n## 0.1.1 — 2026-09-28`n`n- One`n- Two`n`n## 0.1.0 — 2026-01-01`n`n- Old`n"
    }
    It 'changes nothing when Unreleased is empty' {
        $text = "# Changelog`n`n## Unreleased`n`n## 0.1.1 — 2026-09-28`n`n- One`n"
        $r = Update-ChangelogRelease $text '0.1.2' '2026-09-29'
        $r.notes | Should -BeNullOrEmpty
        $r.text | Should -Be $text
    }
    It 'keeps CRLF line endings' {
        $r = Update-ChangelogRelease "# C`r`n`r`n## Unreleased`r`n`r`n- One`r`n" '0.1.1' 'd'
        $r.text | Should -Be "# C`r`n`r`n## Unreleased`r`n`r`n## 0.1.1 — d`r`n`r`n- One`r`n`r`n"
    }
}

Describe 'Format-CommitNotes' {
    It 'lists the subjects, without version commits' {
        Format-CommitNotes @('Fix a', 'Version 0.1.3 [skip ci]', 'Add b') | Should -Be "- Fix a`n- Add b"
    }
}

Describe 'The release script' {
    It 'bumps the version file and writes the notes for a range of commits' {
        $repo = Join-Path $TestDrive 'repo'
        New-Item -ItemType Directory -Force "$repo\lib", "$repo\default" | Out-Null
        Copy-Item "$root\lib\common.ps1", "$root\lib\release.ps1" "$repo\lib"
        New-Item -ItemType Directory -Force "$repo\.github\scripts" | Out-Null
        Copy-Item "$root\.github\scripts\release.ps1" "$repo\.github\scripts"
        Set-Content "$repo\version" '0.1.4'
        Set-Content "$repo\default\upstream.json" '{ "release": "v4.0.4" }'
        Set-Content "$repo\CHANGELOG.md" "# Changelog`n`n## Unreleased`n`n- Something new`n"
        git -C $repo init -q -b main; git -C $repo -c user.name=t -c user.email=t@t commit -q --allow-empty -m first
        git -C $repo -c user.name=t -c user.email=t@t commit -q --allow-empty -m "Add a feature [minor]"
        $out = Join-Path $TestDrive 'out.txt'
        $env:GITHUB_OUTPUT = $out
        try { pwsh -NoProfile -File "$repo\.github\scripts\release.ps1" -Before (git -C $repo rev-parse HEAD~1) -After HEAD | Out-Null }
        finally { Remove-Item Env:GITHUB_OUTPUT }
        (Get-Content -Raw "$repo\version").Trim() | Should -Be '0.2.0'
        $o = Get-Content $out
        $o | Should -Contain 'version=0.2.0'
        $o | Should -Contain 'file=version'
        ($o | Where-Object { $_ -like 'description=*' }) | Should -BeLike '*v0.2.0 · tracks Omarchy v4.0.4'
        Get-Content -Raw (($o | Where-Object { $_ -like 'notes=*' }) -replace '^notes=') | Should -Match 'Something new'
        Get-Content -Raw "$repo\CHANGELOG.md" | Should -Match '## 0\.2\.0 — \d{4}-\d\d-\d\d'
    }
}
