# Pester tests: the Install/Remove catalog (lib/catalog.ps1) and the file the menu reads.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    # herdr: the Terminal group's Herdr row answers its presence test from lib/herdr.ps1.
    # webapps (+ journal): the Web Apps group's rows come from default/webapps.json.
    # apps, ui: a custom terminal app rebuilds the Apps list and says so (both mocked).
    foreach ($f in 'common', 'detect', 'render', 'journal', 'webapps', 'catalog', 'herdr', 'apps', 'ui') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    # The Web Apps rows ask the journal: a scratch one, never the real one.
    $script:JournalDir = Join-Path $TestDrive 'journal'
    $script:JournalCache = $null
    New-Item -ItemType Directory $script:JournalDir | Out-Null
    Write-Json (Join-Path $script:JournalDir 'journal.json') ([ordered]@{ entries = @() })
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

Describe 'Terminal apps in Start' {
    BeforeEach {
        $script:lnkDir = Join-Path $TestDrive ([guid]::NewGuid())
        Mock Get-TuiShortcutPath { Join-Path $script:lnkDir "$($item.tui.name).lnk" }
        Mock Find-TuiExe { Join-Path $env:SystemRoot 'notepad.exe' }
        Mock Save-File {}
    }
    It 'gives every TUI row a Start entry' {
        foreach ($k in 'lazygit', 'lazydocker', 'dua', 'cliamp', 'btop', 'herdr') { (Get-CatalogItem $k).tui | Should -Not -BeNullOrEmpty -Because $k }
    }
    It 'makes one that opens the app in the terminal, with its own AppUserModelID' {
        $item = Get-CatalogItem 'cliamp'
        Add-TuiShortcut $item | Should -BeTrue
        $lnk = Join-Path $script:lnkDir 'Cliamp.lnk'
        $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
        $s.Arguments | Should -Match 'notepad\.exe'
        if (Get-Command wt.exe -ErrorAction SilentlyContinue) { $s.Arguments | Should -Match '^new-tab --title "Cliamp"' }
        [Winarchy.Shortcut]::GetAppId($lnk) | Should -Be 'Winarchy.Tui.cliamp'
        Should -Invoke Save-File -Times 1
    }
    It 'passes the arguments a TUI needs' {
        Add-TuiShortcut (Get-CatalogItem 'dua') | Out-Null
        (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $script:lnkDir 'dua.lnk')).Arguments | Should -Match 'interactive$'
    }
    It 'makes none while the exe is not there yet' {
        Mock Find-TuiExe { $null }
        Add-TuiShortcut (Get-CatalogItem 'lazygit') | Should -BeFalse
        Test-Path (Join-Path $script:lnkDir 'lazygit.lnk') | Should -BeFalse
    }
    It 'takes it out again, and the folder once empty' {
        $item = Get-CatalogItem 'lazygit'
        Add-TuiShortcut $item | Out-Null
        Remove-TuiShortcut $item
        Test-Path $script:lnkDir | Should -BeFalse
    }
    It 'fills in and cleans up on apply' {
        Mock Get-InstalledSnapshot { [ordered]@{ arp = @() } }
        Mock Test-CatalogCommand { $name -eq 'lazygit' }
        Mock Test-CatalogArp { $false }
        Mock Test-HerdrInstalled { $false }
        New-Item -ItemType Directory -Force $script:lnkDir | Out-Null
        Set-Content (Join-Path $script:lnkDir 'dua.lnk') 'stale'
        Sync-TuiShortcuts
        Test-Path (Join-Path $script:lnkDir 'lazygit.lnk') | Should -BeTrue
        Test-Path (Join-Path $script:lnkDir 'dua.lnk') | Should -BeFalse
    }
}

Describe 'Your own terminal apps' {
    BeforeEach {
        $Data = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory $Data | Out-Null
        Mock Find-TuiExe { Join-Path $env:SystemRoot 'notepad.exe' }
        Mock Add-TuiShortcut { $true }
        Mock Remove-TuiShortcut {}
        Mock Update-AppList {}
        Mock Update-Catalog {}
        Mock Write-Ok {}
    }
    It 'keeps a name and a command, with its arguments split off' {
        Add-CustomTui 'Music' 'cliamp --shuffle'
        $t = @(Get-CustomTuis)
        $t.Count | Should -Be 1
        $t[0].tui.command | Should -Be 'cliamp'
        $t[0].tui.args | Should -Be '--shuffle'
        Should -Invoke Add-TuiShortcut -Times 1
    }
    It 'takes a quoted path with spaces' {
        Add-CustomTui 'Tool' '"C:\Program Files\Tool\tool.exe" -x'
        (Get-CustomTuis).tui.command | Should -Be 'C:\Program Files\Tool\tool.exe'
    }
    It 'replaces one of the same name instead of adding a second' {
        Add-CustomTui 'Music' 'cliamp'
        Add-CustomTui 'Music' 'cliamp --shuffle'
        @(Get-CustomTuis).Count | Should -Be 1
    }
    It 'refuses a command it cannot find' {
        Mock Find-TuiExe { $null }
        { Add-CustomTui 'Nope' 'winarchy-no-such-command' } | Should -Throw "*can't find*"
        Test-Path (Get-CustomTuiFile) | Should -BeFalse
    }
    It 'removes one again, shortcut and all' {
        Add-CustomTui 'Music' 'cliamp'
        Remove-CustomTui 'Music'
        @(Get-CustomTuis).Count | Should -Be 0
        Should -Invoke Remove-TuiShortcut -ParameterFilter { $item.label -eq 'Music' }
    }
    It 'is a setting uninstall can keep' {
        . "$root\lib\uninstall.ps1"
        $SettingsItems | Should -Contain 'tuis.json'
    }
}

Describe 'The menu side' {
    It 'searches everything under a menu, not just its own rows' {
        $js = Get-Content -Raw "$root\zebar\omarchy\menu.js"
        $js | Should -Match "if \(q && r === route\) return search\(r, q\)"
        # The apps, what can still be installed, themes, fonts and agents join the search.
        $js | Should -Match "const SEARCHED = \['apps', 'theme', 'font', 'agent'\]"
        # A confirmation's "Yes" (Undo Winarchy?) is never a search result.
        $js | Should -Match 'items\?\.some\(i => i\.back\)'
        Get-Content -Raw "$root\zebar\omarchy\menu.css" | Should -Match '\.row \.crumb'
    }
    It 'refreshes terminal app shortcuts with the Apps list' {
        $cli = Get-Content -Raw "$root\bin\winarchy.ps1"
        $cli | Should -Match "(?s)'apps' \{\s+try \{ Sync-TuiShortcuts \}"
        $ahk = Get-Content -Raw "$root\ahk\menu.ahk"
        $ahk | Should -Match '(?m)^\s+case "tui-add":'
        $ahk | Should -Match '(?m)^\s+case "tui-remove":'
    }
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
