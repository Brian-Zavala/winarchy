# Nerd Fonts: per-user install (no admin), like Omarchy's Install > Style > Font.

# Omarchy's font menu (bin/omarchy-install-font list) -> nerd-fonts release zip names.
$NerdFonts = [ordered]@{
    'JetBrainsMono'         = 'JetBrainsMono Nerd Font'
    'CascadiaMono'          = 'CaskaydiaMono Nerd Font'
    'Meslo'                 = 'MesloLGM Nerd Font'
    'FiraCode'              = 'FiraCode Nerd Font'
    'VictorMono'            = 'VictorMono Nerd Font'
    'BitstreamVeraSansMono' = 'BitstromWera Nerd Font'
    'Iosevka'               = 'Iosevka Nerd Font'
}

function Install-FontFile([string]$file) {
    Initialize-Native
    $dir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    New-Item -ItemType Directory -Force $dir | Out-Null
    $dest = Join-Path $dir ([IO.Path]::GetFileName($file))
    Copy-Item -Force $file $dest
    Add-Type -AssemblyName PresentationCore
    $face = try { ([System.Windows.Media.GlyphTypeface]::new([Uri]$dest)).Win32FamilyNames['en-US'] } catch { [IO.Path]::GetFileNameWithoutExtension($dest) }
    $style = try { ([System.Windows.Media.GlyphTypeface]::new([Uri]$dest)).Win32FaceNames['en-US'] } catch { '' }
    $name = "$face $style (TrueType)".Replace('  ', ' ')
    $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    if (-not (Test-Path $key)) { New-Item -Force $key | Out-Null }
    Set-ItemProperty $key -Name $name -Value $dest
    [void][OmarchyWin.Native]::AddFontResource($dest)
}

# Downloads <Name>.zip from the latest nerd-fonts release and installs its standard
# "<Name>NerdFont-*.ttf" files (not the Mono/Propo variants) for this user.
function Install-NerdFont([string]$name) {
    if (-not $NerdFonts.Contains($name)) { throw "unknown font '$name' (choose: $($NerdFonts.Keys -join ', '))" }
    $tmp = Join-Path $env:TEMP "omarchy-font-$name"
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force $tmp | Out-Null
    $zip = Join-Path $tmp "$name.zip"
    Log "downloading $name Nerd Font"
    Invoke-WebRequest "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$name.zip" -OutFile $zip -TimeoutSec 600
    Expand-Archive $zip (Join-Path $tmp 'x') -Force
    $files = Get-ChildItem (Join-Path $tmp 'x') -Recurse -Include *.ttf, *.otf |
        Where-Object { $_.Name -match 'NerdFont-' -and $_.Name -notmatch 'NerdFont(Mono|Propo)-' }
    if (-not $files) { $files = Get-ChildItem (Join-Path $tmp 'x') -Recurse -Include *.ttf, *.otf }
    foreach ($f in $files) { Install-FontFile $f.FullName }
    $r = [UIntPtr]::Zero   # WM_FONTCHANGE: running apps see the new font
    [void][OmarchyWin.Native]::SendMessageTimeout([IntPtr]0xffff, 0x1D, [UIntPtr]::Zero, $null, 2, 1000, [ref]$r)
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    Log "installed $($files.Count) $name font file(s)"
    $NerdFonts[$name]
}
