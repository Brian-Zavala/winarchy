# Other Packages

Winarchy installs everything with [winget](https://learn.microsoft.com/windows/package-manager/winget/), Windows' own package manager, the way Omarchy uses pacman. Anything not in the Omarchy menu's _Install_ section is one command away:

```powershell
winget search <name>
winget install -e --id <Publisher.App>
```

`winarchy update` upgrades everything winget installed along with Winarchy itself (see [updates](30-updates.md)).

_Install > Windows_ has the Windows extras Winarchy suggests: PowerToys, WSL, Sunshine (to stream games to another device), fastfetch and btop.
