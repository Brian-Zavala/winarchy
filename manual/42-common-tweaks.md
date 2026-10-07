# Common tweaks

This is a collection of common tailorings to the Winarchy setup. Most of them are a line in your settings, `%USERPROFILE%\.winarchy\config.json`, which takes effect as soon as you save it. See [dotfiles](31-dotfiles.md) for every setting there is.

If you screw something up, delete the line again, or delete the whole file to go back to the defaults. If you _really_ screw everything up, `winarchy uninstall` and the install one-liner start you over.

### Remove window gaps

On laptop displays, some people prefer not to waste any pixels on window gaps (or even a top bar, which you can toggle off with `Super + Shift + Space`). You can toggle all gaps off with `Super + Shift + Backspace`, or remove them permanently in your settings:

```json
{ "gap": 0 }
```

### Rounded window corners

Winarchy's default design is one of square corners, like Omarchy's. To soften that up a bit, copy GlazeWM's template with _Setup > Config > GlazeWM_ in the Omarchy menu, and change both `style: 'square'` lines under `corner_style` to `style: 'rounded'`. Saving the file reloads GlazeWM.

### Keep the Windows taskbar

_Trigger > Toggle > Taskbar_ in the Omarchy menu, or `winarchy taskbar off`. Both set this in your settings:

```json
{ "hideTaskbar": false }
```

### Let windows minimize

Nothing minimizes by default, since the taskbar is hidden and a minimized window would have no way back. To turn that off entirely, or for just one program:

```json
{ "blockMinimize": false }
```

```json
{ "minimizeAllowed": ["Spotify"] }
```

### Keep Windows Snap

Windows' own snapping (the layouts bar when you drag a window to the top edge, and the flyout on the maximize button) is off by default, since GlazeWM places windows. To have it back:

```json
{ "disableSnap": false }
```

### Turn off auto-tiling

New windows spiral into Hyprland's dwindle splits by default. `winarchy autotile off` puts them in one row, the way GlazeWM does on its own.

### Turn off focus follows mouse

```json
{ "focusFollowsCursor": false }
```

### Stop theming an app

Every app Winarchy themes can be left alone on its own, for example VS Code:

```json
{ "themeTargets": { "vscode": false } }
```

### Change the bar's look

Put your CSS in `%USERPROFILE%\.glzr\zebar\omarchy\user.css` (_Style > Menu Bar_ opens it). It's loaded after Winarchy's own and never overwritten, and the bar picks it up as soon as you save.
