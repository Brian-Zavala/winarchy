# Settings (`%USERPROFILE%\.omarchy-win\config.json`)

Put only the keys you want to change; everything else comes from
[`default/config.json`](../default/config.json). After editing run `omarchy-win apply`
(or Omarchy menu → Update → Apply Settings). `omarchy-win config` opens the file.

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
| `workspaces` | `"auto"` | 10 workspaces split over your monitors left to right. Or a map of monitor position (1 = leftmost) to workspace names: `{ "1": ["1","2","3"], "2": ["4","5"] }` |
| `gap` | `10` | Gap between windows and around the edges, in pixels at 100 % scaling |
| `hideTaskbar` | `true` | Hide the Windows taskbar while GlazeWM runs (it comes back if GlazeWM stops) |
| `takeOverWinSpace` | `true` | Super+Space = launcher, Super+Ctrl(+Shift)+Space = pickers, Super+Shift+Space = bar. `false` leaves Win+Space to Windows' layout switching |
| `launchers` | `true` | omarchy-win's app keys (Super+Return terminal, Super+Shift+B browser, ...). `false` if you use your own launcher script |
| `apps.terminal` / `browser` / `editor` / `files` | `"auto"` | Programs the launcher keys and menus open; `"auto"` detects Windows Terminal, your default browser, Neovim → VS Code → Notepad |
| `backgroundDirs` | `["~\\Pictures\\Wallpapers"]` | Your own backgrounds ("Mine" in the picker) |
| `themeTargets.<name>` | `true` | Turn one theme target off: `bar`, `glazewm`, `terminal`, `flow`, `accent`, `neovim` (`"auto"` = only Omarchy-style nvim configs), `vscode`, `claude`, `browser`, `btop` |
| `screensaver.enabled` | `true` | Omarchy screensaver (replaces Windows' own; uninstall restores it) |
| `screensaver.idleSeconds` | `150` | Idle time before it starts |
| `weather` | `true` | Weather in the bar |
| `location` | `null` | `{ "lat": 51.5, "lon": -0.12, "name": "London" }` instead of the IP-based guess (ipinfo.io) |
| `screenshotAutoCopy` | `false` | Copy every new screenshot file to the clipboard |
| `syncAtLogin` | `true` | Re-index your background folders after login (no downloads) |
| `glazewmManaged` | `true` | `false` = omarchy-win stops writing `~/.glzr/glazewm/config.yaml` (edit it yourself) |
| `backgroundTransition` | `"reveal"` | Omarchy v4's slanted reveal when the wallpaper changes; `"none"` for an instant change (skipped while Wallpaper Engine or Lively runs) |
| `animations.enabled` | `false` | Experimental window animations: run the GlazeWM build of glzr-io/glazewm#1392 (`omarchy-win animations build`, then `animations on`) |
| `animations.moveMs` / `openMs` / `closeMs` | `379` / `410` / `149` | Durations (Omarchy's `looknfeel.lua`); shorter feels snappier |
| `animations.workspaceSwitch` | `false` | Slide between workspaces (Omarchy keeps this off) |
| `omarchyTag` | `"v4.0.4"` | Omarchy release the themes/backgrounds come from (`omarchy-win update` moves it) |

## Customizing beyond config.json

* **GlazeWM:** Omarchy menu → Setup → GlazeWM creates `%USERPROFILE%\.omarchy-win\glazewm.yaml.tpl`
  (a copy of `templates/glazewm.yaml.tpl`); saving it rewrites GlazeWM's config and reloads it.
  Placeholders: `{{ gap }}`, `{{ gap_top }}`, `{{ focused_border }}`, `{{ workspaces }}`, `{{ animations }}`.
  Delete the file to go back to the default.
* **App keys:** Omarchy menu → Setup → Keybindings opens your launcher script (your own
  `Startup\launchers.ahk`, or `%USERPROFILE%\.omarchy-win\launchers.ahk`, a copy of omarchy-win's);
  saving reloads it.
* **Bar and menu look:** `%USERPROFILE%\.glzr\zebar\omarchy\user.css` (loaded last, never overwritten).
* **Screensaver / About art:** Omarchy menu → Style → Screensaver / About → Edit Text.
* **Browser toolbar color:** `omarchy-win browser-setup` (one admin prompt; Chrome then says
  "Managed by your organization" because the color is a browser policy).
