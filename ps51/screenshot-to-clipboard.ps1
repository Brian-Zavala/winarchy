# Watches the Screenshots folder and copies every new screenshot to the clipboard as an image.
# Runs hidden at logon via the Startup shortcut "Screenshot to Clipboard.lnk"
# (config.json "screenshotAutoCopy": true). Windows PowerShell 5.1, -STA.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -Namespace ShotWatch -Name Shell -MemberDefinition @'
[DllImport("shell32.dll")]
public static extern int SHGetKnownFolderPath([MarshalAs(UnmanagedType.LPStruct)] Guid id, uint flags, IntPtr token, out IntPtr path);
'@

# The real Screenshots folder (it may be redirected, e.g. into OneDrive).
$dir = $null
$ptr = [IntPtr]::Zero
if ([ShotWatch.Shell]::SHGetKnownFolderPath([guid]'b7bede81-df94-4682-a7d8-57a52620b86f', 0, [IntPtr]::Zero, [ref]$ptr) -eq 0) {
    $dir = [Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
    [Runtime.InteropServices.Marshal]::FreeCoTaskMem($ptr)
}
if (-not $dir) { $dir = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Screenshots' }
New-Item -ItemType Directory -Force $dir | Out-Null

# Text capture (OCR) puts text on the clipboard; don't replace it with the snip.
$ocrFlag = Join-Path $env:USERPROFILE '.winarchy\generated\ocr.flag'

# Single instance
$mutex = New-Object System.Threading.Mutex($false, 'Global\ScreenshotToClipboard')
if (-not $mutex.WaitOne(0)) { exit }

$watcher = New-Object System.IO.FileSystemWatcher $dir
$watcher.Filter = '*.*'
$watcher.NotifyFilter = [IO.NotifyFilters]'FileName'

while ($true) {
    $r = $watcher.WaitForChanged([IO.WatcherChangeTypes]'Created, Renamed', 60000)
    if ($r.TimedOut -or $r.Name -notmatch '\.(png|jpe?g|bmp)$') { continue }
    if ((Test-Path $ocrFlag) -and ((Get-Date) - (Get-Item $ocrFlag).LastWriteTime).TotalSeconds -lt 10) { continue }
    $path = Join-Path $dir $r.Name
    $bytes = $null
    for ($i = 0; $i -lt 40 -and -not $bytes; $i++) {
        Start-Sleep -Milliseconds 100
        try { $bytes = [IO.File]::ReadAllBytes($path); if ($bytes.Length -eq 0) { $bytes = $null } } catch {}
    }
    if (-not $bytes) { continue }
    try {
        $img = [Drawing.Image]::FromStream((New-Object IO.MemoryStream(, $bytes)))
        $data = New-Object Windows.Forms.DataObject
        $data.SetImage($img)
        $files = New-Object Collections.Specialized.StringCollection
        [void]$files.Add($path)
        $data.SetFileDropList($files)
        [Windows.Forms.Clipboard]::SetDataObject($data, $true, 10, 100)
    } catch {}
}
