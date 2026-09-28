# System Snapshots

Omarchy takes filesystem snapshots so an update can be rolled back. Windows has nothing like that for your settings, so Winarchy keeps its own record instead: every change it makes to the system is written into a backup journal before it's made, and `winarchy uninstall` replays that journal to put everything back.

The journal lives in `%USERPROFILE%\.winarchy\backup`, one folder per install, with a copy of every file Winarchy replaced.

### What gets recorded

The taskbar, the accent color and light or dark mode, the wallpaper and lock screen, the Windows Terminal, Flow Launcher, VS Code and Claude Code settings Winarchy changes, the Windows screensaver, autostart entries, PATH, the Herdr shortcuts in your PowerShell profile, Herdr's config, installed fonts, and every app installed along the way.

Only the first recording of each thing counts, so running the install or `winarchy apply` again never overwrites the real original.

### Back to normal Windows

`winarchy uninstall`, or _System > Back to normal Windows_ in the Omarchy menu, replays the journal newest-first. `winarchy uninstall -DryRun` shows what it would do without doing it.

It undoes only Winarchy's part of files you share with it. Your PowerShell profile loses just the Herdr shortcuts, VS Code's extension list just Winarchy's theme, and Flow Launcher's and btop's settings just the theme keys, so everything you changed in them since keeps. The same goes for startup programs: only those of the apps Winarchy set up are taken out.

Before it changes anything, it asks two questions:

- **Keep the apps you installed through Winarchy?** Anything from the menu's _Install_ section (Cursor, Steam and so on) and Herdr: keep all, remove all, or choose each.
- **Keep your settings?** Your `config.json`, theme, background and font, your own templates, and your branding. Kept settings are applied again the next time you install Winarchy, and the questions you already answered aren't asked again.

`-Yes` keeps both without asking, and `-KeepApps` keeps everything Winarchy runs on (GlazeWM, Flow Launcher, AutoHotkey and the rest). Downloaded themes and backgrounds are kept unless you add `-Purge`, which still keeps your settings if you said so.

When it's done, the journal is archived, so a later install starts a fresh one.
