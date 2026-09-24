<#
  Omarchy's screensaver (bin/omarchy-screensaver), for Windows Terminal: random
  terminal text effects over the branding text, on black, until a key is pressed.
  omarchy-wm.ahk opens one fullscreen "Omarchy Screensaver" window per monitor and
  closes them all on any mouse/keyboard input.
#>
param(
    [string]$Text = (Join-Path $env:USERPROFILE '.omarchy-win\branding\screensaver.txt'),
    [string]$Ttfx = (Join-Path $env:USERPROFILE '.cargo\bin\ttfx.exe')
)
$esc = [char]27
# Black background (OSC 11), hidden cursor, clean screen.
[Console]::Write("$esc]11;rgb:00/00/00$([char]7)$esc[?25l$esc[2J$esc[H")

# The terminal starts at its default size and grows to fullscreen a moment later;
# ttfx measures once at startup, so wait for the resize (omarchy-screensaver does too).
$deadline = [DateTime]::Now.AddSeconds(2)
$w0 = [Console]::WindowWidth
while ([DateTime]::Now -lt $deadline -and [Console]::WindowWidth -eq $w0) { Start-Sleep -Milliseconds 20 }
Start-Sleep -Milliseconds 100

if (-not (Test-Path $Ttfx) -or -not (Test-Path $Text)) {
    # No effects engine: a still logo is still better than nothing.
    if (Test-Path $Text) { Get-Content $Text | Write-Host -ForegroundColor DarkGray }
    [void][Console]::ReadKey($true); exit
}

$fx = @('-i', "`"$Text`"", '--frame-rate', '120', '--canvas-width', '0', '--canvas-height', '0',
        '--reuse-canvas', '--anchor-canvas', 'c', '--anchor-text', 'c', '--random-effect', '--no-eol', '--no-restore-cursor')
while ($true) {
    $p = Start-Process -FilePath $Ttfx -ArgumentList $fx -NoNewWindow -PassThru
    while (-not $p.HasExited) {
        if ([Console]::KeyAvailable) { try { $p.Kill() } catch {}; exit }
        Start-Sleep -Milliseconds 100
    }
}
