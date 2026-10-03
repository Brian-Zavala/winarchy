# Troubleshooting

### Something looks wrong

Run `winarchy doctor`. It checks every moving part (the apps, what's running, the bar, Herdr, the agent usage, the monitors and the screensaver) and says what to do about each problem. `winarchy doctor -Fix` repairs what it can: it looks for your apps again and reinstalls anything that went missing.

The log is in `%USERPROFILE%\.winarchy\logs\winarchy.log`, and says what Winarchy did and what failed.

### Every terminal Winarchy opens asks for UAC, then says "The system cannot find the file specified"

That's error `0x80070002` from Windows Terminal, and it comes from _Run this profile as Administrator_ being on in Terminal's settings (under _Defaults_, or your default profile). Terminal re-launches the tab elevated, and on the way it loses track of the command. Winarchy's windows open on its own _Omarchy Shell_ profile, which never runs elevated: run `winarchy update` (or `winarchy apply`) to get it. `winarchy doctor` says when a profile runs as administrator. To stop the UAC prompt for your own new tabs too, turn that setting off in _Terminal Settings > Defaults_.

### My settings don't take effect

A `config.json` with a typing mistake is left alone rather than overwritten, and Winarchy runs on the defaults until it's fixed. `winarchy doctor` says where the mistake is. The usual one is a single `\` in a path: in JSON it has to be written `\`, as in `"C:\Games"`.

### A plain bar shows instead of Winarchy's

That's Zebar's own starter bar. Zebar puts it in when it starts and finds no settings of its own, for example after its settings folder was deleted. Winarchy notices it within a few seconds and runs `winarchy apply`, which points Zebar back at Winarchy's bar and restarts it. You can run `winarchy apply` yourself too. `winarchy doctor` says so when Zebar is set to open another bar.

### Some windows can't be moved or tiled

Windows running as administrator can't be managed by programs that don't, and GlazeWM and AutoHotkey don't. That's a Windows security boundary; see [security](48-security.md). For games, `winarchy game-setup` helps; see [gaming](26-gaming.md).

### A game gets tiled, or the bar shows over it

Windows adds a game to its list the first time Game Bar notices it, and the checks for the launchers' own folders and for Playnite catch most others right away. Still missed? `Super + Ctrl + G` marks the focused window as a game, or add its process name (Task Manager > Details, without `.exe`) to `"games"` in your settings. The log says `game: <name>` when a game is recognised.

### A game keeps minimizing by itself

A fullscreen game minimizes whenever another window takes the foreground. Winarchy gives it straight back unless you pressed a key, clicked or used the gamepad just before, and the log names what took it: `game lost focus: <game> -> <program>`. Games that run as administrator need `winarchy game-setup` for this.

### A window minimized and I can't get it back

`Super + M` restores every minimized window. There's no taskbar to bring one back from, which is why nothing minimizes in the first place. `"blockMinimize": false` in your settings turns that off, or add just that one program's process name to `"minimizeAllowed"`.

### The AI agent icon doesn't show up

It only appears once a coding agent has recorded usage on this PC, or its provider reports limits. If you've used one and it still isn't there, run `winarchy doctor`: it says whether Python 3 is missing (the `python` in WindowsApps is only a Microsoft Store shortcut and doesn't count) and what each agent reported.

### `hdl` says "not inside Herdr"

The layouts build around the pane they run in, so run them in a Herdr pane (_Trigger > Herdr_ opens one), not a plain terminal.

### Starting over

`winarchy uninstall` takes Winarchy back out, keeping your settings if you like, and the install one-liner puts it back. See [system snapshots](47-system-snapshots.md).
