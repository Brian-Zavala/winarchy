<#
  Omarchy's screensaver (bin/omarchy-screensaver), for Windows Terminal: random
  terminal text effects over the branding text, on black, until a key is pressed.
  winarchy.ahk opens one fullscreen "Omarchy Screensaver" window per monitor and
  closes them all on any mouse/keyboard input, sleep or lock.

  Safety: ttfx gets an explicit --seed (it reads /dev/urandom otherwise, which doesn't
  exist on Windows, and aborts). If it still fails fast three times in a row, this falls
  back to the still logo instead of retrying - it never spins in a crash loop.
#>
param(
    [string]$Text = (Join-Path $env:USERPROFILE '.winarchy\branding\screensaver.txt'),
    [string]$Ttfx = (Join-Path $env:USERPROFILE '.cargo\bin\ttfx.exe')
)
$esc = [char]27
$log = Join-Path $env:USERPROFILE '.winarchy\logs\winarchy.log'
function Write-SsLog([string]$m) { try { Add-Content $log "$(Get-Date -Format 'HH:mm:ss') [screensaver] $m" } catch {} }

# Black background (OSC 11), hidden cursor, clean screen.
[Console]::Write("$esc]11;rgb:00/00/00$([char]7)$esc[?25l$esc[2J$esc[H")

# The terminal starts at its default size and grows to fullscreen a moment later;
# ttfx measures once at startup, so wait for the resize (omarchy-screensaver does too).
$deadline = [DateTime]::Now.AddSeconds(2)
$w0 = [Console]::WindowWidth
while ([DateTime]::Now -lt $deadline -and [Console]::WindowWidth -eq $w0) { Start-Sleep -Milliseconds 20 }
Start-Sleep -Milliseconds 100

function Show-StillLogo {
    [Console]::Write("$esc[2J$esc[H")
    if (Test-Path $Text) {
        $lines = @(Get-Content $Text)
        $top = [Math]::Max(0, [int](([Console]::WindowHeight - $lines.Count) / 2))
        [Console]::Write("$esc[$($top + 1);1H")
        foreach ($l in $lines) {
            $pad = [Math]::Max(0, [int](([Console]::WindowWidth - $l.Length) / 2))
            [Console]::WriteLine((' ' * $pad) + $l)
        }
    }
    [void][Console]::ReadKey($true)
    exit
}

if (-not (Test-Path $Ttfx) -or -not (Test-Path $Text)) { Show-StillLogo }

$fails = 0
while ($true) {
    $fx = @('-i', "`"$Text`"", '--seed', (Get-Random -Maximum 2147483647), '--frame-rate', '120',
            '--canvas-width', '0', '--canvas-height', '0', '--reuse-canvas', '--anchor-canvas', 'c', '--anchor-text', 'c',
            '--random-effect', '--no-eol', '--no-restore-cursor')
    $started = [DateTime]::Now
    $p = Start-Process -FilePath $Ttfx -ArgumentList $fx -NoNewWindow -PassThru
    while (-not $p.HasExited) {
        if ([Console]::KeyAvailable) { try { $p.Kill() } catch {}; exit }
        Start-Sleep -Milliseconds 100
    }
    # A run that ends within 2 s (or with an error) counts as a failure.
    if ($p.ExitCode -ne 0 -or ([DateTime]::Now - $started).TotalSeconds -lt 2) {
        $fails++
        if ($fails -ge 3) { Write-SsLog "ttfx failed $fails times (exit $($p.ExitCode)); showing the still logo"; Show-StillLogo }
    } else { $fails = 0 }
    Start-Sleep -Milliseconds 400
}
