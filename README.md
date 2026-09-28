![Winarchy](images/winarchy-no-bg.png)

Most people never choose their desktop. They take whatever Microsoft ships, pile a few tweaks on top, and call it a setup. That's a shame, because the computer you stare at all day should be a joy to use, not a compromise you've learned to tolerate.

[Omarchy](https://omarchy.org) showed what happens when somebody makes all the choices for you and makes them well. It's beautiful and fast, and it's opinionated in the best sense: tiling windows, keyboard first, themes that actually look good. But it's Linux, and plenty of us are stuck on Windows for work, for games, or for software that simply won't leave.

So Winarchy brings the good parts over. It's Omarchy's look, its keys and its flow, on Windows 11. Windows tile themselves the way they do in Hyprland. The top bar and the menu are Omarchy's. All twenty-two themes come with it, and switching between them repaints the whole desktop, from the terminal to the editor to the wallpaper. Herdr and the AI coding-agent workflow come too, so you can hand work to an agent and keep your hands on the keyboard.

This is omakase. You don't assemble it from forty plugins and a weekend of YAML. One command installs the lot. If it isn't for you, one command takes it all back out and puts your machine back the way it was.

It won't make Windows into Linux, and it doesn't pretend to. It just makes the time you spend on Windows a lot more pleasant.

*Unofficial, and not affiliated with Omarchy or 37signals. Tracks Omarchy v4.0.4.*

Open PowerShell (not as administrator) and run:

```powershell
irm https://raw.githubusercontent.com/Brian-Zavala/winarchy/main/install.ps1 | iex
```

## The Winarchy Manual

Like Omarchy it lives in [`manual/`](manual/), but if there's a missing chapter it's because Windows isn't cool enough and has nothing to say about.

- [Welcome to Winarchy!](manual/01-welcome-to-winarchy.md)

**The Basics**

- [Getting Started](manual/02-getting-started.md)
- [Coming From Mac or Windows](manual/03-coming-from-mac-or-windows.md)
- [Navigation](manual/04-navigation.md)
- [The top bar](manual/05-the-top-bar.md)
- [Themes](manual/06-themes.md)
- [Hotkeys](manual/07-hotkeys.md)
- [Unified Clipboard & History](manual/08-unified-clipboard-history.md)
- [Notices](manual/10-notices.md)
- [Text Extraction & Dictation](manual/11-text-extraction-dictation.md)
- [Screenshots & Recording](manual/12-screenshots-recording.md)
- [Toggles, idle & screensaver](manual/13-toggles-idle-screensaver.md)
- [Winarchy CLI](manual/14-winarchy-cli.md)

**The Applications**

- [Terminal](manual/15-terminal.md)
- [Neovim](manual/16-neovim.md)
- [AI](manual/17-ai.md)
- [Development Tools](manual/18-development-tools.md)
- [Shell Functions](manual/20-shell-functions.md)
- [TUIs](manual/21-tuis.md)
- [Browsers](manual/23-browsers.md)
- [Commercial apps/services](manual/24-commercial-apps-services.md)
- [Gaming](manual/26-gaming.md)
- [Other Packages](manual/29-other-packages.md)

**Configuration**

- [Updates](manual/30-updates.md)
- [Dotfiles](manual/31-dotfiles.md)
- [Monitors](manual/33-monitors.md)
- [Keyboard, Mouse, Trackpad](manual/34-keyboard-mouse-trackpad.md)
- [Fonts](manual/38-fonts.md)
- [Backgrounds](manual/39-backgrounds.md)
- [Branding](manual/41-branding.md)
- [Common tweaks](manual/42-common-tweaks.md)
- [Making your own theme](manual/43-making-your-own-theme.md)

**The Rest**

- [Troubleshooting](manual/45-troubleshooting.md)
- [FAQ](manual/46-faq.md)
- [System snapshots](manual/47-system-snapshots.md)
- [Security](manual/48-security.md)
- [Unattended Installs](manual/51-unattended-installs.md)

## License

Winarchy is released under the [MIT License](LICENSE). Omarchy's themes, backgrounds, logo and designs are by DHH and contributors; see [NOTICE](NOTICE) for every credit.
