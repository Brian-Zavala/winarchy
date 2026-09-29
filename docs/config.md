# Settings (`%USERPROFILE%\.winarchy\config.json`)

Put only the keys you want to change; everything else comes from
[`default/config.json`](../default/config.json). After editing run `winarchy apply`
(or Omarchy menu → Update → Apply Settings). `winarchy config` opens the file.

```json
{
  "clock": "24h",
  "units": "C",
  "backgroundDirs": ["~\\Pictures\\Wallpapers", "D:\\Art"],
  "screensaver": { "idleSeconds": 300 }
}
```

| Key | Default | What it does |
|---|---|---|
| `clock` | `"auto"` | `"12h"`, `"24h"` or `"auto"` (from your Windows region format) |
| `units` | `"auto"` | Weather in `"C"` or `"F"`; `"auto"` follows your region |
| `workspaces` | `"auto"` | 10 workspaces split over your monitors left to right. Or a map of monitor position (1 = leftmost) to workspace names: `{ "1": ["1","2","3"], "2": ["4","5"] }`. The split grows when a monitor is added but never shrinks by itself (a sleeping monitor looks unplugged); `winarchy apply -MonitorsOnly -Resplit` fits it to the monitors connected now |
| `gap` | `10` | Gap between windows and around the edges, in pixels at 100 % scaling |
| `hideTaskbar` | `true` | Hide the Windows taskbar while GlazeWM runs (it comes back if GlazeWM stops) |
| `hideDesktopIcons` | `true` on a new install | Hide the desktop icons (Explorer's "Show desktop icons" off). An existing install keeps its icons; `false` puts back what the PC had |
| `takeOverWinSpace` | `true` | Super+Space = Omarchy menu, Super+Alt+Space = app launcher, Super+Ctrl(+Shift)+Space = pickers, Super+Shift+Space = bar. `false` leaves Win+Space to Windows' layout switching; the menu then stays on Super+Alt+Space and the launcher on Alt+Space |
| `launchers` | `true` | winarchy's app keys (Super+Return terminal, Super+Shift+B browser, ...). `false` if you use your own launcher script |
| `apps.terminal` / `browser` / `editor` / `files` | `"auto"` | Programs the launcher keys and menus open; `"auto"` detects Windows Terminal, your default browser, Neovim → VS Code → Notepad |
| `apps.agent` | `"auto"` | The coding agent Trigger › Agent and the Herdr layouts start: `claude`, `codex`, `copilot`, `opencode`, `crush`, `cursor-agent`, `grok`, `agy`, `muse`, `omp`, `ori`, `pi`, `hermes`, `openclaw`. `"auto"` means none is chosen yet, and nothing is ticked in Setup › Default Agent — Omarchy picks no agent for you either. Each one is started with its own "don't stop to ask" flags (`winarchy agent list`, then `winarchy default-agent <name>`) |
| `backgroundDirs` | `["~\\Pictures\\Wallpapers"]` | Your own backgrounds ("Mine" in the picker) |
| `themeTargets.<name>` | `true` | Turn one theme target off: `bar`, `glazewm`, `terminal`, `flow`, `accent`, `neovim` (`"auto"` = only Omarchy-style nvim configs), `vscode`, `claude`, `browser`, `btop`, `herdr` |
| `themeTargets.herdr` | `"auto"` | How Herdr is themed. `"auto"` uses the Herdr built-in theme whose name matches your Omarchy theme (`catppuccin`, `catppuccin-latte`, `tokyo-night`, `dracula`, `nord`, `gruvbox`, `one-dark`, `solarized`, `kanagawa`, `rose-pine`, `vesper`) and falls back to `"terminal"` for the rest, which draws Herdr in your terminal's own palette — and winarchy themes Windows Terminal, so Herdr follows the theme either way. Name a Herdr theme here to pin it, or `false` to leave Herdr's config theme alone |
| `screensaver.enabled` | `true` | Omarchy screensaver (replaces Windows' own; uninstall restores it) |
| `screensaver.idleSeconds` | `150` | Idle time before it starts |
| `weather` | `true` | Weather in the bar |
| `agentUsage.enabled` | `true` | The bar's AI agent icon: plan, rate limits, tokens by day and by model for every coding agent on this PC (Omarchy Quattro's agents widget). It only appears once an agent has usage to show, so it costs nothing on a PC without one. Needs Python 3 (`winarchy doctor` says if it is missing) |
| `agentUsage.refreshSeconds` | `900` | How often the usage refreshes (30 to 3600). Opening the panel always refreshes the limits |
| `agentUsage.providers` | `{}` | Hide one agent that is installed: `{ "codex": { "enabled": false } }`. Collectors ship for `claude`, `codex` and `fireworks`; a new `lib/agents/usage-<id>.py` is picked up with no other change. Claude's limits come from Anthropic's usage endpoint using Claude Code's own sign-in (the token goes nowhere else and never into a file), Codex's from `codex app-server`; `CLAUDE_CONFIG_DIR` and `CODEX_HOME` are honored. Fireworks reads `FIREWORKS_API_KEY` or `~/.fireworks/auth.ini`, and an optional `~/.config/omarchy/agents/fireworks.json` for its balance |
| `location` | `null` | `{ "lat": 51.5, "lon": -0.12, "name": "London" }` instead of the IP-based guess (ipinfo.io) |
| `screenshotAutoCopy` | `true` | Copy every new screenshot file to the clipboard, so a snip pastes straight into a terminal app like Claude Code |
| `syncAtLogin` | `true` | Re-index your background folders after login (no downloads) |
| `glazewmManaged` | `true` | `false` = winarchy stops writing `~/.glzr/glazewm/config.yaml` (edit it yourself) |
| `gameMode` | `true` | Games get out of the way: GlazeWM doesn't tile them, the bar hides on the game's monitor, and display-mode changes, bar restarts and the screensaver wait until you leave or close it. Super+W and the bar's gamepad icon close a game; gamepad input counts as activity. Games = the ones Windows' Game Bar recognised (any launcher) + `games`. See the README's Games section |
| `games` | `[]` | More game process names, e.g. `["MyGame"]` or `["MyGame.exe"]` |
| `gameDirs` | `[]` | Folders your games live in, e.g. `["C:\\Games", "G:\\"]`. Catches a game Windows' Game Bar never learned about (installed under Steam/Epic/Xbox/GOG/EA/Ubisoft's own folders, or started by Playnite, is already caught) |
| `blockMinimize` | `true` | Nothing minimizes (the taskbar is hidden, so a minimized window has no way back): windows with a standard title bar lose their minimize button, and anything that minimizes anyway (apps drawing their own title bar) snaps straight back. Also turns off Windows' minimize/maximize animation (and Aero Shake); turning it off puts both back. Exceptions: games, Playnite/Steam Big Picture, `minimizeAllowed`, and dialogs/popups. Super+M / Super+Home restores everything regardless (also: the Toggle menu); Super+D (show desktop) does nothing while this is on |
| `gameFocusGuard` | `true` | A game that loses the foreground without you asking (no key, click or pad input just before) gets it straight back - a fullscreen game otherwise minimizes itself. Every loss is logged as `game lost focus: <game> -> <program>` either way. Admin games need `winarchy game-setup` |
| `minimizeAllowed` | `[]` | Process names allowed to minimize even with `blockMinimize` on, e.g. `["Spotify"]` |
| `openOnHoveredMonitor` | `true` | A new window opens on the monitor under the mouse, the way Hyprland opens it on the focused one, instead of on Windows' primary display. Windows has no "focused monitor", so a window is born on the primary and GlazeWM tiles it into whatever workspace is bound there; winarchy re-homes it to the workspace displayed under the cursor. Left alone: dialogs and popups (they stay with the window that opened them), games, fullscreen windows, windows GlazeWM ignores, and anything that already landed on the right monitor. Needs two monitors to do anything |
| `focusFollowsCursor` | `true` | Focus follows the mouse (Hyprland's `follow_mouse`), re-asserted by winarchy. GlazeWM has its own `focus_follows_cursor`, but it stops following once the pointer touches a window GlazeWM doesn't manage (glzr-io/glazewm#1326) - the bar, Flow Launcher and the pickers, which cover the top strip of every screen - and its cursor warps can re-steal focus (#760). winarchy focuses the window the pointer settles over, which is what a click does. Only real cursor movement moves focus (never while you type with the pointer parked elsewhere), it waits for the pointer to settle so sweeping the screen doesn't focus everything on the way, and it stands down during games/fullscreen and while Super is held (Super+drag moves and resizes). `false` leaves focus entirely to GlazeWM |
| `backgroundTransition` | `"reveal"` | Omarchy v4's slanted reveal when the wallpaper changes; `"none"` for an instant change (skipped while Wallpaper Engine or Lively runs). The background picker plays it on its own monitor, from the blurred preview |
| `animations.enabled` | `false` | Experimental window animations: run the GlazeWM build of glzr-io/glazewm#1392 (`winarchy animations build`, then `animations on`). Trade-off: the official GlazeWM has Windows' "UI access", the local build can't (only signed programs under Program Files can), so its keys stop working whenever an admin window is in front - Super+1..0 included, i.e. no workspace switching over a game run as administrator. `winarchy game-setup` (one admin prompt) brings them back; `winarchy doctor` says when it's needed. If the animation build stops twice within 5 minutes, winarchy switches animations off by itself |
| `animations.moveMs` / `openMs` / `closeMs` | `379` / `410` / `149` | Durations (Omarchy's `looknfeel.lua`); shorter feels snappier |
| `animations.workspaceSwitch` | `false` | Slide between workspaces (Omarchy keeps this off) |
| `autoTiling.enabled` | `true` | Hyprland-style auto-tiling: a background watcher (`lib/autotile-watch.ps1`, started by GlazeWM like Zebar, restarted by winarchy.ahk if it dies, and single-instance so the two can't both run one) wraps each new window that lands next to an existing one into its own perpendicular split, so windows spiral outward instead of piling into one flat row/column (GlazeWM's default). GlazeWM has no built-in dwindle layout; this reacts to each window opening rather than predicting the split ahead of time, so it can occasionally need a `Super+J` nudge to match exactly. `winarchy autotile [on\|off\|toggle\|status]` |
| `omarchyTag` | `"v4.0.4"` | Omarchy release the themes/backgrounds come from (`winarchy update` moves it) |

## Customizing beyond config.json

* **GlazeWM:** Omarchy menu → Setup → GlazeWM creates `%USERPROFILE%\.winarchy\glazewm.yaml.tpl`
  (a copy of `templates/glazewm.yaml.tpl`); saving it rewrites GlazeWM's config and reloads it.
  Placeholders: `{{ gap }}`, `{{ gap_top }}`, `{{ focused_border }}`, `{{ workspaces }}`, `{{ animations }}`, `{{ games }}`, `{{ autotile_startup }}`.
  Delete the file to go back to the default.
* **Herdr:** Omarchy menu → Setup → Herdr Config creates `%USERPROFILE%\.winarchy\herdr.toml.tpl`
  (a copy of `templates/herdr.toml.tpl`); saving it rewrites `%APPDATA%\herdr\config.toml` and
  reloads a running Herdr. Placeholders: `{{ herdr_theme }}`, `{{ herdr_theme_custom }}`,
  `{{ herdr_accent }}`, `{{ herdr_shell }}`. Delete the file to go back to the default.
  The default keeps Omarchy's tmux-shaped bindings (prefix `Ctrl+Space`) and points Herdr's
  panes at PowerShell 7, which is what `winarchy` and the `hdl`/`hds`/`hdlm`/`hsl` shortcuts
  need. `winarchy herdr status` says where everything is; Learn → Herdr keys lists the
  bindings Herdr actually loaded.
* **Herdr shortcuts:** `hdl`, `hds`, `hdlm` and `hsl` are written into
  `%USERPROFILE%\Documents\PowerShell\profile.ps1` between `# >>> winarchy herdr shortcuts >>>`
  markers (re-running replaces just that block; uninstall restores the file). They only work
  inside a Herdr pane, which is where `HERDR_PANE_ID` comes from.
* **App keys:** Omarchy menu → Setup → Keybindings opens your launcher script (your own
  `Startup\launchers.ahk`, or `%USERPROFILE%\.winarchy\launchers.ahk`, a copy of winarchy's);
  saving reloads it.
* **Bar and menu look:** `%USERPROFILE%\.glzr\zebar\omarchy\user.css` (loaded last, never overwritten).
* **Screensaver / About art:** Omarchy menu → Style → Screensaver / About → Edit Text.
* **Browser toolbar color:** `winarchy browser-setup` (one admin prompt; Chrome then says
  "Managed by your organization" because the color is a browser policy).
