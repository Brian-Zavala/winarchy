# Pester tests for the machine-independent logic: run with  Invoke-Pester ./tests
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'targets', 'journal', 'apply', 'herdr') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
}

Describe 'Workspace split' {
    It 'puts all 10 on one monitor' {
        $l = Get-WorkspaceLayout 1 'auto'
        $l.Count | Should -Be 10
        ($l | Where-Object monitor -ne 0).Count | Should -Be 0
    }
    It 'splits 5/5 on two monitors' {
        (Get-WorkspaceLayout 2 'auto' | Group-Object monitor | ForEach-Object Count) -join ',' | Should -Be '5,5'
    }
    It 'splits 4/3/3 on three monitors' {
        (Get-WorkspaceLayout 3 'auto' | Group-Object monitor | ForEach-Object Count) -join ',' | Should -Be '4,3,3'
    }
    It 'follows an explicit map and clamps to real monitors' {
        $l = Get-WorkspaceLayout 1 @{ '1' = @('1', '2'); '2' = @('3') }
        ($l | ForEach-Object { "$($_.name)@$($_.monitor)" }) -join ' ' | Should -Be '1@0 2@0 3@0'
    }
    It 'renders workspace 10 as 0' {
        ConvertTo-WorkspacesYaml (Get-WorkspaceLayout 1 'auto') | Should -Match "name: '10'\s+display_name: '0'"
    }
}

Describe 'Workspace monitors' {
    BeforeAll {
        $yaml = "general:`n  x: 1`n`nworkspaces:`n" + (ConvertTo-WorkspacesYaml (Get-WorkspaceLayout 2 'auto')) +
            "`n  - name: 'scratch'`n    display_name: 'S'`n`nwindow_rules:`n  - name: 'not-a-workspace'`n    bind_to_monitor: 7`n"
        function Mon($x, $w, [string[]]$names, [switch]$focus) {
            [pscustomobject]@{ x = $x; y = 0; width = $w; height = 1440; hasFocus = [bool]$focus
                children = @($names | ForEach-Object { [pscustomobject]@{ name = $_; isDisplayed = $false } }) }
        }
    }
    It 'reads the bindings from the workspaces section only' {
        $b = @(Get-WorkspaceBindings $yaml)
        ($b | ForEach-Object { "$($_.name)@$($_.monitor)" }) -join ' ' | Should -Be '1@0 2@0 3@0 4@0 5@0 6@1 7@1 8@1 9@1 10@1'
        @($b | Where-Object keepAlive).Count | Should -Be 10
        Get-BoundMonitorCount $yaml | Should -Be 2
        Get-BoundMonitorCount '' | Should -Be 0
    }
    It 'keeps the split while a monitor sleeps, unless asked to re-split' {
        Get-LayoutMonitorCount 1 2 | Should -Be 2
        Get-LayoutMonitorCount 3 2 | Should -Be 3
        Get-LayoutMonitorCount 1 2 -Resplit | Should -Be 1
        Get-LayoutMonitorCount 0 0 | Should -Be 1
    }
    It 'finds workspaces stranded after a monitor woke up' {
        # 2026-09-25: 6, 9 and 10 stayed on monitor 0 and 8 was not open yet.
        $live = @((Mon 0 3840 '1', '2', '3', '4', '5', '6', '9', '10' -focus), (Mon 3840 2560 '7'))
        $off = @(Get-MisplacedWorkspaces $live (Get-WorkspaceBindings $yaml))
        ($off | ForEach-Object { "$($_.name):$($_.from)>$($_.to)" }) -join ' ' | Should -Be '6:0>1 8:>1 9:0>1 10:0>1'
    }
    It 'leaves workspaces of a sleeping monitor where GlazeWM parked them' {
        $live = @(Mon 0 3840 (1..10 | ForEach-Object { "$_" }))
        @(Get-MisplacedWorkspaces $live (Get-WorkspaceBindings $yaml)).Count | Should -Be 0
    }
    It 'points move-workspace at the target monitor' {
        Get-MonitorDirection (Mon 0 3840 @()) (Mon 3840 2560 @()) | Should -Be 'right'
        Get-MonitorDirection (Mon 3840 2560 @()) (Mon 0 3840 @()) | Should -Be 'left'
        Get-MonitorDirection ([pscustomobject]@{ x = 0; y = 0; width = 100; height = 100 }) ([pscustomobject]@{ x = 0; y = 100; width = 100; height = 100 }) | Should -Be 'down'
    }
}

Describe 'Templates' {
    BeforeAll { $c = @{ background = '#1a1b26'; foreground = '#a9b1d6'; accent = '#7aa2f7'; mode = 'dark'; theme_type = 'dark' } }
    It 'fills plain, _strip and _rgb placeholders' {
        Expand-Template '{{ accent }}|{{ accent_strip }}|{{ accent_rgb }}' $c | Should -Be '#7aa2f7|7aa2f7|122,162,247'
    }
    It 'mixes colors with a percentage or a fraction' {
        Expand-Template '{{ mix background foreground 6% }}' $c | Should -Be '#232431'
        Expand-Template '{{ mix_rgb accent foreground 0.35 }}' $c | Should -Be '138,167,235'
        Expand-Template '{{ mix_strip accent foreground 35 }}' $c | Should -Be '8aa7eb'
    }
    It 'leaves unknown placeholders alone' {
        Expand-Template '{{ nope }}' $c | Should -Be '{{ nope }}'
    }
    It 'Mix ends at both colors' {
        Mix '#000000' '#ffffff' 0 | Should -Be '#000000'
        Mix '#000000' '#ffffff' 1 | Should -Be '#ffffff'
    }
}

Describe 'Flow hotkey conversion' {
    It 'converts <flow> to <ahk>' -TestCases @(
        @{ flow = 'Alt + Space'; ahk = '!{Space}' }
        @{ flow = 'Ctrl + Shift + K'; ahk = '^+k' }
        @{ flow = 'Win + Alt + F1'; ahk = '#!{F1}' }
        @{ flow = $null; ahk = '!{Space}' }
    ) { ConvertTo-AhkHotkey $flow | Should -Be $ahk }
}

Describe 'JSONC edits (VS Code settings keep their comments)' {
    It 'replaces an existing value' {
        $f = Join-Path $TestDrive 'a.json'
        Set-Content $f "{`n  // comment`n  `"workbench.colorTheme`": `"Old`",`n  `"x`": 1`n}"
        Set-JsoncString $f 'workbench.colorTheme' 'New "One"'
        $t = Get-Content -Raw $f
        $t | Should -Match '// comment'
        Get-JsoncString $f 'workbench.colorTheme' | Should -Be 'New "One"'
    }
    It 'adds a missing key' {
        $f = Join-Path $TestDrive 'b.json'
        Set-Content $f "{`n  `"x`": 1`n}"
        Set-JsoncString $f 'workbench.colorTheme' 'Omarchy'
        Get-JsoncString $f 'workbench.colorTheme' | Should -Be 'Omarchy'
        (Get-Content -Raw $f | ConvertFrom-Json).x | Should -Be 1
    }
}

Describe 'Theme colour fallbacks' {
    It 'resolves a theme with only the basic colours exactly as Omarchy''s omarchy-theme-color does' {
        # omarchy-theme-color.tsv: `omarchy-theme-color --file colors.toml --all` from Omarchy (quattro).
        $Themes = Join-Path $root 'tests\fixtures'
        $c = Read-Colors 'theme-min'
        foreach ($line in Get-Content (Join-Path $Themes 'theme-min\omarchy-theme-color.tsv')) {
            $k, $v = $line -split "`t", 2
            "$k=$($c[$k])" | Should -Be "$k=$v"
        }
    }
    It 'reads single-quoted values and the legacy theme_type' {
        $Themes = Join-Path $TestDrive 'themes'
        New-Item -ItemType Directory -Force "$Themes\t" | Out-Null
        Set-Content "$Themes\t\colors.toml" "theme_type = 'light'`nbackground = '#fafafa'`nforeground = `"#111111`" # ink"
        $c = Read-Colors 't'
        $c.mode | Should -Be 'light'
        $c.foreground | Should -Be '#111111'
        $c.red | Should -BeNullOrEmpty
    }
    It 'takes GlazeWM''s focused border from Hyprland''s active border when the theme has one' {
        $Themes = Join-Path $TestDrive 'themes'
        New-Item -ItemType Directory -Force "$Themes\b" | Out-Null
        Set-Content "$Themes\b\colors.toml" "accent = `"#7aa2f7`"`nhyprland_active_border = `"rgba(26A269ee) rgba(2ec27eee) 45deg`""
        (Read-Colors 'b').focused_border | Should -Be '#26a269'
    }
}

Describe 'Backup journal' {
    BeforeEach {
        $script:JournalDir = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory $script:JournalDir | Out-Null
        Set-Content (Join-Path $script:JournalDir 'journal.json') '{"entries":[]}'
        $script:JournalCache = $null
    }
    It 'records the first original only' {
        $f = Join-Path $TestDrive 'settings.json'
        Set-Content $f '{"a":1}'
        Save-File $f
        Set-Content $f '{"a":2}'
        Save-File $f
        (Read-Journal).entries.Count | Should -Be 1
    }
    It 'restores a JSON property and removes one that did not exist' {
        $f = Join-Path $TestDrive 'wt.json'
        Set-Content $f '{"profiles":{"defaults":{"padding":"8"}}}'
        Save-JsonProperty $f 'profiles.defaults.padding'
        Save-JsonProperty $f 'profiles.defaults.colorScheme'
        Set-Content $f '{"profiles":{"defaults":{"padding":"14","colorScheme":"Omarchy"}}}'
        foreach ($e in (Read-Journal).entries) { Restore-JournalEntry $e $script:JournalDir }
        $o = Get-Content -Raw $f | ConvertFrom-Json
        $o.profiles.defaults.padding | Should -Be '8'
        $o.profiles.defaults.PSObject.Properties.Name | Should -Not -Contain 'colorScheme'
    }
    It 'restores a file that did not exist by deleting it' {
        $f = Join-Path $TestDrive 'new.txt'
        Save-File $f
        Set-Content $f 'x'
        foreach ($e in (Read-Journal).entries) { Restore-JournalEntry $e $script:JournalDir }
        Test-Path $f | Should -BeFalse
    }
}

Describe 'Uninstall keeps what changed since install' {
    BeforeEach {
        $script:JournalDir = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory $script:JournalDir | Out-Null
        Set-Content (Join-Path $script:JournalDir 'journal.json') '{"entries":[]}'
        $script:JournalCache = $null
        $script:home_ = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory $script:home_ | Out-Null
        function Undo { foreach ($e in (Read-Journal).entries) { Restore-JournalEntry $e $script:JournalDir } }
        Mock Log {}
    }
    It 'takes only the Herdr block out of the PowerShell profile' {
        $f = Join-Path $script:home_ 'profile.ps1'
        Set-Content $f 'Set-Alias ll ls'
        Save-File $f
        [void](Set-HerdrProfile $f)
        Add-Content $f 'Set-Alias later gci'
        Undo
        $t = Get-Content -Raw $f
        $t | Should -Match 'Set-Alias ll ls'
        $t | Should -Match 'Set-Alias later gci'
        $t | Should -Not -Match ([regex]::Escape($HerdrProfileBegin))
    }
    It 'deletes a profile that only ever held the Herdr block' {
        $f = Join-Path $script:home_ 'profile.ps1'
        Save-File $f
        [void](Set-HerdrProfile $f)
        Undo
        Test-Path $f | Should -BeFalse
    }
    It 'takes only the Omarchy theme out of VS Code extensions.json' {
        $f = Join-Path $script:home_ '.vscode\extensions\extensions.json'
        New-Item -ItemType Directory (Split-Path $f) | Out-Null
        Set-Content $f '[]'
        Save-File $f
        Set-Content $f '[{"identifier":{"id":"local.omarchy-theme"}},{"identifier":{"id":"later.ext"}}]'
        Undo
        $ids = @((Get-Content -Raw $f | ConvertFrom-Json) | ForEach-Object { $_.identifier.id })
        $ids | Should -Be @('later.ext')
    }
    It 'puts back only the Flow Launcher settings winarchy set' {
        $f = Join-Path $script:home_ 'FlowLauncher\Settings\Settings.json'
        New-Item -ItemType Directory (Split-Path $f) | Out-Null
        Set-Content $f '{"Theme":"Win11Light","Hotkey":"Alt + Space"}'
        Save-File $f
        Set-Content $f '{"Theme":"Omarchy","UseSound":false,"Hotkey":"Ctrl + Space"}'
        Undo
        $s = Get-Content -Raw $f | ConvertFrom-Json
        $s.Theme | Should -Be 'Win11Light'
        $s.Hotkey | Should -Be 'Ctrl + Space'
        $s.PSObject.Properties.Name | Should -Not -Contain 'UseSound'
    }
    It 'puts back only the btop theme lines' {
        $f = Join-Path $script:home_ 'btop.conf'
        Set-Content $f "color_theme = `"Default`"`ntheme_background = True`nupdate_ms = 2000"
        Save-File $f
        Set-Content $f "color_theme = `"omarchy`"`ntheme_background = False`nupdate_ms = 500"
        Undo
        $t = Get-Content -Raw $f
        $t | Should -Match 'color_theme = "Default"'
        $t | Should -Match 'theme_background = True'
        $t | Should -Match 'update_ms = 500'
    }
    It 'takes out only the Run values of apps winarchy set up' {
        $vals = @{ Steam = 'steam.exe'; Discord = 'C:\Discord\Update.exe'; 'Flow.Launcher' = 'C:\Users\x\AppData\Local\FlowLauncher\Flow.Launcher.exe' }
        Mock Get-ItemProperty { [pscustomobject]$vals } -ParameterFilter { $Path -like '*CurrentVersion\Run' }
        Mock Remove-ItemProperty {}
        Mock Write-Host {}
        Restore-JournalEntry @{ kind = 'runkeys'; names = @('Steam') } $script:JournalDir
        Should -Invoke Remove-ItemProperty -Times 1 -Exactly
        Should -Invoke Remove-ItemProperty -ParameterFilter { $Name -eq 'Flow.Launcher' } -Times 1
    }
}

Describe 'Minimize animation (blockMinimize)' {
    BeforeEach {
        $script:JournalDir = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory $script:JournalDir | Out-Null
        Set-Content (Join-Path $script:JournalDir 'journal.json') '{"entries":[]}'
        $script:JournalCache = $null
        $script:anim = 1
        Mock Get-MinimizeAnimation { $script:anim }
        Mock Set-MinimizeAnimation { $script:anim = $on }
        Mock Log {}
    }
    It 'turns it off, and uninstall puts the original back' {
        Set-MinimizeAnimationPolicy @{ blockMinimize = $true }
        $script:anim | Should -Be 0
        foreach ($e in (Read-Journal).entries) { Restore-JournalEntry $e $script:JournalDir }
        $script:anim | Should -Be 1
    }
    It 'puts the original back when blockMinimize is turned off' {
        Set-MinimizeAnimationPolicy @{ blockMinimize = $true }
        Set-MinimizeAnimationPolicy @{ blockMinimize = $false }
        $script:anim | Should -Be 1
    }
    It 'leaves an animation that was already off alone, and records nothing' {
        $script:anim = 0
        Set-MinimizeAnimationPolicy @{ blockMinimize = $true }
        Set-MinimizeAnimationPolicy @{ blockMinimize = $false }
        $script:anim | Should -Be 0
        (Read-Journal).entries.Count | Should -Be 0
    }
}

Describe 'Bar restart' {
    # Zebar attaches to its parent's console: from `winarchy update` it would log into
    # that terminal and die with it. It must be started through (console-less) AutoHotkey.
    BeforeAll {
        Mock Get-Process {}
        Mock Start-Sleep {}
        Mock Start-Process {}
        Mock Start-Hidden {}
    }
    It 'starts Zebar through AutoHotkey, not from this console' {
        Restart-Bar @{ zebar = 'C:\z\zebar.exe'; ahk = 'C:\a\AutoHotkey64.exe' }
        Should -Invoke Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'C:\a\AutoHotkey64.exe' -and $ArgumentList -contains 'bar-start' }
        Should -Invoke Start-Hidden -Times 0
    }
    It 'falls back to a direct start without AutoHotkey' {
        Restart-Bar @{ zebar = 'C:\z\zebar.exe' }
        Should -Invoke Start-Hidden -Times 1
    }
}

Describe 'Theme palette' {
    # theme.css (bar + menu) and index.json (the theme picker's live preview) must use the
    # same color names, or a previewed theme would morph only halfway.
    BeforeAll { Mock Log {} }
    BeforeEach {
        $Themes = Join-Path $TestDrive ([guid]::NewGuid())
        $Pack = Join-Path $TestDrive ([guid]::NewGuid())
        $Thumbs = Join-Path $Pack 'thumbs'
        $Walls = Join-Path $TestDrive 'no-walls'
        # 8-digit hex and missing keys, like some Omarchy themes.
        New-Item -ItemType Directory -Force "$Themes\test-theme" | Out-Null
        Set-Content "$Themes\test-theme\colors.toml" "background = `"#101010ff`"`nforeground = `"#e0e0e0`"`naccent = `"#ff8800`"`nhyprland_active_border = `"rgba(26a269ee)`""
        Set-Content "$Themes\test-theme\preview.png" 'png'
    }
    It 'writes every palette color into theme.css as #rrggbb' {
        $palette = Get-BarPalette (Read-Colors 'test-theme')
        $palette.Values | ForEach-Object { $_ | Should -Match '^#[0-9a-fA-F]{6}$' }
        $palette['bg'] | Should -Be '#101010'
        $palette['bg-light'] | Should -Not -BeNullOrEmpty
        Set-BarTheme (Read-Colors 'test-theme')
        $written = [regex]::Matches((Get-Content -Raw "$Pack\theme.css"), '--([\w-]+):') | ForEach-Object { $_.Groups[1].Value }
        $written | Should -Be @($palette.Keys)
    }
    It 'only animates colors that theme.css defines' {
        $keys = @((Get-BarPalette (Read-Colors 'test-theme')).Keys)
        foreach ($css in 'menu.css', 'bar.css') {
            $registered = [regex]::Matches((Get-Content -Raw "$Code\zebar\omarchy\$css"), '@property --([\w-]+)') | ForEach-Object { $_.Groups[1].Value }
            $registered | Should -Not -BeNullOrEmpty
            $registered | ForEach-Object { $keys | Should -Contain $_ }
        }
    }
    It 'indexes each theme with its palette and a 960px preview' {
        Mock New-Thumb {}
        Mock Write-Status {}
        Mock Get-BackgroundDirs { @() }
        Update-Index
        $t = (Get-Content -Raw "$Pack\index.json" | ConvertFrom-Json).themes[0]
        $t.palette.accent | Should -Be '#ff8800'
        $t.thumb | Should -Be 'thumbs/_themes-960/test-theme.jpg'
        Should -Invoke New-Thumb -Times 1 -ParameterFilter { $Width -eq 960 }
    }
}

Describe 'Background landing' {
    BeforeAll { . "$Code\lib\transition.ps1" }
    It 'finds the monitor the picker covers, left of the primary too' {
        Test-OnMonitor @(1920, 1080) @(0, 0, 3840, 2160) | Should -BeTrue
        Test-OnMonitor @(-960, 540) @(-1920, 0, 1920, 1080) | Should -BeTrue
        Test-OnMonitor @(3840, 10) @(0, 0, 3840, 2160) | Should -BeFalse
        Test-OnMonitor $null @(0, 0, 3840, 2160) | Should -BeFalse
    }
    It 'names the new background in status.json only once the desktop has it' {
        $Pack = Join-Path $TestDrive ([guid]::NewGuid())
        $wall = Join-Path $TestDrive 'wall.jpg'
        Set-Content $wall 'jpg'
        Mock Save-Wallpaper {}; Mock Save-LockScreen {}; Mock Save-State {}; Mock Start-Hidden {}; Mock Log {}
        Mock Get-Paths { @{ powershell = 'powershell.exe' } }
        Mock Set-DesktopWallpaper {
            $script:seen = (Read-Json (Join-Path $Pack 'status.json'))?.background; $script:cov = $covered
            & $after                                   # the wallpaper is set (reveal still playing)
            $script:set = (Read-Json (Join-Path $Pack 'status.json'))?.background
        }
        Set-Background $wall @{ theme = 't'; background = 'old'; perTheme = @{} } @(10, 20)
        $script:seen | Should -Not -Be $wall
        $script:set | Should -Be $wall
        $script:cov | Should -Be @(10, 20)
        (Read-Json (Join-Path $Pack 'status.json')).background | Should -Be $wall
    }
    It 'plays the same band as the desktop reveal' {
        $js = Get-Content -Raw "$Code\zebar\omarchy\menu.js"
        $ps = Get-Content -Raw "$Code\lib\transition.ps1"
        [regex]::Match($js, 'const LAND_MS = (\d+)').Groups[1].Value | Should -Be ([regex]::Match($ps, '\$ms / (\d+)\.0').Groups[1].Value)
        $js | Should -Match '0\.09 \* h'                  # half of Omarchy's 0.18 slant
        $ps | Should -Match '0\.18 \* \$h / 2'
    }
}
Describe 'Browser color task' {
    BeforeEach {
        $script:BrowserTaskInfo = $null
        # Task Scheduler COM stand-in: only the folders listed have the task.
        function New-FakeScheduler([string[]]$has) {
            $svc = [pscustomobject]@{ has = $has }
            $svc | Add-Member ScriptMethod Connect {}
            $svc | Add-Member ScriptMethod GetFolder {
                param($p)
                $f = [pscustomobject]@{ p = $p; ok = $this.has -contains $p }
                $f | Add-Member ScriptMethod GetTask { param($n) if (-not $this.ok) { throw 'not found' }; [pscustomobject]@{ Path = "$($this.p)\$n" } }
                $f
            }
            $svc
        }
    }
    It 'finds the task set up under the old name, and its folder' {
        Mock New-Object { New-FakeScheduler '\omarchy-win' } -ParameterFilter { $ComObject -eq 'Schedule.Service' }
        $t = Get-BrowserTask
        $t.path | Should -Be '\omarchy-win\'
        $t.dir | Should -Be (Join-Path $env:ProgramData 'omarchy-win')
        $t.task.Path | Should -Be '\omarchy-win\browser-color'
        Test-BrowserTask | Should -BeTrue
    }
    It 'prefers the winarchy task and asks the scheduler only once' {
        Mock New-Object { New-FakeScheduler '\winarchy', '\omarchy-win' } -ParameterFilter { $ComObject -eq 'Schedule.Service' }
        (Get-BrowserTask).path | Should -Be '\winarchy\'
        [void](Get-BrowserTask)
        Should -Invoke New-Object -Times 1 -Exactly
    }
    It 'reports no task, with the default folder for browser-setup' {
        Mock New-Object { New-FakeScheduler @() } -ParameterFilter { $ComObject -eq 'Schedule.Service' }
        Test-BrowserTask | Should -BeFalse
        (Get-BrowserTask).dir | Should -Be (Join-Path $env:ProgramData 'winarchy')
    }
}

Describe 'AutoHotkey settings ini' {
    BeforeAll {
        function BaseCfg($over) {
            Merge-Hashtable @{
                apps = @{ editor = 'notepad.exe'; terminal = 'auto'; browser = 'auto'; files = 'explorer.exe' }
                takeOverWinSpace = $true; launchers = $true; hideTaskbar = $true; gap = 10; barHeight = 26
                syncAtLogin = $true; screensaver = @{ enabled = $false; idleSeconds = 150 }; weather = $true
                gameMode = $true; games = @(); gameDirs = @(); blockMinimize = $true; minimizeAllowed = @()
            } $over
        }
        function IniText { Get-Content -Raw (Join-Path $Generated 'winarchy.ini') }
    }
    It 'writes gameDirs, blockMinimize and minimizeAllowed' {
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
        Write-AhkIni @{} (BaseCfg @{ games = @('Foo', 'Bar.exe'); gameDirs = @('C:\Games', '', 'G:\'); minimizeAllowed = @('Spotify') })
        IniText | Should -Match 'games=Foo\|Bar'
        IniText | Should -Match 'gameDirs=C:\\Games\|G:\\'
        IniText | Should -Match 'blockMinimize=1'
        IniText | Should -Match 'minimizeAllowed=Spotify'
    }
    It 'defaults gameFocusGuard on, and turns it off' {
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
        Write-AhkIni @{} (BaseCfg @{})
        IniText | Should -Match 'gameFocusGuard=1'
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
        Write-AhkIni @{} (BaseCfg @{ gameFocusGuard = $false })
        IniText | Should -Match 'gameFocusGuard=0'
    }
    It 'turns blockMinimize off' {
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
        Write-AhkIni @{} (BaseCfg @{ blockMinimize = $false })
        IniText | Should -Match 'blockMinimize=0'
    }
    It 'defaults openOnHoveredMonitor on, and turns it off' {
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
        Write-AhkIni @{} (BaseCfg @{})
        IniText | Should -Match 'openOnHoveredMonitor=1'
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
        Write-AhkIni @{} (BaseCfg @{ openOnHoveredMonitor = $false })
        IniText | Should -Match 'openOnHoveredMonitor=0'
    }
    It 'takes the private-window switch from apps.browser when it overrides the default' {
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
        Write-AhkIni @{ browser = 'C:\c\chrome.exe'; browserPrivate = '--incognito' } (BaseCfg @{ apps = @{ browser = 'C:\ff\firefox.exe' } })
        IniText | Should -Match 'browser=C:\\ff\\firefox\.exe'
        IniText | Should -Match 'browserPrivate=-private-window'
        $Generated = Join-Path $TestDrive ([guid]::NewGuid())
        Write-AhkIni @{ browser = 'C:\e\msedge.exe'; browserPrivate = '--inprivate' } (BaseCfg @{})
        IniText | Should -Match 'browserPrivate=--inprivate'
    }
}

Describe 'User paths' {
    BeforeAll { $script:realProfile = $env:USERPROFILE }
    AfterEach { $env:USERPROFILE = $script:realProfile }
    It 'finds ~\Pictures where Windows keeps it (OneDrive moves it)' {
        $env:USERPROFILE = Join-Path $TestDrive 'profile-empty'
        Mock Get-KnownUserFolder { 'D:\OneDrive\Pictures' } -ParameterFilter { $name -eq 'Pictures' }
        Expand-UserPath '~\Pictures\Wallpapers' | Should -Be 'D:\OneDrive\Pictures\Wallpapers'
    }
    It 'asks Windows for the real folder' {
        $env:USERPROFILE = $script:realProfile
        Get-KnownUserFolder 'Pictures' | Should -Be ([Environment]::GetFolderPath('MyPictures'))
    }
    It 'keeps a literal folder that exists' {
        $env:USERPROFILE = Join-Path $TestDrive 'profile-full'
        New-Item -ItemType Directory -Force "$env:USERPROFILE\Pictures\Wallpapers" | Out-Null
        Expand-UserPath '~\Pictures\Wallpapers' | Should -Be "$env:USERPROFILE\Pictures\Wallpapers"
    }
    It 'leaves other ~ paths alone' {
        $env:USERPROFILE = Join-Path $TestDrive 'profile-empty'
        Expand-UserPath '~\Art' | Should -Be "$env:USERPROFILE\Art"
    }
}

Describe 'Omarchy apps'' theme file' {
    BeforeAll { $script:realProfile = $env:USERPROFILE; $script:realXdg = $env:XDG_STATE_HOME }
    AfterEach { $env:USERPROFILE = $script:realProfile; $env:XDG_STATE_HOME = $script:realXdg }
    It 'puts the theme''s colors.toml where Omawrite, Omacalc, Omacut and Hype read it, journalled' {
        $env:USERPROFILE = Join-Path $TestDrive 'profile'
        $env:XDG_STATE_HOME = Join-Path $TestDrive 'xdg'
        $Themes = Join-Path $TestDrive 'themes'
        New-Item -ItemType Directory -Force (Join-Path $Themes 'nord') | Out-Null
        Set-Content (Join-Path $Themes 'nord\colors.toml') 'accent = "#88c0d0"'
        Mock Save-File {}
        Set-OmarchyStateTheme 'nord'
        Get-Content -Raw "$env:USERPROFILE\.local\state\omarchy\current\theme\colors.toml" | Should -Match '88c0d0'
        Get-Content -Raw "$env:XDG_STATE_HOME\omarchy\current\theme\colors.toml" | Should -Match '88c0d0'
        Should -Invoke Save-File -Times 2
    }
    It 'writes nothing for a theme without colors' {
        $env:USERPROFILE = Join-Path $TestDrive 'profile2'
        $Themes = Join-Path $TestDrive 'nothemes'
        Set-OmarchyStateTheme 'missing'
        Test-Path "$env:USERPROFILE\.local" | Should -BeFalse
    }
}

Describe 'OneDrive placeholders' {
    It 'leaves out pictures that are only in the cloud, and counts them' {
        $d = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Force $d | Out-Null
        Set-Content (Join-Path $d 'here.jpg') 'x'; Set-Content (Join-Path $d 'cloud.jpg') 'x'; Set-Content (Join-Path $d 'notes.txt') 'x'
        $cloud = Get-Item (Join-Path $d 'cloud.jpg')
        $cloud.Attributes = $cloud.Attributes -bor [IO.FileAttributes]::Offline
        $script:CloudSkipped = @{}
        try { @(Get-LocalImages $d).Name | Should -Be @('here.jpg') } finally { $skipped = $script:CloudSkipped; $script:CloudSkipped = $null }
        $skipped[$d] | Should -Be 1
    }
}

Describe 'Bundled theme' {
    It 'ships a complete Omarchy colors.toml' {
        $c = Get-Content -Raw (Join-Path $root 'default\themes\tokyo-night\colors.toml')
        foreach ($k in 'mode', 'accent', 'background', 'foreground', 'red', 'bright_magenta', 'selection') { $c | Should -Match "(?m)^$k = " }
    }
    It 'fills an empty themes folder, and never replaces a downloaded copy' {
        $Themes = Join-Path $TestDrive ([guid]::NewGuid())
        Mock Log {}
        Add-BundledThemes
        Test-Path (Join-Path $Themes 'tokyo-night\colors.toml') | Should -BeTrue
        Set-Content (Join-Path $Themes 'tokyo-night\colors.toml') 'downloaded'
        Add-BundledThemes
        Get-Content (Join-Path $Themes 'tokyo-night\colors.toml') | Should -Be 'downloaded'
    }
}

Describe 'Zebar client download' {
    It 'saves the esm.sh bundle as it is' {
        $d = Join-Path $TestDrive ([guid]::NewGuid()); New-Item -ItemType Directory $d | Out-Null
        Save-ZebarClient '3.0.3' $d { param($u) 'export{a as createProvider};' }
        Get-Content -Raw "$d\zebar.mjs" | Should -Match 'createProvider'
        @(Get-ChildItem $d -Filter 'zebar-dep-*').Count | Should -Be 0
    }
    It 'falls back to jsDelivr and points every import at a local copy' {
        $d = Join-Path $TestDrive ([guid]::NewGuid()); New-Item -ItemType Directory $d | Out-Null
        $site = @{
            'https://cdn.jsdelivr.net/npm/zebar@3.0.3/+esm' = 'import{z}from"/npm/zod@3.24.2/+esm";import{invoke}from"/npm/@tauri-apps/api@2.0.2/core/+esm";export{L as createProvider};'
            'https://cdn.jsdelivr.net/npm/zod@3.24.2/+esm' = 'export const z=1;'
            'https://cdn.jsdelivr.net/npm/@tauri-apps/api@2.0.2/core/+esm' = 'import"/npm/zod@3.24.2/+esm";export const invoke=1;'
        }
        Save-ZebarClient '3.0.3' $d { param($u) if ($u -like '*esm.sh*') { throw 'blocked' }; $site[$u] ?? (throw "404 $u") }
        $main = Get-Content -Raw "$d\zebar.mjs"
        $main | Should -Match '"\./zebar-dep-zod_3\.24\.2\.mjs"'
        $main | Should -Match '"\./zebar-dep-_tauri-apps_api_2\.0\.2_core\.mjs"'
        Get-Content -Raw "$d\zebar-dep-_tauri-apps_api_2.0.2_core.mjs" | Should -Match '"\./zebar-dep-zod_3\.24\.2\.mjs"'
        (Get-ChildItem $d -Filter *.mjs | Get-Content -Raw) -join '' | Should -Not -Match '"/npm/'
    }
    It 'writes nothing, and throws for apply to log, when neither site answers' {
        $d = Join-Path $TestDrive ([guid]::NewGuid()); New-Item -ItemType Directory $d | Out-Null
        { Save-ZebarClient '3.0.3' $d { param($u) throw 'offline' } } | Should -Throw
        @(Get-ChildItem $d).Count | Should -Be 0
    }
    It 'never lets a failed download stop apply' {
        $src = Get-Content -Raw (Join-Path $root 'lib\apply.ps1')
        $src | Should -Match 'try \{ Save-ZebarClient [^\r\n]+\}\s+catch \{ Log '
    }
}

Describe 'Default browser' {
    BeforeAll { $script:base = 'TestRegistry:\https' }
    It 'reads the ProgId subkey of UserChoiceLatest before the stale UserChoice' {
        New-Item "$script:base\UserChoice" -Force | New-ItemProperty -Name ProgId -Value 'MSEdgeHTM' | Out-Null
        New-Item "$script:base\UserChoiceLatest\ProgId" -Force | New-ItemProperty -Name ProgId -Value 'ChromeHTML' | Out-Null
        Get-DefaultBrowserProgId $script:base | Should -Be 'ChromeHTML'
    }
    It 'falls back to UserChoice on builds without UserChoiceLatest' {
        Remove-Item "$script:base\UserChoiceLatest" -Recurse -Force
        Get-DefaultBrowserProgId $script:base | Should -Be 'MSEdgeHTM'
    }
    It 'maps browsers to their private-window switch' {
        Get-BrowserPrivateFlag 'C:\x\firefox.exe' | Should -Be '-private-window'
        Get-BrowserPrivateFlag 'C:\x\msedge.exe' | Should -Be '--inprivate'
        Get-BrowserPrivateFlag 'C:\x\brave.exe' | Should -Be '--incognito'
        Get-BrowserPrivateFlag '' | Should -Be '--incognito'
    }
}

Describe 'Theme set order' {
    It 'themes what is on screen, then the status and the background, then the rest' {
        $script:order = [Collections.Generic.List[string]]::new()
        Mock Read-Colors { @{} }; Mock Save-State {}; Mock Log {}
        Mock Get-Config { @{ themeTargets = @{ off = $false } } }
        Mock Read-State { @{ theme = 'old'; perTheme = @{ t = $TestDrive } } }
        Mock Get-ThemeTargets {
            [ordered]@{
                slow = @{ label = 'slow'; run = { $script:order.Add('slow') } }
                bar  = @{ label = 'bar'; fast = $true; run = { $script:order.Add('bar') } }
                off  = @{ label = 'off'; fast = $true; run = { $script:order.Add('off') } }
            }
        }
        Mock Write-Status { $script:order.Add("status:$([bool]$BumpTheme)") }
        Mock Set-Background { $script:order.Add('background') }
        Mock Set-OmarchyStateTheme {}
        Invoke-ThemeSet 't'
        $script:order -join ' ' | Should -Be 'bar status:True background slow'
    }
}

Describe 'Gaps toggled off vs a gap of 0 in config.json' {
    BeforeAll { foreach ($f in 'animations', 'autotile') { . "$root\lib\$f.ps1" } }
    BeforeEach {
        $GlazeConfig = Join-Path $TestDrive "$([guid]::NewGuid()).yaml"
        $Data = Join-Path $TestDrive ([guid]::NewGuid())
        $Generated = Join-Path $Data 'generated'
        $script:state = @{}
        Mock Read-State { $script:state }
        Mock Save-State { $script:state = $s }
        Mock Save-File {}
        Mock Log {}
        Mock Get-Paths { @{} }
        Mock Read-Colors { @{ focused_border = '#7aa2f7' } }
        function Gap { if ((Get-Content -Raw $GlazeConfig) -match "inner_gap:\s*'(\d+)px'\s*# gaps") { [int]$Matches[1] } }
    }
    It 'keeps gaps off after Super + Shift + Backspace' {
        Mock Get-Config { @{ gap = 10; barHeight = 26 } }
        [void](Write-GlazeConfig 1)
        (Get-Content -Raw $GlazeConfig) -replace "'10px'(\s*# gaps)(?!:)", "'0px'`$1" | Set-Content $GlazeConfig
        [void](Write-GlazeConfig 1)
        Gap | Should -Be 0
    }
    It 'uses a new gap after config.json had 0' {
        Mock Get-Config { @{ gap = 0; barHeight = 26 } }
        [void](Write-GlazeConfig 1)
        Mock Get-Config { @{ gap = 8; barHeight = 26 } }
        [void](Write-GlazeConfig 1)
        Gap | Should -Be 8
    }
}
