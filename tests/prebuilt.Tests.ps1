# Pester tests: the builds default/prebuilt.json pins (.github/workflows/prebuilt.yml
# publishes them), downloaded instead of compiled: ttfx and the window-animation GlazeWM.
# Nothing is downloaded for real: Invoke-WebRequest and Save-PinnedFile are mocked.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'targets', 'journal', 'apply', 'catalog', 'herdr', 'extras', 'setup', 'animations') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    $Pack = Join-Path $TestDrive 'pack'
    New-Item -ItemType Directory -Force $Pack | Out-Null
    # SHA-256 of the text "hello".
    $helloSha = '2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E73043362938B9824'
    # Windows-only (CIM): a stand-in so these tests also run under PowerShell elsewhere.
    if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) { function Get-CimInstance {} }
    # A zip holding $files (relative path -> text), as the prebuilt workflow makes them.
    function New-TestZip([hashtable]$files) {
        $dir = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        foreach ($k in $files.Keys) {
            $p = Join-Path $dir $k
            New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
            Set-Content -LiteralPath $p $files[$k]
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::CreateFromDirectory($dir, "$dir.zip")
        "$dir.zip"
    }
}

Describe 'Pinned downloads' {
    It 'keeps a download whose hash matches' {
        Mock Invoke-WebRequest { [IO.File]::WriteAllText($OutFile, 'hello') }
        $dest = Join-Path $TestDrive 'ok\file.bin'
        Save-PinnedFile 'https://example.test/file.bin' $helloSha.ToLower() $dest
        Get-Content -Raw $dest | Should -Be 'hello'
        Test-Path "$dest.part" | Should -BeFalse
    }
    It 'leaves nothing behind when the hash does not match' {
        Mock Invoke-WebRequest { [IO.File]::WriteAllText($OutFile, 'changed') }
        $dest = Join-Path $TestDrive 'bad\file.bin'
        { Save-PinnedFile 'https://example.test/file.bin' $helloSha $dest } | Should -Throw '*pinned SHA-256*'
        Test-Path $dest | Should -BeFalse
        Test-Path "$dest.part" | Should -BeFalse
    }
    It 'offers only a build with both a url and a hash' {
        $Code = Join-Path $TestDrive 'code'
        New-Item -ItemType Directory -Force (Join-Path $Code 'default') | Out-Null
        Set-Content (Join-Path $Code 'default\prebuilt.json') '{"a":{"url":"https://x/a.zip","sha256":"AB"},"b":{"url":null,"sha256":null},"c":{"url":"https://x/c.zip","sha256":null}}'
        (Get-Prebuilt 'a').url | Should -Be 'https://x/a.zip'
        Get-Prebuilt 'b' | Should -BeNullOrEmpty
        Get-Prebuilt 'c' | Should -BeNullOrEmpty
        Get-Prebuilt 'missing' | Should -BeNullOrEmpty
    }
}

Describe 'The pinned sources' {
    BeforeAll {
        $m = Get-Content -Raw (Join-Path $root 'default\prebuilt.json') | ConvertFrom-Json
        $cfg = Get-Content -Raw (Join-Path $root 'default\config.json') | ConvertFrom-Json
    }
    It 'builds the GlazeWM commit the animation setting pins' {
        $g = $m.'glazewm-animations'
        $g.source | Should -Be $cfg.animations.source.repo
        $g.commit | Should -Be $cfg.animations.source.commit
        $g.version | Should -Be $cfg.animations.source.version
        $g.fallbackToolchain | Should -Be $cfg.animations.source.fallbackToolchain
    }
    It 'pins a url only together with its hash' {
        foreach ($e in $m.ttfx, $m.'glazewm-animations') { [bool]$e.url | Should -Be ([bool]$e.sha256) }
    }
    It 'has a workflow that builds each entry' {
        $wf = Get-Content -Raw (Join-Path $root '.github\workflows\prebuilt.yml')
        $wf | Should -Match '\.ttfx'
        $wf | Should -Match "\.'glazewm-animations'"
        # The layout Install-AnimationPrebuilt expects.
        foreach ($f in $AnimFiles.Values) { $wf | Should -Match ([regex]::Escape(($f -replace '\\', '/'))) }
    }
}

Describe 'ttfx' {
    BeforeEach {
        Mock Write-Step {}
        Mock Write-Ok {}
        Mock Write-Done {}
        Mock Save-Winget {}
        Mock Install-WingetPackage { $true }
        Mock Update-Paths { @{ btopDir = 'C:\btop'; ttfx = $null } }
        Mock Find-Python { 'C:\Python313\python.exe' }
        Mock Get-Command { [pscustomobject]@{ Source = 'C:\fastfetch.exe' } } -ParameterFilter { $Name -eq 'fastfetch.exe' }
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'cargo' }
        Mock Get-Config { @{ ttfxUrl = $null } }
        Mock Get-Prebuilt { @{ url = 'https://x/ttfx.zip'; sha256 = 'AB'; version = '0.3.3' } } -ParameterFilter { $key -eq 'ttfx' }
        Mock Install-PrebuiltTtfx {}
        Mock Start-Hidden {}
        Mock Add-JournalEntry {}
        Mock Get-CimInstance {}
        Mock Get-Paths { @{ pwsh = 'pwsh.exe' } }
    }
    It 'downloads the pinned build instead of compiling it' {
        Install-Extras
        Should -Invoke Install-PrebuiltTtfx -Times 1
        Should -Invoke Start-Hidden -Times 0
    }
    It 'builds the pinned tag with cargo when the download fails' {
        Mock Install-PrebuiltTtfx { throw 'the download does not match its pinned SHA-256' }
        Mock Get-Command { [pscustomobject]@{ Source = 'C:\cargo.exe' } } -ParameterFilter { $Name -eq 'cargo' }
        Install-Extras
        Should -Invoke Start-Hidden -Times 1 -ParameterFilter {
            [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($arguments[-1])) -match 'omacom/ttfx --tag v0\.3\.3 --locked'
        }
    }
    It 'uses a ttfxUrl of your own first' {
        Mock Get-Config { @{ ttfxUrl = 'https://mine.test/ttfx.exe' } }
        Mock Invoke-WebRequest {}
        Install-Extras
        Should -Invoke Invoke-WebRequest -Times 1 -ParameterFilter { $Uri -eq 'https://mine.test/ttfx.exe' }
        Should -Invoke Get-Prebuilt -Times 0
    }
}

Describe 'ttfx release zip' {
    It 'keeps only ttfx.exe from it' {
        $script:testZip = New-TestZip @{ 'ttfx.exe' = 'exe'; 'LICENSE' = 'MIT' }
        Mock Save-PinnedFile { Copy-Item $script:testZip $dest }
        $dest = Join-Path $TestDrive 'bin\ttfx.exe'
        Install-PrebuiltTtfx @{ url = 'https://x/ttfx.zip'; sha256 = 'AB' } $dest
        (Get-Content $dest) | Should -Be 'exe'
        Test-Path (Join-Path $TestDrive 'bin\LICENSE') | Should -BeFalse
    }
}

Describe 'Animation build download' {
    BeforeEach {
        $AnimDir = Join-Path $TestDrive 'anim'
        $AnimSrc = Join-Path $TestDrive 'src'
        Remove-Item -Recurse -Force $AnimDir, $AnimSrc -ErrorAction SilentlyContinue
        Mock Get-Process {}
        $pin = @{ source = 'florensm/glazewm'; commit = 'd76641418f9642837b63817a8eeed7fbed4aadb5'; url = 'https://x/glazewm.zip'; sha256 = 'AB' }
    }
    It 'is used only for the commit config.json pins' {
        Mock Get-Prebuilt { @{ commit = 'abc'; url = 'u'; sha256 = 's' } }
        Mock Get-Config { @{ animations = @{ source = @{ commit = 'abc' } } } }
        (Get-AnimationPrebuilt).commit | Should -Be 'abc'
        Mock Get-Config { @{ animations = @{ source = @{ commit = 'def' } } } }
        Get-AnimationPrebuilt | Should -BeNullOrEmpty
    }
    It 'installs the official layout and records the commit' {
        $script:testZip = New-TestZip @{ 'glazewm.exe' = 'wm'; 'glazewm-watcher.exe' = 'watcher'; 'cli/glazewm.exe' = 'cli'; 'LICENSE.md' = 'GPL' }
        Mock Save-PinnedFile { Copy-Item $script:testZip $dest }
        Install-AnimationPrebuilt $pin
        Get-Content (Join-Path $AnimDir 'cli\glazewm.exe') | Should -Be 'cli'
        Get-Content (Join-Path $AnimDir 'glazewm-watcher.exe') | Should -Be 'watcher'
        (Read-Json (Join-Path $AnimDir 'build.json')).commit | Should -Be $pin.commit
        (Get-AnimationBuild).commit | Should -Be $pin.commit
    }
    It 'refuses a download that is missing a file' {
        $script:testZip = New-TestZip @{ 'glazewm.exe' = 'wm'; 'cli/glazewm.exe' = 'cli' }
        Mock Save-PinnedFile { Copy-Item $script:testZip $dest }
        { Install-AnimationPrebuilt $pin } | Should -Throw '*glazewm-watcher.exe*'
        Test-Path (Join-Path $AnimDir 'glazewm.exe') | Should -BeFalse
    }
    It 'puts back the downloaded build when nothing was built here' {
        Mock Get-AnimationPrebuilt { $pin }
        Mock Install-AnimationPrebuilt {}
        Restore-AnimationFiles
        Should -Invoke Install-AnimationPrebuilt -Times 1
    }
}
