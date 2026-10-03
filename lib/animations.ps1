# Window animations (experimental): GlazeWM built from its open animation pull request
# (glzr-io/glazewm#1392), which animates with DWM-thumbnail stand-ins inside the WM.
# The official GlazeWM stays installed; `winarchy animations on|off` switches between
# them. Setup downloads the build .github/workflows/prebuilt.yml published for the pinned
# commit (GPL-3.0, released with its complete source); `winarchy animations build`, or a
# commit with no published build, compiles it on this PC instead.

$AnimDir = Join-Path $Data 'glazewm-animations'
$AnimSrc = Join-Path $Data 'build\glazewm'
$SwitchFlag = Join-Path $Data 'generated\glazewm-switch.flag'

# All three of its files ($AnimFiles), or $null: Defender can take any one of them, and a
# build missing one is put back (Restore-AnimationFiles) rather than run.
function Get-AnimationBuild {
    $exe = Join-Path $AnimDir 'glazewm.exe'
    foreach ($f in $AnimFiles.Values) { if (-not (Test-Path (Join-Path $AnimDir $f))) { return $null } }
    $info = Read-Json (Join-Path $AnimDir 'build.json')
    [ordered]@{ exe = $exe; cli = Join-Path $AnimDir 'cli\glazewm.exe'; commit = $info.commit; built = $info.built }
}

$VcOverride = '--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
$BuildTools = @(
    @{ name = 'Git'; id = 'Git.Git'; test = { [bool](Get-Command git -ErrorAction SilentlyContinue) } }
    # ~/.cargo/bin too: a terminal opened before Rust was installed lacks it on PATH, and
    # winget's rustup-init on a PC that has Rust re-downloads the whole toolchain.
    @{ name = 'Rust'; id = 'Rustlang.Rustup'; test = {
            $bin = Join-Path $env:USERPROFILE '.cargo\bin'
            ((Get-Command rustup -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $bin 'rustup.exe'))) -and
                ((Get-Command cargo -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $bin 'cargo.exe'))) } }
    @{ name = 'Visual C++ build tools'; id = 'Microsoft.VisualStudio.2022.BuildTools'; override = $VcOverride; test = {
            $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
            (Test-Path $vswhere) -and [bool](& $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath) } }
)

function Get-MissingBuildTools { @($BuildTools | Where-Object { -not (& $_.test) }) }

function Test-BuildTools {
    Get-MissingBuildTools | ForEach-Object {
        $override = if ($_.override) { ' --override "{0}"' -f $_.override } else { '' }
        '{0}:  winget install -e --id {1}{2}' -f $_.name, $_.id, $override
    }
}

# winget installs them; the new PATH entries only reach this session by reading them back.
function Install-BuildTools {
    foreach ($t in Get-MissingBuildTools) {
        Log "installing $($t.name) (for the animation build)"
        $a = @(Get-WingetArgs install $t.id $null)
        if ($t.override) { $a += @('--override', $t.override) }
        $r = Invoke-Unattended 'winget' $a 3600
        if (-not $r.Ok -and $r.Code -notin $WingetExitOk) { Log "$($t.name): winget $($r.Reason)" }
    }
    Update-ProcessPath
    $env:Path += ';' + (Join-Path $env:USERPROFILE '.cargo\bin')
}

# The build of the pinned commit is installed (built here or downloaded).
function Test-AnimationBuildInPlace {
    $b = Get-AnimationBuild
    [bool]($b -and $b.commit -eq (Get-Config).animations.source.commit)
}

# The build for the pinned commit is on disk already (a reinstall, or Defender took the
# installed copy): installing it needs no compiler.
function Test-AnimationBuildOutput {
    (Test-Path (Join-Path $AnimSrc 'target\release\glazewm.exe')) -and
        (Read-Json (Join-Path $AnimDir 'build.json')).commit -eq (Get-Config).animations.source.commit
}

# Clones the pinned commit, builds glazewm + cli + watcher, installs them next to each
# other in ~/.winarchy/glazewm-animations (the same layout as the official install).
function Invoke-AnimationBuild {
    $src = (Get-Config).animations.source
    $missing = @(Test-BuildTools)
    if ($missing) {
        Write-Host 'Building the animation version of GlazeWM needs:' -ForegroundColor Yellow
        $missing | ForEach-Object { Write-Host "  $_" }
        throw 'build tools missing (see above), then run: winarchy animations build'
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
        Install-AnimationFiles
        Write-Json (Join-Path $AnimDir 'build.json') ([ordered]@{ repo = $src.repo; commit = $src.commit; built = (Get-Date).ToString('s') })
        Log "animation build ready: $AnimDir"
    } finally { Pop-Location; Remove-Item Env:VERSION_NUMBER -ErrorAction SilentlyContinue }
}

# build output -> installed name
$AnimFiles = [ordered]@{ 'glazewm.exe' = 'glazewm.exe'; 'glazewm-watcher.exe' = 'glazewm-watcher.exe'; 'glazewm-cli.exe' = 'cli\glazewm.exe' }

# Its files can't be replaced while it runs.
function Assert-AnimationBuildStopped {
    $running = Get-Process glazewm -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$AnimDir*" }
    if ($running) { throw 'the animation build is running: winarchy animations off, then try again' }
}

# Copies the build output into place (after a build, or to put back what antivirus removed).
function Install-AnimationFiles {
    $out = Join-Path $AnimSrc 'target\release'
    if (-not (Test-Path (Join-Path $out 'glazewm.exe'))) { throw 'no animation build to install: winarchy animations build (about 10 minutes)' }
    Assert-AnimationBuildStopped
    New-Item -ItemType Directory -Force (Join-Path $AnimDir 'cli') | Out-Null
    foreach ($f in $AnimFiles.GetEnumerator()) { Copy-Item -Force (Join-Path $out $f.Key) (Join-Path $AnimDir $f.Value) }
}

# The published build of the pinned commit, or $null: none yet, or config.json points
# animations.source at another commit (that one is built here).
function Get-AnimationPrebuilt {
    $pin = Get-Prebuilt 'glazewm-animations'
    if ($pin -and $pin.commit -eq (Get-Config).animations.source.commit) { $pin }
}

# Downloads the published build (its zip holds the installed layout: glazewm.exe,
# glazewm-watcher.exe, cli\glazewm.exe) and puts it in place, no compiler needed.
function Install-AnimationPrebuilt($pin) {
    Assert-AnimationBuildStopped
    $tmp = Join-Path ([IO.Path]::GetTempPath()) "winarchy-glazewm-$([guid]::NewGuid().ToString('N'))"
    try {
        Log "downloading the GlazeWM animation build ($($pin.commit.Substring(0, 12)))"
        Save-PinnedFile $pin.url $pin.sha256 "$tmp.zip"
        Expand-Archive -LiteralPath "$tmp.zip" -DestinationPath $tmp -Force
        foreach ($f in $AnimFiles.Values) {
            if (-not (Test-Path -LiteralPath (Join-Path $tmp $f))) { throw "the download has no $f" }
        }
        New-Item -ItemType Directory -Force (Join-Path $AnimDir 'cli') | Out-Null
        foreach ($f in $AnimFiles.Values) { Copy-Item -Force -LiteralPath (Join-Path $tmp $f) (Join-Path $AnimDir $f) }
        Write-Json (Join-Path $AnimDir 'build.json') ([ordered]@{ repo = $pin.source; commit = $pin.commit; built = (Get-Date).ToString('s'); prebuilt = $pin.url })
        Log "animation build ready: $AnimDir (downloaded)"
    } finally { Remove-Item -LiteralPath $tmp, "$tmp.zip" -Recurse -Force -ErrorAction SilentlyContinue }
}

# Puts back a build that is gone (Defender took it): the one built here, else the download.
function Restore-AnimationFiles {
    if (Test-Path (Join-Path $AnimSrc 'target\release\glazewm.exe')) { return Install-AnimationFiles }
    if ($pin = Get-AnimationPrebuilt) { return Install-AnimationPrebuilt $pin }
    Install-AnimationFiles
}

# Defender's behaviour model can quarantine the build (Behavior:Win32/Persistence.A!ml): it
# is unsigned, built on this PC and starts at every login. Defender keeps a record of it.
function Get-AnimationQuarantine {
    try { @(Get-MpThreatDetection -ErrorAction Stop | Where-Object { "$($_.Resources)" -like "*$AnimDir*" }) } catch { @() }
}

function Test-DefenderActive {
    try { [bool](Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled } catch { $false }
}

function Test-AnimationExclusionNeeded { (Test-DefenderActive) -and -not (Test-Journaled 'defender|animations') }

# One UAC prompt: a Defender exclusion for the build's three files only (not the folder),
# journaled so uninstall takes it back out. Paths need not exist yet: added before the
# files are copied, Defender never gets a look at them.
function Add-AnimationExclusion {
    $paths = @($AnimFiles.Values | ForEach-Object { Join-Path $AnimDir $_ })
    $list = ($paths | ForEach-Object { "'$_'" }) -join ','
    Write-Host 'Windows will ask for admin permission (Defender exclusions are admin-only).'
    Start-Process (Get-Paths).powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $(ConvertTo-EncodedCommand "Add-MpPreference -ExclusionPath $list")"
    [void](Add-JournalEntry @{ kind = 'defender'; key = 'defender|animations'; paths = $paths })
    Log 'Defender: the animation build is excluded from scanning'
}

# After `animations build`: asked, never assumed (-Yes skips it), since it lowers Defender's guard.
function Request-AnimationExclusion {
    if ($script:AssumeYes -or -not (Test-AnimationExclusionNeeded)) { return }
    Write-Host 'Windows Defender may remove this build: it is unsigned and made on this PC.' -ForegroundColor Yellow
    if (Read-YesNo 'Exclude its three files from Defender scanning (one admin prompt)?' $true) { Add-AnimationExclusion }
    else { Write-Host '    If it disappears later: winarchy animations allow' }
}

# Everything window animations need, in one go: build tools, the build (or the one on disk),
# the Defender exclusion, the admin game helper (the build can't have UI access, so the
# helper carries Super+1..0 over admin windows), then switch.
function Invoke-AnimationSetup {
    if (Test-AnimationExclusionNeeded) { Add-AnimationExclusion }
    if (Test-AnimationBuildInPlace) {
        Log 'animation build: already in place'
    } elseif (Test-AnimationBuildOutput) {
        Install-AnimationFiles; Log 'animation build installed from the earlier build'
    } else {
        $done = $false
        if ($pin = Get-AnimationPrebuilt) {
            try { Install-AnimationPrebuilt $pin; $done = $true }
            catch { Log "animation build download failed ($($_.Exception.Message)): building it here instead" }
        }
        if (-not $done) {
            Install-BuildTools
            Invoke-AnimationBuild
        }
    }
    # Without it animations still work; only the keys over admin windows don't (doctor says so).
    if (-not (Test-GameHelperCurrent)) {
        try { Enable-GameHelper } catch { Log "game helper not set up ($($_.Exception.Message)): winarchy game-setup" }
    }
    Invoke-Animations 'on'
}

# What the install says before asking: the good and the bad in plain words, so the choice
# is an informed one. Only the cost differs between a first build and a restore.
function Get-AnimationPitch([bool]$ready, [string[]]$tools, [bool]$prebuilt) {
    $cost = if ($ready) { 'It is already built on this PC, so turning it back on takes a few seconds.' }
    elseif ($prebuilt) { 'It downloads a ready-made build (a few MB), so it takes a few seconds.' }
    elseif ($tools) {
        $size = if ($tools -match 'Visual C\+\+') { 'several GB' } else { 'a few hundred MB' }
        "It is built on this PC: first it installs $($tools -join ', ') (free, $size), then compiles for about 10 minutes."
    }
    else { 'It is built on this PC: about 10 minutes of compiling, and you can keep working meanwhile.' }
    @(
        'Omarchy on Linux glides windows into place: they zoom in when they open and slide'
        'when they move or resize. Windows can do that too, with a test version of GlazeWM'
        '(the window manager) that has animations added.'
        ''
        'The good:'
        '  + Windows open, move and resize smoothly, like on Omarchy. Your keys stay the same.'
        '  + Easy to undo: "winarchy animations off", or Toggle > Window Animations in the menu.'
        '  + If it crashes twice in 5 minutes, or Defender removes it, winarchy switches back to'
        '    the normal GlazeWM by itself.'
        ''
        'The catch:'
        '  - It is experimental: movement can look a little janky now and then.'
        "  - $cost"
        '  - It is not signed, so Windows Defender may remove it. winarchy asks Windows to'
        '    leave just its three files alone (an admin prompt; uninstall takes that back out).'
        '  - Windows gives unsigned programs no keys while an admin window is in front, like a'
        '    game run as administrator. A small helper passes Super + 1..0 through (another admin prompt).'
        ''
        'You can add it any time later with: winarchy animations setup'
    )
}

# The install's last step: opt-in, since it is experimental and heavy. A build already on
# disk turns the question into a quick restore, so there the default flips to yes.
function Invoke-AnimationOffer {
    if ((Get-Config).animations.enabled -and (Get-AnimationBuild)) { return }
    Write-Step 'Window animations (optional, experimental)'
    if ($script:AssumeYes) { Write-Ok 'Skipped (unattended): winarchy animations setup adds them.'; return }
    $ready = (Test-AnimationBuildOutput) -or (Test-AnimationBuildInPlace)
    $prebuilt = -not $ready -and [bool](Get-AnimationPrebuilt)
    $tools = if ($ready -or $prebuilt) { @() } else { @(Get-MissingBuildTools | ForEach-Object name) }
    Write-Host ''
    foreach ($line in Get-AnimationPitch $ready $tools $prebuilt) {
        $color = switch -Wildcard ($line) { '  + *' { 'Green' } '  - *' { 'Yellow' } default { 'Gray' } }
        Write-Host "    $line" -ForegroundColor $color
    }
    Write-Host ''
    $q = if ($ready) { 'Turn window animations back on?' } else { 'Add window animations?' }
    if (-not (Read-YesNo $q $ready)) { Write-Ok 'Skipped: winarchy animations setup adds them any time.'; return }
    try { Invoke-AnimationSetup; Write-Ok 'Window animations on (winarchy animations off turns them off).' }
    catch {
        Log "animations: FAILED: $($_.Exception.Message)"
        Add-Unfinished "window animations not set up ($($_.Exception.Message)); the official GlazeWM is running. Try again: winarchy animations setup"
    }
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
# window (hidden workspaces included) before the other build takes over. -NoRestart (the
# install's apply): with none running, leave the start to Start-Everything, once.
function Switch-GlazeWM($p, [switch]$NoRestart) {
    $want = $p.glazewm
    if (-not $want) { return }
    $running = @(Get-GlazeWmProcess)      # the WM only: the auto-tiling watcher keeps a CLI alive too
    if (-not $running -and ($NoRestart -or (Test-GlazeWmMutex))) { return }
    if ($running.Count -eq 1 -and (Get-GlazeWMPath $running[0] $p) -eq $want) { return }
    Write-Utf8 $SwitchFlag (Get-Date).ToString('s')
    foreach ($r in $running) {
        $cli = Join-Path (Split-Path (Get-GlazeWMPath $r $p)) 'cli\glazewm.exe'
        if (Test-Path $cli) { & $cli command wm-exit 2>$null | Out-Null }
        if (-not $r.WaitForExit(10000)) { Stop-Process -Id $r.Id -Force -ErrorAction SilentlyContinue }
    }
    Start-Sleep -Milliseconds 500
    Start-GlazeWM $want
    Log "GlazeWM switched to $want"
}

function Set-Animations([bool]$on) {
    Set-ConfigValue 'animations.enabled' $on
}

function Invoke-Animations([string]$action) {
    switch ($action) {
        'build' { Invoke-AnimationBuild; Request-AnimationExclusion; Write-Host 'Turn them on with: winarchy animations on' }
        # Toggle > Window Animations while the build is missing (never built, or Defender took it).
        'setup' { Invoke-AnimationSetup }
        'allow' {
            Add-AnimationExclusion
            if (-not (Get-AnimationBuild)) { Restore-AnimationFiles; Log 'animation build restored' }
            Use-Lock { Invoke-Apply }
        }
        'on' {
            if (-not (Get-AnimationBuild)) { throw 'not built yet: winarchy animations build (about 10 minutes)' }
            Set-Animations $true; Use-Lock { Invoke-Apply }
        }
        'off' { Set-Animations $false; Use-Lock { Invoke-Apply } }
        'toggle' { Invoke-Animations $(if ((Get-Config).animations.enabled) { 'off' } else { 'on' }) }
        default {
            $b = Get-AnimationBuild
            "window animations: $(if ((Get-Config).animations.enabled -and $b) { 'on' } else { 'off' })"
            "animation build:   $(if ($b) { "$($b.commit.Substring(0, 12)), built $($b.built)" } elseif (Get-AnimationQuarantine) { 'removed by Windows Defender (winarchy animations allow)' } else { 'not built (winarchy animations build)' })"
            $r = Get-GlazeWmProcess | Select-Object -First 1
            "running GlazeWM:   $(if ($r) { Get-GlazeWMPath $r (Get-Paths) } else { 'not running' })"
        }
    }
}

# The `animations:` block for GlazeWM's config (only the animation build reads it; the
# official GlazeWM ignores unknown keys). Omarchy's timing, from default/hypr/looknfeel.lua:
# windows 3.79 easeOutQuint, windowsIn 4.1 popin 87%, windowsOut 1.49 linear, workspaces off.
# No opacity fades: the build fades by changing the real window's transparency, and an
# interrupted fade left windows (Windows Terminal) almost invisible.
function ConvertTo-AnimationsYaml($cfg) {
    $a = $cfg.animations
    if (-not $a.enabled -or -not (Get-AnimationBuild)) { return '# Window animations: off (turn on with: winarchy animations on)' }
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
    opacity_from: 1.0
  window_close:
    enabled: true
    duration_ms: $([int]$a.closeMs)
    easing: 'linear'
    style: 'zoom'
    opacity_to: 1.0
  workspace_switch:
    enabled: $ws
    duration_ms: 250
    easing: 'ease_out_cubic'
    style: 'slide'
"@
}
