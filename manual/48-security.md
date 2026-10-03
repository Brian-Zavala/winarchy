# Security

Winarchy runs as you, not as administrator. Everything it installs goes into your user profile, except the few things below, and each of those asks first with a UAC prompt.

### What asks for administrator rights, and why

| What | When | Why |
|---|---|---|
| Installing apps with winget | Install, update, and _Install_ in the menu | Some installers (GlazeWM, for one) install for every user. Apps that need it are retried together, in one prompt |
| The browser toolbar color | `winarchy browser-setup`, once | Chrome and Brave only take a toolbar color as a browser policy, which lives in the machine-wide registry. Chrome then says "Managed by your organization" |
| The admin games helper | The install (its _Gaming_ step), or `winarchy game-setup` | Windows keeps normal programs away from games that run as administrator. See [gaming](26-gaming.md) |

Both one-time setups install a scheduled task that runs at the highest level for your account only. You can take them away with `winarchy game-setup remove`, or by uninstalling.

### Nothing you can write to runs as administrator

A program that runs as administrator must never run a file that a normal program could have changed, or any program could quietly borrow its rights. So both helpers run from their own copy in `%ProgramData%`, a folder only administrators can write to, and never from Winarchy's own folder in your profile.

They only read your files as data. The browser task reads the color to set from a text file, and the game helper reads the list of games. The game helper doesn't run GlazeWM's command-line tool itself either, since that lives in your profile. It tells Winarchy's normal, non-admin script which key you pressed, and that script does the rest.

### Windows you can't manage

Windows that run as administrator can't be moved, tiled or closed by programs that don't, and that includes GlazeWM and AutoHotkey. That's a Windows security boundary, and Winarchy leaves it in place: only the games helper crosses it, and only for the few things listed in [gaming](26-gaming.md).

### The backup journal

Every change Winarchy makes to your system is recorded in `%USERPROFILE%\.winarchy\backup` before it's made, so it can be undone. See [system snapshots](47-system-snapshots.md).
