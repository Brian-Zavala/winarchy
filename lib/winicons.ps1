# Per-app icons for the bar's chevron flyout (windows.json, written by winarchy.ahk).
# Extracted lazily and cached forever under $Pack\icons\<key>.png: winarchy.ahk asks for
# a given exe's icon at most once (it checks the file exists before calling this).

function Update-WindowIcon {
    param([Parameter(Mandatory)][string]$ExePath, [Parameter(Mandatory)][string]$Key)
    $dir = Join-Path $Pack 'icons'
    $dest = Join-Path $dir "$Key.png"
    if ((Test-Path $dest) -or -not (Test-Path -LiteralPath $ExePath)) { return }
    New-Item -ItemType Directory -Force $dir | Out-Null
    Add-Type -AssemblyName System.Drawing
    $icon = $null
    try {
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($ExePath)
        if (-not $icon) { return }
        $part = "$dest.part"
        $bmp = $icon.ToBitmap()
        try { $bmp.Save($part, [System.Drawing.Imaging.ImageFormat]::Png) } finally { $bmp.Dispose() }
        Move-Item -Force $part $dest
    } catch {
        Log "winicon FAILED ($ExePath): $($_.Exception.Message)"
    } finally {
        if ($icon) { $icon.Dispose() }
    }
}
