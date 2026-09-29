# Tailscale: Omarchy Quattro's omarchy.tailscale bar widget, on Windows. It is never part of
# a default install. The installer offers it (default No, never under -Yes), and
# Omarchy menu > Install > Service > Tailscale adds it any time, as Omarchy's
# omarchy-install-service-tailscale does. The bar icon shows up by itself once
# tailscale.exe exists (winarchy.ahk TailscaleStatus), and goes away again when removed.

function Get-TailscaleExe {
    Join-Path $env:ProgramFiles 'Tailscale\tailscale.exe'
}

function Test-TailscaleInstalled {
    Test-Path (Get-TailscaleExe)
}

# After the MSI: start Tailscale's own app, which walks through signing in (Omarchy runs
# `tailscale up`, which opens the same login page), then have the bar look again now
# instead of at its next 30 s tick.
function Start-TailscaleApp {
    $ipn = Join-Path $env:ProgramFiles 'Tailscale\tailscale-ipn.exe'
    if ((Test-Path $ipn) -and -not (Get-Process tailscale-ipn -ErrorAction SilentlyContinue)) {
        Start-Process $ipn
    }
    Write-Ok 'Tailscale: sign in in the window it opened. The bar shows its icon (click: machines, right click: on/off).'
    $p = Get-Paths
    if ($p.ahk) { Start-Process -FilePath $p.ahk -ArgumentList "`"$Code\ahk\menu.ahk`"", 'tailscale', 'refresh' }
}

# The install question. Asked once: the answer is kept (tailscaleOffered), so a reinstall
# that restores your settings does not ask again.
function Install-TailscaleStep([switch]$Restoring) {
    if (Test-TailscaleInstalled) { Write-Ok "Tailscale: $(Get-TailscaleExe)"; return }
    $later = 'Omarchy menu > Install > Service > Tailscale adds it any time.'
    $cfg = Read-Json $ConfigFile -AsHashtable
    if ($Restoring -and $cfg -and $cfg.Contains('tailscaleOffered')) { return }
    Write-Step 'Tailscale (optional)'
    Write-Ok 'A private network between your own devices (Omarchy Quattro has it in the bar):'
    Write-Ok 'reach this PC from your laptop or phone anywhere, send files, use exit nodes.'
    Write-Ok 'It needs a Tailscale account and one admin prompt to install.'
    if ($script:AssumeYes) { Write-Ok "Not installed in an unattended install. $later"; return }
    $yes = Read-YesNo 'Install Tailscale?' $false
    try { Set-ConfigValue 'tailscaleOffered' $true } catch { Log "tailscaleOffered: $($_.Exception.Message)" }
    if (-not $yes) { Write-Ok "Skipped. $later"; return }
    # A failed optional extra must not take the whole install down with it.
    try { Install-CatalogItem 'tailscale' } catch { Write-Ok "Tailscale install failed (skipping): $($_.Exception.Message)" }
}
