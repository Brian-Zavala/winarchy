# Finds the apps and paths this machine actually has, so nothing is hard-coded.
# Writes ~/.winarchy/paths.json (winarchy detect / doctor -Fix refresh it).

function Find-First([string[]]$candidates) {
    foreach ($c in $candidates) { if ($c -and (Test-Path -LiteralPath $c)) { return (Resolve-Path -LiteralPath $c).Path } }
    $null
}
# Split-Path throws on $null/'' even with -ErrorAction, so anything not found goes through here.
function Get-ParentDir([string]$path) {
    if ($path) { Split-Path $path }
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

# A real Python 3, for the agent-usage collectors (lib/agents). Two traps on Windows:
# `python.exe` in WindowsApps is a Store stub that opens the Microsoft Store instead of
# running anything, and it is often first on PATH; and a python.org install may not be on
# PATH at all. The py launcher knows every python.org install, so ask it first and store
# the interpreter it names, not the launcher.
function Find-Python {
    $py = Find-First @((Join-Path $env:LOCALAPPDATA 'Programs\Python\Launcher\py.exe'), (Join-Path $env:SystemRoot 'py.exe'))
    if (-not $py) { $py = Find-Program py.exe }
    if ($py) {
        try {
            $exe = (& $py -3 -c 'import sys; print(sys.executable)' 2>$null | Select-Object -First 1)
            if ($exe -and (Test-Path -LiteralPath $exe.Trim())) { return $exe.Trim() }
        } catch {}
    }
    foreach ($c in @(Get-Command python.exe, python3.exe -CommandType Application -All -ErrorAction SilentlyContinue)) {
        # WindowsApps holds both the Store stub and a real Store (or Install Manager)
        # Python under the same alias name, so ask it rather than go by the path.
        if ($c.Source -like '*\WindowsApps\*' -and -not (Test-RealPython $c.Source)) { continue }
        return $c.Source
    }
    $null
}

# The stub, given arguments, prints a hint and exits 9009 without opening the Store.
function Test-RealPython([string]$exe) {
    try {
        # No Select-Object -First here: stopping the pipeline early loses the exit code.
        $out = @(& $exe -c 'import sys; print(sys.version_info[0])' 2>$null)
        $LASTEXITCODE -eq 0 -and "$($out[0])".Trim() -eq '3'
    } catch { $false }
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

# The https handler's ProgId. Current builds keep the live choice in a ProgId subkey
# of UserChoiceLatest (its own values are only a hash), and leave the older UserChoice
# behind with whatever was chosen before, so the subkey comes first.
function Get-DefaultBrowserProgId([string]$base = 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https') {
    foreach ($k in 'UserChoiceLatest\ProgId', 'UserChoiceLatest', 'UserChoice') {
        $v = (Get-ItemProperty (Join-Path $base $k) -ErrorAction SilentlyContinue).ProgId
        if ($v) { return $v }
    }
    $null
}

# Default browser from the https handler, with its private-window flag.
function Find-Browser {
    $progId = Get-DefaultBrowserProgId
    $exe = $null
    if ($progId) {
        $cmd = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$progId\shell\open\command" -ErrorAction SilentlyContinue).'(default)'
        if ($cmd -match '^\s*"([^"]+)"' -or $cmd -match '^\s*(\S+\.exe)') { $exe = $Matches[1] }
    }
    if (-not $exe -or -not (Test-Path -LiteralPath $exe)) {
        $exe = Find-First @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe")
    }
    $name = if ($exe) { [IO.Path]::GetFileNameWithoutExtension($exe).ToLower() } else { '' }
    @{ exe = $exe; name = $name; private = (Get-BrowserPrivateFlag $exe); progId = $progId }
}

# A browser's private-window switch, from its exe name.
function Get-BrowserPrivateFlag([string]$exe) {
    $name = if ($exe) { [IO.Path]::GetFileNameWithoutExtension($exe).ToLower() } else { '' }
    switch -Regex ($name) {
        '^(chrome|brave|vivaldi|chromium|thorium)$' { '--incognito' }
        '^msedge$' { '--inprivate' }
        '^(firefox|librewolf|waterfox|zen)$' { '-private-window' }
        '^opera' { '--private' }
        default { '--incognito' }
    }
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
    Add-NativeType Dpi '[DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);'
    [void][Winarchy.Dpi]::SetThreadDpiAwarenessContext([IntPtr]-4)
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
    $glazeDir = Find-First @((Join-Path $env:ProgramFiles 'glzr.io\GlazeWM'), (Get-ParentDir (Find-Program glazewm)))
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
        glazewmOfficial    = if ($glazeDir) { Find-First @((Join-Path $glazeDir 'glazewm.exe')) }
        glazewmCliOfficial = if ($glazeDir) { Find-First @((Join-Path $glazeDir 'cli\glazewm.exe'), (Join-Path $glazeDir 'glazewm.exe')) }
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
        btopDir        = Get-ParentDir (Find-First @(
                            (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\aristocratos.btop4win_*\btop4win\btop4win.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName,
                            (Find-Program btop4win.exe)))
        fastfetch      = Find-Program fastfetch.exe
        # Herdr installs itself outside winget, at a stable alias path plus the PATH entry
        # its own installer adds (which a shell started before the install won't have).
        herdr          = Find-First @((Join-Path $env:LOCALAPPDATA 'Programs\Herdr\bin\herdr.exe'), (Find-Program herdr.exe))
        python         = Find-Python
        ttfx           = Find-First @((Join-Path $env:USERPROFILE '.cargo\bin\ttfx.exe'), (Join-Path $Data 'bin\ttfx.exe'), (Find-Program ttfx.exe), (Find-Program tte.exe))
        browser        = $browser.exe
        browserName    = $browser.name
        browserPrivate = $browser.private
        screenshots    = Get-KnownFolder 'b7bede81-df94-4682-a7d8-57a52620b86f'
        pictures       = [Environment]::GetFolderPath('MyPictures')
        startup        = [Environment]::GetFolderPath('Startup')
        # The keys your own Startup scripts bind: winarchy's leave them to you (lib/keys.ps1).
        userHotkeys    = Get-UserHotkeys
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
