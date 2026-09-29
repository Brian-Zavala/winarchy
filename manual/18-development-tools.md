# Development Tools

Omarchy's _Install_ menu sets up a programming language or an editor in one step, and so does Winarchy's, with winget doing the installing. Each install runs in a terminal so you can watch it, and is recorded, so `winarchy uninstall` takes it back out if you ask it to.

### Development

_Install > Development_ in the Omarchy menu: Git, Python, Node.js, Bun, Deno, Go, Rust, .NET, Java (Temurin), PHP, Docker Desktop, Ruby, Elixir, Zig, OCaml and Scala.

### Editors

_Install > Editor_: VS Code, Cursor, Zed, Sublime Text, Helix, Neovim, Vim and Emacs. Winarchy themes VS Code and Neovim with everything else (see [Neovim](16-neovim.md)), and opens your editor with `Super + Shift + N`.

### Terminals

_Install > Terminal_: Windows Terminal, Alacritty, WezTerm and Herdr. See [terminal](15-terminal.md).

Something you already have stays in the list, dimmed and ticked, so it still reads as a catalog. _Remove_ only lists what's actually there. From a terminal, `winarchy catalog` shows the lot, and `winarchy install-app <key>` installs one.
