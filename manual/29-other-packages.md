# Other Packages

Winarchy installs everything with [winget](https://learn.microsoft.com/windows/package-manager/winget/), Windows' own package manager, the way Omarchy uses pacman. Anything not in the Omarchy menu's _Install_ section is one command away:

```powershell
winget search <name>
winget install -e --id <Publisher.App>
```

`winarchy update` upgrades everything winget installed along with Winarchy itself (see [updates](30-updates.md)).

What _Install_ in the Omarchy menu has:

| Group | What's in it |
|---|---|
| Desktop Apps | The apps Omarchy comes with: Obsidian, LibreOffice, Xournal++ (for writing on PDFs), Pinta, mpv, OBS Studio and Kdenlive |
| Omarchy Apps | Omarchy's own apps built for Windows: Omawrite, Omacalc, Omacut, Hype and Aether, once each has a Windows build |
| Web Apps | Omarchy's web apps (see [web apps](25-web-apps.md)) |
| TUI | lazydocker, lazygit, Cliamp and dua (see [TUIs](21-tuis.md)) |
| Shell Tools | starship, zoxide, eza, fzf, bat, ripgrep, fd, jq and the GitHub CLI; `winarchy shell on` wires them into PowerShell the way Omarchy's shell has them |
| Windows | PowerToys, WSL, Sunshine (to stream games to another device), fastfetch, btop, FFmpeg, yt-dlp and QuickLook (press `Space` on a file in File Explorer to preview it) |

### Omarchy's shell, in PowerShell

`winarchy shell on` adds a block to your PowerShell profile with Omarchy's shell setup: the starship prompt, `z` and `zd` to jump to folders you use, `l`, `lsa`, `lt` and `lta` (eza), `ff` (fzf with a preview), `..`, `g`, `gcam`, `d`, `n` and the agent shortcuts `a`, `c`, `cx` and `cy`. Each needs its tool installed, and it takes effect in a new window.

`ls`, `cat` and `cd` stay PowerShell's own, since scripts rely on what they return, and so does any name that is already a command: `gcm`, `h` and `r` are PowerShell's. `winarchy shell off` takes the block out again, and so does `winarchy uninstall`.
