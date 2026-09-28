# Terminal

`Super + Return` opens your terminal: Windows Terminal, running PowerShell 7. Winarchy themes it with everything else, in the theme's colors and your font, and gives it Omarchy's padding. `"apps": { "terminal": ... }` in your settings picks another terminal.

Copy and paste with `Super + C` and `Super + V`, the same as in every other app (see [clipboard](08-unified-clipboard-history.md)).

## Herdr

Omarchy Quattro replaced tmux with [Herdr](https://herdr.dev), a terminal workspace manager built for AI coding agents, and so does Winarchy. It keeps your editor, your agents and your shells in one window, and your sessions survive closing it. A Herdr workspace is a tmux session, a tab is a window, and a pane is a pane.

The installer offers Herdr; otherwise add it from _Install > Terminal > Herdr_. Then `Super + Ctrl + Return`, or _Trigger > Herdr_, opens it or re-attaches the session you left.

Winarchy gives Herdr Omarchy's config, with its tmux-shaped keys, and PowerShell 7 in its panes. Its prefix is `Ctrl + Space`; press `?` after it for help, and _Learn > Herdr_ in the Omarchy menu lists every key as Herdr loaded them.

| Hotkey | Function |
|---|---|
| `Ctrl + Space`, then `c` | New tab |
| `Ctrl + Space`, then `h` / `v` | Split horizontally / vertically |
| `Ctrl + Alt + Arrows` | Move between panes |
| `Ctrl + Space`, then `z` | Zoom the pane |
| `Ctrl + Space`, then `x` | Close the pane |
| `Alt + 1..9` | Go to a tab |
| `Ctrl + Space`, then `d` | Detach, leaving everything running |

Herdr follows your theme: when your Omarchy theme has a Herdr theme of the same name it uses that, and otherwise it draws itself in your terminal's colors. Your own copy of its config is under _Setup > Config > Herdr_ (see [dotfiles](31-dotfiles.md)).

The layouts that put your editor and agents side by side are in [shell functions](20-shell-functions.md).
