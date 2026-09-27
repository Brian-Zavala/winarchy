![Winarchy](images/winarchy-no-bg.png)


**[Omarchy](https://omarchy.org)'s look, keys and themes on Windows 11** — including what Omarchy 4
(Quattro) added: its menu with a software catalog, Herdr and the AI coding-agent workflow built on
it, and the agent usage panel in the bar. Tiling windows, the Omarchy top bar and menu, 22 Omarchy
themes that recolor everything at once, the background and theme pickers, the screensaver, games
that just work, and the Super-key workflow — installed in one command, undone in one command.

> Unofficial. Not affiliated with Omarchy or 37signals. Built on [GlazeWM](https://github.com/glzr-io/glazewm),
> [Zebar](https://github.com/glzr-io/zebar), [Flow Launcher](https://www.flowlauncher.com),
> [AutoHotkey](https://www.autohotkey.com) and [Herdr](https://herdr.dev).

## Install

Open **PowerShell** (not as administrator) and run:

```powershell
irm https://raw.githubusercontent.com/Brian-Zavala/winarchy/main/install.ps1 | iex
```

The installer:

1. checks the PC (Windows 11, winget) and installs what's missing: PowerShell 7, AutoHotkey v2,
   the JetBrainsMono Nerd Font, GlazeWM + Zebar (one UAC prompt), Flow Launcher, fastfetch, btop,
   and Python 3 (for the bar's AI agent usage);
2. asks a few questions (only the ones that depend on you: keep your own launcher script?
   hide the taskbar? take over Win+Space if you use several keyboard layouts? install Herdr?);
3. **records every setting it changes** in a backup journal before changing it;
4. writes the configs for *your* machine — any number of monitors, any scaling, laptop or desktop,
   your default browser, terminal and editor;
5. downloads Omarchy's themes and backgrounds (~110 MB, asks first) and applies Tokyo Night.

Then press **Super + K** for every key. Super is the Windows key.

**Unattended:** `$env:WINARCHY_YES = 1` before the one-liner takes every recommended answer and asks
nothing. The one thing it skips is Herdr (it installs from outside winget and is unsigned, so that
stays your call) — add it any time from the menu's Install › Terminal.

**Requirements:** Windows 11 22H2 or newer, winget (App Installer), an internet connection for install.

## What you get

### Desktop

| | |
|---|---|
| **Tiling** | GlazeWM with Omarchy's keys: Super+1..0 workspaces (split across your monitors), Super+Tab to cycle them, Super+arrows, Super+Shift+arrows, Super+F, Super+T, Super+J, Super+-/=. **Hyprland-style auto-tiling**: new windows spiral into dwindle splits instead of piling into one row (`winarchy autotile`) |
| **Hyprland behaviour** | Focus follows the mouse (reliably, even across the bar); a new window opens on the monitor you're hovering, not always the primary; Super+drag moves a window and drops it exactly where you let go — onto another tile, or onto another monitor's workspace; Super+right-drag resizes |
| **No minimizing** | There's no taskbar to bring a window back from, so nothing minimizes (games, dialogs and your `minimizeAllowed` list excepted). Super+M / Super+Home restores everything, just in case |
| **Top bar** | Omarchy Quattro's bar: logo (menu), workspaces, the clock at the exact centre with the Quattro calendar under it (Super+Ctrl+Alt+D), indicators to its left (hover to reveal the ones that are off, click to toggle), weather, updates, the AI agent icon, and system modules. Running windows and the tray fold behind a chevron. Always above windows (except fullscreen ones and games); tiles never go under it. Super+Shift+Space turns it off until you turn it back on |
| **Gaming** | Games get out of the way by themselves: GlazeWM doesn't tile them, the bar hides on the game's monitor, nothing steals focus from a fullscreen game, and each game stays on its own workspace. A gamepad icon in the bar switches to the game or closes it; Super+W closes it too. Gamepad input keeps the screensaver away. See [Games](#games) |

### The Omarchy menu (Super+Alt+Space)

Laid out like Omarchy Quattro's: **Apps · Learn · Trigger · Style · Setup · Install · Remove · Update · About · System**.

| | |
|---|---|
| **Apps** | Everything Windows lists in Start — desktop programs and Store apps alike — searchable, and refreshed each time you open it |
| **Learn** | Winarchy's keybindings (also Super+K), Herdr's keybindings as Herdr actually loaded them, and the Omarchy, GlazeWM, Zebar, Neovim and PowerShell manuals |
| **Trigger** | Capture (region screenshot, screen recording, **text capture (OCR)**, color picker), Toggle (stay awake, night light, do not disturb, top bar, gaps, transparency), your default **coding agent**, **Herdr**, emoji, calculator, Activity (btop), clipboard, weather |
| **Style** | Theme and background pickers, next background, font, screensaver and About text, browser toolbar color, your bar CSS, your GlazeWM template |
| **Setup** | Hardware panels, your settings, your keybindings, **default coding agent**, your own **Herdr config**, your own GlazeWM template, the admin-games helper |
| **Install / Remove** | Omarchy Quattro's software catalog, on winget — 46 packages in 7 groups: **AI** (Claude Desktop, Ollama, LM Studio, Perplexity) · **Gaming** (Steam, Heroic for Epic, RetroArch, Battle.net, Minecraft, GeForce NOW, Playnite) · **Development** (Git, Python, Node.js, Bun, Deno, Go, Rust, .NET, Java, PHP, Docker) · **Editor** (VS Code, Cursor, Zed, Sublime, Helix, Neovim, Vim, Emacs) · **Terminal** (Windows Terminal, Alacritty, WezTerm, Herdr) · **Service** (1Password, Bitwarden, Dropbox, Spotify, Signal, Tailscale, NordVPN) · **Windows** (PowerToys, WSL, Sunshine, fastfetch, btop). Something you already have stays in the list, dim and ticked, so it still reads as a catalog; Remove only lists what is actually there. Each install runs in a terminal so you can watch it, and is recorded so `winarchy uninstall` takes it back out |
| **System** | Lock, suspend, restart, shut down, log out, back to normal Windows (also Super+Escape) |

### AI coding agents and Herdr

| | |
|---|---|
| **Herdr** | Omarchy Quattro's replacement for tmux: one terminal holding your editor, your agent and a shell, with sessions that survive closing the window. Winarchy gives it Omarchy's config — tmux-shaped keys, prefix Ctrl+Space — themes it with everything else, and adds Omarchy's layouts as shell shortcuts: `hdl claude`, `hds`, `hdlm`, `hsl`. See [Herdr and coding agents](#herdr-and-coding-agents) |
| **Coding agents** | Trigger › Agent (or right-click the bar's agent icon) starts your default agent — Claude Code, Codex, GitHub Copilot, OpenCode, Crush, Cursor, Grok, Antigravity, Muse, Oh My Pi, Ori, Pi or Hermes — with that agent's own "don't stop to ask" flags. Setup › Default Agent picks it; none is picked for you |
| **Agent usage** | Omarchy Quattro's agents widget: a robot icon in the bar for every AI coding subscription on the PC. Hover for the plan, rate limits and today's tokens; click for a panel with a meter and reset time per limit, tokens by day for the last week, and tokens by model. Claude Code and Codex are found by themselves (Fireworks too), limits come straight from the provider, and the icon only appears once an agent has something to show |

### Look

| | |
|---|---|
| **Themes** | Super+Ctrl+Shift+Space: 22 Omarchy themes recolor the bar, menus, window borders, Windows accent + light/dark, Windows Terminal, Flow Launcher, VS Code, Claude Code, Neovim (Omarchy-style configs), btop, Herdr, Chrome/Brave toolbar (opt-in), wallpaper and lock screen |
| **Backgrounds** | Super+Ctrl+Space: every Omarchy background plus your own (`Pictures\Wallpapers`), opening out of the middle of every monitor in Omarchy v4's slanted reveal |
| **Fonts** | Style › Font: one font for terminal, bar, menus and launcher; installs Omarchy's Nerd Fonts |
| **Screensaver** | Omarchy's animated logo ([ttfx](https://github.com/omacom/ttfx) effects) on every monitor after 2.5 min idle (gamepad input counts as activity); never while a video, game or fullscreen app is in front |
| **About / Activity** | fastfetch with the Omarchy logo; btop |
| **Window animations** *(experimental)* | `winarchy animations build` compiles GlazeWM's open animation pull request ([#1392](https://github.com/glzr-io/glazewm/pull/1392)) and switches to it: windows zoom and glide to their tiles. Needs Rust + Visual C++ build tools; `animations off` returns to the official GlazeWM |

## Everyday commands

```text
winarchy doctor            check everything and explain problems (-Fix repairs)
winarchy theme <name>      switch theme            (winarchy theme list)
winarchy font <family>     switch font             (winarchy font list)
winarchy bg <image>        set the background      (winarchy bg next)
winarchy config            open your settings      (saving applies them)
winarchy catalog           list what Install/Remove offers, and what you already have
winarchy install-app <key> install one of them     (winarchy remove-app <key> takes it back out)
winarchy herdr status      Herdr: where it is, its config and theme (herdr install adds it)
winarchy agent list        the coding agents, and which one is the default
winarchy default-agent <n> the coding agent Trigger > Agent starts
winarchy agent-usage       refresh the bar's AI agent usage now (-Force: rescan everything)
winarchy autotile off      turn off auto-tiling    (on / toggle / status)
winarchy animations on     window animations       (experimental; first: animations build)
winarchy bar off           hide the top bar        (winarchy bar on / toggle; Super+Shift+Space)
winarchy update            update winarchy, Omarchy themes, Herdr and the apps
winarchy uninstall         back to normal Windows  (-DryRun to preview, -KeepApps)
```

## Settings

Your settings live in `%USERPROFILE%\.winarchy\config.json` and only need the keys you change —
see [docs/config.md](docs/config.md). Examples: 24-hour clock, °C, your own workspace-to-monitor map,
more background folders, turning single theme targets off, screensaver timeout, your default coding
agent, hiding one agent from the usage icon.

Bar/menu CSS overrides go in `%USERPROFILE%\.glzr\zebar\omarchy\user.css` (kept across updates).

Like Hyprland, saved edits take effect by themselves: `config.json` re-applies, your GlazeWM
template reloads GlazeWM, your Herdr template reloads Herdr, your keybindings script reloads, and
the bar picks up `user.css`. Open them from the Omarchy menu (Setup / Style).

## Herdr and coding agents

[Herdr](https://herdr.dev) is a terminal workspace manager for AI coding agents, and what Omarchy
Quattro uses instead of tmux (a Herdr workspace is a tmux session, a tab a window, a pane a pane).
Install offers it; otherwise the menu's Install › Terminal › Herdr adds it. Trigger › Herdr opens it
or re-attaches to the session you left.

Inside a Herdr pane, Omarchy's layouts are one word each:

| Shortcut | Layout |
|---|---|
| `hdl <agent> [<agent2>]` | Your editor, the agent on the right (30%), a terminal along the bottom (15%); a second agent splits the agent pane in half. The tab is named after the folder |
| `hds` | A 2x2: editor, a live git diff, a terminal, and your default agent |
| `hdlm <agent> [<agent2>]` | One `hdl` tab per subfolder of the current folder — a whole monorepo at once |
| `hsl <count> <command>` | A swarm: `count` panes in an even grid, all running the same command (`hsl 4 claude`) |

`<agent>` is any agent name or Omarchy's shorthand (`c` = Claude Code, `cx` = Codex); anything else
is run as typed. The shortcuts live in your PowerShell profile between `winarchy herdr shortcuts`
markers and call `winarchy herdr layout|square|multi|swarm`.

Herdr is themed with everything else: when your Omarchy theme has a Herdr built-in of the same name
(Tokyo Night, Catppuccin, Gruvbox, Nord, Kanagawa, Rose Pine…) it uses that, otherwise it draws
itself in your terminal's palette, which Winarchy themes too. Learn › Herdr keys lists its bindings
(prefix Ctrl+Space, then `?` for help). Setup › Herdr Config gives you your own copy of the config
template — saving it re-renders Herdr's config and reloads a running Herdr; delete it to go back.

The **agent usage icon** runs Omarchy's own usage collectors every 15 minutes: Claude Code
(transcripts, plus the 5-hour and weekly limits from Anthropic with Claude Code's own sign-in, which
never leaves that one request), Codex (sessions, plus limits from `codex app-server`) and Fireworks.
Nothing names an agent: a new collector in `lib/agents` shows up by itself. It needs Python 3, which
install sets up and `winarchy doctor` checks. `"agentUsage": { "enabled": false }` removes the icon.

## Games

A tiling window manager and a game both want to control the game's window: a game that switches
display mode would otherwise be re-tiled and covered by the bar, and drop out of fullscreen again
and again (black screen, blinking bar). So Winarchy steps aside for games, with any launcher
(Steam, Epic, GOG, Battle.net, EA, Ubisoft, Xbox, Playnite, emulators). The launchers themselves
are in the menu's Install › Gaming.

* **What counts as a game:** everything Windows' Game Bar has recognised as one (Windows keeps
  that list for every game you've run); anything installed under Steam/Epic/Xbox/GOG/EA/Ubisoft's
  own folders, or under a folder you list in `"gameDirs"`; anything started by Playnite; and the
  process names you list in `"games": ["MyGame"]`. Playnite's fullscreen mode and Steam Big
  Picture are left alone too. Missed one? Super+Ctrl+G marks the focused window by hand.
* **While a game is in front:** GlazeWM doesn't tile it, the top bar hides on its monitor (the
  other monitors keep theirs), and display changes, bar restarts and the screensaver wait until
  you leave or close the game. A game played in a window is left untiled as well. A background
  program that grabs the foreground doesn't knock a fullscreen game out: winarchy gives it straight
  back unless you pressed a key, clicked or used the pad just before.
* **Switching away and back:** the game itself is left alone (no re-tiling redraw, no workspace
  repair) for as long as it's still open, even minimized or on another workspace - that's what a
  streamed session (Apollo/Sunshine, a virtual display replacing your monitors) used to leave
  black once the stream ended and you'd switched workspaces. The bar still comes back on your
  monitors promptly. GlazeWM doesn't manage a game, so it wouldn't hide one either; winarchy does:
  switching to another workspace minimizes the game and focuses that workspace, and switching back
  to the game's own workspace brings it back to front. Alt+Tab to a game (or clicking the bar's
  gamepad icon) takes you to its workspace. Super+W (or right-clicking the gamepad icon) closes it.
* **Closing a game:** Super+W / Super+Q, or right-click the gamepad icon in the bar. Doing it
  again within 15 s force-quits a game that doesn't close. Clicking the icon switches back to the game.
* **Games that run as administrator** (the "Run this program as an administrator" compatibility
  setting, common for games): Windows keeps normal programs away from them, so Super+W would reach
  Windows (it opens Widgets) and nothing could close them. Run `winarchy game-setup` once (Omarchy
  menu → Setup → Admin Games; one admin prompt): a small helper then runs as administrator at login
  and does just this: Super+W / Super+Q close admin windows, closing from the bar works, Super
  alone doesn't open Start there, and GlazeWM's own keys keep working in front of any admin window
  (Super+1..0 and Super+Shift(+Alt)+1..0, Super(+Shift)+arrows, Super+Tab, Super+S, Super+F).
  Those last ones matter with window animations on: the animation build of GlazeWM can't have
  Windows' "UI access" (only a signed program installed under Program Files can), so without the
  helper *workspace switching stops* whenever a game run as administrator - or any admin window -
  is in front. The helper never runs GlazeWM's command-line tool itself (it lives in your user
  folder, and nothing user-writable may run as administrator); it tells winarchy.ahk which key
  it was, and winarchy.ahk does the rest. It runs from an admin-only copy; `winarchy doctor` says when it's
  needed or out of date, and `winarchy game-setup remove` (or uninstall) takes it away.
* **Streaming:** Sunshine (Install › Windows) and Apollo streams are handled — see "Switching away
  and back" above.
* **Gamepad:** controller input counts as activity, so the screensaver never starts mid-game,
  and a button press ends it.
* **Turn it off:** `"gameMode": false` in `config.json` (games are then tiled like any window).

## Undo

`winarchy uninstall` (or Omarchy menu → System → Back to normal Windows) replays the backup
journal newest-first: taskbar, accent and light/dark mode, wallpaper and lock screen, Windows
Terminal / Flow / VS Code / Claude Code settings, the Windows screensaver, autostart entries,
PATH, your PowerShell profile (the Herdr shortcuts come back out) and Herdr's config, and
uninstalls the apps Winarchy installed — including anything from the menu's Install section, and
Herdr (`-KeepApps` keeps them). Downloaded themes, backgrounds and fonts are kept unless you add
`-Purge`.

## FAQ

**Some windows can't be moved or tiled.** Windows running as administrator can't be managed by
non-admin tools (GlazeWM, AutoHotkey). That's a Windows security boundary.

**I use several keyboard layouts.** Windows switches layouts with Win+Space; Omarchy uses it for
the launcher. The installer asks. Alt+Shift still switches layouts either way, and
`"takeOverWinSpace": false` in config.json gives Win+Space back.

**Keys on my keyboard layout.** Letters follow your layout (like Hyprland). Punctuation keys
(`,` `-` `=` `` ` ``) are bound by physical position, so they work on AZERTY/QWERTZ too.

**Laptop without a PrtScn key.** Super+Ctrl+C opens the Capture menu (screenshot, recording,
text, color).

**Docking / undocking.** When a monitor is added, workspaces re-split across the monitors automatically. A monitor that sleeps or is unplugged keeps its workspaces: they wait on the other monitors and go back when it returns. If you removed a monitor for good, run `winarchy apply -MonitorsOnly -Resplit`.

**A game gets tiled, or the bar shows over it.** Windows adds a game to its list the first time
Game Bar notices it; the folder/Playnite checks (see [Games](#games)) catch most others right
away. Still missed? Super+Ctrl+G marks the focused window, or add its process name (Task
Manager > Details, without `.exe`) to `"games"` in config.json. The log
(`%USERPROFILE%\.winarchy\logs\winarchy.log`) says `game: <name>` when a game is recognised.

**A window minimized and I can't get it back.** Super+M (or Super+Home) restores every
minimized window. `"blockMinimize": false` in config.json turns off the no-minimize policy
entirely (or add just that one program's process name to `"minimizeAllowed"`).

**A game keeps minimizing by itself.** A fullscreen game minimizes whenever another window
takes the foreground. winarchy gives it straight back unless you pressed a key, clicked or used
the pad just before, and logs every time a game loses it: `game lost focus: <game> -> <program>`
in the log names what took it. Games that run as administrator need the helper for this
(`winarchy game-setup`). `"gameFocusGuard": false` turns the give-back off (the logging stays).

**The AI agent icon doesn't show up.** It only appears once a coding agent has recorded usage on
this PC (or its provider reports limits). If you've used one and it still isn't there, run
`winarchy doctor`: it says whether Python 3 is missing — the `python` in WindowsApps is only a
Microsoft Store shortcut and doesn't count — and what each agent reported.

**`hdl` says "not inside Herdr".** The layouts build around the pane they run in, so run them in a
Herdr pane (Trigger › Herdr opens one), not a plain terminal.

**Something looks wrong.** Run `winarchy doctor`. Logs: `%USERPROFILE%\.winarchy\logs`.

## Credits

Omarchy by DHH and contributors (MIT) — themes, backgrounds, keybinding design, logo, templates,
the Herdr config and layouts, and the agent usage collectors (ported to Windows in `lib/agents`).
GlazeWM and Zebar by glzr-io (GPL-3.0, installed via winget, not bundled). Herdr by its authors
(installed from herdr.dev, not bundled). See [NOTICE](NOTICE).

## Contributing

Winarchy is free for anyone to use, change and share. Ideas, fixes and new features are welcome:
see [CONTRIBUTING.md](CONTRIBUTING.md) for how the code is laid out and how to test a change.

## License

MIT — see [LICENSE](LICENSE). Use it, fork it, change it, ship it.
