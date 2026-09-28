# Neovim

[Neovim](https://neovim.io/) is a modern implementation of [the vi editor](<https://en.wikipedia.org/wiki/Vi_(text_editor)>), a modal editor where insert mode and command mode are separated. It's a bit of a superpower once you learn even just a subset of its key commands, and Omarchy's own manual has [a good introduction to it](https://github.com/omacom/omarchy/blob/quattro/manual/16-neovim.md).

Winarchy doesn't install a Neovim setup of its own. Neovim is in _Install > Editor_ in the Omarchy menu, and when it's installed it's the editor Winarchy opens (`Super + Shift + N`, and every _Edit_ entry in the menu). Set `"apps": { "editor": ... }` in your settings to use another one.

### Themes

Winarchy themes Neovim the way Omarchy does, for Neovim configs that follow Omarchy's convention: a `lua\plugins\theme.lua` in your config folder (`%LOCALAPPDATA%\nvim`). On every theme switch, that file is rewritten with the theme's own `neovim.lua`, or Omarchy's generated colorscheme when the theme has none. The theme's name is also written to `%USERPROFILE%\.local\state\omarchy\current\theme.name`, which Omarchy-style configs read.

A config without that file is left alone. `"themeTargets": { "neovim": true }` writes the file into any config that has a `lua\plugins` folder, and `false` never touches Neovim.

### Herdr

The `hdl` and `hds` layouts open your editor in the big pane, next to your coding agent. See [shell functions](20-shell-functions.md).
