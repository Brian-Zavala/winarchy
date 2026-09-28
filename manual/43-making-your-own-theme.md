# Making your own theme

You can add your own themes to `%USERPROFILE%\.winarchy\themes`. Just copy one of the existing ones in that folder as a base, give the copy a new folder name, then tweak to your delight. As long as your theme is inside that folder and has a `colors.toml`, it'll be included in the theme selector (`Super + Ctrl + Shift + Space`) the next time the themes are indexed: run `winarchy sync -Offline`, or just `winarchy apply`.

The main file you have to tweak is `colors.toml`, in the same format Omarchy uses, so a theme made for Omarchy works here as it is. It defines the color set that's then used for the top bar and menus, GlazeWM's borders, the Windows accent, Windows Terminal, Flow Launcher, VS Code, Claude Code, Neovim, btop and Herdr.

A theme can also bring its own files, which are used instead of the generated ones:

| File | Used for |
|---|---|
| `neovim.lua` | Neovim's colorscheme, for Omarchy-style Neovim configs |
| `vscode.json` | A VS Code theme extension to install and select (`{ "name": ..., "extension": ... }`) |
| `btop.theme` | btop's colors |
| `chromium.theme` | The Chrome and Brave toolbar color |
| `preview.png` | The card in the theme selector |

Leave any of them out and Winarchy generates it from `colors.toml`, the same way Omarchy does.

### Backgrounds

Put your theme's backgrounds in `%USERPROFILE%\.winarchy\wallpapers\<theme name>`, using the same folder name as the theme. They show up under the theme's name in the background selector (`Super + Ctrl + Space`).

### Light mode

If you're making a light mode theme, set `mode = "light"` at the top of your `colors.toml`. Windows then switches to light mode with it, and so do the apps that follow Windows. (The old ways still work too: `theme_type = "light"`, or an empty file called `light.mode` in your theme's folder.)

### Missing colors

You don't have to define every color. Anything you leave out is derived the way Omarchy's `omarchy-theme-color` does it: the darker backgrounds are the background mixed 25% and 50% toward black, the bright colors are 20% toward white, brown comes from orange, and the ANSI names `color0` to `color15` map both ways. GlazeWM's focused border uses the first color of `hyprland_active_border` when your theme sets one, and `accent` otherwise.
