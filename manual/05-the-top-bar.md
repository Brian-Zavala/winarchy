# The top bar

The top bar is Omarchy Quattro's, drawn with [Zebar](https://github.com/glzr-io/zebar). It stays above your windows, and tiles never go under it, except for fullscreen windows and games, which it gets out of the way of.

Double-click empty space on the bar to make it transparent (again to bring the background back). It is remembered across restarts, and _Style > Menu Bar > Transparency_ does the same.

From left to right:

| Part | Click | Right-click |
|---|---|---|
| The logo | The Omarchy menu | A terminal |
| Workspaces | Go to that workspace | |
| Indicators | Turn it off | |
| The clock, centered | The calendar (`Super + Ctrl + Alt + D`) | The next date format; middle-click opens the world clock (`Super + Ctrl + Alt + E`) |
| What's playing, when something is | Play / pause | Next track; middle-click goes back |
| A bell and a time, when a reminder is set | All your reminders (`Super + Ctrl + Alt + R`) | |
| Weather | The weather details | |
| Updates, when there are any | Update everything | |
| The chevron | Running windows and the tray | |
| The AI agent icon | The agents panel: limits, tokens today, and tiles that have your agent make a theme, plugin or app (see [AI](17-ai.md)) | Start your coding agent |
| Bluetooth | The Bluetooth panel (`Super + Ctrl + B`): the radio switch and your paired devices | |
| Tailscale, once installed | The Tailscale panel | Turn it on or off; middle-click refreshes |
| Network | The network panel (`Super + Ctrl + W`): speed test, DNS provider, Wi-Fi networks | Windows' network settings |
| Audio | The audio panel (`Super + Ctrl + A`): master volume, output, microphone and a slider per app | Mute; scroll for the volume |
| Display | The Display panel | Scroll for the brightness |
| CPU | btop (`Super + Ctrl + T`) | Task Manager |
| Battery, on a laptop | The Power panel (`Super + Ctrl + P`) | Show or hide the percentage |

### Indicators

Left of the clock, an icon shows while one of these is on: stay awake, nightlight, do not disturb, dictation, screen recording, a game in front, and a waiting admin prompt. Hover the area to see the ones that are off too, and click one to toggle it. See [toggles](13-toggles-idle-screensaver.md).

### Display

The monitor icon opens Quattro's Display panel for the monitor you clicked on:

- **Brightness**, a slider from 1 to 100%. A laptop's own screen always has it. An external monitor has it when it supports DDC/CI, which most do; turn DDC/CI on in the monitor's own menu if the slider isn't there. Scrolling on the icon changes it 5% at a time.
- **Text size**, from 9 to 20 px (12 is the default). It sizes the bar, these panels and your terminals together, and the bar grows taller for sizes above 12. `winarchy text-size <px>` does the same from a terminal.
- **Scale**, the monitor's Windows scaling (100%, 125%, 150%...), limited to the steps Windows offers for it. The dot marks the recommended one.
- **Displays**, with more than one monitor: click one to turn it off or back on. The last monitor that is on stays on.

`j` / `k` move between the sections, `h` / `l` adjust, `Enter` picks, and `Esc` closes it. See [monitors](33-monitors.md).

### Power

On a laptop, the battery icon opens Quattro's Power panel:

- **Battery**: the charge, as a number and a bar that breathes while it charges, and what the battery is up to.
- **Battery size** and **charge cycles**, where the battery reports them, then the **time left** on battery or the **time to full** while charging, and how fast it's draining or charging in watts. Plugged in and holding below full (a battery-care charge limit from your laptop's maker), it says so instead.
- **Power profile**: Power-saver, Balanced or Performance, which are Windows' power modes (_Settings > System > Power_).

Arrow keys or `h` / `l` move between the profiles, `Enter` picks, and `Esc` closes. Right-click the icon, or _Trigger > Toggle > Battery Percentage_, to show the percentage next to it. On a desktop, `Super + Ctrl + P` opens the Power menu instead.

### Tailscale

[Tailscale](https://tailscale.com) isn't installed by default. The installer offers it, and _Install > Service > Tailscale_ adds it any time. Once it's installed, its icon joins the ones on the right: solid when connected, struck through when off, and with a red `!` when it needs you to sign in.

Its panel has an on/off switch, your connections (with more than one account), exit nodes (including Mullvad's), and the machines online on your tailnet. Hover a machine to copy its IP, name or DNS name, or to send it files with Taildrop. From the keyboard: `c`, `n` and `d` copy, `s` sends files, `t` turns Tailscale on or off, and `r` refreshes.

### Games

While a game is open, a gamepad icon appears. Click it to go back to the game, and right-click it to close it (twice to force-quit). The bar also hides on a game's monitor while it's in front. See [gaming](26-gaming.md).

### Turning it off

`Super + Shift + Space` hides the bar until you press it again, and gives its strip back to your windows. `winarchy bar on` and `winarchy bar off` do the same from a terminal.

### Making it yours

Put your own CSS in `%USERPROFILE%\.glzr\zebar\omarchy\user.css`, or open it with _Style > Menu Bar_. It loads after Winarchy's own, is never overwritten, and applies as soon as you save. The bar's height is `barHeight` in your settings (see [dotfiles](31-dotfiles.md)).
