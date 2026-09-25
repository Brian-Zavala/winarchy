# Pester tests: window-animation build selection, the reveal band, status font, CLI errors.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'apply', 'animations', 'transition') { . "$root\lib\$f.ps1" }
    $Code = $root
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
