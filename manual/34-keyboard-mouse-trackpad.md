# Keyboard, Mouse, Trackpad

### Keyboard layouts

Letters follow your keyboard layout, as they do in Hyprland. Punctuation keys (`,` `-` `=` `` ` ``) are bound by their physical position instead, so they're in the same place on AZERTY and QWERTZ as on QWERTY.

Windows switches between layouts with `Win + Space`, and Winarchy uses that key for the Omarchy menu. The installer asks about it when you have more than one layout. Either way, `Alt + Shift` still switches layouts, and `"takeOverWinSpace": false` in your settings gives `Win + Space` back to Windows; the menu then stays on `Super + Alt + Space`, and the launcher on `Alt + Space`.

Add a layout under _Setup > Input_ in the Omarchy menu.

### Mouse

Focus follows the mouse, as Hyprland's does: point at a window and it's the one you type into. It waits for the pointer to settle, so sweeping across the screen doesn't focus everything on the way, and it never moves focus while you're typing. Moving onto another monitor focuses that monitor even where there's no window under the pointer (an empty workspace, the bar), so the next app you open lands there. `"focusFollowsCursor": false` in your settings turns it off.

`Super + drag` moves a window from anywhere inside it, and `Super + right drag` resizes it. `Super + scroll wheel` goes to the next or previous workspace.

### Trackpad

On a laptop, _Trigger > Hardware > Touchpad_ opens Windows' touchpad settings, for speed, gestures and turning it off while typing.
