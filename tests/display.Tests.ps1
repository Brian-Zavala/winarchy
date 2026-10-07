# Pester tests: Quattro's Display panel (text size, bar height, the panel's wiring) and the
# Tailscale widget (bar icon, panel, the install question). Nothing here touches a real
# monitor, Tailscale or the real ~/.winarchy: every setter below is stubbed.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'journal', 'catalog', 'herdr', 'apply', 'fonts', 'tailscale') { . "$root\lib\$f.ps1" }
    $Code = $root
    $Data = Join-Path $TestDrive 'data'
    $ConfigFile = Join-Path $Data 'config.json'
    $StateFile = Join-Path $Data 'state.json'
    $Generated = Join-Path $Data 'generated'
    $Pack = Join-Path $TestDrive 'pack'
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    # The journal too: the real one in ~/.winarchy/backup is what uninstall replays.
    $BackupRoot = Join-Path $TestDrive 'backup'
    $AlacrittyConfig = Join-Path $TestDrive 'alacritty.toml'
    New-Item -ItemType Directory -Force $Data, $Pack | Out-Null
    $script:JournalDir = Join-Path $TestDrive 'journal'
    New-Item -ItemType Directory -Force $script:JournalDir | Out-Null
    Write-Json (Join-Path $script:JournalDir 'journal.json') ([ordered]@{ entries = @() })
    function Write-Step {}
    function Write-Ok {}
    function Read-YesNo([string]$q, [bool]$default = $true) { if ($script:AssumeYes) { return $default }; $a = Read-Host; if (-not $a) { return $default }; $a -match '^(y|yes)$' }
    $bar = Get-Content -Raw "$root\zebar\omarchy\bar.html"
    $menuAhk = Get-Content -Raw "$root\ahk\menu.ahk"
}

Describe 'Text size (omarchy-display-text-size)' {
    BeforeEach {
        Remove-Item $ConfigFile -ErrorAction SilentlyContinue
        $wt = Join-Path $TestDrive 'wt-settings.json'
        Write-Json $wt ([ordered]@{ profiles = [ordered]@{ defaults = [ordered]@{ font = [ordered]@{ face = 'JetBrainsMono Nerd Font' } }; list = @() } })
        Mock Get-Paths { @{ wtSettings = $wt } }
        Mock Write-Status {}
        Mock Invoke-Apply {}
        Mock Update-BarHeight {}
        Mock Save-JsonProperty {}
    }
    It 'refuses sizes outside 9-20 and non-numbers' {
        { Invoke-TextSize '8' } | Should -Throw '*9 to 20*'
        { Invoke-TextSize '21' } | Should -Throw '*9 to 20*'
        { Invoke-TextSize 'big' } | Should -Throw '*9 to 20*'
    }
    It 'maps px to terminal points as Quattro does (12px = 9pt)' {
        ConvertTo-TerminalPoints 12 | Should -Be 9
        ConvertTo-TerminalPoints 16 | Should -Be 12
        ConvertTo-TerminalPoints 20 | Should -Be 15
        # Windows Terminal's own default is 12pt, so its scale starts there.
        ConvertTo-TerminalPoints 12 12 | Should -Be 12
        ConvertTo-TerminalPoints 16 12 | Should -Be 16
    }
    It 'writes the size to config, font.css and Windows Terminal' {
        Invoke-TextSize '14'
        (Get-Config).textSize | Should -Be 14
        Get-Content -Raw (Join-Path $Pack 'font.css') | Should -Match '--text-size: 14px; --text-scale: 1\.1667;'
        (Read-Json $wt).profiles.defaults.font.size | Should -Be 14
        (Read-Json $wt).profiles.defaults.font.face | Should -Be 'JetBrainsMono Nerd Font'
    }
    It 'resizes the bar only when it has to grow, and never restarts it' {
        Invoke-TextSize '10'
        Should -Invoke Update-BarHeight -Times 0 -Exactly
        Invoke-TextSize '16'
        Should -Invoke Update-BarHeight -Times 1 -Exactly
        Should -Invoke Invoke-Apply -Times 0 -Exactly
    }
    It 'resets to 12px' {
        Invoke-TextSize '16'
        Invoke-TextSize 'reset'
        (Get-Config).textSize | Should -Be 12
    }
}

Describe 'A taller bar without a restart' {
    BeforeEach {
        Mock Get-Paths { @{ glazewmCli = 'C:\g\glazewm.exe'; monitors = @(1, 2) } }
        Mock Get-Config { @{ barHeight = 26; textSize = 16 } }
        Mock Write-ZebarPack {}
        Mock Write-AhkIni {}
        Mock Write-GlazeConfig { $false }
        Mock Resize-BarWindows { 2 }
        Mock Restart-Bar {}
        Mock Stop-Zebar {}
        Mock Restart-OmarchyAhk {}
        $GlazeConfig = Join-Path $TestDrive 'glazewm.yaml'
    }
    It 'resizes the open bars and writes what the next start reads, restarting nothing' {
        Update-BarHeight
        Should -Invoke Resize-BarWindows -Times 1 -Exactly -ParameterFilter { $height -eq 35 }
        Should -Invoke Write-ZebarPack -Times 1 -Exactly
        Should -Invoke Write-AhkIni -Times 1 -Exactly
        Should -Invoke Write-GlazeConfig -Times 1 -Exactly
        Should -Invoke Restart-Bar -Times 0 -Exactly
        Should -Invoke Stop-Zebar -Times 0 -Exactly
        Should -Invoke Restart-OmarchyAhk -Times 0 -Exactly
    }
}

Describe 'Bar height follows the text size' {
    It 'keeps barHeight at 12px and below, grows it above' {
        Get-BarHeight @{ barHeight = 26; textSize = 12 } | Should -Be 26
        Get-BarHeight @{ barHeight = 26; textSize = 9 } | Should -Be 26
        Get-BarHeight @{ barHeight = 26 } | Should -Be 26
        Get-BarHeight @{ barHeight = 26; textSize = 16 } | Should -Be 35
        Get-BarHeight @{ barHeight = 26; textSize = 20 } | Should -Be 43
    }
    It 'defaults textSize to 12' {
        (Read-Json "$root\default\config.json").textSize | Should -Be 12
    }
}

Describe 'Zebar pack' {
    It 'has the Display, Tailscale and Power panels, one preset per monitor position' {
        $cfg = @{ barHeight = 26 }
        $z = Get-ZpackJson @{ ahk = 'C:\ahk.exe' } | ConvertFrom-Json
        foreach ($w in @(@{ name = 'display'; p = 'd' }, @{ name = 'tailscale'; p = 't' }, @{ name = 'power'; p = 'p' })) {
            $widget = $z.widgets | Where-Object name -EQ $w.name
            $widget | Should -Not -BeNullOrEmpty
            $widget.htmlPath | Should -Be "./$($w.name).html"
            @($widget.presets).Count | Should -Be 8
            $widget.presets[3].name | Should -Be "$($w.p)3"
            $widget.includeFiles | Should -Contain '*.json'
            Test-Path "$root\zebar\omarchy\$($w.name).html" | Should -BeTrue
            Test-Path "$root\zebar\omarchy\$($w.name).js" | Should -BeTrue
        }
    }
    It 'keeps every panel loaded between opens (panel.js), with the files it reads' {
        $cfg = @{ barHeight = 26 }
        $z = Get-ZpackJson @{ ahk = 'C:\ahk.exe' } | ConvertFrom-Json
        $panels = [ordered]@{ audio = 'a'; bluetooth = 'b'; network = 'n'; display = 'd'; tailscale = 't'; power = 'p'; usage = 'u'; calendar = 'c'; worldclock = 'w' }
        foreach ($name in $panels.Keys) {
            $widget = $z.widgets | Where-Object name -EQ $name
            @($widget.presets).Count | Should -Be 8 -Because $name
            $widget.presets[2].name | Should -Be "$($panels[$name])2"
            # panel.js and style.js; style.js reads status.json for a theme change while hidden.
            $widget.includeFiles | Should -Contain '*.js' -Because $name
            $widget.includeFiles | Should -Contain '*.json' -Because $name
            $js = Get-Content -Raw "$root\zebar\omarchy\$name.js"
            $js | Should -Match "from '\./panel\.js'" -Because "$name hides instead of closing"
            $js | Should -Not -Match 'tauri\.close\(' -Because "$name hides instead of closing"
            $menuAhk | Should -Match "OpenPanel\(`"$name`", `"$($panels[$name])`"" -Because "menu.ahk shows a hidden $name"
        }
    }
    # Zebar closes and rebuilds every widget on a monitor change (a game switching display
    # mode): a rebuilt menu or panel that took focus knocked the game out, round and round.
    It 'never lets a widget take focus as Zebar creates it' {
        $cfg = @{ barHeight = 26 }
        $z = Get-ZpackJson @{ ahk = 'C:\ahk.exe' } | ConvertFrom-Json
        foreach ($w in $z.widgets) { $w.focused | Should -BeFalse -Because $w.name }
    }
    It 'opens a menu or panel only when winarchy just asked for it' {
        $widgets = Get-Content -Raw "$root\ahk\lib\widgets.ahk"
        $widgets | Should -Match '(?s)OpenMenuWarm\(.*MarkOpenRequest\("menu"\).*ShowHiddenWidget'
        $widgets | Should -Match '-open\.json'
        $menuAhk | Should -Match '(?s)OpenPanel\(name.*MarkOpenRequest\(name\).*ShowHiddenWidget'
        $menuJs = Get-Content -Raw "$root\zebar\omarchy\menu.js"
        $menuJs | Should -Match "get\('menu-open\.json'\)"
        $menuJs | Should -Match '(?m)^if \(await asked\(\)\) await open\(\);'
        $panelJs = Get-Content -Raw "$root\zebar\omarchy\panel.js"
        $panelJs | Should -Match 'getJson\(`\$\{name\}-open\.json`\)'
        $panelJs | Should -Match 'asked\(\)\.then\(ok => \(ok \? start\(false\) : quit\(\)\)\)'
    }
}

Describe 'Bar icons' {
    It 'puts Tailscale and Display with the system icons, outside the drawer' {
        $drawerEnd = $bar.IndexOf('</div>', $bar.IndexOf('id="drawer"'))
        $order = 'agents', 'bluetooth', 'tailscale', 'network', 'audio', 'display', 'cpu', 'battery' |
            ForEach-Object { $bar.IndexOf("id=`"$_`"") }
        foreach ($i in $order) { $i | Should -BeGreaterThan $drawerEnd }
        ($order | Sort-Object) -join ',' | Should -Be ($order -join ',')
    }
    It 'hides the Tailscale icon until Tailscale is installed' {
        $bar | Should -Match '<span class="module hidden" id="tailscale">'
        $bar | Should -Match "classList\.toggle\('hidden', !ts\?\.installed\)"
    }
    It 'sends the icons to menu.ahk verbs that exist and do not wait for the menu' {
        foreach ($verb in 'display-panel', 'brightness-step', 'tailscale-panel', 'tailscale', 'power-panel', 'battery-percentage') {
            $bar | Should -Match "act\('$verb'"
            $menuAhk | Should -Match "(?m)^\s+case `"$verb`":"
        }
        foreach ($verb in 'display-panel', 'display-state', 'brightness', 'scale', 'monitor', 'text-size', 'tailscale', 'power-panel', 'power-state', 'battery-percentage', 'copy') {
            $menuAhk | Should -Match "\|$verb[|)]"
        }
        # The Power panel sets the power mode quietly; the Power menu's rows still show the OSD.
        $menuAhk | Should -Match 'case "power-mode": SetPowerMode\(arg, [^\n]*"panel"\)'
        # The menu's own Trigger > Hardware "display" verb (laptop / mirror) is unchanged.
        $menuAhk | Should -Match '(?m)^\s+case "display": ToggleDisplay\(arg\)'
    }
}

Describe 'Tailscale install question' {
    BeforeEach {
        Remove-Item $ConfigFile -ErrorAction SilentlyContinue
        $script:AssumeYes = $false
        Mock Test-TailscaleInstalled { $false }
        Mock Install-CatalogItem {}
    }
    It 'is not installed by an unattended install' {
        $script:AssumeYes = $true
        Mock Read-Host { throw 'asked' }
        Install-TailscaleStep
        Should -Invoke Install-CatalogItem -Times 0 -Exactly
    }
    It 'defaults to No' {
        Mock Read-Host { '' }
        Install-TailscaleStep
        Should -Invoke Install-CatalogItem -Times 0 -Exactly
        $script:TailscaleOffered | Should -BeTrue
    }
    It 'writes no config.json of its own, so a stopped install is not taken for a restore' {
        Mock Read-Host { '' }
        Install-TailscaleStep
        Test-Path $ConfigFile | Should -BeFalse
    }
    It 'installs through the catalog (journaled as yours) on yes' {
        Mock Read-Host { 'y' }
        Install-TailscaleStep
        Should -Invoke Install-CatalogItem -Times 1 -Exactly -ParameterFilter { $key -eq 'tailscale' }
    }
    It 'does not ask again when restoring settings that already answered it' {
        Write-Json $ConfigFile @{ tailscaleOffered = $true }
        Mock Read-Host { throw 'asked' }
        Install-TailscaleStep -Restoring
        Should -Invoke Install-CatalogItem -Times 0 -Exactly
    }
    It 'says nothing more when it is already there' {
        Mock Test-TailscaleInstalled { $true }
        Mock Read-Host { throw 'asked' }
        Install-TailscaleStep
        Should -Invoke Install-CatalogItem -Times 0 -Exactly
    }
    It 'stays in Install > Service, and starts its sign-in after installing' {
        $item = Get-CatalogItem 'tailscale'
        $item.id | Should -Be 'Tailscale.Tailscale'
        $item.postInstall | Should -BeOfType [scriptblock]
        ($Catalog | Where-Object key -EQ 'service').items.key | Should -Contain 'tailscale'
    }
    It 'is asked by the installer right after Herdr' {
        Get-Content -Raw "$root\lib\setup.ps1" | Should -Match 'Install-HerdrStep\r?\n\s+Install-TailscaleStep -Restoring:\$restoring'
    }
}
