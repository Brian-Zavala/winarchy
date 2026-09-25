# Finds the apps and paths this machine actually has, so nothing is hard-coded.
# Writes ~/.omarchy-win/paths.json (omarchy-win detect / doctor -Fix refresh it).

function Find-First([string[]]$candidates) {
    foreach ($c in $candidates) { if ($c -and (Test-Path -LiteralPath $c)) { return (Resolve-Path -LiteralPath $c).Path } }
    $null
}
function Find-Program([string]$name) {
    $c = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c) { $c.Source }
}

function Find-AutoHotkey {
    $dirs = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey'),
        (Join-Path $env:ProgramFiles 'AutoHotkey')
    )
    foreach ($key in 'HKCU:\SOFTWARE\AutoHotkey', 'HKLM:\SOFTWARE\AutoHotkey') {
        $d = (Get-ItemProperty $key -ErrorAction SilentlyContinue).InstallDir
        if ($d) { $dirs = @($d) + $dirs }
    }
    $exe = if ([Environment]::Is64BitOperatingSystem) { 'AutoHotkey64.exe' } else { 'AutoHotkey32.exe' }
    Find-First ($dirs | ForEach-Object { Join-Path $_ "v2\$exe"; Join-Path $_ $exe })
}

function Find-Pwsh {
    # The Program Files / App Execution Alias paths survive pwsh updates; the MSIX
    # package path (WindowsApps\Microsoft.PowerShell_7.x.y...) does not.
    Find-First @(
        (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\pwsh.exe'),
        (Find-Program pwsh)
    )
}

function Find-TerminalSettings {
    Find-First @(
        (Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName,
        (Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_*\LocalState\settings.json" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName,
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    )
}

# Default browser from the https handler, with its private-window flag.
function Find-Browser {
    $progId = $null
    foreach ($k in 'UserChoiceLatest', 'UserChoice') {
        $v = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\$k" -ErrorAction SilentlyContinue).ProgId
        if ($v) { $progId = $v; break }
    }
    $exe = $null
    if ($progId) {
        $cmd = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$progId\shell\open\command" -ErrorAction SilentlyContinue).'(default)'
        if ($cmd -match '^\s*"([^"]+)"' -or $cmd -match '^\s*(\S+\.exe)') { $exe = $Matches[1] }
    }
    if (-not $exe -or -not (Test-Path -LiteralPath $exe)) {
        $exe = Find-First @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe")
    }
    $name = if ($exe) { [IO.Path]::GetFileNameWithoutExtension($exe).ToLower() } else { '' }
    $private = switch -Regex ($name) {
        '^(chrome|brave|vivaldi|chromium|thorium)$' { '--incognito' }
        '^msedge$' { '--inprivate' }
        '^(firefox|librewolf|waterfox|zen)$' { '-private-window' }
        '^opera' { '--private' }
        default { '--incognito' }
    }
    @{ exe = $exe; name = $name; private = $private; progId = $progId }
}

# Flow Launcher's own hotkey ("Alt + Space") as an AutoHotkey Send string ("!{Space}").
function ConvertTo-AhkHotkey([string]$flow) {
    if (-not $flow) { return '!{Space}' }
    $mods = ''; $key = ''
    foreach ($part in ($flow -split '\+') | ForEach-Object { $_.Trim() } | Where-Object { $_ }) {
        switch -Regex ($part) {
            '^(Ctrl|Control)$' { $mods += '^'; continue }
            '^Alt$' { $mods += '!'; continue }
            '^Shift$' { $mods += '+'; continue }
            '^(Win|LWin|Windows)$' { $mods += '#'; continue }
            default { $key = if ($part.Length -eq 1) { $part.ToLower() } else { "{$part}" } }
        }
    }
    "$mods$key"
}

function Get-MonitorLayout {
    Add-Type -AssemblyName System.Windows.Forms
    # Physical pixels, like GlazeWM (otherwise mixed-DPI monitors come back scaled).
    Add-Type -Namespace OmarchyWin -Name Dpi -MemberDefinition '[DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);' -ErrorAction SilentlyContinue
    [void][OmarchyWin.Dpi]::SetThreadDpiAwarenessContext([IntPtr]-4)
    # Same order GlazeWM and Zebar use: left to right, then top to bottom.
    @([System.Windows.Forms.Screen]::AllScreens | Sort-Object { $_.Bounds.X }, { $_.Bounds.Y } | ForEach-Object {
        @{ name = $_.DeviceName; primary = $_.Primary; x = $_.Bounds.X; y = $_.Bounds.Y; width = $_.Bounds.Width; height = $_.Bounds.Height }
    })
}

function Get-InputLayouts {
    try {
        $langs = Get-WinUserLanguageList
        $tips = @($langs | ForEach-Object { $_.InputMethodTips }).Count
        $ime = [bool]($langs | Where-Object { $_.LanguageTag -match '^(ja|zh|ko|vi)' })
        @{ count = [Math]::Max($tips, @($langs).Count); ime = $ime; languages = @($langs.LanguageTag) }
    } catch { @{ count = 1; ime = $false; languages = @() } }
}

function Test-FontFamily([string]$pattern) {
    foreach ($key in 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts') {
        $p = Get-ItemProperty $key -ErrorAction SilentlyContinue
        if ($p -and ($p.PSObject.Properties.Name | Where-Object { $_ -match $pattern })) { return $true }
    }
    $false
}

function Update-Paths {
    $flowDir = Join-Path $env:LOCALAPPDATA 'FlowLauncher'
    $flowSettings = Join-Path $env:APPDATA 'FlowLauncher\Settings\Settings.json'
    $flowHotkey = (Read-Json $flowSettings).Hotkey
    $nvimConfig = Join-Path $env:LOCALAPPDATA 'nvim'
    $glazeDir = Find-First @((Join-Path $env:ProgramFiles 'glzr.io\GlazeWM'), (Split-Path (Find-Program glazewm) -ErrorAction SilentlyContinue))
    $culture = Get-Culture
    $browser = Find-Browser
    $p = [ordered]@{
        detected       = (Get-Date).ToString('s')
        code           = $Code
        data           = $Data
        pack           = $Pack
        ahk            = Find-AutoHotkey
        pwsh           = Find-Pwsh
        powershell     = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        glazewmOfficial    = Find-First @((Join-Path "$glazeDir" 'glazewm.exe'))
        glazewmCliOfficial = Find-First @((Join-Path "$glazeDir" 'cli\glazewm.exe'), (Join-Path "$glazeDir" 'glazewm.exe'))
        zebar          = Find-First @((Join-Path $env:ProgramFiles 'glzr.io\Zebar\zebar.exe'), (Find-Program zebar))
        flow           = Find-First @((Join-Path $flowDir 'Flow.Launcher.exe'))
        flowSettings   = $flowSettings
        flowThemes     = Join-Path $env:APPDATA 'FlowLauncher\Themes'
        flowHotkey     = ConvertTo-AhkHotkey $flowHotkey
        wt             = Find-Program wt.exe
        wtSettings     = Find-TerminalSettings
        nvim           = Find-Program nvim
        nvimConfig     = $nvimConfig
        nvimOmarchy    = (Test-Path (Join-Path $nvimConfig 'lua\plugins\theme.lua'))
        vscode        = Find-Program code
        vscodeSettings = Join-Path $env:APPDATA 'Code\User\settings.json'
        btopDir        = Split-Path (Find-First @(
                            (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\aristocratos.btop4win_*\btop4win\btop4win.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName,
                            (Find-Program btop4win.exe))) -ErrorAction SilentlyContinue
        fastfetch      = Find-Program fastfetch.exe
        ttfx           = Find-First @((Join-Path $env:USERPROFILE '.cargo\bin\ttfx.exe'), (Join-Path $Data 'bin\ttfx.exe'), (Find-Program ttfx.exe), (Find-Program tte.exe))
        browser        = $browser.exe
        browserName    = $browser.name
        browserPrivate = $browser.private
        screenshots    = Get-KnownFolder 'b7bede81-df94-4682-a7d8-57a52620b86f'
        pictures       = [Environment]::GetFolderPath('MyPictures')
        startup        = [Environment]::GetFolderPath('Startup')
        clock24        = $culture.DateTimeFormat.ShortTimePattern -cmatch 'H'
        metric         = [Globalization.RegionInfo]::CurrentRegion.IsMetric
        monitors       = @(Get-MonitorLayout)
        input          = Get-InputLayouts
        battery        = [bool](Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)
        nerdFont       = Test-FontFamily 'JetBrainsMono N(F|erd)'
        build          = [Environment]::OSVersion.Version.Build
        arch           = $env:PROCESSOR_ARCHITECTURE
    }
    # glazewm / glazewmCli: the GlazeWM that should run (the animation build when it is on).
    $sel = Get-SelectedGlazeWM $p
    $p.glazewm = $sel.exe
    $p.glazewmCli = $sel.cli
    Write-Json $PathsFile $p 6
    Read-Json $PathsFile -AsHashtable
}
