# Pester tests: window-animation build selection, the reveal band, status font, CLI errors.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'apply', 'animations', 'transition') { . "$root\lib\$f.ps1" }
    $Code = $root
    # Log lines from tests go to a scratch log, never the real one.
    $LogFile = Join-Path $TestDrive 'winarchy.log'
}

Describe 'Window animations' {
    It 'writes only a comment while animations are off' {
        Mock Get-AnimationBuild { @{ exe = 'x' } }
        ConvertTo-AnimationsYaml @{ animations = @{ enabled = $false } } | Should -Match '^# Window animations: off'
    }
    It 'writes Omarchy''s timing when on and built' {
        Mock Get-AnimationBuild { @{ exe = 'x' } }
        $y = ConvertTo-AnimationsYaml @{ animations = @{ enabled = $true; moveMs = 379; openMs = 410; closeMs = 149; workspaceSwitch = $false } }
        $y | Should -Match 'window_move:\s+enabled: true\s+duration_ms: 379'
        $y | Should -Match "easing: 'cubic_bezier\(0.23, 1, 0.32, 1\)'"
        $y | Should -Match 'window_close:[\s\S]*duration_ms: 149'
        $y | Should -Match 'workspace_switch:\s+enabled: false'
    }
    It 'stays off when the build is missing' {
        Mock Get-AnimationBuild { $null }
        ConvertTo-AnimationsYaml @{ animations = @{ enabled = $true } } | Should -Match '^# Window animations: off'
    }
    It 'selects the animation build only when on and built' {
        $p = @{ glazewmOfficial = 'C:\official\glazewm.exe'; glazewmCliOfficial = 'C:\official\cli\glazewm.exe' }
        Mock Get-AnimationBuild { @{ exe = 'C:\anim\glazewm.exe'; cli = 'C:\anim\cli\glazewm.exe' } }
        Mock Get-Config { @{ animations = @{ enabled = $true } } }
        (Get-SelectedGlazeWM $p).exe | Should -Be 'C:\anim\glazewm.exe'
        Mock Get-Config { @{ animations = @{ enabled = $false } } }
        (Get-SelectedGlazeWM $p).exe | Should -Be 'C:\official\glazewm.exe'
        Mock Get-Config { @{ animations = @{ enabled = $true } } }
        Mock Get-AnimationBuild { $null }
        (Get-SelectedGlazeWM $p).cli | Should -Be 'C:\official\cli\glazewm.exe'
    }
}

Describe 'Animation build and Defender' {
    BeforeEach {
        $AnimDir = Join-Path $TestDrive 'anim'
        $AnimSrc = Join-Path $TestDrive 'src'
        Remove-Item -Recurse -Force $AnimDir, $AnimSrc -ErrorAction SilentlyContinue
    }
    It 'finds only detections of the animation build' {
        function Get-MpThreatDetection {}
        Mock Get-MpThreatDetection { @(
                [pscustomobject]@{ Resources = @("file:_$AnimDir\glazewm.exe") },
                [pscustomobject]@{ Resources = @('file:_C:\other\thing.exe') }) }
        @(Get-AnimationQuarantine).Count | Should -Be 1
    }
    It 'finds nothing when Defender is unavailable' {
        function Get-MpThreatDetection {}
        Mock Get-MpThreatDetection { throw 'no Defender' }
        @(Get-AnimationQuarantine).Count | Should -Be 0
    }
    It 'puts the build output back in the official layout' {
        $out = Join-Path $AnimSrc 'target\release'
        New-Item -ItemType Directory -Force $out | Out-Null
        foreach ($f in 'glazewm.exe', 'glazewm-watcher.exe', 'glazewm-cli.exe') { Set-Content (Join-Path $out $f) $f }
        Install-AnimationFiles
        Get-Content (Join-Path $AnimDir 'cli\glazewm.exe') | Should -Be 'glazewm-cli.exe'
        Test-Path (Join-Path $AnimDir 'glazewm-watcher.exe') | Should -BeTrue
    }
    It 'says to build when there is no build output' {
        { Install-AnimationFiles } | Should -Throw '*winarchy animations build*'
    }
    It 'never adds the exclusion unattended' {
        function Test-Journaled {}
        Mock Test-DefenderActive { $true }
        Mock Test-Journaled { $false }
        Mock Add-AnimationExclusion {}
        $script:AssumeYes = $true
        try { Request-AnimationExclusion } finally { $script:AssumeYes = $false }
        Should -Invoke Add-AnimationExclusion -Times 0
    }
}

Describe 'Animation setup (install offer)' {
    BeforeAll {
        # From lib/setup.ps1 and lib/targets.ps1, which this file does not load.
        function Write-Step {} ; function Write-Ok {}
        function Add-Unfinished([string]$what) {} ; function Read-YesNo([string]$question, [bool]$default) {}
        function Test-GameHelperCurrent {} ; function Enable-GameHelper {}
    }
    BeforeEach {
        $script:order = [Collections.Generic.List[string]]::new()
        Mock Get-Config { @{ animations = @{ enabled = $false; source = @{ commit = 'abc' } } } }
        Mock Get-AnimationBuild { $null }
        Mock Test-AnimationExclusionNeeded { $true }
        Mock Add-AnimationExclusion { $script:order.Add('exclude') }
        Mock Install-AnimationFiles { $script:order.Add('install') }
        Mock Install-BuildTools { $script:order.Add('tools') }
        Mock Invoke-AnimationBuild { $script:order.Add('build') }
        Mock Get-AnimationPrebuilt { $null }
        Mock Install-AnimationPrebuilt { $script:order.Add('download') }
        Mock Test-GameHelperCurrent { $true }
        Mock Invoke-Animations {}
        Mock Read-YesNo { $true }
    }
    It 'is skipped unattended' {
        $script:AssumeYes = $true
        try { Invoke-AnimationOffer } finally { $script:AssumeYes = $false }
        Should -Invoke Read-YesNo -Times 0
        $script:order.Count | Should -Be 0
    }
    It 'is not offered while animations already run' {
        Mock Get-Config { @{ animations = @{ enabled = $true } } }
        Mock Get-AnimationBuild { @{ exe = 'x' } }
        Invoke-AnimationOffer
        Should -Invoke Read-YesNo -Times 0
    }
    It 'defaults to no for a fresh build and to yes for a restore' {
        Mock Test-AnimationBuildOutput { $false }
        Mock Get-MissingBuildTools { @() }
        Mock Read-YesNo { $false }
        Invoke-AnimationOffer
        Should -Invoke Read-YesNo -ParameterFilter { $default -eq $false }
        Mock Test-AnimationBuildOutput { $true }
        Invoke-AnimationOffer
        Should -Invoke Read-YesNo -ParameterFilter { $default -eq $true }
    }
    It 'restores the build on disk without compiling, exclusion first' {
        Mock Test-AnimationBuildOutput { $true }
        Invoke-AnimationOffer
        $script:order -join ',' | Should -Be 'exclude,install'
        Should -Invoke Invoke-Animations -ParameterFilter { $action -eq 'on' }
    }
    It 'installs tools and builds when nothing is built, exclusion first' {
        Mock Test-AnimationBuildOutput { $false }
        Mock Get-MissingBuildTools { @() }
        Invoke-AnimationOffer
        $script:order -join ',' | Should -Be 'exclude,tools,build'
    }
    It 'downloads the published build instead of compiling, exclusion first' {
        Mock Test-AnimationBuildOutput { $false }
        Mock Get-AnimationPrebuilt { @{ commit = 'abc'; url = 'u'; sha256 = 's' } }
        Invoke-AnimationOffer
        $script:order -join ',' | Should -Be 'exclude,download'
        Should -Invoke Invoke-Animations -ParameterFilter { $action -eq 'on' }
    }
    It 'compiles here when the download fails' {
        Mock Test-AnimationBuildOutput { $false }
        Mock Get-MissingBuildTools { @() }
        Mock Get-AnimationPrebuilt { @{ commit = 'abc'; url = 'u'; sha256 = 's' } }
        Mock Install-AnimationPrebuilt { throw 'the download does not match its pinned SHA-256' }
        Invoke-AnimationOffer
        $script:order -join ',' | Should -Be 'exclude,tools,build'
    }
    It 'leaves an installed build of the pinned commit alone' {
        Mock Test-AnimationBuildOutput { $false }
        Mock Get-AnimationBuild { @{ exe = 'x'; commit = 'abc' } }
        Invoke-AnimationOffer
        $script:order -join ',' | Should -Be 'exclude'
        Should -Invoke Read-YesNo -ParameterFilter { $default -eq $true }
    }
    It 'keeps going when the game helper prompt is declined' {
        Mock Test-AnimationBuildOutput { $true }
        Mock Test-GameHelperCurrent { $false }
        Mock Enable-GameHelper { throw 'declined' }
        Invoke-AnimationOffer
        Should -Invoke Invoke-Animations -ParameterFilter { $action -eq 'on' }
    }
    It 'explains the good and the catch before asking, with the right cost' {
        $fresh = (Get-AnimationPitch $false @('Rust')) -join "`n"
        $fresh | Should -Match 'The good:'
        $fresh | Should -Match 'The catch:'
        $fresh | Should -Match 'installs Rust \(free, a few hundred MB\)'
        $fresh | Should -Match 'Defender'
        (Get-AnimationPitch $false @('Rust', 'Visual C++ build tools')) -join "`n" | Should -Match 'several GB'
        (Get-AnimationPitch $true @()) -join "`n" | Should -Match 'already built on this PC'
        $download = (Get-AnimationPitch $false @() $true) -join "`n"
        $download | Should -Match 'ready-made build'
        $download | Should -Not -Match 'compil'
    }
    It 'reports a failed build as unfinished, not as a crash' {
        Mock Test-AnimationBuildOutput { $false }
        Mock Get-MissingBuildTools { @() }
        Mock Invoke-AnimationBuild { throw 'cargo broke' }
        Mock Add-Unfinished {}
        { Invoke-AnimationOffer } | Should -Not -Throw
        Should -Invoke Add-Unfinished -ParameterFilter { $what -like '*cargo broke*winarchy animations setup*' }
    }
}

Describe 'Wallpaper reveal band' {
    BeforeAll { Add-Type -AssemblyName WindowsBase }
    It 'starts closed and leans like Omarchy''s (slant -0.18)' {
        $pts = Get-RevealBand 1000 500 0
        $pts[0].X | Should -Be $pts[1].X
        $pts[0].X | Should -BeGreaterThan $pts[3].X      # top centre right of bottom centre
    }
    It 'covers the whole surface when done' {
        $pts = Get-RevealBand 1000 500 1
        $pts[0].X | Should -BeLessOrEqual 0
        $pts[1].X | Should -BeGreaterOrEqual 1000
        $pts[3].X | Should -BeLessOrEqual 0
        $pts[2].X | Should -BeGreaterOrEqual 1000
    }
}

Describe 'Status' {
    It 'reports the effective font when none was picked' {
        $Pack = Join-Path $TestDrive 'pack'
        Mock Read-State { @{} }       # not this PC's state.json (its font may be picked)
        Write-Status @{ theme = 't'; background = 'b' }
        (Read-Json (Join-Path $Pack 'status.json')).font | Should -Be 'JetBrainsMono Nerd Font'
    }
}

Describe 'CLI errors' {
    It 'logs FAILED and exits 1' {
        $home2 = Join-Path $TestDrive 'home'
        New-Item -ItemType Directory -Force $home2 | Out-Null
        $cli = Join-Path $root 'bin\winarchy.ps1'
        $saved = $env:USERPROFILE
        try {
            $env:USERPROFILE = $home2
            & (Get-Process -Id $PID).Path -NoProfile -File $cli theme-set no-such-theme *> $null
            $LASTEXITCODE | Should -Be 1
        } finally { $env:USERPROFILE = $saved }
        Get-Content (Join-Path $home2 '.winarchy\logs\winarchy.log') -Raw | Should -Match '\[theme-set\] FAILED: .*no-such-theme'
    }
}
