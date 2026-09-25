# Window animations (experimental): GlazeWM built from its open animation pull request
# (glzr-io/glazewm#1392), which animates with DWM-thumbnail stand-ins inside the WM.
# The official GlazeWM stays installed; `omarchy-win animations on|off` switches between
# them. Built locally from source (GPL-3.0); nothing is redistributed.

$AnimDir = Join-Path $Data 'glazewm-animations'
$AnimSrc = Join-Path $Data 'build\glazewm'
$SwitchFlag = Join-Path $Data 'generated\glazewm-switch.flag'

function Get-AnimationBuild {
    $exe = Join-Path $AnimDir 'glazewm.exe'
    if (-not (Test-Path $exe) -or -not (Test-Path (Join-Path $AnimDir 'cli\glazewm.exe'))) { return $null }
    $info = Read-Json (Join-Path $AnimDir 'build.json')
    [ordered]@{ exe = $exe; cli = Join-Path $AnimDir 'cli\glazewm.exe'; commit = $info.commit; built = $info.built }
}

function Test-BuildTools {
    $missing = @()
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $missing += 'Git:  winget install -e --id Git.Git' }
    if (-not (Get-Command rustup -ErrorAction SilentlyContinue) -or -not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        $missing += 'Rust:  winget install -e --id Rustlang.Rustup'
    }
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $vc = if (Test-Path $vswhere) { & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath } else { $null }
    if (-not $vc) { $missing += 'Visual C++ build tools:  winget install -e --id Microsoft.VisualStudio.2022.BuildTools --override "--quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"' }
    $missing
}

# Clones the pinned commit, builds glazewm + cli + watcher, installs them next to each
# other in ~/.omarchy-win/glazewm-animations (the same layout as the official install).
function Invoke-AnimationBuild {
    $src = (Get-Config).animations.source
    $missing = @(Test-BuildTools)
    if ($missing) {
        Write-Host 'Building the animation version of GlazeWM needs:' -ForegroundColor Yellow
        $missing | ForEach-Object { Write-Host "  $_" }
        throw 'build tools missing (see above), then run: omarchy-win animations build'
    }
    Log "building GlazeWM with animations from $($src.repo)@$($src.commit.Substring(0, 12)) (about 10 minutes)"
    New-Item -ItemType Directory -Force $AnimSrc | Out-Null
    Push-Location $AnimSrc
    try {
        if (-not (Test-Path '.git')) { git init --quiet; git remote add origin "https://github.com/$($src.repo).git" }
        git fetch --depth 1 origin $src.commit
        if ($LASTEXITCODE) { throw "git fetch of $($src.commit) failed" }
        git checkout --quiet --force FETCH_HEAD
        # build.rs embeds the version: keep it in step with the official GlazeWM it is based on.
        $env:VERSION_NUMBER = $src.version
        $built = $false
        foreach ($toolchain in @('nightly', $src.fallbackToolchain) | Where-Object { $_ }) {
            Log "toolchain $toolchain"
            rustup toolchain install $toolchain --profile minimal --no-self-update
            if ($LASTEXITCODE) { continue }
            cargo "+$toolchain" build --release --locked -p wm -p wm-cli -p wm-watcher
            if (-not $LASTEXITCODE) { $built = $true; break }
            Log "build with $toolchain failed"
        }
        if (-not $built) { throw 'the GlazeWM animation build failed (see the output above)' }
        $out = Join-Path $AnimSrc 'target\release'
        # Stop our build if it is running, so its files can be replaced.
        $running = Get-Process glazewm -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$AnimDir*" }
        if ($running) { throw 'the animation build is running: omarchy-win animations off, then build again' }
        New-Item -ItemType Directory -Force (Join-Path $AnimDir 'cli') | Out-Null
        Copy-Item -Force (Join-Path $out 'glazewm.exe') (Join-Path $AnimDir 'glazewm.exe')
        Copy-Item -Force (Join-Path $out 'glazewm-watcher.exe') (Join-Path $AnimDir 'glazewm-watcher.exe')
        Copy-Item -Force (Join-Path $out 'glazewm-cli.exe') (Join-Path $AnimDir 'cli\glazewm.exe')
        Write-Json (Join-Path $AnimDir 'build.json') ([ordered]@{ repo = $src.repo; commit = $src.commit; built = (Get-Date).ToString('s') })
        Log "animation build ready: $AnimDir"
    } finally { Pop-Location; Remove-Item Env:VERSION_NUMBER -ErrorAction SilentlyContinue }
}

# Which GlazeWM should run: the animation build when animations are on and it exists.
function Get-SelectedGlazeWM($p) {
    $b = Get-AnimationBuild
    if ((Get-Config).animations.enabled -and $b) { return $b }
    [ordered]@{ exe = $p.glazewmOfficial; cli = $p.glazewmCliOfficial }
}

# The official GlazeWM runs with UI access, so its path can't be read from a normal
# process (Path comes back empty); our own build always can be.
function Get-GlazeWMPath($proc, $p) {
    if ($proc.Path) { $proc.Path } else { $p.glazewmOfficial }
}

# Restart GlazeWM when the running one isn't the selected build. wm-exit restores every
# window (hidden workspaces included) before the other build takes over.
function Switch-GlazeWM($p) {
    $want = $p.glazewm
    if (-not $want) { return }
    $running = @(Get-Process glazewm -ErrorAction SilentlyContinue)
    if ($running.Count -eq 1 -and (Get-GlazeWMPath $running[0] $p) -eq $want) { return }
    Write-Utf8 $SwitchFlag (Get-Date).ToString('s')
    foreach ($r in $running) {
        $cli = Join-Path (Split-Path (Get-GlazeWMPath $r $p)) 'cli\glazewm.exe'
        if (Test-Path $cli) { & $cli command wm-exit 2>$null | Out-Null }
        if (-not $r.WaitForExit(10000)) { Stop-Process -Id $r.Id -Force -ErrorAction SilentlyContinue }
    }
    Start-Sleep -Milliseconds 500
    Start-Process -FilePath $want -WorkingDirectory (Split-Path $want)
    Log "GlazeWM switched to $want"
}

function Set-Animations([bool]$on) {
    $user = Read-Json $ConfigFile -AsHashtable
    if (-not $user) { $user = [ordered]@{} }
    if (-not $user.animations) { $user.animations = @{} }
    $user.animations.enabled = $on
    Write-Json $ConfigFile $user 8
    # omarchy-wm.ahk re-applies config.json when it is saved; this change applies itself.
    Write-Utf8 (Join-Path $Generated 'config.selfwrite') (Get-Item $ConfigFile).LastWriteTime.ToString('yyyyMMddHHmmss')
}

function Invoke-Animations([string]$action) {
    switch ($action) {
        'build' { Invoke-AnimationBuild; Write-Host 'Turn them on with: omarchy-win animations on' }
        # Toggle > Window Animations before the first build: build, then switch.
        'setup' { Invoke-AnimationBuild; Invoke-Animations 'on' }
        'on' {
            if (-not (Get-AnimationBuild)) { throw 'not built yet: omarchy-win animations build (about 10 minutes)' }
            Set-Animations $true; Use-Lock { Invoke-Apply }
        }
        'off' { Set-Animations $false; Use-Lock { Invoke-Apply } }
        'toggle' { Invoke-Animations $(if ((Get-Config).animations.enabled) { 'off' } else { 'on' }) }
        default {
            $b = Get-AnimationBuild
            "window animations: $(if ((Get-Config).animations.enabled -and $b) { 'on' } else { 'off' })"
            "animation build:   $(if ($b) { "$($b.commit.Substring(0, 12)), built $($b.built)" } else { 'not built (omarchy-win animations build)' })"
            $r = Get-Process glazewm -ErrorAction SilentlyContinue | Select-Object -First 1
            "running GlazeWM:   $(if ($r) { Get-GlazeWMPath $r (Get-Paths) } else { 'not running' })"
        }
    }
}

# The `animations:` block for GlazeWM's config (only the animation build reads it; the
# official GlazeWM ignores unknown keys). Omarchy's timing, from default/hypr/looknfeel.lua:
# windows 3.79 easeOutQuint, windowsIn 4.1 popin 87%, windowsOut 1.49 linear, workspaces off.
function ConvertTo-AnimationsYaml($cfg) {
    $a = $cfg.animations
    if (-not $a.enabled -or -not (Get-AnimationBuild)) { return '# Window animations: off (turn on with: omarchy-win animations on)' }
    $ease = 'cubic_bezier(0.23, 1, 0.32, 1)'
    $ws = if ($a.workspaceSwitch) { 'true' } else { 'false' }
    @"
# Window animations (experimental build of glzr-io/glazewm#1392), Omarchy's timing.
animations:
  window_move:
    enabled: true
    duration_ms: $([int]$a.moveMs)
    easing: '$ease'
    threshold_px: 10
  window_resize:
    enabled: true
    duration_ms: $([int]$a.moveMs)
    easing: '$ease'
    threshold_px: 10
  window_open:
    enabled: true
    duration_ms: $([int]$a.openMs)
    easing: '$ease'
    style: 'zoom'
    opacity_from: 0.0
  window_close:
    enabled: true
    duration_ms: $([int]$a.closeMs)
    easing: 'linear'
    style: 'zoom'
    opacity_to: 0.0
  workspace_switch:
    enabled: $ws
    duration_ms: 250
    easing: 'ease_out_cubic'
    style: 'slide'
"@
}
