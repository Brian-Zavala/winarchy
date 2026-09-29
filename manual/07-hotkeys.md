# Hotkeys

Winarchy is keyboard-first, with Omarchy's keys wherever Windows allows them. `Super` is the Windows key. `Super + K` shows this list on screen, and you can search it.

### Menus

| Hotkey | Function |
|---|---|
| `Super + Space` | The Omarchy menu |
| `Super + Alt + Space` | The app launcher (Flow Launcher) |
| `Super + Escape` | System: lock, suspend, reboot, shut down |
| `Super + K` | Keybindings |
| `Super + Ctrl + Space` | Background selector |
| `Super + Ctrl + Shift + Space` | Theme selector |
| `Super + Ctrl + C` | Capture menu |
| `Super + Ctrl + O` | Toggle menu |

### Navigating

| Hotkey | Function |
|---|---|
| `Super + 1..0` | Go to a workspace |
| `Super + Shift + 1..0` | Move the window to a workspace, and follow it |
| `Super + Shift + Alt + 1..0` | Move the window to a workspace, and stay |
| `Super + Tab` / `Super + Shift + Tab` | Next / previous workspace |
| `Super + Ctrl + Tab` | The workspace you were on before |
| `Super + scroll wheel` | Next / previous workspace |
| `Super + S` or `` Super + ` `` | The scratchpad |
| `Super + Alt + S` or `` Super + Shift + ` `` | Send the window to the scratchpad |
| `Super + Shift + Alt + Arrows` | Move the whole workspace to another monitor |
| `Ctrl + Alt + Tab` | Focus the next monitor (add `Shift` for the previous one) |
| `Super + Arrows` | Move focus |
| `Super + Shift + Arrows` | Move the window, across monitors too |
| `Super + W` or `Super + Q` | Close the window |
| `Super + T` | Toggle floating / tiling |
| `Super + F` | Fullscreen |
| `Super + Alt + F` | Full width |
| `Super + O` | Pop out: float and stay on top |
| `Super + J` | Flip the split: side by side or stacked |
| `Super + -` / `Super + =` | Shrink / grow the width by 100px |
| `Super + Shift + -` / `Super + Shift + =` | Shrink / grow the height |
| `Alt` / `Ctrl` with the resize keys | Fine (25px) / coarse (300px) steps |
| `Super + drag` | Move a window |
| `Super + right drag` | Resize a window |
| `Super + M` or `Super + Home` | Restore every minimized window |

### Launching apps

| Hotkey | Function |
|---|---|
| `Super + Return` | Terminal |
| `Super + Shift + B` or `Super + Shift + Return` | Browser |
| `Super + Shift + F` | File Explorer |
| `Super + Shift + N` | Editor |
| `Super + Shift + M` | Spotify |
| `Super + Shift + /` | 1Password |
| `Super + Shift + O` | Obsidian |
| `Super + Shift + G` | Signal |
| `Super + Shift + D` | lazydocker |
| `Super + Shift + Alt + M` | Cliamp (music in the terminal) |
| `Super + Shift + W` | Omawrite |
| `Super + Ctrl + Return` | Herdr: open or re-attach your session |
| `Super + Shift + E` / `C` / `A` / `Y` / `X` / `P` | Web apps: HEY, HEY Calendar, ChatGPT, YouTube, X, Google Photos (see [web apps](25-web-apps.md) for all of them) |

These are in your own copy of the launcher script, which _Setup > Keybindings_ opens. See [dotfiles](31-dotfiles.md).

A key that an AutoHotkey script of your own in the Startup folder already binds stays yours: Winarchy's keys leave it alone, and `Super + K` marks it "(your script)". Save a change to your script and Winarchy picks it up within a few seconds. `winarchy doctor` lists the keys it left to you.

### Universal clipboard

| Hotkey | Function |
|---|---|
| `Super + C` / `Super + V` / `Super + X` / `Super + A` | Copy / paste / cut / select all, in every app |
| `Super + Ctrl + V` | Clipboard history |
| `Super + Ctrl + E` | Emoji picker |

### Capture

| Hotkey | Function |
|---|---|
| `Print` | Screenshot of a region |
| `Alt + Print` | Screen recording |
| `Super + Print` | Color picker: the color under the click is copied |
| `Super + Ctrl + Print` | Text capture: the text in a region is copied |
| `Shift + Print` | Screenshot of everything, saved to `Pictures\Screenshots` |
| `Shift + F9` or `Super + Ctrl + X` | Dictation: talk and it types, again to stop |

These are Omarchy's, and what a new install gets. An install from before this version keeps its own: `Super + Print` saves the whole screen, `Super + Ctrl + Print` is the color picker and `Super + Shift + Print` the text capture. `"captureKeys"` in your settings switches between the two (see [dotfiles](31-dotfiles.md)).

No `Print` key on your laptop? `Super + Ctrl + C` opens the capture menu.

### Notifications and notices

| Hotkey | Function |
|---|---|
| `Super + Ctrl + Alt + T` | Show the time |
| `Super + Ctrl + Alt + B` | Show the battery |
| `Super + Ctrl + Alt + W` | Show the weather |
| `Super + Ctrl + Alt + D` | Calendar |
| `Super + Ctrl + Alt + E` | World clock |
| `Super + Shift + Alt + ,` | Notification history |

### Toggles

| Hotkey | Function |
|---|---|
| `Super + Ctrl + I` | Stay awake |
| `Super + Ctrl + N` | Nightlight |
| `Super + Ctrl + ,` | Do not disturb |
| `Super + Shift + Space` | The top bar |
| `Super + Backspace` | Window transparency |
| `Super + Shift + Backspace` | Window gaps |

### System controls

| Hotkey | Function |
|---|---|
| `Super + Ctrl + A` | Audio panel: master volume, output, microphone and per-app volumes |
| `Super + Ctrl + B` | Bluetooth panel: radio switch and paired devices |
| `Super + Ctrl + W` | Network panel: speed test, DNS and Wi-Fi |
| `Super + Ctrl + D` | Display panel: brightness, scale and text size |
| `Super + Ctrl + P` | Power settings |
| `Super + Ctrl + T` | Activity (btop) |
| `Super + Ctrl + Q` | Calculator (Omacalc once it's installed) |
| `Super + Ctrl + Z` | Zoom in (add `Alt` to reset) |
| `Super + Ctrl + L` | Lock |
| `Super + Ctrl + Delete` | Laptop screen off / on, with a monitor plugged in |
| `Super + Ctrl + Alt + Delete` | Mirror the screens / extend them again |
| `Alt + Volume Up` / `Alt + Volume Down` | Volume in 1% steps |
| `Alt + Play` / `Alt + Shift + Play` | Next / previous track |
| `Shift + Mute` | Switch to the next playback device |

### Utilities

| Hotkey | Function |
|---|---|
| `Super + Ctrl + R` | Set a reminder (add `Alt` to show them, `Shift` to clear them) |
| `Super + Ctrl + S` | Share files (LocalSend) |
| `Super + Ctrl + .` | Transcode a picture or video |
| `Super + Shift + Ctrl + A` | Start your coding agent |
| `Super + Ctrl + K` | Herdr keybindings |
| `Super + Ctrl + Alt + F` | Full screen desktop: no bar and no gaps, again to bring them back |
| `CapsLock`, then keys | Compose: `m s` 😄, `m y` 👍, `m h` ❤️ and the rest of Omarchy's, `Space Space` an em dash, `Space n` / `Space e` your name / email |
| `Left Shift + Right Shift` | Caps Lock, while `CapsLock` composes |

Compose is on for new installs (`"compose"` in your settings; see [dotfiles](31-dotfiles.md)).
| `Ctrl + Esc` | The Windows Start menu |
| `Super + Shift + Alt + R` | Reload GlazeWM's config |
| `Super + Shift + Alt + P` | Pause / resume GlazeWM |

### Games

| Hotkey | Function |
|---|---|
| `Super + W` or `Super + Q` | Close the game; again within 15 seconds to force-quit it |
| `Super + Ctrl + G` | Mark the focused window as a game |

See [gaming](26-gaming.md).

### Herdr

`Ctrl + Space` is Herdr's prefix, then `?` for help. _Learn > Herdr_ lists every Herdr key as Herdr loaded them. See [terminal](15-terminal.md).

### Windows limits

A few of Omarchy's keys have no Windows equivalent. Window grouping and the scrolling layout don't exist in GlazeWM, `Super + L` belongs to Windows' lock, `Ctrl + Alt + Del` is reserved by Windows, and `Alt + Tab` is left to Windows so games stay reachable. `Super + Shift + S` stays Windows' region screenshot rather than Google Maps. Windows can't dismiss a notification from a key, so `Super + ,` and its variants have nothing to do.

While a window that runs as administrator is in front, Windows keeps Winarchy's AutoHotkey keys from it, so the menus, launchers and utilities above don't work over it. GlazeWM's own keys (workspaces, focus, moving windows) still do. See [gaming](26-gaming.md) for games that run as administrator.
