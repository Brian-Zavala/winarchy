<#
  Hyprland-style dwindle auto-tiling for GlazeWM.

  GlazeWM inserts every new tiling window as a flat sibling of whatever window was
  focused, in that window's own parent container (source: packages/wm/src/commands/
  window/manage_window.rs, insertion_target()) -- an i3/sway-style N-ary layout, not a
  binary tree, which is why left alone every window just piles into one flat row/column
  (glzr-io/glazewm has no dwindle/BSP layout: #678, #1175, #1377 are open requests).

  The one lever that actually restructures the tree from outside is a side effect of
  `command --id <window-id> toggle-tiling-direction` targeted at a WINDOW that already
  has a sibling (packages/wm/src/commands/container/toggle_tiling_direction.rs,
  toggle_window_direction()): GlazeWM wraps *that window alone* into a brand-new split
  container, perpendicular to its old parent's direction. Since the next window opened
  always lands next to whatever is focused, and the just-wrapped window is still focused,
  the following window becomes that split's second child -- producing a real alternating
  spiral. (Calling this on a container id, or on a window with no sibling yet, only flips
  a direction field and does nothing visible.)

  Each window_managed event carries the newly-managed window's own data directly
  (`data.managedWindow`, the full container object -- packages/wm-common/src/wm_event.rs).
  Handling is keyed off THAT window specifically, not "whichever window is currently
  focused": when several windows open in a fast burst, `sub` events can queue up faster
  than each is processed, and re-querying "current focus" for every queued event would
  make them all act on the same, by-then-most-recent window instead of their own --
  repeatedly re-toggling it and leaving earlier windows unwrapped (this was the first cut
  of this script's bug, surfacing as focus/cursor seeming to "stick" to the last window
  created during a burst). Only window_managed and window_unmanaged are subscribed to, not
  focus_changed -- reacting to a later refocus of an already-wrapped window would nest it
  again on every alt-tab. After either event, a workspace left with one window or none
  goes back to its monitor's split direction (Repair-Directions): closing the window next
  to a dwindle split makes GlazeWM hand the split's direction to the workspace itself.

  A window GlazeWM starts as fullscreen only because it reopened at full-screen size (no
  taskbar, so apps save that size) is tiled first, or it would sit behind the bar.

  Started by GlazeWM's own general.startup_commands (templates/glazewm.yaml.tpl), the
  same way Zebar is, and passed the currently-selected CLI path (official install, or the
  animations-fork build when window animations are on -- see lib/animations.ps1's
  Get-SelectedGlazeWM) the same way ahk/winarchy.ahk passes -Cli to lib/drop.ps1. Exits on
  its own once GlazeWM closes the IPC connection the `sub` stream depends on (wm-exit, or
  the process closing outright) -- no separate shutdown hook needed.
#>
param([Parameter(Mandatory)][string]$Cli)

. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\autotile.ps1"

if (-not (Test-Path $Cli)) {
    Log "autotile: GlazeWM CLI not found at $Cli, exiting"
    exit 1
}

# One watcher at a time: GlazeWM's startup_commands and winarchy.ahk's guard can both
# reach for it, and two of them would each wrap every new window (two wraps = no wrap).
$mutex = [Threading.Mutex]::new($false, 'Global\winarchy-autotile')
if (-not $mutex.WaitOne(0)) { exit 0 }

Add-Type -Namespace WinarchyAutotile -Name Native -MemberDefinition '[DllImport("user32.dll")] public static extern IntPtr GetWindowLongPtrW(IntPtr hwnd, int index);'

function Get-WindowStyle($handle) {
    try { [WinarchyAutotile.Native]::GetWindowLongPtrW([IntPtr][long]$handle, -16).ToInt64() } catch { 0 }   # GWL_STYLE
}

function Test-TilingSibling($node) { $node.type -eq 'split' -or ($node.type -eq 'window' -and $node.state.type -eq 'tiling') }

# Depth-first search of the workspace tree for a container by id (same walk as
# lib/drop.ps1's Find-Workspace).
function Find-Container($roots, [string]$id) {
    $stack = [Collections.Stack]::new()
    foreach ($r in $roots) { $stack.Push($r) }
    while ($stack.Count) {
        $c = $stack.Pop()
        if ($c.id -eq $id) { return $c }
        foreach ($ch in $c.children) { $stack.Push($ch) }
    }
}

# The container whose children currently hold this window. The event payload carries a
# parentId, but that is a snapshot from when the event was emitted and can already be
# stale, so the live tree decides instead.
function Find-Parent($roots, [string]$childId) {
    $stack = [Collections.Stack]::new()
    foreach ($r in $roots) { $stack.Push($r) }
    while ($stack.Count) {
        $c = $stack.Pop()
        foreach ($ch in $c.children) {
            if ($ch.id -eq $childId) { return $c }
            $stack.Push($ch)
        }
    }
}

function Invoke-DwindleWrap($win) {
    if (-not $win -or $win.type -ne 'window' -or -not $win.id) { return }
    $short = $win.id.Substring(0, 8)
    # The event can arrive a beat before the tree shows the window, so look twice.
    foreach ($attempt in 1, 2) {
        $workspaces = try { (& $Cli query workspaces | ConvertFrom-Json).data.workspaces } catch { $null }
        if (-not $workspaces) { Log "autotile: $short query failed"; return }
        $live = Find-Container $workspaces $win.id
        if ($live) { break }
        if ($attempt -eq 1) { Start-Sleep -Milliseconds 80 }
    }
    if (-not $live) { Log "autotile: $short never appeared in the tree"; return }
    if (Test-TileFullSize $live (Get-WindowStyle $live.handle)) {
        # Opened at full-screen size, not as real fullscreen: tile it under the bar.
        & $Cli command --id $win.id set-tiling 2>$null | Out-Null
        Log "autotile: $short opened full-size ($($live.processName)), tiled"
        $workspaces = try { (& $Cli query workspaces | ConvertFrom-Json).data.workspaces } catch { $null }
        if (-not $workspaces -or -not ($live = Find-Container $workspaces $win.id)) { return }
    }
    if ($live.state.type -ne 'tiling') { Log "autotile: $short is $($live.state.type), left alone"; return }
    $parent = Find-Parent $workspaces $win.id
    if (-not $parent) { Log "autotile: $short has no parent container"; return }
    $sibs = @($parent.children | Where-Object { $_.id -ne $win.id -and (Test-TilingSibling $_) })
    if ($sibs.Count -lt 1) { Log "autotile: $short alone in its $($parent.type), nothing to split"; return }
    & $Cli command --id $win.id toggle-tiling-direction 2>$null | Out-Null
    Log "autotile: $short wrapped ($($sibs.Count) sibling(s), $($parent.type) was $($parent.tilingDirection))"
}

# Workspaces with one window or none back to their monitor's split direction
# (Get-DirectionFixes in lib/autotile.ps1 says why they drift).
function Repair-Directions {
    $monitors = try { (& $Cli query monitors | ConvertFrom-Json).data.monitors } catch { $null }
    foreach ($id in @(Get-DirectionFixes $monitors)) {
        & $Cli command --id $id toggle-tiling-direction 2>$null | Out-Null
        Log "autotile: workspace $($id.Substring(0, 8)) set back to its monitor's direction"
    }
}

Log "autotile: watching (cli: $Cli)"
Repair-Directions
# Anything that ends this process should say why: it has been seen to disappear while
# GlazeWM kept running, and a dead watcher silently stops new windows dwindling.
try {
    & $Cli sub -e window_managed window_unmanaged | ForEach-Object {
        try {
            $evt = $_ | ConvertFrom-Json
            if ($evt.success -ne $false) {
                if ($evt.data.managedWindow) { Invoke-DwindleWrap $evt.data.managedWindow }
                Repair-Directions
            }
        } catch { Log "autotile: event handling failed: $_" }
    }
    Log 'autotile: subscribe stream ended, exiting'
} catch {
    Log "autotile: stopped by an error: $($_.Exception.Message)"
} finally {
    $mutex.ReleaseMutex()
}
