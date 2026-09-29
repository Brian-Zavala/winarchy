# Omarchy parity

Winarchy tracks Omarchy Quattro (v4.0.4). This lists what the menu and bar have from
Omarchy, and the entries that are left out on purpose because they have no Windows
meaning. `default/upstream.json` records the upstream commit last reviewed.

## Omarchy's apps and keys

| Omarchy | Winarchy |
|---|---|
| Web apps (HEY, Basecamp, ChatGPT, Grok, WhatsApp, Google Messages / Photos / Maps / Contacts, X, YouTube, Zoom, Discord) | `default/webapps.json`, same URLs and keys; _Install > Web Apps_ puts them in Start (`lib/webapps.ps1`) |
| Launch-or-focus web apps (WhatsApp, Messages, Photos, Maps) | the key brings back the window it opened, or one titled with the site's name |
| Omawrite, Omacalc, Omacut, Hype, Aether | built for Windows by `.github/workflows/ports.yml`, _Install > Omarchy Apps_ once published (`lib/ports.ps1`); they read the theme from the colors.toml winarchy keeps where they look |
| Preinstalled GUI apps (Obsidian, LibreOffice, Xournal++, Pinta, mpv, OBS, Kdenlive) | _Install > Desktop Apps_ |
| TUIs (lazydocker, lazygit, Cliamp, dua) | _Install > TUI_, with `Super + Shift + D` and `Super + Shift + Alt + M` |
| Shell setup (starship, zoxide, eza, fzf, bat, aliases) | `winarchy shell on` (opt-in; never shadows a command PowerShell already has) |
| xcompose (CapsLock emoji, em dash, name, email) | `ahk/lib/compose.ahk` ("compose"; on for new installs) |
| Capture keys (Super + Print color picker, Super + Ctrl + Print text) | "captureKeys": "omarchy" for new installs; installs from before keep their own layout |
| Reminders, share, transcode, agent, Herdr keys, fullscreen desktop, laptop display / mirror, media keys | the same keys (`ahk/winarchy.ahk`) |
| Power panel and profiles (Super + Ctrl + P) | the bar's battery icon opens the Power panel (`zebar/omarchy/power.*`, `ahk/lib/power.ahk`): battery stats and Windows' power modes; _Setup > Power_ and a desktop's Super + Ctrl + P keep the menu |
| Media module in the bar | the bar's media module (Zebar's media provider) |
| No default coding agent until you pick one | Claude Code, once it is installed; picking another replaces it (`apps.agent`) |
| Agents panel: every subscription's limits, tokens today, Use / sign in, _Make something_ (theme, plugin, app) | the bar's agent panel (`zebar/omarchy/usage.*`); _Plugin_ makes a Zebar widget pack, which follows the theme and font; the tiles' prompts point at `agents/make/*.md` instead of Omarchy's skill |
| Agent account switching (Omarchy's `agent-account-switching` branch): several accounts per agent, `+`, Use, autoswitch, free resets | `lib/accounts.ps1` and `winarchy agent-account`; junctions instead of symlinks, copied settings; the active account reaches new sessions through Winarchy's launches and `claude`/`codex` functions in the PowerShell profile, not a session-wide variable; Codex adds accounts by device code, since it ignores `BROWSER` on Windows |

Every one of these keys yields to a key your own AutoHotkey script in the Startup folder
already binds (`lib/keys.ps1`, `BindUnlessUser`).

## Left out on purpose (Linux-only)

| Omarchy | Why |
|---|---|
| Install > Package / AUR, Style installs | pacman and the AUR |
| Install > Windows (VM), Preinstalls | Omarchy's own VM and package sets |
| Style > Unlock (Plymouth), Update > Config > Plymouth/Hyprsunset/XCompose | Linux boot and X/Wayland config |
| Setup > Security > Fingerprint / Fido2 / SSHD / Passwordless Sudo / Sudoless Docker | PAM and sudo; Windows Hello lives in Sign-in Options |
| Setup > Direct Boot, Reset Computer (btrfs snapshots) | Linux boot and snapshots |
| Setup > Plugins | Quickshell plugins (a Zebar pack is the equivalent) |
| Update > Channel | Winarchy has one release line |
| Trigger > Toggle > Crash Capture, Hybrid GPU, Touchpad Haptics | coredumps and Linux GPU switching |
| Trigger > Capture > QR Code | no screen QR reader on Windows |
| Monologue | PulseAudio capture; Windows has its own dictation (`Shift + F9`) |
| Tensaku, Omasnap | GTK4 layer-shell and Wayland-only screen capture |
| Voxtype keys | Windows' voice typing takes their place |
| Tmux (`Super + Alt + Return`, `Super + Alt + K`) | Herdr is the terminal workspace here |
| ONCE apps (Campfire, Writebook, ...) | self-hosted under Docker; a web app of your own points at one |
| Window grouping, scrolling layout, pseudo-tiling, tiled fullscreen, window width save/restore | GlazeWM has no equivalent |
| Notification keys (`Super + ,` dismiss, `Super + Shift + ,` dismiss all, `Super + Alt + ,` invoke) | Windows has no way to dismiss or invoke a toast from outside |
| `Super + Ctrl + Backspace` single-window square aspect | no GlazeWM equivalent |
| `Ctrl + Alt + Delete` close all windows | Windows reserves the key |
| Google Maps on `Super + Shift + S` | Windows' region screenshot keeps that key |
| xcompose's locale sequences (`include "%L"`: ' e = é, ...) | Windows' own keyboard layouts (US-International) do that |
| Keyboard backlight and touchpad keys | vendor tools own them on Windows |

## Limits

- Winarchy's AutoHotkey keys don't reach a window that runs as administrator (Windows'
  UIPI); GlazeWM's own keys do. Games that run as administrator: `winarchy game-setup`.
- Omarchy's apps built for Windows are not signed: Smart App Control blocks them, and the
  Install row says so before downloading.
- English-only parsing: `netsh` output in the Network panel, and date/time words in the bar.
- GlazeWM's IPC port is machine-wide, so two people signed in at once share one.

## Not done yet

- World clock: no globe or weather, and no drag to reorder.
- Toggle > 1-Window Ratio.
- Install > AI: Dictation, Grok Bot, Hermes Desktop and T3 Code have no winget or
  Store package. Agents whose install hint could not be confirmed (Antigravity, Ori, Pi,
  Oh My Pi, Crush, Cursor CLI, Muse, Hermes) stay under Setup > Defaults > Agent only.
- Omarchy's apps: the first Windows builds (the ports workflow has not been run yet, so
  _Install > Omarchy Apps_ stays hidden until default/ports.json has a published build).
- Omawrite as an "Open with" choice for .md files.
