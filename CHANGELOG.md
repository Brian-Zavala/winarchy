# Changelog

## Unreleased

- Games no longer fight the desktop: GlazeWM doesn't tile games (the ones Windows' Game Bar knows, plus config `games`), the bar stays behind a fullscreen game, and display-mode changes, bar restarts and the screensaver wait until it closes (a game switching resolution used to loop with the bar: black screen, blinking bar). Gamepad input counts as activity for the screensaver. `gameMode: false` turns this off.
- Games: the bar hides on the game's monitor (a topmost bar blinked over exclusive-fullscreen games); games are recognised as soon as their window shows; a gamepad icon in the bar switches to or closes the running game, and Super+W / Super+Q close games too (twice: force-quit). See the README's Games section and Super+K.
- Super+Shift+Space (top bar off) now lasts until you turn the bar back on, across restarts; `winarchy bar on|off|toggle`.
- Holding Super no longer opens the Start menu on release.
- Bar indicators work like Omarchy 4 (Quattro): the clock sits at the exact center, and active indicators sit to its left in the normal text color. Hovering the center reveals the others, dimmed, so one click turns them on: dictation, screen recording, night light, do not disturb, stay awake. The clock shows a pointer, and clicking it opens the calendar.

## 0.1.0 (unreleased)

- First portable release: one-line install, backup journal + uninstall, doctor, config.json.
- Tiling (GlazeWM), Omarchy top bar and menus (Zebar), launcher (Flow), Super-key workflow (AutoHotkey).
- 22 Omarchy themes across bar, borders, Windows accent, Terminal, Flow, VS Code, Claude Code, Neovim, btop, Chrome/Brave (opt-in), wallpaper, lock screen.
- Background and theme pickers, font switcher, screensaver, nightlight, do not disturb, OCR, weather, update indicator, About (fastfetch), Activity (btop).
- Bar space kept free by GlazeWM's top gap on every monitor/DPI; bar above windows except fullscreen.
- The bar is started through AutoHotkey, so Zebar no longer logs into (and dies with) the Update/Doctor terminal.
- Animated pickers: a 3D cover-flow theme selector that previews each theme by morphing the whole menu into its colors, a wallpaper grid with a live blurred backdrop that stays up when you pick and opens into the new wallpaper with the same reveal as the desktop (one animation, no flash of the old wallpaper), gliding highlights, sliding sub-menus, a font picker drawn in each font, and a bar that fades between themes. Windows' "Animation effects" setting turns the motion off.
- Screensaver windows open visibly (they were started hidden and never closed); leftovers are cleaned up.
- Saved edits apply themselves: config.json, your GlazeWM template, your keybindings script, user.css.
- Menu actions report back (OSD); failures are logged and shown by doctor; long downloads run in a terminal.
- Omarchy v4 wallpaper reveal; experimental window animations (GlazeWM #1392 build, `winarchy animations`).
- Bar shield for admin (UAC) prompts that Windows parks in the (hidden) taskbar: click it to open the prompt.
- Renamed to Winarchy (`winarchy` CLI; `omarchy-win` still works as an alias).
