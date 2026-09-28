# Pester tests: the Install/Remove catalog (lib/catalog.ps1) and the file the menu reads.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    # herdr: the Terminal group's Herdr row answers its presence test from lib/herdr.ps1.
    foreach ($f in 'common', 'detect', 'render', 'catalog', 'herdr') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
}

Describe 'Catalog table' {
    It 'gives every item a key, label and winget id' {
        foreach ($group in $Catalog) {
            $group.key | Should -Match '^[a-z][a-z0-9-]*$'
            $group.label | Should -Not -BeNullOrEmpty
            $group.icon | Should -Not -BeNullOrEmpty
            foreach ($item in $group.items) {
                $item.key | Should -Match '^[a-z0-9][a-z0-9.-]*$'
                $item.label | Should -Not -BeNullOrEmpty
                $item.id | Should -Not -BeNullOrEmpty
                $item.test | Should -BeOfType [scriptblock]
            }
        }
    }
    It 'uses winget id syntax' {
        foreach ($group in $Catalog) {
            foreach ($item in $group.items) { $item.id | Should -Match '^[A-Za-z0-9][A-Za-z0-9._+-]*$' }
        }
    }
    It 'keeps item keys unique across groups' {
        # The menu sends back a key alone, so two groups sharing one would install the wrong thing.
        $keys = @(foreach ($group in $Catalog) { foreach ($item in $group.items) { $item.key } })
        ($keys | Select-Object -Unique).Count | Should -Be $keys.Count
    }
    It 'looks an item up by key, and nothing by a key it does not have' {
        (Get-CatalogItem 'steam').id | Should -Be 'Valve.Steam'
        Get-CatalogItem 'no-such-item' | Should -BeNullOrEmpty
    }
}

Describe 'Presence tests' {
    It 'matches an Add/Remove Programs display name' {
        $snapshot = [ordered]@{ arp = @('Steam', 'Git', 'Microsoft Edge') }
        Test-CatalogArp $snapshot '^Steam' | Should -BeTrue
        Test-CatalogArp $snapshot 'Battle\.net' | Should -BeFalse
    }
    It 'answers every row from one snapshot' {
        $snapshot = Get-InstalledSnapshot
        $snapshot.arp | Should -Not -BeNullOrEmpty
        foreach ($group in $Catalog) {
            foreach ($item in $group.items) { { & $item.test $snapshot } | Should -Not -Throw }
        }
    }
    It 'never asks winget whether something is installed' {
        # The menu has to open now, not after a `winget list` per row -- that stall is the
        # whole reason presence comes from a registry snapshot instead.
        (Get-Command Get-InstalledSnapshot).ScriptBlock.ToString() | Should -Not -Match 'winget'
        foreach ($group in $Catalog) {
            foreach ($item in $group.items) { $item.test.ToString() | Should -Not -Match 'winget' }
        }
    }
    It 'survives a test whose target is missing' {
        $snapshot = [ordered]@{ arp = @() }
        Test-CatalogArp $snapshot 'Nothing Installed Here' | Should -BeFalse
        Test-CatalogCommand 'winarchy-no-such-command' | Should -BeFalse
    }
}

Describe 'catalog.json' {
    BeforeAll {
        $script:pack = Join-Path ([IO.Path]::GetTempPath()) "winarchy-catalog-$PID"
        New-Item -ItemType Directory -Force $script:pack | Out-Null
        $Pack = $script:pack
        $script:state = Update-Catalog
        $script:json = Get-Content -Raw (Join-Path $script:pack 'catalog.json') | ConvertFrom-Json
    }
    AfterAll { Remove-Item -Recurse -Force $script:pack -ErrorAction SilentlyContinue }

    It 'writes one group per catalog group, in order' {
        @($script:json.groups).Count | Should -Be $Catalog.Count
        @($script:json.groups.key) | Should -Be @($Catalog | ForEach-Object { $_.key })
    }
    It 'writes every item with an installed flag' {
        foreach ($group in $script:json.groups) {
            foreach ($item in $group.items) {
                $item.key | Should -Not -BeNullOrEmpty
                $item.label | Should -Not -BeNullOrEmpty
                $item.installed | Should -BeOfType [bool]
            }
        }
    }
    It 'keeps winget ids out of the file the widget reads' {
        # The menu only ever sends a key back, so the ids have no business being published.
        $raw = Get-Content -Raw (Join-Path $script:pack 'catalog.json')
        $raw | Should -Not -Match 'Valve\.Steam'
        $raw | Should -Not -Match 'Microsoft\.VisualStudioCode'
    }
    It 'returns the same item count it wrote' {
        $written = @($script:json.groups | ForEach-Object { $_.items }).Count
        @($script:state).Count | Should -Be $written
    }
}

Describe 'Install and remove' {
    It 'refuses a key that is not in the catalog' {
        { Install-CatalogItem 'no-such-item' } | Should -Throw '*unknown catalog item*'
        { Uninstall-CatalogItem 'no-such-item' } | Should -Throw '*unknown catalog item*'
    }
}

Describe 'The menu side' {
    It 'offers Install and Remove from the root menu' {
        $menu = Get-Content -Raw "$root\zebar\omarchy\menu.json" | ConvertFrom-Json
        @($menu.root.items | Where-Object { $_.route -eq 'install' }).Count | Should -Be 1
        @($menu.root.items | Where-Object { $_.route -eq 'remove' }).Count | Should -Be 1
    }
    It 'names every generated route in menu.js, so a direct open is not dropped' {
        # menu.js falls back to root for a route it does not recognise, which is how the
        # Apps route was silently unreachable by `menu.ahk open apps`.
        $js = Get-Content -Raw "$root\zebar\omarchy\menu.js"
        $js | Should -Match "const generated = r => \[[^\]]*'apps'[^\]]*\]\.includes\(r\)"
        $js | Should -Match "r === 'install'"
        $js | Should -Match "r === 'remove'"
    }
    It 'dispatches the catalog verbs through menu.ahk' {
        $ahk = Get-Content -Raw "$root\ahk\menu.ahk"
        $ahk | Should -Match '(?m)^\s+case "install-app":'
        $ahk | Should -Match '(?m)^\s+case "remove-app":'
        $ahk | Should -Match '(?m)^\s+case "catalog-refresh":'
        # catalog-refresh sends no keys, so it must not wait for the menu to close first.
        $ahk | Should -Match 'catalog-refresh\)\$'
    }
    It 'styles an installed row as dim' {
        Get-Content -Raw "$root\zebar\omarchy\menu.css" | Should -Match '\.row\.dim'
    }
}
