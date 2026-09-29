<img src="images/winarchy-no-bg.png" width="100%" alt="Winarchy">

Most people never choose their desktop. They accept whatever Microsoft ships, bolt on a few tweaks, and settle. Don't settle! The computer you stare at all day deserves more than tolerance. It deserves flavor and taste.

[Omarchy](https://omarchy.org) proved it. DHH and a crew of contributors made a thousand opinionated choices, got nearly all of them right, and kept sharpening the rest. Hyprland tiling. The keyboard for everything. Themes so slick you'll switch them just to gawk at them. It's the Linux desktop as it should have been all along, built on the long tradition of tiling window managers and polished until it shines like heavenly silicon.

But plenty of us are still on Windows. For work, for games, for that one piece of software that simply refuses to integrate into Linux. Fine. That's no excuse to live with a boring computer.

Winarchy brings the good parts over. Omarchy's look, Omarchy's keys, Omarchy's flow, as close as Windows 11 will let us get. Windows tile Hyprland-style. The top bar and the menu are Omarchy's. All twenty-two themes come along, and switching one repaints everything: terminal, editor, wallpaper, the lot. Herdr comes too, with workspaces, tabs, and panes in a persistent session you can walk away from and pick right back up. Park your AI coding agents there, let them work, and never take your hands off the keyboard.

This is omakase. No forty-plugin shopping list. No weekend lost to YAML. One command installs it all. Don't like it? One command takes it back out and puts your machine back the way it was.

Winarchy won't turn Windows into Linux, and it isn't pretending to. It just makes the hours you spend there a whole lot nicer. Enjoy!

*Unofficial, and not affiliated with Omarchy or 37signals. Tracks Omarchy v4.0.4.*

## Install

Open PowerShell (not as administrator) and run:

```powershell
irm https://raw.githubusercontent.com/Brian-Zavala/winarchy/main/install.ps1 | iex
```

Rather read it before you run it? Good instinct. Here's [install.ps1](install.ps1).

## Uninstall

Changed your mind? One line puts Windows back exactly as it was:

```powershell
winarchy uninstall
```

Add `-DryRun` to see what it would undo first.

Before it touches anything, it asks whether to keep the apps you installed through Winarchy, and whether to keep your settings: your `config.json`, theme, background, font, templates and branding. Keep them, and the install one-liner above puts them all back next time without asking the setup questions again. See [system snapshots](manual/47-system-snapshots.md).

## The Winarchy Manual

Like Omarchy, it lives in [`manual/`](manual/). If a chapter is missing, it's because Windows had nothing worth saying about it.

- [Welcome to Winarchy!](manual/01-welcome-to-winarchy.md)

**The Basics**

- [Getting Started](manual/02-getting-started.md)
- [Coming From Mac or Stock Windows](manual/03-coming-from-mac-or-windows.md)
- [Navigation](manual/04-navigation.md)
- [The Top Bar](manual/05-the-top-bar.md)
- [Themes](manual/06-themes.md)
- [Hotkeys](manual/07-hotkeys.md)
- [Unified Clipboard & History](manual/08-unified-clipboard-history.md)
- [Notices](manual/10-notices.md)
- [Text Extraction & Dictation](manual/11-text-extraction-dictation.md)
- [Screenshots & Recording](manual/12-screenshots-recording.md)
- [Toggles, Idle & Screensaver](manual/13-toggles-idle-screensaver.md)
- [Winarchy CLI](manual/14-winarchy-cli.md)

**The Applications**

- [Terminal](manual/15-terminal.md)
- [Neovim](manual/16-neovim.md)
- [AI](manual/17-ai.md)
- [Development Tools](manual/18-development-tools.md)
- [Shell Functions](manual/20-shell-functions.md)
- [TUIs](manual/21-tuis.md)
- [Browsers](manual/23-browsers.md)
- [Commercial Apps & Services](manual/24-commercial-apps-services.md)
- [Web Apps](manual/25-web-apps.md)
- [Gaming](manual/26-gaming.md)
- [Other Packages](manual/29-other-packages.md)

**Configuration**

- [Updates](manual/30-updates.md)
- [Dotfiles](manual/31-dotfiles.md)
- [Monitors](manual/33-monitors.md)
- [Keyboard, Mouse & Trackpad](manual/34-keyboard-mouse-trackpad.md)
- [Fonts](manual/38-fonts.md)
- [Backgrounds](manual/39-backgrounds.md)
- [Branding](manual/41-branding.md)
- [Common Tweaks](manual/42-common-tweaks.md)
- [Making Your Own Theme](manual/43-making-your-own-theme.md)

**The Rest**

- [Troubleshooting](manual/45-troubleshooting.md)
- [FAQ](manual/46-faq.md)
- [System Snapshots](manual/47-system-snapshots.md)
- [Security](manual/48-security.md)
- [Unattended Installs](manual/51-unattended-installs.md)

## License

Winarchy is released under the [MIT License](LICENSE). Omarchy's themes, backgrounds, logo, and designs are by DHH and contributors; see [NOTICE](NOTICE) for every credit.
