# Pester tests: Omarchy's web apps (default/webapps.json, lib/webapps.ps1, the launcher
# keys in ahk/launchers.ahk). Shortcuts go to TestDrive, never the real Start menu, and
# nothing is downloaded (the favicon fetch is mocked).
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'keys', 'journal', 'webapps', 'catalog', 'herdr') { . "$root\lib\$f.ps1" }
    $Code = $root
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    # The journal too: the real one in ~/.winarchy/backup is what uninstall replays.
    $BackupRoot = Join-Path $TestDrive 'backup'
    $presets = Get-WebAppPresets
    function New-ScratchJournal {
        $script:JournalDir = Join-Path $TestDrive ([guid]::NewGuid())
        $script:JournalCache = $null
        New-Item -ItemType Directory $script:JournalDir | Out-Null
        Write-Json (Join-Path $script:JournalDir 'journal.json') ([ordered]@{ entries = @() })
    }
}

Describe 'Presets' {
    It 'uses Omarchy''s URLs' {
        # default/hypr/bindings/applications.lua
        $want = @{
            'hey' = 'https://app.hey.com'; 'hey-calendar' = 'https://app.hey.com/calendar/weeks/'
            'hey-compose' = 'https://app.hey.com/messages/new?display=standalone&new_window=true'
            'basecamp' = 'https://launchpad.37signals.com'; 'chatgpt-web' = 'https://chatgpt.com'; 'grok' = 'https://grok.com'
            'whatsapp' = 'https://web.whatsapp.com/'; 'google-messages' = 'https://messages.google.com/web/conversations'
            'google-photos' = 'https://photos.google.com/'; 'google-maps' = 'https://maps.google.com/'
            'google-contacts' = 'https://contacts.google.com/'; 'x' = 'https://x.com/'; 'x-post' = 'https://x.com/compose/post'
            'youtube' = 'https://youtube.com/'; 'zoom' = 'https://app.zoom.us/wc/home'; 'discord' = 'https://discord.com/channels/@me'
        }
        foreach ($k in $want.Keys) { ($presets | Where-Object key -eq $k).url | Should -Be $want[$k] -Because $k }
    }
    It 'gives every preset a unique key, a label and an https URL' {
        @($presets.key | Select-Object -Unique).Count | Should -Be @($presets).Count
        foreach ($a in $presets) {
            $a.key | Should -Match '^[a-z0-9][a-z0-9-]*$'
            $a.label | Should -Not -BeNullOrEmpty
            $a.url | Should -Match '^https://'
        }
    }
    It 'brings an open window back where Omarchy does, and can find one it did not open' {
        foreach ($k in 'whatsapp', 'google-messages', 'google-photos', 'google-maps') {
            $a = $presets | Where-Object key -eq $k
            $a.focus | Should -BeTrue -Because $k
            $a.title | Should -Not -BeNullOrEmpty -Because $k
        }
    }
    It 'leaves Windows'' own Super+Shift+S (screen snip) alone' {
        @($presets.hotkey) | Should -Not -Contain '#+s'
    }
    It 'puts every installable preset in the Install > Web Apps group' {
        $group = $Catalog | Where-Object key -eq 'webapps'
        @($group.items.key) | Should -Be @($presets | Where-Object { $_.install -ne $false } | ForEach-Object key)
        foreach ($i in $group.items) { $i.install | Should -BeOfType [scriptblock]; $i.remove | Should -BeOfType [scriptblock] }
    }
}

Describe 'Keys' {
    It 'binds no key twice across winarchy''s own scripts' {
        $ids = [Collections.Generic.List[string]]::new()
        foreach ($f in 'winarchy.ahk', 'launchers.ahk') {
            $r = Get-AhkHotkeys (Get-Content -Raw (Join-Path $root "ahk\$f"))
            foreach ($k in $r.keys) { $ids.Add($k) }
        }
        # The launcher table's keys are Map() entries, not "x::" lines.
        foreach ($m in [regex]::Matches((Get-Content -Raw (Join-Path $root 'ahk\launchers.ahk')), '(?m)^\s+"([^"]+)",\s+\(\*\)')) { $ids.Add((ConvertTo-KeyId $m.Groups[1].Value)) }
        foreach ($a in $presets | Where-Object hotkey) { $ids.Add((ConvertTo-KeyId $a.hotkey)) }
        $dupes = @($ids | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
        $dupes | Should -BeNullOrEmpty
    }
    It 'lists every web app key in the keybindings list' {
        $text = Get-Content -Raw (Join-Path $root 'default\keybindings-apps.txt')
        $listed = @(foreach ($line in $text -split "`n") {
                if ($line -match '^\s+(\S(?:.*?\S)?)\s{2,}') { ConvertFrom-KeyText $Matches[1] }
            })
        foreach ($a in $presets | Where-Object hotkey) { $listed | Should -Contain (ConvertTo-KeyId $a.hotkey) -Because $a.label }
    }
}

Describe 'Browser' {
    It 'uses the default browser when it has app windows' {
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -eq 'C:\b\brave.exe' }
        Find-WebAppBrowser @{ browser = 'C:\b\brave.exe' } | Should -Be 'C:\b\brave.exe'
    }
    It 'falls back to a Chromium browser when the default is Firefox' {
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -eq 'C:\f\firefox.exe' }
        Mock Find-First { 'C:\c\chrome.exe' }
        Find-WebAppBrowser @{ browser = 'C:\f\firefox.exe' } | Should -Be 'C:\c\chrome.exe'
    }
    It 'finds none rather than assume Edge (it can be removed in the EEA)' {
        Mock Find-First { $null }
        Find-WebAppBrowser @{ browser = 'C:\f\firefox.exe' } | Should -BeNullOrEmpty
    }
    It 'quotes the URL, which carries & and ?' {
        Get-WebAppArgs 'https://app.hey.com/messages/new?display=standalone&new_window=true' |
            Should -Be '--app="https://app.hey.com/messages/new?display=standalone&new_window=true"'
    }
}

Describe 'Shortcuts' {
    BeforeEach {
        New-ScratchJournal
        $script:start = Join-Path $TestDrive ([guid]::NewGuid())
        Mock Get-WebAppDir { $script:start }
        Mock Get-WebAppIconDir { Join-Path $TestDrive 'icons' }
        Mock Save-WebAppIcon { $null }
        Mock Find-WebAppBrowser { Join-Path $env:SystemRoot 'notepad.exe' }
    }
    It 'makes a Start shortcut with its own AppUserModelID, journalled' {
        $lnk = Add-WebApp 'hey' 'HEY' 'https://app.hey.com' @{}
        Test-Path $lnk | Should -BeTrue
        $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
        $s.Arguments | Should -Be '--app="https://app.hey.com"'
        Initialize-ShortcutNative
        [Winarchy.Shortcut]::GetAppId($lnk) | Should -Be 'Winarchy.WebApp.hey'
        Test-WebApp 'hey' | Should -BeTrue
        (Read-Journal).entries.kind | Should -Contain 'webapp'
    }
    It 'gives each web app a different ID, so Start keeps them apart' {
        $a = Add-WebApp 'x' 'X' 'https://x.com/' @{}
        $b = Add-WebApp 'youtube' 'YouTube' 'https://youtube.com/' @{}
        [Winarchy.Shortcut]::GetAppId($a) | Should -Not -Be ([Winarchy.Shortcut]::GetAppId($b))
    }
    It 'removes it, and the journal forgets it' {
        $lnk = Add-WebApp 'grok' 'Grok' 'https://grok.com' @{}
        Remove-WebAppByKey 'grok'
        Test-Path $lnk | Should -BeFalse
        Test-WebApp 'grok' | Should -BeFalse
        Test-Journaled 'webapp|grok' | Should -BeFalse
    }
    It 'replaces the shortcut when the same web app is made again' {
        $old = Add-WebApp 'custom-notes' 'Notes' 'https://a.example' @{}
        $new = Add-WebApp 'custom-notes' 'My Notes' 'https://b.example' @{}
        Test-Path $old | Should -BeFalse
        Test-Path $new | Should -BeTrue
        @((Read-Journal).entries | Where-Object key -eq 'webapp|custom-notes').Count | Should -Be 1
    }
    It 'opens as a tab when there is no Chromium browser' {
        Mock Find-WebAppBrowser { $null }
        $lnk = Add-WebApp 'zoom' 'Zoom' 'https://app.zoom.us/wc/home' @{}
        (New-Object -ComObject WScript.Shell).CreateShortcut($lnk).TargetPath | Should -Match 'explorer\.exe$'
    }
}

Describe 'Uninstall' {
    It 'counts web apps among the apps you installed' {
        . "$root\lib\uninstall.ps1"
        function Get-CoreWingetIds { @() }
        $apps = @(Get-UserApps @(@{ kind = 'webapp'; key = 'webapp|hey'; label = 'HEY'; path = 'C:\x.lnk' }))
        $apps.label | Should -Be 'HEY (web app)'
    }
}

Describe 'AutoHotkey settings' {
    It 'writes each preset for the launcher keys' {
        $Generated = Join-Path $TestDrive 'gen'
        Mock Find-WebAppBrowser { 'C:\c\chrome.exe' }
        Write-WebAppIni @{}
        $ini = Get-Content -Raw (Join-Path $Generated 'webapps.ini')
        $ini | Should -Match '\[browser\]\r?\nexe=C:\\c\\chrome\.exe'
        $ini | Should -Match '\[whatsapp\][^\[]*hotkey=#\+!g[^\[]*focus=1'
        $ini | Should -Match '\[hey-compose\][^\[]*url=https://app\.hey\.com/messages/new\?display=standalone&new_window=true'
    }
}
