# Unattended Installs

Winarchy can install itself with nobody answering questions. Set `WINARCHY_YES` before the one-liner, and every question takes its recommended answer and nothing waits for a key:

```powershell
$env:WINARCHY_YES = 1; irm https://raw.githubusercontent.com/Brian-Zavala/winarchy/main/install.ps1 | iex
```

That makes Winarchy easy to put on a fresh PC from a provisioning script, or on a test VM you throw away afterwards.

The one thing an unattended install skips is Herdr. It installs from outside winget and is unsigned, so running its installer stays your call. Add it any time from _Install > Terminal > Herdr_ in the Omarchy menu.

## The settings

| Variable | Default | Purpose |
|------|----------|---------|
| `WINARCHY_YES` | not set | Take every recommended answer; also makes `winarchy uninstall` keep your apps and settings without asking |
| `WINARCHY_REPO` | `Brian-Zavala/winarchy` | The GitHub repo to install from, for a fork |
| `WINARCHY_REF` | `main` | The branch to install from; an existing copy switches to it. `winarchy update` follows it too |
| `WINARCHY_ALLOW_ELEVATED` | not set | Install from a window running as administrator anyway. Everything Winarchy starts from it then runs elevated |

Winarchy goes into `%LOCALAPPDATA%\winarchy`: a git clone when git is installed, otherwise the branch's zip.

## Taking your settings along

Your settings live in `%USERPROFILE%\.winarchy\config.json` (see [dotfiles](31-dotfiles.md)). Copy that file to the new PC before installing, and the install applies it instead of the defaults. An uninstall that kept your settings does the same on the next install, and doesn't ask the questions you already answered.
