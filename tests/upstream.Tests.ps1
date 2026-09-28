# Pester tests: the upstream checker (lib/upstream.ps1), on a recorded GitHub comparison
# (tests/fixtures/upstream/compare.json), so no network.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'upstream') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    $compare = Get-Content -Raw "$root\tests\fixtures\upstream\compare.json" | ConvertFrom-Json
    $state = [pscustomobject]@{ repo = 'omacom/omarchy'; branch = 'quattro'; reviewedCommit = 'b2ffea57429d92c425b2ac9d86edda7a0d8c062b'; release = 'v4.0.4' }
}

Describe 'Get-UpstreamArea' {
    It 'maps <path> to <area>' -ForEach @(
        @{ path = 'default/hypr/bindings/tiling.lua'; area = 'Keys' }
        @{ path = 'default/omarchy/omarchy-menu.jsonc'; area = 'Menu' }
        @{ path = 'bin/omarchy-menu-keybindings'; area = 'Menu' }
        @{ path = 'default/bash/aliases'; area = 'Herdr and shell' }
        @{ path = 'bin/omarchy-agent-usage-claude'; area = 'Agent usage' }
        @{ path = 'bin/omarchy-agent'; area = 'Coding agents' }
        @{ path = 'bin/omarchy-theme-color'; area = 'Theming' }
        @{ path = 'themes/nord/colors.toml'; area = 'Theming' }
        @{ path = 'shell/plugins/bar/Bar.qml'; area = 'Top bar' }
        @{ path = 'shell/plugins/panels/clock/Panel.qml'; area = 'Bar panels' }
        @{ path = 'bin/omarchy'; area = 'CLI' }
        @{ path = 'bin/omarchy-install-steam'; area = 'Install / Remove' }
        @{ path = 'bin/omarchy-toggle-animations'; area = 'Toggles' }
        @{ path = 'default/hypr/looknfeel.lua'; area = 'Window manager' }
        @{ path = 'test/shell.d/toggle-test.sh'; area = 'Upstream only' }
        @{ path = 'something/else'; area = 'Other' }
    ) {
        (Get-UpstreamArea $path).area | Should -Be $area
    }
    It 'points a manual chapter at ours, or says it is new' {
        (Get-UpstreamArea 'manual/06-themes.md').review | Should -Contain 'manual/06-themes.md'
        (Get-UpstreamArea 'manual/09-reminders.md').review | Should -Contain '(new upstream chapter 09)'
    }
    It 'flags nothing to review for upstream-only files' {
        (Get-UpstreamArea 'install/user/all.sh').review | Should -BeNullOrEmpty
    }
}

Describe 'ConvertTo-UpstreamReport' {
    BeforeAll { $r = ConvertTo-UpstreamReport $compare $state 'v4.0.4' '2026-09-28' }
    It 'lists every commit, linked' {
        foreach ($c in $compare.commits) { $r.text | Should -Match ([regex]::Escape("[$($c.sha.Substring(0, 7))]($($c.html_url))")) }
    }
    It 'groups the files by area, with the files to review' {
        $r.areas | Should -Contain 'Keys'
        $r.areas | Should -Contain 'Menu'
        $r.text | Should -Match '\| Keys \| `default/hypr/bindings/applications.lua` \| `ahk/winarchy.ahk`'
    }
    It 'ends at the newest commit' { $r.head | Should -Be $compare.commits[-1].sha }
    It 'says nothing about a release that is not new' { $r.text | Should -Not -Match 'New Omarchy release' }
    It 'announces a new release' {
        (ConvertTo-UpstreamReport $compare $state 'v4.1.0' '2026-09-28').text | Should -Match 'New Omarchy release: v4\.1\.0'
    }
}

Describe 'Invoke-UpstreamCheck -Write' {
    BeforeEach {
        $Code = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Force "$Code\default", "$Code\docs" | Out-Null
        $UpstreamFile = "$Code\default\upstream.json"
        $UpstreamLog = "$Code\docs\upstream.md"
        $state | ConvertTo-Json | Set-Content $UpstreamFile
        Set-Content "$Code\default\config.json" '{ "omarchyTag": "v4.0.4", "gap": 10 }'
        Set-Content "$Code\README.md" 'Tracks Omarchy v4.0.4.'
        Mock Invoke-GitHubApi { $compare } -ParameterFilter { $path -like '*/compare/*' }
        Mock Invoke-GitHubApi { [pscustomobject]@{ tag_name = 'v4.1.0' } } -ParameterFilter { $path -like '*/releases/latest' }
    }
    It 'writes the report, moves the reviewed commit and follows the new release' {
        Invoke-UpstreamCheck -Write | Out-Null
        $s = Get-Content -Raw $UpstreamFile | ConvertFrom-Json
        $s.reviewedCommit | Should -Be $compare.commits[-1].sha
        $s.release | Should -Be 'v4.1.0'
        (Get-Content -Raw "$Code\default\config.json" | ConvertFrom-Json).omarchyTag | Should -Be 'v4.1.0'
        Get-Content -Raw "$Code\README.md" | Should -Match 'Tracks Omarchy v4\.1\.0'
        Get-Content -Raw $UpstreamLog | Should -Match '(?s)^# Upstream.*## \d{4}-\d\d-\d\d'
    }
    It 'puts the newest report first' {
        Set-Content $UpstreamLog "# Upstream`n`nIntro.`n`n## 2026-01-01`n`nOld.`n"
        Invoke-UpstreamCheck -Write | Out-Null
        $t = Get-Content -Raw $UpstreamLog
        $t.IndexOf('Old.') | Should -BeGreaterThan $t.IndexOf('new commit(s)')
    }
}
