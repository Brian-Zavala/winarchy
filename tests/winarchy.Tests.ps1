# Pester tests for the machine-independent logic: run with  Invoke-Pester ./tests
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'targets', 'journal', 'apply') { . "$root\lib\$f.ps1" }
    $Code = $root
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
        Mock Set-DesktopWallpaper { $script:seen = (Read-Json (Join-Path $Pack 'status.json'))?.background; $script:cov = $covered }
        Set-Background $wall @{ theme = 't'; background = 'old'; perTheme = @{} } @(10, 20)
        $script:seen | Should -Not -Be $wall
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