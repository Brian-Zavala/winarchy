# Omarchy v4's wallpaper reveal (shell/plugins/background/Background.qml), for Windows:
# the new wallpaper grows out of the middle of each monitor in a slanted band, 420 ms,
# in-out cubic, on every monitor at once.
#
# How: one borderless, click-through window per monitor sits just above the desktop
# (below every app window and the bar) showing the old wallpaper, with the new one on top
# clipped to the band. The real wallpaper is set underneath while the band is still
# closed, the band opens, then the windows go away. Anything unexpected: the wallpaper is
# simply set, as before. The background picker plays the same band on the monitor it
# covers (zebar/omarchy/menu.js, land), so that monitor gets no window here.

function Initialize-Reveal {
    if (-not ('Winarchy.Reveal' -as [type])) {
        Add-Type -Namespace Winarchy -Name Reveal -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hgt, uint flags);
[DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
[DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h, int i, int v);
[DllImport("user32.dll")] public static extern IntPtr OpenInputDesktop(uint flags, bool inherit, uint access);
[DllImport("user32.dll")] public static extern bool CloseDesktop(IntPtr h);
public delegate bool MonitorProc(IntPtr mon, IntPtr hdc, ref RECT r, IntPtr data);
[DllImport("user32.dll")] public static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr clip, MonitorProc proc, IntPtr data);
public struct RECT { public int Left, Top, Right, Bottom; }
public static System.Collections.Generic.List<int[]> Monitors() {
    var list = new System.Collections.Generic.List<int[]>();
    EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (IntPtr m, IntPtr d, ref RECT r, IntPtr x) => {
        list.Add(new[] { r.Left, r.Top, r.Right - r.Left, r.Bottom - r.Top }); return true; }, IntPtr.Zero);
    return list;
}
'@
    }
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
}

# Reasons to just set the wallpaper: turned off, a live-wallpaper app draws the desktop,
# the session is locked (nobody would see it), or there is no old image to reveal from.
function Test-RevealWanted([string]$old) {
    if ((Get-Config).backgroundTransition -eq 'none') { return $false }
    if (Get-Process wallpaper32, wallpaper64, Lively, Lively.UI.WinUI -ErrorAction SilentlyContinue) { return $false }
    if (-not (Test-Path -LiteralPath $old)) { return $false }
    $desk = [Winarchy.Reveal]::OpenInputDesktop(0, $false, 0x100)
    if ($desk -eq [IntPtr]::Zero) { return $false }
    [void][Winarchy.Reveal]::CloseDesktop($desk)
    $true
}

function Read-RevealImage([string]$path, [int]$width) {
    # From memory, so the file isn't locked (Windows rewrites TranscodedWallpaper next).
    $ms = [IO.MemoryStream]::new([IO.File]::ReadAllBytes($path))
    $bi = [System.Windows.Media.Imaging.BitmapImage]::new()
    $bi.BeginInit()
    $bi.StreamSource = $ms
    $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bi.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile
    $bi.DecodePixelWidth = $width
    $bi.EndInit()
    $bi.Freeze()
    $bi
}

# Pump WPF (rendering included) for a while.
function Wait-Dispatcher([int]$ms) {
    $frame = [System.Windows.Threading.DispatcherFrame]::new()
    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds($ms)
    $timer.add_Tick({ $timer.Stop(); $frame.Continue = $false }.GetNewClosure())
    $timer.Start()
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

# Omarchy's band at progress p (0..1) for a w x h surface: slant -0.18, centred.
function Get-RevealBand([double]$w, [double]$h, [double]$p) {
    $slant = -0.18
    $top = $w / 2 - $slant * $h / 2
    $bottom = $w / 2 + $slant * $h / 2
    $spread = ($w / 2 + [Math]::Abs($slant) * $h / 2 + 4) * $p
    @(
        [System.Windows.Point]::new($top - $spread, 0), [System.Windows.Point]::new($top + $spread, 0),
        [System.Windows.Point]::new($bottom + $spread, $h), [System.Windows.Point]::new($bottom - $spread, $h)
    )
}

function New-RevealWindow([int[]]$rect, $oldImg, $newImg) {
    $w = [System.Windows.Window]::new()
    $w.WindowStyle = 'None'; $w.ResizeMode = 'NoResize'; $w.ShowInTaskbar = $false
    $w.ShowActivated = $false; $w.Focusable = $false; $w.Title = 'winarchy background'
    $w.Background = [System.Windows.Media.Brushes]::Black
    $w.WindowStartupLocation = 'Manual'
    $grid = [System.Windows.Controls.Grid]::new()
    foreach ($img in $oldImg, $newImg) {
        $el = [System.Windows.Controls.Image]::new()
        $el.Source = $img
        $el.Stretch = 'UniformToFill'          # Windows "Fill": centred crop
        [void]$grid.Children.Add($el)
    }
    $grid.Children[1].Clip = [System.Windows.Media.RectangleGeometry]::new([System.Windows.Rect]::Empty)
    $w.Content = $grid
    # Tool window + no-activate + click-through before it is shown: GlazeWM leaves it
    # alone, it never takes focus, and clicks go to the desktop.
    $hwnd = [System.Windows.Interop.WindowInteropHelper]::new($w).EnsureHandle()
    $ex = [Winarchy.Reveal]::GetWindowLong($hwnd, -20)
    [void][Winarchy.Reveal]::SetWindowLong($hwnd, -20, ($ex -bor 0x80 -bor 0x08000000 -bor 0x20))
    # Physical pixels, at the bottom of the z-order (just above the desktop).
    $flags = 0x0010 -bor 0x0200   # NOACTIVATE | NOOWNERZORDER
    [void][Winarchy.Reveal]::SetWindowPos($hwnd, [IntPtr]1, $rect[0], $rect[1], $rect[2], $rect[3], $flags)
    $w.Show()
    [void][Winarchy.Reveal]::SetWindowPos($hwnd, [IntPtr]1, $rect[0], $rect[1], $rect[2], $rect[3], $flags -bor 0x0040)
    [pscustomobject]@{ window = $w; image = $grid.Children[1] }
}

# Is point (x, y) on monitor rect (x, y, w, h)?
function Test-OnMonitor([int[]]$point, [int[]]$rect) {
    $point.Count -eq 2 -and $point[0] -ge $rect[0] -and $point[0] -lt $rect[0] + $rect[2] -and
        $point[1] -ge $rect[1] -and $point[1] -lt $rect[1] + $rect[3]
}

# $skip: a point (physical pixels) on the monitor the background picker covers.
function Invoke-BackgroundReveal([string]$new, [scriptblock]$apply, [int[]]$skip) {
    $old = Join-Path $env:APPDATA 'Microsoft\Windows\Themes\TranscodedWallpaper'
    $applied = $false
    $applyError = $null
    $reveals = @()
    $oldCtx = [IntPtr]::Zero
    try {
        # One monitor, and the picker covers it: nothing to reveal (and no compile wait).
        $alone = $false
        if ($skip.Count -eq 2) {
            Add-Type -AssemblyName System.Windows.Forms
            $alone = [System.Windows.Forms.SystemInformation]::MonitorCount -le 1
        }
        $monitors = @()
        if (-not $alone) { Initialize-Reveal }
        if (-not $alone -and (Test-RevealWanted $old)) {
            # Per-monitor DPI v2: real pixels on every monitor (mixed 4K/1440p setups).
            $oldCtx = [Winarchy.Reveal]::SetThreadDpiAwarenessContext([IntPtr]-4)
            $monitors = @([Winarchy.Reveal]::Monitors() | Where-Object { -not (Test-OnMonitor $skip $_) })
        }
        if ($monitors) {                    # none left: the picker reveals them all
            $width = ($monitors | ForEach-Object { $_[2] } | Measure-Object -Maximum).Maximum
            $oldImg = Read-RevealImage $old $width
            $newImg = Read-RevealImage $new $width
            foreach ($m in $monitors) { $reveals += New-RevealWindow $m $oldImg $newImg }
            Wait-Dispatcher 60              # the old image is on screen: swap underneath
            $applied = $true
            try { & $apply } catch { $applyError = $_ }
            if (-not $applyError) {
                # Each frame: widen every monitor's band (Get-RevealBand, inlined: this runs
                # as a WPF callback, outside this script's function scope).
                $st = @{ sw = [Diagnostics.Stopwatch]::StartNew(); frame = [System.Windows.Threading.DispatcherFrame]::new(); images = @($reveals.image) }
                $handler = [EventHandler]{
                    $ms = $st.sw.Elapsed.TotalMilliseconds
                    $t = [Math]::Min(1.0, $ms / 420.0)
                    $p = if ($t -lt 0.5) { 4 * $t * $t * $t } else { 1 - [Math]::Pow(-2 * $t + 2, 3) / 2 }   # InOutCubic
                    foreach ($img in $st.images) {
                        $w = $img.ActualWidth; $h = $img.ActualHeight
                        $top = $w / 2 + 0.18 * $h / 2; $bottom = $w / 2 - 0.18 * $h / 2
                        $spread = ($w / 2 + 0.18 * $h / 2 + 4) * $p
                        $fig = [System.Windows.Media.PathFigure]::new()
                        $fig.StartPoint = [System.Windows.Point]::new($top - $spread, 0)
                        $fig.IsClosed = $true
                        $pts = [System.Windows.Point[]]@(
                            [System.Windows.Point]::new($top + $spread, 0),
                            [System.Windows.Point]::new($bottom + $spread, $h),
                            [System.Windows.Point]::new($bottom - $spread, $h))
                        $fig.Segments.Add([System.Windows.Media.PolyLineSegment]::new($pts, $false))
                        $geo = [System.Windows.Media.PathGeometry]::new()
                        $geo.Figures.Add($fig)
                        $img.Clip = $geo
                    }
                    if ($t -ge 1.0 -or $ms -gt 3000) { $st.frame.Continue = $false }
                }.GetNewClosure()
                [System.Windows.Media.CompositionTarget]::add_Rendering($handler)
                try { [System.Windows.Threading.Dispatcher]::PushFrame($st.frame) }
                finally { [System.Windows.Media.CompositionTarget]::remove_Rendering($handler) }
                Wait-Dispatcher 250         # Explorer finishes painting the real one
            }
        }
    } catch {
        Log "background reveal skipped: $($_.Exception.Message)"
    } finally {
        foreach ($r in $reveals) { try { $r.window.Close() } catch {} }
        if ($oldCtx -ne [IntPtr]::Zero) { [void][Winarchy.Reveal]::SetThreadDpiAwarenessContext($oldCtx) }
    }
    if (-not $applied) { & $apply }
    elseif ($applyError) { throw $applyError }
}
