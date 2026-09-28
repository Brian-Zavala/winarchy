# FAQ

### How do I switch between keyboard layouts?

Windows switches layouts with `Win + Space`, and Winarchy uses that for the Omarchy menu, so the installer asks when you have more than one layout. `Alt + Shift` still switches layouts either way, and `"takeOverWinSpace": false` in your settings gives `Win + Space` back to Windows. See [keyboard, mouse and trackpad](34-keyboard-mouse-trackpad.md).

### Do the keys work on AZERTY or QWERTZ?

Yes. Letters follow your layout, as they do in Hyprland. Punctuation keys (`,` `-` `=` `` ` ``) are bound by their physical position, so they're in the same place on every layout.

### My laptop has no PrtScn key

`Super + Ctrl + C` opens the capture menu: screenshot, recording, text capture and color picker.

### How do I change the clock format to 24-hour?

Right-click the clock in the bar to cycle through the formats, or set `"clock": "24h"` in your settings. By default it follows your Windows region format.

### How do I get the weather in Celsius?

Set `"units": "C"` in your settings. By default it follows your region. The bar guesses your location from your IP address; set `"location"` to pin it. See [dotfiles](31-dotfiles.md).

### Can I keep the Windows taskbar?

Yes: `"hideTaskbar": false` in your settings. The installer asks too.

### Can I use my own AutoHotkey script for app keys?

Yes. The installer asks whether to keep your own launcher script, or set `"launchers": false` in your settings. See [dotfiles](31-dotfiles.md).

### Does it change anything I can't get back?

No. Every change is recorded before it's made, and `winarchy uninstall` puts it all back. See [system snapshots](47-system-snapshots.md).
