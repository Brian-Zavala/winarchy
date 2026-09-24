<#
  Called by omarchy-wm.ahk when a Super+drag of a window ends.
  Hyprland-style drop: a tiled window lands where it was dropped (swapping past
  the tiled window under the cursor, or moving to the other monitor's workspace);
  a floating window that crossed monitors is re-homed to that monitor's workspace.
  Coordinates are physical pixels (same space GlazeWM uses).
#>
param([Parameter(Mandatory)][string]$Id, [int]$X, [int]$Y, [string]$Cli = (Join-Path $env:ProgramFiles 'glzr.io\GlazeWM\cli\glazewm.exe'))

$g = $Cli
function Query($what) { (& $g query $what | ConvertFrom-Json).data }
function Glaze([string[]]$cmdArgs) { & $g command @cmdArgs | Out-Null }

function Find-Workspace($id) {
    foreach ($ws in (Query workspaces).workspaces) {
        $stack = [System.Collections.Stack]::new(); $stack.Push($ws)
        while ($stack.Count) {
            $c = $stack.Pop()
            if ($c.id -eq $id) { return $ws }
            foreach ($ch in $c.children) { $stack.Push($ch) }
        }
    }
}
function Contains($c, $px, $py) { $px -ge $c.x -and $px -lt $c.x + $c.width -and $py -ge $c.y -and $py -lt $c.y + $c.height }

$me = (Query windows).windows | Where-Object id -eq $Id
if (-not $me) { exit }
$monitor = (Query monitors).monitors | Where-Object { Contains $_ $X $Y } | Select-Object -First 1
if (-not $monitor) { Glaze 'wm-redraw'; exit }
$target = $monitor.children | Where-Object isDisplayed | Select-Object -First 1
$current = Find-Workspace $Id

if ($target -and $current -and $target.id -ne $current.id) {
    Glaze '--id', $Id, 'move', '--workspace', $target.name
}

if ($me.state.type -eq 'tiling') {
    # Step the window toward the drop point until it sits under the cursor.
    for ($i = 0; $i -lt 6; $i++) {
        $wins = (Query windows).windows | Where-Object { $_.state.type -eq 'tiling' -and $_.displayState -eq 'shown' }
        $mine = $wins | Where-Object id -eq $Id
        if (-not $mine -or (Contains $mine $X $Y)) { break }
        $under = $wins | Where-Object { $_.id -ne $Id -and (Contains $_ $X $Y) } | Select-Object -First 1
        if (-not $under) { break }
        $dx = ($under.x + $under.width / 2) - ($mine.x + $mine.width / 2)
        $dy = ($under.y + $under.height / 2) - ($mine.y + $mine.height / 2)
        $dir = if ([Math]::Abs($dx) -ge [Math]::Abs($dy)) { if ($dx -gt 0) { 'right' } else { 'left' } } else { if ($dy -gt 0) { 'down' } else { 'up' } }
        Glaze '--id', $Id, 'move', '--direction', $dir
    }
    Glaze 'wm-redraw'
}
