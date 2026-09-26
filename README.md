![Winarchy](images/winarchy-no-bg.png)


**[Omarchy](https://omarchy.org)'s look, keys and themes on Windows 11.** Tiling windows, the Omarchy
top bar and menu, 22 Omarchy themes that recolor everything at once, the background and theme
pickers, the screensaver, and the Super-key workflow — installed in one command, undone in one command.

> Unofficial. Not affiliated with Omarchy or 37signals. Built on [GlazeWM](https://github.com/glzr-io/glazewm),
> [Zebar](https://github.com/glzr-io/zebar), [Flow Launcher](https://www.flowlauncher.com) and
> [AutoHotkey](https://www.autohotkey.com).

## Install

Open **PowerShell** (not as administrator) and run:

```powershell
irm https://raw.githubusercontent.com/Brian-Zavala/winarchy/main/install.ps1 | iex
```

The installer:

1. checks the PC (Windows 11, winget) and installs what's missing: PowerShell 7, AutoHotkey v2,
   the JetBrainsMono Nerd Font, GlazeWM + Zebar (one UAC prompt), Flow Launcher, fastfetch, btop;
2. asks a few questions (only the ones that depend on you: keep your own launcher script?
   hide the taskbar? take over Win+Space if you use several keyboard layouts?);
3. **records every setting it changes** in a backup journal before changing it;
4. writes the configs for *your* machine — any number of monitors, any scaling, laptop or desktop,
   your default browser, terminal and editor;
5. downloads Omarchy's themes and backgrounds (~110 MB, asks first) and applies Tokyo Night.

Then press **Super + K** for every key. Super is the Windows key.

**Requirements:** Windows 11 22H2 or newer, winget (App Installer), an internet connection for install.

## What you get

| | |
|---|---|
| **Tiling** | GlazeWM with Omarchy's keys: Super+1..0 workspaces (split across your monitors), Super+arrows, Super+Shift+arrows, Super+F, Super+T, Super+J, Super+-/=, Super+drag to move/resize. Nothing minimizes (there's no taskbar to bring it back from) - Super+M / Super+Home restores everything, just in case |
| **Top bar** | Omarchy logo (menu), workspaces, indicators, clock, weather, updates, tray, Bluetooth, network, audio, CPU, battery. Always above windows (except fullscreen ones and games); tiles and maximized windows never go under it. Super+Shift+Space turns it off until you turn it back on |
| **Gaming** | Games get out of the way by themselves: GlazeWM doesn't tile them, the bar hides on the game's monitor, and nothing pops over a game while you play. A gamepad icon in the bar switches to the game or closes it; Super+W closes it too. Gamepad input keeps the screensaver away. See [Games](#games) |
| **Menus** | Super+Alt+Space (Omarchy menu), Super+Escape (system), Super+K (keys), Super+Ctrl+C/O/H (capture/toggle/setup) |
| **Themes** | Super+Ctrl+Shift+Space: 22 Omarchy themes recolor the bar, menus, window borders, Windows accent + light/dark, Windows Terminal, Flow Launcher, VS Code, Claude Code, Neovim (Omarchy-style configs), btop, Chrome/Brave toolbar (opt-in), wallpaper and lock screen |
| **Backgrounds** | Super+Ctrl+Space: every Omarchy background plus your own (`Pictures\Wallpapers`) |
| **Fonts** | Style > Font: one font for terminal, bar, menus and launcher; installs Omarchy's Nerd Fonts |
| **Screensaver** | Omarchy's animated logo ([ttfx](https://github.com/omacom/ttfx) effects) on every monitor after 2.5 min idle (gamepad input counts as activity); never while a video, game or fullscreen app is in front |
| **Wallpaper reveal** | New backgrounds open out of the middle of every monitor in Omarchy v4's slanted band (420 ms) |
| **Window animations** *(experimental)* | `winarchy animations build` compiles GlazeWM's open animation pull request ([#1392](https://github.com/glzr-io/glazewm/pull/1392)) and switches to it: windows zoom and glide to their tiles. Needs Rust + Visual C++ build tools; `animations off` returns to the official GlazeWM |
| **Toggles** | Stay awake, nightlight, do not disturb, top bar, gaps, transparency |
| **Capture** | Region screenshot, screen recording, **text capture (OCR)**, color picker |
| **About / Activity** | fastfetch with the Omarchy logo; btop |

## Everyday commands

```text
winarchy doctor            check everything and explain problems (-Fix repairs)
winarchy theme <name>      switch theme            (winarchy theme list)
winarchy font <family>     switch font             (winarchy font list)
winarchy bg <image>        set the background      (winarchy bg next)
winarchy config            open your settings      (saving applies them)
winarchy animations on     window animations       (experimental; first: animations build)
winarchy bar off           hide the top bar        (winarchy bar on / toggle; Super+Shift+Space)
winarchy update            update winarchy, Omarchy themes and the apps
winarchy uninstall         back to normal Windows  (-DryRun to preview, -KeepApps)
```

## Settings

Your settings live in `%USERPROFILE%\.winarchy\config.json` and only need the keys you change —
see [docs/config.md](docs/config.md). Examples: 24-hour clock, °C, your own workspace-to-monitor map,
more background folders, turning single theme targets off, screensaver timeout.

Bar/menu CSS overrides go in `%USERPROFILE%\.glzr\zebar\omarchy\user.css` (kept across updates).

Like Hyprland, saved edits take effect by themselves: `config.json` re-applies, your GlazeWM
template reloads GlazeWM, your keybindings script reloads, and the bar picks up `user.css`.
Open them from the Omarchy menu (Setup / Style).

## Games

A tiling window manager and a game both want to control the game's window: a game that switches
display mode would otherwise be re-tiled and covered by the bar, and drop out of fullscreen again
and again (black screen, blinking bar). So Winarchy steps aside for games, with any launcher
(Steam, Epic, GOG, Battle.net, EA, Ubisoft, Xbox, Playnite, emulators):

* **What counts as a game:** everything Windows' Game Bar has recognised as one (Windows keeps
  that list for every game you've run); anything installed under Steam/Epic/Xbox/GOG/EA/Ubisoft's
  own folders, or under a folder you list in `"gameDirs"`; anything started by Playnite; and the
  process names you list in `"games": ["MyGame"]`. Playnite's fullscreen mode and Steam Big
  Picture are left alone too. Missed one? Super+Ctrl+G marks the focused window by hand.
* **While a game is in front:** GlazeWM doesn't tile it, the top bar hides on its monitor (the
  other monitors keep theirs), and display changes, bar restarts and the screensaver wait until
  you leave or close the game. A game played in a window is left untiled as well.
* **Switching away and back:** the game itself is left alone (no re-tiling redraw, no workspace
  repair) for as long as it's still open, even minimized or on another workspace - that's what a
  streamed session (Apollo/Sunshine, a virtual display replacing your monitors) used to leave
  black once the stream ended and you'd switched workspaces. The bar still comes back on your
  monitors promptly; switching back to the game's own workspace brings the game back to front.
* **Closing a game:** Super+W / Super+Q, or right-click the gamepad icon in the bar. Doing it
  again within 15 s force-quits a game that doesn't close. Clicking the icon switches back to the game.
* **Games that run as administrator** (the "Run this program as an administrator" compatibility
  setting, common for games): Windows keeps normal programs away from them, so Super+W would reach
  Windows (it opens Widgets) and nothing could close them. Run `winarchy game-setup` once (Omarchy
  menu → Setup → Admin Games; one admin prompt): a small helper then runs as administrator at login
  and does just this: Super+W / Super+Q close admin windows, closing from the bar works, and Super
  alone doesn't open Start there. It runs from an admin-only copy; `winarchy doctor` says when it's
  needed or out of date, and `winarchy game-setup remove` (or uninstall) takes it away.
* **Gamepad:** controller input counts as activity, so the screensaver never starts mid-game,
  and a button press ends it.
* **Turn it off:** `"gameMode": false` in `config.json` (games are then tiled like any window).

## Undo

`winarchy uninstall` (or Omarchy menu → System → Back to normal Windows) replays the backup
journal newest-first: taskbar, accent and light/dark mode, wallpaper and lock screen, Windows
Terminal / Flow / VS Code / Claude Code settings, the Windows screensaver, autostart entries,
PATH, and uninstalls the apps Winarchy installed (`-KeepApps` keeps them). Downloaded themes,
backgrounds and fonts are kept unless you add `-Purge`.

## FAQ

**Some windows can't be moved or tiled.** Windows running as administrator can't be managed by
non-admin tools (GlazeWM, AutoHotkey). That's a Windows security boundary.

**I use several keyboard layouts.** Windows switches layouts with Win+Space; Omarchy uses it for
the launcher. The installer asks. Alt+Shift still switches layouts either way, and
`"takeOverWinSpace": false` in config.json gives Win+Space back.

**Keys on my keyboard layout.** Letters follow your layout (like Hyprland). Punctuation keys
(`,` `-` `=` `` ` ``) are bound by physical position, so they work on AZERTY/QWERTZ too.

**Laptop without a PrtScn key.** Super+Ctrl+C opens the Capture menu (screenshot, recording,
text, color).

**Docking / undocking.** When a monitor is added, workspaces re-split across the monitors automatically. A monitor that sleeps or is unplugged keeps its workspaces: they wait on the other monitors and go back when it returns. If you removed a monitor for good, run `winarchy apply -MonitorsOnly -Resplit`.

**A game gets tiled, or the bar shows over it.** Windows adds a game to its list the first time
Game Bar notices it; the folder/Playnite checks (see [Games](#games)) catch most others right
away. Still missed? Super+Ctrl+G marks the focused window, or add its process name (Task
Manager > Details, without `.exe`) to `"games"` in config.json. The log
(`%USERPROFILE%\.winarchy\logs\winarchy.log`) says `game: <name>` when a game is recognised.

**A window minimized and I can't get it back.** Super+M (or Super+Home) restores every
minimized window. `"blockMinimize": false` in config.json turns off the no-minimize policy
entirely (or add just that one program's process name to `"minimizeAllowed"`).

**Something looks wrong.** Run `winarchy doctor`. Logs: `%USERPROFILE%\.winarchy\logs`.

## Credits

Omarchy by DHH and contributors (MIT) — themes, backgrounds, keybinding design, logo, templates.
GlazeWM and Zebar by glzr-io (GPL-3.0, installed via winget, not bundled). See [NOTICE](NOTICE).

## Contributing

Winarchy is free for anyone to use, change and share. Ideas, fixes and new features are welcome:
see [CONTRIBUTING.md](CONTRIBUTING.md) for how the code is laid out and how to test a change.

## License

MIT — see [LICENSE](LICENSE). Use it, fork it, change it, ship it.
