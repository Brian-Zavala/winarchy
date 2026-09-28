# Navigation

Winarchy tiles your windows with [GlazeWM](https://github.com/glzr-io/glazewm), using Omarchy's keys. A new window takes its share of the screen, and the others make room. Every key is listed in [hotkeys](07-hotkeys.md), or press `Super + K`.

### Workspaces

There are ten workspaces, split across your monitors from left to right (see [monitors](33-monitors.md)).

| Hotkey | Function |
|---|---|
| `Super + 1..0` | Go to a workspace |
| `Super + Shift + 1..0` | Move the window there, and follow it |
| `Super + Shift + Alt + 1..0` | Move the window there, and stay |
| `Super + Tab` / `Super + Shift + Tab` | Next / previous workspace |
| `Super + Ctrl + Tab` | The workspace you were on before |
| `Super + scroll wheel` | Next / previous workspace |
| `Super + S` or `` Super + ` `` | The scratchpad, a workspace of its own for things you want at hand but out of the way |
| `Super + Alt + S` or `` Super + Shift + ` `` | Send the window to the scratchpad |

### Windows

| Hotkey | Function |
|---|---|
| `Super + Arrows` | Move focus |
| `Super + Shift + Arrows` | Move the window, across monitors too |
| `Super + W` or `Super + Q` | Close the window |
| `Super + T` | Toggle floating / tiling |
| `Super + F` | Fullscreen |
| `Super + O` | Pop out: float and stay on top |
| `Super + J` | Flip the split: side by side or stacked |
| `Super + -` / `Super + =` | Shrink / grow the width (add `Shift` for the height, `Alt` for fine steps, `Ctrl` for coarse ones) |
| `Super + Backspace` | Toggle window transparency |
| `Super + M` | Restore every minimized window |

### The mouse

Focus follows the mouse, as in Hyprland: point at a window and it's the one you type into. `Super + drag` moves a window from anywhere inside it, and drops it exactly where you let go, onto another tile or another monitor. `Super + right drag` resizes it.

### Auto-tiling

New windows spiral into Hyprland's dwindle splits instead of piling into one row: each one splits the space of the window next to it. If a split comes out the wrong way, `Super + J` flips it. `winarchy autotile off` turns this off.

### Escape hatches

`Super + Shift + Alt + P` pauses GlazeWM, and pressing it again resumes it. `Super + Shift + Alt + R` reloads its config.
