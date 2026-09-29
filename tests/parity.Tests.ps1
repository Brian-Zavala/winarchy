# Pester tests: the Omarchy parity pass (world clock, bar transparency, the extra menu rows).
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'catalog', 'herdr', 'agents', 'system', 'netpanel', 'audio') { . "$root\lib\$f.ps1" }
    $Code = $root
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    $menu = Get-Content -Raw (Join-Path $root 'zebar\omarchy\menu.json') | ConvertFrom-Json -AsHashtable
    $ahk = Get-Content -Raw (Join-Path $root 'ahk\menu.ahk')
    $bar = Get-Content -Raw (Join-Path $root 'zebar\omarchy\bar.html')
}

Describe 'menu.json rows' {
    It 'sends only verbs that menu.ahk has a case for' {
        foreach ($route in $menu.Keys) {
            foreach ($item in $menu[$route].items) {
                if ($item.action) { $ahk | Should -Match "case\s[^`n]*`"$($item.action[0])`"" -Because "$route / $($item.label)" }
            }
        }
    }
    It 'points every route at a static menu or a generated one' {
        $generated = 'background', 'theme', 'keys', 'font', 'apps', 'herdr-keys', 'agent', 'timezone', 'install', 'remove'
        foreach ($route in $menu.Keys) {
            foreach ($item in $menu[$route].items) {
                if ($item.route) {
                    ($menu.ContainsKey($item.route) -or $item.route -in $generated -or $item.route -match '^(install|remove)-') |
                        Should -BeTrue -Because "$route / $($item.label) -> $($item.route)"
                }
            }
        }
    }
    It 'gives every row an icon' {
        foreach ($route in $menu.Keys) { foreach ($item in $menu[$route].items) { $item.icon | Should -Not -BeNullOrEmpty -Because "$route / $($item.label)" } }
    }
    It 'carries the Omarchy rows added for parity' {
        @($menu.trigger.items.label) | Should -Contain 'World Clock'
        @($menu.trigger.items.label) | Should -Contain 'Reminder'
        @($menu.trigger.items.label) | Should -Contain 'Speed Test'
        @($menu.'style-bar'.items.label) | Should -Contain 'Transparency'
        @($menu.'setup-dns'.items.label) | Should -Be @('DHCP', 'Cloudflare', 'Google', 'Custom')
        @($menu.update.items | Where-Object label -eq 'Timezone').route | Should -Be 'timezone'
    }
}

Describe 'the bar' {
    It 'opens the Power panel from the battery icon, and a desktop keeps the Power menu' {
        $bar | Should -Match "\$\('battery'\)\.onclick = \(\) => act\('power-panel'\)"
        $bar | Should -Match "barState\?\.percent"
        $ahk | Should -Match '(?s)case "power-panel":\s+if HasBattery\(\)\s+OpenPanel\("power", "p", WritePowerState\)\s+else\s+OpenMenu\("power"\)'
        (Get-Content -Raw (Join-Path $root 'ahk\winarchy.ahk')) | Should -Match '#\^p::[^\n]*power-panel'
        foreach ($f in 'html', 'css', 'js') { Test-Path (Join-Path $root "zebar\omarchy\power.$f") | Should -BeTrue }
    }
    It 'toggles the battery percentage from Toggle, on a laptop only' {
        $row = $menu.toggle.items | Where-Object label -EQ 'Battery Percentage'
        $row.action | Should -Be @('battery-percentage')
        $row.when | Should -Be 'laptop'
    }
    It 'keeps both bar switches in bar-state.json when one is flipped' {
        $ahk | Should -Match 'case "bar-clear": ToggleBarState\("clear"\)'
        $ahk | Should -Match 'case "battery-percentage": ToggleBarState\("percent"\)'
        $ahk | Should -Match '\{"clear":[^\n]*,"percent":'
    }
    It 'toggles transparency on a double-click on empty bar space, through bar-state.json' {
        $bar | Should -Match "addEventListener\('dblclick'"
        $bar | Should -Match "bar-state\.json"
        $ahk | Should -Match 'case "bar-clear"'
        (Get-Content -Raw (Join-Path $root 'zebar\omarchy\bar.css')) | Should -Match 'html\.clear'
    }
    It 'opens the world clock from a middle click on the clock' {
        $bar | Should -Match "onauxclick[^\n]*button === 1[^\n]*worldclock"
        $ahk | Should -Match 'case "worldclock"'
        (Get-Content -Raw (Join-Path $root 'ahk\winarchy.ahk')) | Should -Match '#\^!e::'
    }
    It 'ships the world clock panel and registers its widget with per-monitor presets' {
        foreach ($f in 'html', 'css', 'js') { Test-Path (Join-Path $root "zebar\omarchy\worldclock.$f") | Should -BeTrue }
        (Get-Content -Raw (Join-Path $root 'lib\apply.ps1')) | Should -Match "'worldclock' './worldclock\.html'"
    }
}

Describe 'the bar panels' {
    It 'opens Quattro-style network, audio and bluetooth panels from the bar icons' {
        foreach ($p in 'network', 'audio', 'bluetooth') {
            $bar | Should -Match "act\('$p-panel'\)"
            $ahk | Should -Match "case `"$p-panel`""
            foreach ($f in 'html', 'css', 'js') { Test-Path (Join-Path $root "zebar\omarchy\$p.$f") | Should -BeTrue }
            (Get-Content -Raw (Join-Path $root 'lib\apply.ps1')) | Should -Match "'$p' './$p\.html'"
        }
    }
    It 'has menu.ahk verbs for everything the panels send' {
        foreach ($f in 'network', 'audio', 'bluetooth') {
            $js = Get-Content -Raw (Join-Path $root "zebar\omarchy\$f.js")
            foreach ($m in [regex]::Matches($js, "act\('([a-z-]+)'")) { $ahk | Should -Match "case\s[^`n]*`"$($m.Groups[1].Value)`"" -Because "$f.js sends $($m.Groups[1].Value)" }
        }
    }
    It 'knows the speed test and audio verbs' {
        (Get-Command Invoke-SpeedRun).Name | Should -Be 'Invoke-SpeedRun'
        (Get-Command Invoke-AudioAction).Name | Should -Be 'Invoke-AudioAction'
        { Invoke-AudioAction 'nope' } | Should -Throw '*usage*'
    }
}

Describe 'AI parity' {
    It 'knows OpenClaw as a default agent' {
        $AgentTable.Contains('openclaw') | Should -BeTrue
        (Resolve-AgentName 'openclaw') | Should -Be 'openclaw'
    }
    It 'lists the coding agents and the Store and browser groups in Install' {
        @($Catalog.key) | Should -Contain 'agents'
        @($Catalog.key) | Should -Contain 'browser'
        (Get-CatalogItem 'chatgpt').install | Should -BeOfType [scriptblock]
        (Get-CatalogItem 'claude-code').remove | Should -BeOfType [scriptblock]
    }
}

Describe 'system verbs' {
    It 'reads reminder times' {
        (ConvertTo-ReminderTime '10') | Should -BeGreaterThan (Get-Date).AddMinutes(9)
        (ConvertTo-ReminderTime '2h') | Should -BeGreaterThan (Get-Date).AddMinutes(119)
        (ConvertTo-ReminderTime '23:59').TimeOfDay.TotalMinutes | Should -Be (23 * 60 + 59)
        { ConvertTo-ReminderTime 'tomorrowish' } | Should -Throw '*can''t read*'
    }
    It 'turns an IANA zone into a Windows one' {
        ConvertTo-WindowsZoneId 'Europe/Paris' | Should -Be 'Romance Standard Time'
    }
    It 'refuses an unknown DNS provider without touching the network' {
        { Set-WinarchyDns 'nope' } | Should -Throw '*unknown DNS provider*'
    }
}
