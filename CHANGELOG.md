# Changelog

## 0.1.0 (unreleased)

- First portable release: one-line install, backup journal + uninstall, doctor, config.json.
- Tiling (GlazeWM), Omarchy top bar and menus (Zebar), launcher (Flow), Super-key workflow (AutoHotkey).
- 22 Omarchy themes across bar, borders, Windows accent, Terminal, Flow, VS Code, Claude Code, Neovim, btop, Chrome/Brave (opt-in), wallpaper, lock screen.
- Background and theme pickers, font switcher, screensaver, nightlight, do not disturb, OCR, weather, update indicator, About (fastfetch), Activity (btop).
- Bar space kept free by GlazeWM's top gap on every monitor/DPI; bar above windows except fullscreen.
- The bar is started through AutoHotkey, so Zebar no longer logs into (and dies with) the Update/Doctor terminal.
- Animated pickers: a 3D cover-flow theme selector that previews each theme by morphing the whole menu into its colors, a wallpaper grid with a live blurred backdrop that lands as the desktop, gliding highlights, sliding sub-menus, a font picker drawn in each font, and a bar that fades between themes. Windows' "Animation effects" setting turns the motion off.
- Screensaver windows open visibly (they were started hidden and never closed); leftovers are cleaned up.
- Saved edits apply themselves: config.json, your GlazeWM template, your keybindings script, user.css.
- Menu actions report back (OSD); failures are logged and shown by doctor; long downloads run in a terminal.
- Omarchy v4 wallpaper reveal; experimental window animations (GlazeWM #1392 build, `omarchy-win animations`).
