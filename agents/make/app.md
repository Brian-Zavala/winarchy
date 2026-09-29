# Making an app for Winarchy

The usage panel's _Make something > App_ tile hands you this guide. You're making a small app for the user's Windows desktop running Winarchy, the Windows port of Omarchy. First ask what it should do. Then build it, put it in Start so the user's launchers find it, start it once, and ask if they want anything changed.

## Where it goes

`%USERPROFILE%\.winarchy\apps\<name>\`, one folder per app. The agent was started in `%USERPROFILE%\.winarchy\apps`. Pick the simplest thing that does the job, using what the PC already has:

- **A terminal app.** PowerShell 7 (`pwsh`), or Python if `python` runs. Omarchy's taste is keyboard-first TUIs.
- **A window app.** A single HTML page opened in the browser's app mode, or Python's `tkinter`.
- **A web app.** A site the user already uses, in a window of its own.

Don't install system-wide runtimes or services without asking. A Python package the app needs goes in a virtual environment in its own folder.

## Match the theme

The current theme's colours are in `%USERPROFILE%\.glzr\zebar\omarchy\theme.css` (`--bg`, `--fg`, `--accent`, ...). Terminal apps get them from the terminal's own colours, so plain ANSI colours follow the theme by themselves.

## Put it in Start

Winarchy's _Apps_ list and Flow Launcher (`Super + Space`) find programs in Start.

- **A terminal program:** `winarchy tui-add "<Name>" "<command>"`. The command is the program, then any arguments, with a path with spaces in quotes. For example: `winarchy tui-add "Pomodoro" "pwsh -NoProfile -File C:\Users\me\.winarchy\apps\pomodoro\pomodoro.ps1"`. It opens in the terminal from Start and _Apps_. `winarchy tui-remove "<Name>"` takes it out.
- **A site:** `winarchy web-app "<Name>" "<https url>"`. It opens in the browser's app mode, a window with no tabs. `winarchy web-app remove "<Name>"` takes it out.
- **Anything else with a window:** a shortcut in the user's Start folder, then `winarchy apps` so _Apps_ lists it. For a local HTML page, the target is Edge, Chrome or Brave and the arguments are `--app=file:///C:/path/to/index.html`.

  ```powershell
  $lnk = Join-Path ([Environment]::GetFolderPath('Programs')) '<Name>.lnk'
  $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
  $s.TargetPath = '<exe>'; $s.Arguments = '<args>'; $s.WorkingDirectory = '<folder>'; $s.Save()
  winarchy apps
  ```

To give it a key, the user's launchers script is `%USERPROFILE%\.winarchy\launchers.ahk` (Omarchy menu: _Setup > Keybindings_). Offer that; don't change it unasked.
