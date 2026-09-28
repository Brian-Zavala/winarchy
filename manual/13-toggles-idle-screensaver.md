# Toggles, idle & screensaver

The toggles are in _Trigger > Toggle_ in the Omarchy menu (`Super + Ctrl + O` goes straight there), and most have their own key too:

| Hotkey | Toggle |
|---|---|
| `Super + Ctrl + I` | Stay awake: the PC doesn't sleep or start the screensaver |
| `Super + Ctrl + ,` | Notifications: do not disturb |
| | Screensaver |
| `Super + Ctrl + N` | Nightlight: warmer colors for the evening |
| `Super + Shift + Space` | The top bar |
| `Super + Shift + Backspace` | Window gaps |
| | Window animations (experimental) |
| `Super + Backspace` | Window transparency |

An icon shows in the bar while stay awake, nightlight or do not disturb is on, and clicking it turns that off again.

### Screensaver

After 2.5 minutes idle, Omarchy's animated logo plays on every monitor. Any key, mouse move or gamepad input ends it. It never starts while a video, a game or a fullscreen app is in front, and gamepad input counts as activity, so it never starts mid-game.

`"screensaver": { "idleSeconds": 300 }` in your settings changes the wait, and _Style > Screensaver_ changes what it shows (see [branding](41-branding.md)). _System > Screensaver_ starts it right away.
