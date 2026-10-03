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

Yes: _Trigger > Toggle > Taskbar_ in the Omarchy menu, or `"hideTaskbar": false` in your settings.

### Can I use my own AutoHotkey script for app keys?

Yes. The installer asks whether to keep your own launcher script, or set `"launchers": false` in your settings. See [dotfiles](31-dotfiles.md).

### Does it change anything I can't get back?

No. Every change is recorded before it's made, and `winarchy uninstall` puts it all back. See [system snapshots](47-system-snapshots.md).

### Should I just use Omarchy instead?

If you can, yes. Omarchy on Linux is the real thing: Hyprland does what GlazeWM can't, and nothing has to work around Windows. Winarchy is for when you can't switch yet, and the keys, themes and menu here are Omarchy's, so moving over later is easy. When you do, `winarchy uninstall` puts this PC back the way it was.
