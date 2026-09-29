# The installer's look: Tokyo Night colours, a banner, step headers with a running clock,
# an in-place progress bar and a finish screen. Colour goes through $PSStyle, so NO_COLOR
# and redirected output get plain text; terminals without Unicode get ASCII stand-ins.

$UiColors = @{
    blue = 0x7aa2f7; cyan = 0x7dcfff; magenta = 0xbb9af7; green = 0x9ece6a
    yellow = 0xe0af68; red = 0xf7768e; dim = 0x565f89; fg = 0xc0caf5
}
# Install and update switch this on: log lines become tidy bullets, headers get a clock.
$script:UiPretty = $false
$script:UiClock = $null

# Windows Terminal and VS Code draw these; the old console host's fonts may not.
function Test-UiUnicode { [bool]($env:WT_SESSION -or $env:TERM_PROGRAM -eq 'vscode' -or $env:WINARCHY_UNICODE) }

function Get-UiGlyphs {
    if (Test-UiUnicode) { @{ step = '◆'; ok = '✓'; info = '·'; log = '›'; warn = '!'; fail = '✗'; ask = '?'; full = '█'; empty = '░' } }
    else { @{ step = '==>'; ok = '+'; info = '-'; log = '>'; warn = '!'; fail = 'x'; ask = '?'; full = '#'; empty = '.' } }
}

function Format-Ui([string]$text, [string]$color, [switch]$Bold) {
    $b = if ($Bold) { $PSStyle.Bold } else { '' }
    "$b$($PSStyle.Foreground.FromRgb($UiColors[$color]))$text$($PSStyle.Reset)"
}

function Get-UiClock {
    if (-not $script:UiClock) { return '' }
    $e = $script:UiClock.Elapsed
    '{0}:{1:00}' -f [int][Math]::Floor($e.TotalMinutes), $e.Seconds
}

function Start-UiClock { $script:UiPretty = $true; $script:UiClock = [Diagnostics.Stopwatch]::StartNew() }

# Blend two 0xRRGGBB colours; t in 0..1.
function Get-UiBlend([int]$a, [int]$b, [double]$t) {
    $ch = { param($c, $s) ($c -shr $s) -band 0xff }
    $mix = foreach ($s in 16, 8, 0) { [int]((& $ch $a $s) + ((& $ch $b $s) - (& $ch $a $s)) * $t) }
    ($mix[0] -shl 16) -bor ($mix[1] -shl 8) -bor $mix[2]
}

# WINARCHY in the ANSI Shadow figlet font, one array per letter so every row lines up.
$UiLetters = @(
    @('██╗    ██╗', '██║    ██║', '██║ █╗ ██║', '██║███╗██║', '╚███╔███╔╝', ' ╚══╝╚══╝ '),
    @('██╗', '██║', '██║', '██║', '██║', '╚═╝'),
    @('███╗   ██╗', '████╗  ██║', '██╔██╗ ██║', '██║╚██╗██║', '██║ ╚████║', '╚═╝  ╚═══╝'),
    @(' █████╗ ', '██╔══██╗', '███████║', '██╔══██║', '██║  ██║', '╚═╝  ╚═╝'),
    @('██████╗ ', '██╔══██╗', '██████╔╝', '██╔══██╗', '██║  ██║', '╚═╝  ╚═╝'),
    @(' ██████╗', '██╔════╝', '██║     ', '██║     ', '╚██████╗', ' ╚═════╝'),
    @('██╗  ██╗', '██║  ██║', '███████║', '██╔══██║', '██║  ██║', '╚═╝  ╚═╝'),
    @('██╗   ██╗', '╚██╗ ██╔╝', ' ╚████╔╝ ', '  ╚██╔╝  ', '   ██║   ', '   ╚═╝   ')
)

function Get-UiBannerRows {
    foreach ($row in 0..5) {
        ($UiLetters | ForEach-Object { $w = ($_ | Measure-Object Length -Maximum).Maximum; $_[$row].PadRight($w) }) -join ' '
    }
}

function Write-UiBanner([string]$version) {
    $rows = @(Get-UiBannerRows)
    $width = $rows[0].Length
    $fits = try { [Console]::WindowWidth -ge $width + 4 } catch { $false }
    Write-Host ''
    if ((Test-UiUnicode) -and $fits) {
        # Blue -> magenta -> cyan across the letters, like a Tokyo Night sunset.
        foreach ($r in $rows) {
            $sb = [Text.StringBuilder]::new('  ')
            for ($i = 0; $i -lt $r.Length; $i++) {
                $t = $i / [Math]::Max(1, $width - 1)
                $rgb = if ($t -lt 0.5) { Get-UiBlend $UiColors.blue $UiColors.magenta ($t * 2) } else { Get-UiBlend $UiColors.magenta $UiColors.cyan (($t - 0.5) * 2) }
                [void]$sb.Append($PSStyle.Foreground.FromRgb($rgb)).Append($r[$i])
            }
            Write-Host ($sb.Append($PSStyle.Reset).ToString())
        }
    } else {
        Write-Host ('  ' + (Format-Ui 'winarchy' 'magenta' -Bold))
    }
    Write-Host ('  ' + (Format-Ui "Omarchy's look, keys and themes for Windows 11" 'fg') + (Format-Ui "  ·  v$version  ·  unofficial" 'dim'))
}

function Write-Step([string]$msg) {
    $g = Get-UiGlyphs
    $clock = Get-UiClock
    Write-Host ''
    Write-Host ("$(Format-Ui $g.step 'magenta') $(Format-Ui $msg 'blue' -Bold)" + $(if ($clock) { '  ' + (Format-Ui $clock 'dim') }))
}

function Write-Ok([string]$msg) { Write-Host "    $(Format-Ui (Get-UiGlyphs).info 'dim') $(Format-Ui $msg 'fg')" }
function Write-Done([string]$msg) { Write-Host "    $(Format-Ui (Get-UiGlyphs).ok 'green') $msg" }
function Write-Warn([string]$msg) { Write-Host "    $(Format-Ui (Get-UiGlyphs).warn 'yellow') $(Format-Ui $msg 'yellow')" }

# Log's console half while the UI is on: the log file keeps the timestamped line.
function Write-UiLog([string]$msg) {
    $g = Get-UiGlyphs
    if ($msg -match 'FAILED') { Write-Host "    $(Format-Ui $g.fail 'red') $(Format-Ui $msg 'red')" }
    else { Write-Host "    $(Format-Ui $g.log 'dim') $(Format-Ui $msg 'dim')" }
}

function Write-UiQuestion([string]$question, [string]$hint) {
    Write-Host "  $(Format-Ui (Get-UiGlyphs).ask 'magenta' -Bold) $(Format-Ui $question 'fg' -Bold) $(Format-Ui $hint 'dim') " -NoNewline
}

# One line redrawn in place; nothing at all when the output goes to a file or pipe.
function Write-UiProgress([string]$label, [int]$done, [int]$total, [string]$detail) {
    if ([Console]::IsOutputRedirected -or $total -le 0) { return }
    $g = Get-UiGlyphs
    $w = 24
    $n = [int][Math]::Floor($w * $done / $total)
    $bar = (Format-Ui ($g.full * $n) 'cyan') + (Format-Ui ($g.empty * ($w - $n)) 'dim')
    $line = "    $bar $(Format-Ui ('{0,3}%' -f [int](100 * $done / $total)) 'fg') $(Format-Ui "$label $detail" 'dim')"
    Write-Host "`r$line$(' ' * 4)" -NoNewline
    if ($done -ge $total) { Write-Host '' }
}

function Write-UiFinish {
    $g = Get-UiGlyphs
    $clock = Get-UiClock
    Write-Host ''
    Write-Host ("  $(Format-Ui $g.ok 'green' -Bold) $(Format-Ui 'Winarchy is ready.' 'green' -Bold)" + $(if ($clock) { (Format-Ui "  took $clock" 'dim') }))
    Write-Host "    $(Format-Ui 'Super = the Windows key. Start here:' 'fg')"
    $keys = @(
        @('Super + K', 'all keybindings'), @('Super + Space', 'Omarchy menu'),
        @('Super + Alt + Space', 'app launcher'), @('Super + Return', 'terminal'),
        @('Super + 1..0', 'workspaces'), @('winarchy doctor', 'check the setup'),
        @('winarchy uninstall', 'undo everything')
    )
    foreach ($k in $keys) { Write-Host "      $(Format-Ui $k[0].PadRight(21) 'cyan') $(Format-Ui $k[1] 'fg')" }
    Write-Host "    $(Format-Ui "Settings: $ConfigFile  (then: winarchy apply)" 'dim')"
}
