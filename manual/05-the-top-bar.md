# The top bar

The top bar is Omarchy Quattro's, drawn with [Zebar](https://github.com/glzr-io/zebar). It stays above your windows, and tiles never go under it, except for fullscreen windows and games, which it gets out of the way of.

From left to right:

| Part | Click | Right-click |
|---|---|---|
| The logo | The Omarchy menu | A terminal |
| Workspaces | Go to that workspace | |
| Indicators | Turn it off | |
| The clock, centered | The calendar (`Super + Ctrl + Alt + D`) | The next date format |
| Weather | The weather details | |
| Updates, when there are any | Update everything | |
| The chevron | Running windows and the tray | |
| The AI agent icon | The agent usage panel (see [AI](17-ai.md)) | Start your coding agent |
| Bluetooth | The Bluetooth panel (`Super + Ctrl + B`) | |
| Network | Network settings | |
| Audio | The audio panel (`Super + Ctrl + A`) | Mute; scroll for the volume |
| CPU | btop (`Super + Ctrl + T`) | Task Manager |
| Battery, on a laptop | | |

### Indicators

Left of the clock, an icon shows while one of these is on: stay awake, nightlight, do not disturb, dictation, screen recording, a game in front, and a waiting admin prompt. Hover the area to see the ones that are off too, and click one to toggle it. See [toggles](13-toggles-idle-screensaver.md).

### Games

While a game is open, a gamepad icon appears. Click it to go back to the game, and right-click it to close it (twice to force-quit). The bar also hides on a game's monitor while it's in front. See [gaming](26-gaming.md).

### Turning it off

`Super + Shift + Space` hides the bar until you press it again, and gives its strip back to your windows. `winarchy bar on` and `winarchy bar off` do the same from a terminal.

### Making it yours

Put your own CSS in `%USERPROFILE%\.glzr\zebar\omarchy\user.css`, or open it with _Style > Menu Bar_. It loads after Winarchy's own, is never overwritten, and applies as soon as you save. The bar's height is `barHeight` in your settings (see [dotfiles](31-dotfiles.md)).
