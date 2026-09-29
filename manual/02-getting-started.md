# Getting Started

Winarchy installs on top of the Windows 11 you already have. Open PowerShell (not as administrator) and run:

```powershell
irm https://raw.githubusercontent.com/Brian-Zavala/winarchy/main/install.ps1 | iex
```

You need Windows 11 22H2 or newer, winget (App Installer, which ships with Windows 11), and an internet connection for the install.

### What the installer does

1. It asks whether to download Omarchy's themes and backgrounds (about 110 MB). They download in the background while the rest installs.
2. It checks the PC and installs what's missing: PowerShell 7, AutoHotkey v2, the JetBrainsMono Nerd Font, GlazeWM and Zebar (one UAC prompt), Flow Launcher, fastfetch, btop, and Python 3 for the bar's AI agent usage.
3. It asks only the questions that depend on you: keep your own launcher script, hide the taskbar, take over `Win + Space` if you use several keyboard layouts, and install Herdr.
4. It records every setting it changes in a backup journal before changing it, so [uninstalling](47-system-snapshots.md) puts everything back.
5. It writes the configs for your machine: any number of monitors, any scaling, laptop or desktop, and your default browser, terminal and editor.
6. It finishes the theme download, then applies Tokyo Night.

Then press `Super + Space` for the Omarchy menu and `Super + K` for every key.

You don't have to know where something lives in the menu: just type. The search reaches everything under the menu you're in, so from the top, `clion` finds CLion in _Apps_, `tokyo` the Tokyo Night theme and `docker` Docker Desktop in _Install_. Each result says where it's from, and `Enter` runs it.

### Dependencies stay automatic

`winarchy update` installs anything a newer Winarchy needs that your PC doesn't have yet, and `winarchy doctor -Fix` puts back anything that went missing. Each only installs what isn't there, and records it so uninstall takes it back out.

### Unattended installs

Winarchy can also install with nobody answering questions. See [unattended installs](51-unattended-installs.md).

### Help if you're stuck

Run `winarchy doctor` first: it checks every moving part and says what to do about each problem. See [troubleshooting](45-troubleshooting.md) for the rest, and [open an issue](https://github.com/Brian-Zavala/winarchy/issues) if you're still stuck.
