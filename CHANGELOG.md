# Changelog

## Unreleased

- Holding an arrow key in the menu now scrolls at the speed you hold it, with the highlight on
  the row you are actually on. The 260ms glide and the smooth scroll were restarted by every
  key repeat, so neither ever finished and the list trailed a dozen rows behind the selection;
  a repeat now moves instantly, once per frame, and the row colour snaps instead of fading.
  Single presses still animate. Moving the highlight also no longer touches every row in the
  list, which matters most on the 200-plus entries of the new Apps route.
- A new window opens on the monitor you are hovering, like Hyprland opens it on the focused one, instead of always on Windows' primary display. Windows has no notion of a focused monitor, so a window was born on the primary and GlazeWM tiled it into the workspace bound to *that* monitor; it is now re-homed to the workspace displayed under the cursor. Dialogs and popups still open next to the window that opened them, and games, fullscreen windows and windows GlazeWM ignores are left alone. `openOnHoveredMonitor: false` turns it off.
- Nothing minimizes any more (there's no taskbar to bring it back from): a window snaps back the instant it starts to minimize. Exceptions: games, Playnite/Steam Big Picture, dialogs/popups, and config `minimizeAllowed`. Super+M / Super+Home restores every minimized window regardless (also in the Toggle menu), and Windows' own Win+D (show desktop) does nothing while this is on. `blockMinimize: false` turns it off.
- Games are recognised more broadly: anything installed under Steam/Epic/Xbox/GOG/EA/Ubisoft's own folders, under config `gameDirs`, or started by Playnite - not only ones Windows' Game Bar already knew. Super+Ctrl+G marks the focused window by hand for anything still missed.
- Fixed: a game left open on another workspace after an Apollo/Sunshine streamed session ended (the virtual display it replaces your monitors with going away) could come back black once you switched to its workspace and back. The workspace/monitor repair, bar restart and re-tiling redraw that a display change triggers now wait for every open game to close, not just the one that was last in front (a fullscreen game auto-minimizing on losing focus used to end that wait early); the bar still comes back on your monitors promptly either way. Switching back to a game's own workspace also brings the game itself back to front.
- The menu's **Apps** now lists the apps you actually have installed, searchable, instead of only
  pressing Flow Launcher's hotkey and leaving you at an empty search box. It shows everything
  Windows lists in Start — desktop programs and Store apps alike — minus uninstallers, help files
  and pinned folders. The list is written by `winarchy apply`, refreshed in the background each
  time you open Apps (so installing something shows up without re-applying), and `winarchy apps`
  rebuilds and prints it. Super+Space still opens Flow Launcher.
- Games no longer fight the desktop: GlazeWM doesn't tile games (the ones Windows' Game Bar knows, plus config `games`), the bar stays behind a fullscreen game, and display-mode changes, bar restarts and the screensaver wait until it closes (a game switching resolution used to loop with the bar: black screen, blinking bar). Gamepad input counts as activity for the screensaver. `gameMode: false` turns this off.
- Games: the bar hides on the game's monitor (a topmost bar blinked over exclusive-fullscreen games); games are recognised as soon as their window shows; a gamepad icon in the bar switches to or closes the running game, and Super+W / Super+Q close games too (twice: force-quit). See the README's Games section and Super+K.
- Super+Shift+Space (top bar off) now lasts until you turn the bar back on, across restarts; `winarchy bar on|off|toggle`.
- Holding Super no longer opens the Start menu on release.
- Games that run as administrator: Winarchy now recognises them, and `winarchy game-setup` (Setup → Admin Games, one admin prompt) adds a small admin helper so Super+W / the bar can close them (Super+W used to open Windows Widgets). Doctor tells you when it's needed.
- Called through the old `omarchy-win` folder (a shell started before the rename), winarchy pointed autostart and the running script there; it now always uses the real folder.
- Bar indicators work like Omarchy 4 (Quattro): the clock sits at the exact center, and active indicators sit to its left in the normal text color. Hovering the center reveals the others, dimmed, so one click turns them on: dictation, screen recording, night light, do not disturb, stay awake. The clock shows a pointer, and clicking it (or Super+Ctrl+Alt+D) opens Quattro's calendar under it: a month grid with ISO week numbers and the year's progress, stepped with the chevrons, scroll wheel or arrow keys.
- `winarchy apply` no longer leaves two copies of winarchy.ahk running when one was started through the old omarchy-win folder name.

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
