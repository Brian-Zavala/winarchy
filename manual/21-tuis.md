# TUIs

Winarchy uses a few terminal apps the way Omarchy does, and themes each of them with everything else.

| App | Where | What it's for |
|---|---|---|
| [btop](https://github.com/aristocratos/btop) | `Super + Ctrl + T`, _Trigger > Activity_, or click the bar's CPU icon | What's using your CPU, memory, disks and network. Right-click the CPU icon for Task Manager instead |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | _About_ in the Omarchy menu | Your PC's details next to the Omarchy logo (or your own art, see [branding](41-branding.md)) |
| [Herdr](https://herdr.dev) | `Super + Ctrl + Return` | Your editor, agents and shells in one window. See [terminal](15-terminal.md) |
| [lazydocker](https://github.com/jesseduffield/lazydocker) | `Super + Shift + D` | Your Docker containers, images and logs (it talks to Docker Desktop) |
| [lazygit](https://github.com/jesseduffield/lazygit) | `lazygit` in a repo | Git: stage, commit, branch and rebase with single keys |
| [Cliamp](https://github.com/bjarneo/cliamp) | `Super + Shift + Alt + M` | Music in the terminal (it plays through FFmpeg and streams with yt-dlp) |
| [dua](https://github.com/Byron/dua-cli) | `dua i` | What is filling your disk, and clearing it out |

The installer sets up btop and fastfetch, and both are also in _Install > Windows_ in the Omarchy menu. Herdr is in _Install > Terminal_; lazydocker, lazygit, Cliamp and dua are in _Install > TUI_. A key for one that isn't installed yet says where to get it.

Each of them also goes in Start when it's installed, so the menu's _Apps_ list and Flow Launcher find it by name; it opens in the terminal. Removing it from _Remove_ takes that entry out again.
