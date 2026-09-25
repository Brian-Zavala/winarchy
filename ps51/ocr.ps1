<#
  Text capture (Omarchy: Capture > Text). Reads the image on the clipboard (a fresh
  Win+Shift+S snip), runs Windows' built-in OCR in your Windows display languages, and
  puts the text on the clipboard. Writes the number of lines found to -Out.
  Windows PowerShell 5.1 with -STA (clipboard + WinRT):
    powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File ocr.ps1 -Out <file>
#>
param(
    [string]$Out = (Join-Path $env:TEMP 'omarchy-ocr.out'),
    [string]$Image    # test mode: read this file and print the text; the clipboard is not touched
)

$lines = 0
try {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.Runtime.WindowsRuntime
    $img = if ($Image) { [Drawing.Image]::FromFile($Image) } else { [Windows.Forms.Clipboard]::GetImage() }
    if ($img) {
        # Small snips read better scaled up.
        if ($img.Width -lt 800) {
            $scale = [Math]::Min(3, [Math]::Ceiling(800 / $img.Width))
            $big = New-Object Drawing.Bitmap ($img.Width * $scale), ($img.Height * $scale)
            $g = [Drawing.Graphics]::FromImage($big)
            $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.DrawImage($img, 0, 0, $big.Width, $big.Height); $g.Dispose()
            $img = $big
        }
        $tmp = Join-Path $env:TEMP 'omarchy-ocr.png'
        $img.Save($tmp, [Drawing.Imaging.ImageFormat]::Png)

        $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() |
            Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } |
            Select-Object -First 1
        function Await($op, [type]$type) {
            $t = $asTask.MakeGenericMethod($type).Invoke($null, @($op))
            [void]$t.Wait(20000); $t.Result
        }
        [void][Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
        [void][Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]
        [void][Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics, ContentType = WindowsRuntime]
        [void][Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]

        $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($tmp)) ([Windows.Storage.StorageFile])
        $stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
        $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
        $bitmap = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
        $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
        if ($engine) {
            $result = Await ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
            $text = (@($result.Lines) | ForEach-Object { $_.Text }) -join "`r`n"
            if ($text.Trim()) {
                if ($Image) { Write-Output $text } else { [Windows.Forms.Clipboard]::SetText($text) }
                $lines = @($result.Lines).Count
            }
        }
        $stream.Dispose()
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
} catch {
    try { Add-Content (Join-Path $env:USERPROFILE '.winarchy\logs\winarchy.log') "$(Get-Date -Format 'HH:mm:ss') [ocr] FAILED: $($_.Exception.Message)" } catch {}
}
[IO.File]::WriteAllText($Out, "$lines")
