# Pester tests: the README is the manual's index, and the manual keeps Omarchy's style.
BeforeDiscovery {
    $root = Split-Path -Parent $PSScriptRoot
    $docs = @(Get-ChildItem "$root\manual" -Filter *.md) + @(Get-Item "$root\README.md")
    $chapters = @(Get-ChildItem "$root\manual" -Filter *.md | ForEach-Object { @{ name = $_.Name } })
    $pages = @($docs | ForEach-Object { @{ name = $_.Name; path = $_.FullName } })
}

BeforeAll {
    $root = Split-Path -Parent $PSScriptRoot
    $readme = Get-Content -Raw "$root\README.md"
}

Describe 'The README' {
    It 'links <name>' -ForEach $chapters {
        $readme | Should -Match ([regex]::Escape("](manual/$name)"))
    }
}

Describe '<name>' -ForEach $pages {
    BeforeAll { $text = Get-Content -Raw $path; $dir = Split-Path $path }
    It 'links only to files that exist' {
        $broken = foreach ($m in [regex]::Matches($text, '\]\(([^)#\s]+)(#[^)]*)?\)')) {
            $target = $m.Groups[1].Value
            if ($target -match '^<?[a-z]+:') { continue }
            if (-not (Test-Path (Join-Path $dir $target))) { $target }
        }
        $broken | Should -BeNullOrEmpty
    }
    It 'writes keys as `Super + X` and menu paths with >' {
        $text | Should -Not -Match '\b(Super|Ctrl|Alt|Shift)\+\S'
        $text | Should -Not -Match '›'
    }
    It 'starts with its title' {
        ($text -split "`n" | Where-Object { $_ -match '^#' } | Select-Object -First 1) | Should -Match '^# '
    }
}
