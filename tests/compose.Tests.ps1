# Pester tests: CapsLock compose (ahk/lib/compose.ahk) and the settings that turn it and
# Omarchy's capture keys on: new installs get Omarchy's, a config from before keeps its own
# (Invoke-ConfigMigration), and a value you set is never touched.
BeforeDiscovery {
    $Verb = 'test'
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\common.ps1')
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\detect.ps1')
    $hasAhk = [bool](Find-AutoHotkey)
}

BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'keys', 'render', 'themes', 'journal', 'apply', 'setup') { . "$root\lib\$f.ps1" }
    $Code = $root
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    # The journal too: the real one in ~/.winarchy/backup is what uninstall replays.
    $BackupRoot = Join-Path $TestDrive 'backup'
    $Generated = Join-Path $TestDrive 'generated'
}

Describe 'Config migration' {
    BeforeEach { $ConfigFile = Join-Path $TestDrive "config-$([guid]::NewGuid()).json" }
    It 'gives a config from before the settings it had: capture keys and CapsLock as they were' {
        Write-Json $ConfigFile ([ordered]@{ launchers = $true; textSize = 12 })
        Invoke-ConfigMigration
        $c = Read-UserConfig
        $c.captureKeys | Should -Be 'winarchy'
        $c.compose | Should -BeFalse
        $c.textSize | Should -Be 12
        $c.hideDesktopIcons | Should -BeFalse
    }
    It 'never touches a value you set' {
        Write-Json $ConfigFile ([ordered]@{ captureKeys = 'omarchy'; compose = $true; hideDesktopIcons = $true })
        $before = Get-Content -Raw $ConfigFile
        Invoke-ConfigMigration
        Get-Content -Raw $ConfigFile | Should -Be $before
    }
    It 'fills in only the one that is missing' {
        Write-Json $ConfigFile ([ordered]@{ captureKeys = 'omarchy' })
        Invoke-ConfigMigration
        $c = Read-UserConfig
        $c.captureKeys | Should -Be 'omarchy'
        $c.compose | Should -BeFalse
    }
    It 'does nothing without a config.json, or with one that does not parse' {
        Invoke-ConfigMigration
        Test-Path $ConfigFile | Should -BeFalse
        Set-Content $ConfigFile '{ "a": "C:\x" }'
        Invoke-ConfigMigration
        Get-Content -Raw $ConfigFile | Should -Match 'C:\\x'
    }
    It 'stamps its write so winarchy.ahk does not apply it a second time' {
        Write-Json $ConfigFile ([ordered]@{ gap = 8 })
        Invoke-ConfigMigration
        Get-Content (Join-Path $Generated 'config.selfwrite') | Should -Be (Get-Item $ConfigFile).LastWriteTime.ToString('yyyyMMddHHmmss')
    }
    It 'runs first thing in apply' {
        (Get-Command Invoke-Apply).ScriptBlock.ToString() | Should -Match '^\s*param\([^\r\n]*\)\s+Invoke-ConfigMigration'
    }
}

Describe 'Install answers' {
    BeforeEach {
        $ConfigFile = Join-Path $TestDrive "config-$([guid]::NewGuid()).json"
        Mock Read-Host { 'y' }
        Mock Write-Step {}; Mock Write-Ok {}
    }
    It 'gives a new install Omarchy''s capture keys and compose' {
        $script:FreshInstall = $true
        $cfg = Get-InstallAnswers @{ input = @{ count = 1 }; startup = $TestDrive; pictures = $TestDrive }
        $cfg.captureKeys | Should -Be 'omarchy'
        $cfg.compose | Should -BeTrue
        $cfg.hideDesktopIcons | Should -BeTrue
    }
    It 'leaves CapsLock alone with an input method' {
        $script:FreshInstall = $true
        $cfg = Get-InstallAnswers @{ input = @{ count = 2; ime = $true }; startup = $TestDrive; pictures = $TestDrive }
        $cfg.compose | Should -BeFalse
    }
    It 'adds nothing to a config that was there before install' {
        $script:FreshInstall = $false
        Write-Json $ConfigFile ([ordered]@{ hideTaskbar = $true; launchers = $true; takeOverWinSpace = $true })
        $cfg = Get-InstallAnswers @{ input = @{ count = 1 }; startup = $TestDrive; pictures = $TestDrive } -Restoring
        $cfg.Contains('captureKeys') | Should -BeFalse
        $cfg.Contains('compose') | Should -BeFalse
        $cfg.Contains('hideDesktopIcons') | Should -BeFalse
    }
    AfterAll { $script:FreshInstall = $null }
}

Describe 'AutoHotkey settings' {
    It 'writes the capture layout and compose, never compose with an input method' {
        $base = @{ apps = @{ editor = 'notepad.exe'; terminal = 'auto'; browser = 'auto'; files = 'explorer.exe' }; screensaver = @{}; agentUsage = @{}; autoTiling = @{} }
        Write-AhkIni @{ input = @{ ime = $false } } ($base + @{ captureKeys = 'omarchy'; compose = $true })
        $ini = Get-Content -Raw (Join-Path $Generated 'winarchy.ini')
        $ini | Should -Match 'captureKeys=omarchy'
        $ini | Should -Match 'compose=1'
        Write-AhkIni @{ input = @{ ime = $true } } ($base + @{ captureKeys = 'nonsense'; compose = $true })
        $ini = Get-Content -Raw (Join-Path $Generated 'winarchy.ini')
        $ini | Should -Match 'captureKeys=winarchy'
        $ini | Should -Match 'compose=0'
    }
    It 'lists the Print keys the way the layout has them' {
        Get-CaptureKeysText @{ captureKeys = 'omarchy' } | Should -Match 'Super \+ Print\s+Color picker'
        Get-CaptureKeysText @{ captureKeys = 'winarchy' } | Should -Match 'Super \+ Print\s+Full screenshot'
    }
}

Describe 'Keybindings sheet' {
    It 'takes an empty apps list of your own (launchers off)' {
        $Data = Join-Path $TestDrive "data-$([guid]::NewGuid())"
        New-Item -ItemType Directory $Data | Out-Null
        New-Item -ItemType File (Join-Path $Data 'keybindings-apps.txt') | Out-Null
        $txt = Get-KeybindingsText @{ launchers = $false; captureKeys = 'omarchy' } @{ userHotkeys = @{ keys = @() } }
        $txt | Should -Not -Match '\{\{ apps \}\}'
    }
}

Describe 'Compose table' -Skip:(-not $hasAhk) {
    It 'has every one of Omarchy''s sequences, with the same text' {
        $out = Join-Path $TestDrive 'compose.txt'
        $harness = Join-Path $TestDrive 'compose.ahk'
        $fixture = Join-Path $root 'tests\fixtures\xcompose\xcompose'
        Set-Content $harness -Encoding utf8 @"
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((*) => ExitApp(2))
#Include "$root\ahk\lib\env.ahk"
#Include "$root\ahk\lib\compose.ahk"
global OW := Map("data", "$TestDrive", "composeName", "Ada", "composeEmail", "ada@example.com")
out := ""
for line in StrSplit(FileRead("$fixture", "UTF-8"), "``n", "``r") {
    seq := ComposeParseLine(line, &text)
    if seq = ""
        continue
    got := ComposeLookup(seq)
    out .= (got == text ? "ok" : "MISMATCH") " " seq "``n"
}
out .= "name " ComposeLookup(" n") "``n" "email " ComposeLookup(" e") "``n"
out .= "upper " ComposeLookup("MS") "``n" "prefix " ComposePrefix("m") "``n" "none " ComposeLookup("zz") "``n"
FileAppend out, "$out", "UTF-8"
ExitApp 0
"@
        $p = Start-Process (Find-AutoHotkey) -ArgumentList "`"$harness`"" -Wait -PassThru
        $p.ExitCode | Should -Be 0
        $lines = @(Get-Content $out -Encoding utf8 | Where-Object { $_ })
        @($lines | Where-Object { $_ -like 'ok *' }).Count | Should -Be 24     # 23 emoji + the em dash
        $lines | Where-Object { $_ -like 'MISMATCH*' } | Should -BeNullOrEmpty
        $lines | Should -Contain 'name Ada'
        $lines | Should -Contain 'email ada@example.com'
        $lines | Should -Contain 'upper 😄'
        $lines | Should -Contain 'prefix 1'
        $lines | Should -Contain 'none '
    }
}
