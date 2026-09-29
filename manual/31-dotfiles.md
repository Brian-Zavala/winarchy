# Dotfiles

Winarchy keeps your settings in one file, `%USERPROFILE%\.winarchy\config.json`, and it only needs the keys you want to change. Everything else comes from [`default/config.json`](../default/config.json). `winarchy config` opens it, as does _Setup > Config > Settings_ in the Omarchy menu.

Like Hyprland, a saved edit takes effect by itself: `config.json` is applied again the moment you save it. From a terminal, `winarchy apply` does the same.

```json
{
  "clock": "24h",
  "units": "C",
  "backgroundDirs": ["~\\Pictures\\Wallpapers", "D:\\Art"],
  "screensaver": { "idleSeconds": 300 }
}
```

It's JSON, so a `\` in a path is written `\\`. A file with a mistake in it is left alone rather than overwritten, and `winarchy doctor` says where the mistake is.

## Settings

### Desktop

| Key | Default | What it does |
|---|---|---|
| `workspaces` | `"auto"` | The ten workspaces split over your monitors from left to right. Or a map of monitor position (1 is the leftmost) to workspace names: `{ "1": ["1","2","3"], "2": ["4","5"] }`. See [monitors](33-monitors.md) |
| `gap` | `10` | Gap between windows and around the edges, in pixels at 100% scaling |
| `barHeight` | `26` | Height of the top bar, in pixels at 100% scaling. It grows with `textSize` above 12 |
| `textSize` | `12` | Text size of the bar, its panels and the terminals, in px from 9 to 20. The bar's Display panel sets it, as does `winarchy text-size` |
| `hideTaskbar` | `true` | Hide the Windows taskbar while GlazeWM runs (it comes back if GlazeWM stops) |
| `hideDesktopIcons` | `true` on a new install | Hide the desktop icons (Explorer's "Show desktop icons" off). An existing install keeps its icons; `false` puts back what the PC had |
| `takeOverWinSpace` | `true` | `Super + Space` opens the Omarchy menu. `false` leaves `Win + Space` to Windows' layout switching; the menu then stays on `Super + Alt + Space`, and the launcher on `Alt + Space` |
| `launchers` | `true` | Winarchy's app keys (`Super + Return` terminal, `Super + Shift + B` browser, ...). `false` if you use your own launcher script. Either way, a key your own Startup script binds stays yours |
| `captureKeys` | `"winarchy"` | The `Print` key layout. `"omarchy"` (what a new install writes) is Omarchy's: `Super + Print` color picker, `Super + Ctrl + Print` text capture, `Shift + Print` full screenshot. `"winarchy"` (installs from before keep it): `Super + Print` full screenshot, `Super + Ctrl + Print` color picker, `Super + Shift + Print` text capture |
| `compose` | `false` | `CapsLock` as Omarchy's compose key: `CapsLock m s` 😄, `CapsLock Space Space` an em dash, `CapsLock Space n` / `Space e` your name / email (from git). Both Shift keys together toggle Caps Lock. A new install turns it on, except with a Japanese, Chinese or Korean input method. Your own sequences go in `%USERPROFILE%\.winarchy\compose.txt`, written like Omarchy's `~/.XCompose` |
| `blockMinimize` | `true` | Nothing minimizes, since the taskbar is hidden and a minimized window would have no way back. Windows with a standard title bar lose their minimize button, and anything that minimizes anyway snaps straight back. Also turns off Windows' minimize animation and Aero Shake; turning it off puts both back. Games, dialogs and `minimizeAllowed` are left alone, and `Super + M` restores everything regardless |
| `minimizeAllowed` | `[]` | Process names allowed to minimize anyway, e.g. `["Spotify"]` |
| `openOnHoveredMonitor` | `true` | A new window opens on the monitor under the mouse instead of the primary display. See [monitors](33-monitors.md) |
| `focusFollowsCursor` | `true` | Focus follows the mouse, like Hyprland's `follow_mouse`. It waits for the pointer to settle, only follows real movement (never while you type), and stands down during games and while `Super` is held. `false` leaves focus to GlazeWM |
| `autoTiling.enabled` | `true` | Hyprland-style dwindle tiling: each new window splits the space of the one it lands next to, so windows spiral outward instead of piling into one row. `winarchy autotile on\|off\|toggle\|status` |
| `glazewmManaged` | `true` | `false` stops Winarchy writing GlazeWM's `config.yaml`, so you can edit it yourself |

### Apps

| Key | Default | What it does |
|---|---|---|
| `apps.terminal` / `browser` / `editor` / `files` | `"auto"` | The programs the launcher keys and menus open. `"auto"` finds Windows Terminal, your default browser, Neovim then VS Code then Notepad, and File Explorer |
| `apps.agent` | `"auto"` | The coding agent _Trigger > Agent_ and the Herdr layouts start: `claude`, `codex`, `copilot`, `opencode`, `crush`, `cursor-agent`, `grok`, `agy`, `muse`, `omp`, `ori`, `pi`, `hermes` or `openclaw`. `"auto"` means Claude Code once it's installed, and none before that. See [AI](17-ai.md) |

### Look

| Key | Default | What it does |
|---|---|---|
| `clock` | `"auto"` | `"12h"`, `"24h"`, or `"auto"` to follow your Windows region format |
| `units` | `"auto"` | Weather in `"C"` or `"F"`; `"auto"` follows your region |
| `weather` | `true` | Weather in the bar |
| `location` | `null` | `{ "lat": 51.5, "lon": -0.12, "name": "London" }` instead of the guess from your IP address (ipinfo.io) |
| `backgroundDirs` | `["~\\Pictures\\Wallpapers"]` | Your own backgrounds, shown under _Mine_. See [backgrounds](39-backgrounds.md) |
| `backgroundTransition` | `"reveal"` | Omarchy v4's slanted reveal when the background changes; `"none"` for an instant change (skipped while Wallpaper Engine or Lively runs) |
| `themeTargets.<name>` | `true` | Turn one theme target off: `bar`, `glazewm`, `terminal`, `flow`, `accent`, `neovim`, `vscode`, `claude`, `browser`, `btop` or `herdr`. `neovim` defaults to `"auto"`, which themes only Omarchy-style Neovim configs |
| `themeTargets.herdr` | `"auto"` | `"auto"` uses the Herdr theme with your Omarchy theme's name (`catppuccin`, `catppuccin-latte`, `tokyo-night`, `dracula`, `nord`, `gruvbox`, `one-dark`, `solarized`, `kanagawa`, `rose-pine`, `vesper`) and otherwise `"terminal"`, which draws Herdr in your terminal's palette, and Winarchy themes the terminal. Name a Herdr theme to pin it, or `false` to keep Herdr on its terminal palette |
| `screensaver.enabled` | `true` | Omarchy's screensaver, in place of Windows' own (uninstalling restores it) |
| `screensaver.idleSeconds` | `150` | Idle time before it starts |
| `animations.enabled` | `false` | Experimental window animations from a GlazeWM build with its animation pull request. The install offers them as its last step; later, `winarchy animations setup` does everything (build tools, the build, a Defender exclusion, switching on), or `winarchy animations build`, then `winarchy animations on`. That build can't have Windows' "UI access", so its keys stop working in front of admin windows unless you run `winarchy game-setup`. It switches itself off if it crashes twice in five minutes, or if Windows Defender removes it (it is unsigned and built on your PC): `winarchy animations allow` excludes its three files from Defender with one admin prompt and puts them back without a rebuild |
| `animations.moveMs` / `openMs` / `closeMs` | `379` / `410` / `149` | Durations, from Omarchy's `looknfeel.lua` |
| `animations.workspaceSwitch` | `false` | Slide between workspaces (Omarchy keeps this off too) |
| `animations.source` | | The GlazeWM repo and commit `winarchy animations build` compiles |

### Games

| Key | Default | What it does |
|---|---|---|
| `gameMode` | `true` | Games get out of the way. See [gaming](26-gaming.md) |
| `games` | `[]` | More game process names, e.g. `["MyGame"]` |
| `gameDirs` | `[]` | Folders your games live in, e.g. `["C:\\Games", "G:\\"]` |
| `gameFocusGuard` | `true` | A game that loses the foreground without you asking gets it straight back |

### Agent usage

| Key | Default | What it does |
|---|---|---|
| `agentUsage.enabled` | `true` | The bar's AI agent icon. It only appears once an agent has usage to show, and needs Python 3 |
| `agentUsage.refreshSeconds` | `900` | How often the usage refreshes (30 to 3600). Opening the panel always refreshes the limits |
| `agentUsage.providers` | `{}` | Hide one agent: `{ "codex": { "enabled": false } }`. See [AI](17-ai.md) |

### Updates and downloads

| Key | Default | What it does |
|---|---|---|
| `syncAtLogin` | `true` | Index your background folders again after login (no downloads) |
| `screenshotAutoCopy` | `true` | Copy every new screenshot file to the clipboard, so a snip pastes straight into a terminal app like Claude Code |
| `omarchyRepo` | `"omacom/omarchy"` | The GitHub repo the themes and backgrounds come from |
| `omarchyTag` | `"v4.0.4"` | The Omarchy release they come from. `winarchy update` moves it to the latest |
| `zebarClientVersion` | `"3.0.3"` | The version of Zebar's client library the bar loads |
| `ttfxUrl` | `null` | A download for the screensaver's effects engine, used instead of building it with Rust |

## Beyond config.json

### GlazeWM

_Setup > Config > GlazeWM_ in the Omarchy menu creates `%USERPROFILE%\.winarchy\glazewm.yaml.tpl`, a copy of [the default template](../templates/glazewm.yaml.tpl). Saving it rewrites GlazeWM's config and reloads GlazeWM. It uses these placeholders: `{{ gap }}`, `{{ gap_top }}`, `{{ focused_border }}`, `{{ workspaces }}`, `{{ animations }}`, `{{ games }}` and `{{ autotile_startup }}`. Delete the file to go back to the default.

### Herdr

_Setup > Config > Herdr_ creates `%USERPROFILE%\.winarchy\herdr.toml.tpl`, a copy of [the default template](../templates/herdr.toml.tpl). Saving it rewrites `%APPDATA%\herdr\config.toml` and reloads a running Herdr. It uses these placeholders: `{{ herdr_theme }}`, `{{ herdr_theme_custom }}`, `{{ herdr_accent }}` and `{{ herdr_shell }}`. Delete the file to go back to the default.

The default keeps Omarchy's tmux-shaped bindings (prefix `Ctrl + Space`) and points Herdr's panes at PowerShell 7, which `winarchy` and the `hdl`, `hds`, `hdlm` and `hsl` shortcuts need. `winarchy herdr status` says where everything is.

### Shell shortcuts

`hdl`, `hds`, `hdlm` and `hsl` are written into `%USERPROFILE%\Documents\PowerShell\profile.ps1`, between `# >>> winarchy herdr shortcuts >>>` markers. Running the install or `winarchy apply` again replaces just that block, and uninstalling takes just that block back out. See [shell functions](20-shell-functions.md).

### App keys

_Setup > Keybindings_ opens your launcher script: your own `Startup\launchers.ahk`, or `%USERPROFILE%\.winarchy\launchers.ahk`, a copy of Winarchy's. Saving it reloads it.

### The bar and menu

Put your CSS in `%USERPROFILE%\.glzr\zebar\omarchy\user.css`. It's loaded last and never overwritten, and the bar picks it up as soon as you save. _Style > Menu Bar_ opens it.

### Screensaver and About

_Style > Screensaver_ and _Style > About_ let you edit the text they show. See [branding](41-branding.md).
