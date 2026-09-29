# Fonts

Winarchy uses JetBrainsMono Nerd Font as the font for the terminal, the bar, the menus and the launcher by default.

You can change it through the _Style > Font_ menu in the Omarchy menu (`Super + Space`). That sets the monospace font everywhere Winarchy themes: Windows Terminal, the bar and menus, Flow Launcher, VS Code and Neovim.

The same menu installs other popular programming fonts: Cascadia Mono, Meslo LG Mono, Fira Code, Victor Mono, Bitstream Vera Mono and Iosevka, all in their Nerd Font versions so the glyphs in the bar and terminal keep working. They install for your user only, with no admin prompt, and uninstalling takes them back out.

The size is separate: _Text size_ in the bar's Display panel, or `winarchy text-size <px>` (9 to 20, 12 is the default), sizes the bar, its panels and the terminals together (see [the top bar](05-the-top-bar.md)).

From a terminal, `winarchy font list` shows the fonts you can pick, and `winarchy font <family>` switches to one.
