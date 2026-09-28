# Gaming

A tiling window manager and a game both want to control the game's window. A game that switches display mode would otherwise be re-tiled and covered by the bar, and drop out of fullscreen again and again (black screen, blinking bar). So Winarchy steps aside for games, with any launcher: Steam, Epic, GOG, Battle.net, EA, Ubisoft, Xbox, Playnite and emulators. The launchers themselves are one click away in _Install > Gaming_ in the Omarchy menu.

### What counts as a game

- Everything Windows' Game Bar has recognised as one. Windows keeps that list for every game you've run.
- Anything installed under Steam, Epic, Xbox, GOG, EA or Ubisoft's own folders, or under a folder you list in `"gameDirs"`.
- Anything started by Playnite.
- The process names you list in `"games": ["MyGame"]`.

Playnite's fullscreen mode and Steam Big Picture are left alone too. Missed one? `Super + Ctrl + G` marks the focused window as a game by hand, and remembers it in your settings.

### While a game is in front

GlazeWM doesn't tile it, and the top bar hides on its monitor (the other monitors keep theirs). Display changes, bar restarts and the screensaver wait until you leave or close the game. A game played in a window is left untiled as well.

A background program that grabs the foreground doesn't knock a fullscreen game out: Winarchy gives it straight back unless you pressed a key, clicked or used the gamepad just before. Every time a game loses the foreground, the log says what took it: `game lost focus: <game> -> <program>`. `"gameFocusGuard": false` turns the give-back off (the logging stays).

### Switching away and back

The game itself is left alone for as long as it's open, even minimized or on another workspace: no re-tiling redraw, no workspace repair. The bar still comes back on your monitors promptly.

GlazeWM doesn't manage a game, so it wouldn't hide one either; Winarchy does. Switching to another workspace minimizes the game and focuses that workspace, and switching back to the game's own workspace brings it back to front. `Alt + Tab` to a game, or a click on the bar's gamepad icon, takes you to its workspace.

That's also what keeps a streamed session (Sunshine or Apollo, with a virtual display replacing your monitors) from coming back black once the stream ends.

### Closing a game

`Super + W` or `Super + Q`, or right-click the gamepad icon in the bar. Doing it again within 15 seconds force-quits a game that doesn't close.

### Games that run as administrator

Many games are set to "Run this program as an administrator". Windows then keeps normal programs away from them, so `Super + W` would reach Windows (it opens Widgets) and nothing could close them.

Run `winarchy game-setup` once (one admin prompt). A small helper then runs as administrator at login and does just this:

- `Super + W` and `Super + Q` close admin windows, and closing from the bar works.
- `Super` alone doesn't open Start in front of them.
- GlazeWM's own keys keep working in front of any admin window: `Super + 1..0`, `Super + Shift (+ Alt) + 1..0`, `Super (+ Shift) + Arrows`, `Super + Tab`, `Super + S` and `Super + F`.

The helper never runs anything from your user folder, since nothing you can write to may run as administrator. See [security](48-security.md). `winarchy doctor` says when the helper is needed or out of date, and `winarchy game-setup remove` (or uninstalling) takes it away.

### Gamepad

Controller input counts as activity, so the screensaver never starts mid-game, and a button press ends it.

### Turning it off

`"gameMode": false` in your settings turns all of this off, and games are then tiled like any other window.
