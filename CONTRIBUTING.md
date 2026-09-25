# Contributing to Winarchy

Winarchy is MIT-licensed: use it, fork it, change it, share it. Pull requests and issues are welcome,
whether that's a bug report, a fix for your hardware, a new theme target or a whole feature.

## How it fits together

| Folder | What lives there |
|---|---|
| `bin/winarchy.ps1` | The CLI (`winarchy <verb>`): every verb dispatches into `lib/` |
| `lib/*.ps1` | PowerShell 7 logic: detection, templates, themes, apply, backup journal, uninstall, doctor, extras |
| `ps51/*.ps1` | Small Windows PowerShell 5.1 helpers for WinRT APIs (lock screen, Bluetooth, OCR) |
| `ahk/winarchy.ahk` | The always-running AutoHotkey script: keys GlazeWM can't do, toggles, screensaver, live reload |
| `ahk/menu.ahk` | Action dispatcher for the bar and the Omarchy menu (Zebar calls it) |
| `ahk/lib/` | Shared AutoHotkey helpers (`env.ahk` reads the generated settings, `osd.ahk`) |
| `zebar/omarchy/` | The top bar and the menu/pickers (HTML/CSS/JS, a Zebar widget pack) |
| `templates/` | GlazeWM config and Flow Launcher theme templates |
| `default/` | Default `config.json` and the keybindings list |
| `tests/` | Pester tests for the machine-independent logic |

Your machine's settings live in `%USERPROFILE%\.winarchy` (config, state, logs, backups); the generated
configs go to `~/.glzr/`. Nothing in the repo hard-codes a path: `winarchy apply` writes them for
the PC it runs on.

## Rules of thumb

- **Every change to the system is recorded first** in the backup journal (`lib/journal.ps1`), so
  `winarchy uninstall` can undo it. New targets should use `Save-File`, `Save-Reg`, `Save-JsonProperty`.
- **Any PC:** any number of monitors, any DPI, any keyboard layout and UI language. Match windows by
  process and class, not by English titles; use scan codes for punctuation keys.
- **Degrade gracefully:** if an app is missing, skip that target with a log line instead of failing.
- **Don't pop UI in tests.** Anything that shows windows or changes the desktop needs a human check.

## Testing a change

```powershell
Invoke-Pester ./tests                                   # unit tests
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error  # lint
AutoHotkey64.exe /ErrorStdOut /validate ahk\winarchy.ahk
winarchy apply; winarchy doctor                         # on your PC
```

CI runs the same checks on every push and pull request.

## Credits

Winarchy is an unofficial port of [Omarchy](https://github.com/omacom/omarchy) (MIT) to Windows, built on
GlazeWM and Zebar (GPL-3.0, installed separately). Please keep the credits in `NOTICE` when you
redistribute it.
