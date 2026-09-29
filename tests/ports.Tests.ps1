# Pester tests: Omarchy's own apps built for Windows (lib/ports.ps1, default/ports.json).
# Nothing is downloaded (Invoke-WebRequest copies a zip made here) and nothing lands in
# the real Programs folders or Start menu.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'journal', 'webapps', 'ports', 'catalog', 'herdr') { . "$root\lib\$f.ps1" }
    $Code = $root
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    function Write-Ok { }

    # A zip holding a stand-in exe (any file will do: it is never run).
    function New-FakeBuild([string]$key) {
        $dir = Join-Path $TestDrive "build-$key-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Force $dir | Out-Null
        Set-Content (Join-Path $dir "$key.exe") 'not really an exe'
        Set-Content (Join-Path $dir 'Qt6Core.dll') 'x'
        $zip = "$dir.zip"
        Compress-Archive "$dir\*" $zip
        @{ zip = $zip; sha256 = (Get-FileHash $zip -Algorithm SHA256).Hash }
    }
}

Describe 'Manifest' {
    It 'lists the five apps the plan ports, at Omarchy''s versions' {
        $m = Get-PortManifest
        @($m.key) | Should -Be @('omawrite', 'omacalc', 'omacut', 'hype', 'aether')
        ($m | Where-Object key -eq 'omawrite').tag | Should -Be 'v0.5.0'
        ($m | Where-Object key -eq 'omacalc').tag | Should -Be 'v0.2.2'
        ($m | Where-Object key -eq 'omacut').tag | Should -Be 'v0.4.0'
        ($m | Where-Object key -eq 'hype').tag | Should -Be 'v0.4.3'
    }
    It 'pins every published build by URL and SHA-256' {
        foreach ($a in Get-PublishedPorts) {
            $a.url | Should -Match '^https://github\.com/.+/releases/download/port-'
            $a.sha256 | Should -Match '^[0-9A-Fa-f]{64}$'
        }
    }
    It 'offers only published builds in Install' {
        @(Get-PortCatalogItems).Count | Should -Be @(Get-PublishedPorts).Count
    }
    It 'keeps the launch paths winarchy.ahk uses' {
        $ahk = Get-Content -Raw (Join-Path $root 'ahk\winarchy.ahk')
        $ahk | Should -Match 'Programs\\Winarchy\\oma\\" name "\\" name "\.exe'
        Get-PortExe 'omacalc' | Should -BeLike '*\Programs\Winarchy\oma\omacalc\omacalc.exe'
    }
}

Describe 'Install and remove' {
    BeforeEach {
        $script:JournalDir = Join-Path $TestDrive ([guid]::NewGuid())
        $script:JournalCache = $null
        New-Item -ItemType Directory $script:JournalDir | Out-Null
        Write-Json (Join-Path $script:JournalDir 'journal.json') ([ordered]@{ entries = @() })
        $script:ports = Join-Path $TestDrive ([guid]::NewGuid())
        $script:start = Join-Path $TestDrive ([guid]::NewGuid())
        Mock Get-PortRoot { $script:ports }
        Mock Get-PortStartDir { $script:start }
        Mock Get-SmartAppControlState { 0 }
        $script:build = New-FakeBuild 'omacalc'
        Mock Get-PortManifest { @(@{ key = 'omacalc'; label = 'Omacalc'; version = '0.2.2'; url = 'https://github.com/x/y/releases/download/port-omacalc-v0.2.2-1/omacalc.zip'; sha256 = $script:build.sha256 }) }
        Mock Invoke-WebRequest { Copy-Item $script:build.zip $OutFile }
    }
    It 'unpacks it, adds it to Start and journals it' {
        Install-Port 'omacalc'
        Test-Port 'omacalc' | Should -BeTrue
        Test-Path (Join-Path $script:start 'Omacalc.lnk') | Should -BeTrue
        Test-Journaled 'port|omacalc' | Should -BeTrue
        Get-Content (Join-Path $script:ports 'omacalc\winarchy-version.txt') | Should -Be '0.2.2'
    }
    It 'refuses a download that does not match its pinned hash' {
        Mock Get-PortManifest { @(@{ key = 'omacalc'; label = 'Omacalc'; version = '0.2.2'; url = 'https://x'; sha256 = ('0' * 64) }) }
        { Install-Port 'omacalc' } | Should -Throw '*SHA-256*'
        Test-Port 'omacalc' | Should -BeFalse
    }
    It 'says why up front when Smart App Control would block it' {
        Mock Get-SmartAppControlState { 1 }
        { Install-Port 'omacalc' } | Should -Throw '*Smart App Control*'
        Should -Invoke Invoke-WebRequest -Times 0
    }
    It 'refuses an app with no Windows build yet' {
        Mock Get-PortManifest { @(@{ key = 'omacut'; label = 'Omacut'; version = '0.4.0'; url = $null; sha256 = $null }) }
        { Install-Port 'omacut' } | Should -Throw '*no Windows build*'
    }
    It 'removes it again, and the folders it leaves empty' {
        Install-Port 'omacalc'
        Remove-Port 'omacalc'
        Test-Port 'omacalc' | Should -BeFalse
        Test-Path $script:start | Should -BeFalse
        Test-Journaled 'port|omacalc' | Should -BeFalse
    }
    It 'finds an installed one whose pinned build moved on' {
        Install-Port 'omacalc'
        @(Get-OutdatedPorts).Count | Should -Be 0
        Mock Get-PortManifest { @(@{ key = 'omacalc'; label = 'Omacalc'; version = '0.2.3'; url = 'https://x'; sha256 = ('A' * 64) }) }
        @(Get-OutdatedPorts).key | Should -Be 'omacalc'
    }
}

Describe 'Smart App Control' {
    It 'reads the state Windows keeps, and counts a missing one as off' {
        Get-SmartAppControlState | Should -BeIn 0, 1, 2
    }
}
