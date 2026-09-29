# Omarchy parity

Winarchy tracks Omarchy Quattro (v4.0.4). This lists what the menu and bar have from
Omarchy, and the entries that are left out on purpose because they have no Windows
meaning. `default/upstream.json` records the upstream commit last reviewed.

## Left out on purpose (Linux-only)

| Omarchy | Why |
|---|---|
| Install > Package / AUR / TUI, Style installs | pacman and the AUR |
| Install > Windows (VM), Preinstalls | Omarchy's own VM and package sets |
| Style > Unlock (Plymouth), Update > Config > Plymouth/Hyprsunset/XCompose | Linux boot and X/Wayland config |
| Setup > Security > Fingerprint / Fido2 / SSHD / Passwordless Sudo / Sudoless Docker | PAM and sudo; Windows Hello lives in Sign-in Options |
| Setup > Direct Boot, Reset Computer (btrfs snapshots) | Linux boot and snapshots |
| Setup > Plugins | Quickshell plugins (a Zebar pack is the equivalent) |
| Update > Channel | Winarchy has one release line |
| Trigger > Toggle > Crash Capture, Hybrid GPU, Touchpad Haptics | coredumps and Linux GPU switching |
| Trigger > Capture > QR Code | no screen QR reader on Windows |

## Not done yet

- World clock: no globe or weather, and no drag to reorder.
- Toggle > Battery Percentage and 1-Window Ratio.
- Install > AI: Dictation, Grok Bot, Hermes Desktop and T3 Code have no winget or
  Store package. Agents whose install hint could not be confirmed (Antigravity, Ori, Pi,
  Oh My Pi, Crush, Cursor CLI, Muse, Hermes) stay under Setup > Defaults > Agent only.
