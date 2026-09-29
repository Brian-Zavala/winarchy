# Making a Winarchy theme

The usage panel's _Make something > Theme_ tile hands you this guide. You're making a theme for Winarchy, the Windows port of Omarchy. First ask what look the user has in mind: a mood, a palette, a picture or an existing theme to start from. Then build it, switch to it, and ask if they want anything changed.

## Where it goes

A theme is a folder in `%USERPROFILE%\.winarchy\themes`. The agent was started there. Name the folder in lowercase with hyphens (`desert-dusk`), because the folder name is the theme's name everywhere.

Don't reuse the name of a theme that's already there. `winarchy sync` overwrites Omarchy's own themes with their upstream copies, and the user's changes would be lost. Copy one of those to a new name instead.

## colors.toml

The only file a theme needs. It's Omarchy's format, so a theme made for Omarchy works as it is. Copy an existing theme's `colors.toml` for the full list of keys. This is the core:

```toml
mode = "dark"                 # or "light": Windows and its apps switch with the theme

accent = "#7aa2f7"            # the focus colour: the bar, menus, window borders, the Windows accent
selection = "#292e42"
muted = "#414868"

background = "#1a1b26"
foreground = "#a9b1d6"

red = "#f7768e"               # also the bar's alert colour
yellow = "#e0af68"
orange = "#eb927b"
green = "#9ece6a"
cyan = "#449dab"
blue = "#7aa2f7"
magenta = "#ad8ee6"
```

Anything left out is worked out the way Omarchy does it: `dark_background` and `darker_background` from `background`, the `bright_*` colours from the plain ones, and `color0` to `color15` from the names.

Keep text readable. `foreground` on `background` should be at least 4.5:1, and so should `accent` on `background`, since the bar and menus draw small text in both.

## Optional files

Any of these replace the one Winarchy would otherwise generate from `colors.toml`. `manual\43-making-your-own-theme.md` in the Winarchy code folder has the details.

- `preview.png`: the card in the theme picker. Without one, the picker shows the theme's colours.
- `neovim.lua`, `vscode.json`, `btop.theme`, `chromium.theme`: colours for those apps.

Backgrounds go in `%USERPROFILE%\.winarchy\wallpapers\<theme name>`, a folder with the theme's name. Use `.jpg`, `.png` or `.webp`, at least the screen's size. A theme without its own backgrounds keeps the current one.

## Switch to it

```powershell
winarchy sync -Offline      # index the new theme (no download)
winarchy theme <name>       # apply it: bar, menus, borders, terminal, launcher, editors
```

`winarchy theme list` shows every theme. After this the user can pick it again with `Super + Ctrl + Shift + Space`.
