# Winarchy CLI

Everything the Omarchy menu does is also a `winarchy` command, for scripts or when you're in a terminal anyway. `winarchy help` lists them all.

### Everyday

| Command | What it does |
|---|---|
| `winarchy doctor [-Fix]` | Check everything and explain what's wrong; `-Fix` repairs what it can |
| `winarchy theme <name>` | Switch theme (`winarchy theme list` shows them) |
| `winarchy bg <image>` / `winarchy bg next` | Set the background, or go to the next one |
| `winarchy font <family>` | Switch font (`winarchy font list`); `winarchy font-install <Name>` installs a Nerd Font |
| `winarchy config` | Open your settings; saving applies them |
| `winarchy apply [-MonitorsOnly] [-Resplit]` | Apply your settings again; `-Resplit` fits the workspaces to the monitors connected now |
| `winarchy bar on\|off\|toggle` | The top bar |
| `winarchy keys` | Print the keybindings |
| `winarchy keys-refresh` | Read again which keys your own Startup scripts bind (Winarchy's leave those to them; this runs by itself when one is saved) |
| `winarchy status` / `winarchy version` | The current theme, background and font / the version |

### Apps

| Command | What it does |
|---|---|
| `winarchy catalog` | What _Install_ and _Remove_ offer, and what you already have |
| `winarchy install-app <key>` / `winarchy remove-app <key>` | Install or remove one of them |
| `winarchy apps` | Rebuild the menu's _Apps_ list |

### Coding agents and Herdr

| Command | What it does |
|---|---|
| `winarchy agent [-Inline] [-Prompt <text>]` | Start your default coding agent; `winarchy agent list` shows them all |
| `winarchy default-agent <name>` | Choose the default agent, and start it |
| `winarchy agent-usage [-Force]` | Refresh the bar's agent usage |
| `winarchy herdr status` | Where Herdr is, its config and its theme |
| `winarchy herdr layout\|square\|multi\|swarm` | The layouts behind `hdl`, `hds`, `hdlm` and `hsl` (see [shell functions](20-shell-functions.md)) |

### Windows and games

| Command | What it does |
|---|---|
| `winarchy autotile on\|off\|toggle\|status` | Hyprland-style auto-tiling |
| `winarchy taskbar on\|off\|toggle\|status` | Hide the Windows taskbar, or bring it back |
| `winarchy animations on\|off\|toggle\|build\|status` | Experimental window animations |
| `winarchy game-add <name>` | Treat a program as a game |
| `winarchy game-setup [remove]` | The helper for games that run as administrator (see [gaming](26-gaming.md)) |
| `winarchy browser-setup` | Tint Chrome and Brave's toolbar with the theme |

### Install, update, uninstall

| Command | What it does |
|---|---|
| `winarchy install [-Yes]` | Set everything up; `-Yes` takes every recommended answer |
| `winarchy update` | Update Winarchy, the themes, Herdr and your apps (see [updates](30-updates.md)) |
| `winarchy update-check` | Look for updates now |
| `winarchy timezone-set <Region/City>` / `winarchy time-sync` | Set the time zone / sync the clock (admin prompt) |
| `winarchy dns-set <dhcp\|cloudflare\|google\|custom>` | Switch the DNS servers on your connections (admin prompt) |
| `winarchy reminder [when] [text]` / `reminder show` / `reminder clear` | Set, list or clear reminders |
| `winarchy speedtest [network\|disk]` | Measure your internet or disk speed |
| `winarchy transcode [file] [format] [size]` | Omarchy's transcode: a picture to jpg / png (high, medium, low), a video to mp4 / gif (4k, 1080p, 720p), saved beside it and copied to the clipboard |
| `winarchy web-app [name] [url]` / `web-app remove` | Add or remove a web app of your own (Omarchy's are in _Install > Web Apps_; see [web apps](25-web-apps.md)) |
| `winarchy deps` | Install anything Winarchy needs that's missing |
| `winarchy sync [-Offline]` | Download Omarchy's themes and backgrounds, and rebuild the selectors |
| `winarchy uninstall [-DryRun] [-KeepApps] [-Purge] [-Yes]` | Back to normal Windows (see [system snapshots](47-system-snapshots.md)) |

The log is in `%USERPROFILE%\.winarchy\logs\winarchy.log`.
