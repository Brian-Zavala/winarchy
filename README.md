# Winarchy

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
| **Tiling** | GlazeWM with Omarchy's keys: Super+1..0 workspaces (split across your monitors), Super+arrows, Super+Shift+arrows, Super+F, Super+T, Super+J, Super+-/=, Super+drag to move/resize |
| **Top bar** | Omarchy logo (menu), workspaces, indicators, clock, weather, updates, tray, Bluetooth, network, audio, CPU, battery. Always above windows; tiles and maximized windows never go under it |
| **Menus** | Super+Alt+Space (Omarchy menu), Super+Escape (system), Super+K (keys), Super+Ctrl+C/O/H (capture/toggle/setup) |
| **Themes** | Super+Ctrl+Shift+Space: 22 Omarchy themes recolor the bar, menus, window borders, Windows accent + light/dark, Windows Terminal, Flow Launcher, VS Code, Claude Code, Neovim (Omarchy-style configs), btop, Chrome/Brave toolbar (opt-in), wallpaper and lock screen |
| **Backgrounds** | Super+Ctrl+Space: every Omarchy background plus your own (`Pictures\Wallpapers`) |
| **Fonts** | Style > Font: one font for terminal, bar, menus and launcher; installs Omarchy's Nerd Fonts |
| **Screensaver** | Omarchy's animated logo ([ttfx](https://github.com/omacom/ttfx) effects) on every monitor after 2.5 min idle; never while a video plays |
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

**Docking / undocking.** Workspaces re-split across the monitors automatically.

**Something looks wrong.** Run `winarchy doctor`. Logs: `%USERPROFILE%\.winarchy\logs`.

## Credits

Omarchy by DHH and contributors (MIT) — themes, backgrounds, keybinding design, logo, templates.
GlazeWM and Zebar by glzr-io (GPL-3.0, installed via winget, not bundled). See [NOTICE](NOTICE).

## Contributing

Winarchy is free for anyone to use, change and share. Ideas, fixes and new features are welcome:
see [CONTRIBUTING.md](CONTRIBUTING.md) for how the code is laid out and how to test a change.

## License

MIT — see [LICENSE](LICENSE). Use it, fork it, change it, ship it.
