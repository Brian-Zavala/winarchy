# Monitors

Winarchy works with any number of monitors, at any scaling. The ten workspaces are split across your monitors from left to right: all ten on one monitor, 5 and 5 on two, 4, 3 and 3 on three.

`Super + 1..0` goes to a workspace wherever it is, and `Super + Shift + Alt + Arrows` moves the whole current workspace to another monitor. `Ctrl + Alt + Tab` focuses the next monitor (add `Shift` for the previous one).

### Your own split

Set `"workspaces"` in your settings to a map of monitor position (1 is the leftmost) to workspace names, for example `{ "1": ["1", "2", "3"], "2": ["4", "5"] }`. See [dotfiles](31-dotfiles.md).

### Docking and undocking

When a monitor is added, the workspaces re-split across the monitors automatically. A monitor that sleeps or is unplugged keeps its workspaces: they wait on the other monitors and go back when it returns, because a sleeping monitor looks exactly like an unplugged one.

If you've removed a monitor for good, run `winarchy apply -MonitorsOnly -Resplit` to fit the split to the monitors connected now.

### New windows open where you are

Windows has no idea of a "focused monitor", so it opens every new window on the primary display. Winarchy moves it to the workspace shown under the mouse instead, the way Hyprland opens it on the focused monitor. Dialogs and popups stay with the window that opened them, and games and fullscreen windows are left where they are. `"openOnHoveredMonitor": false` turns this off.

### Scaling

The bar, the gaps and the pickers are all sized per monitor, so they line up on a 4K screen next to a 1080p one. Change a monitor's scaling in Windows' own display settings (_Setup > Monitors_ in the Omarchy menu opens them).
