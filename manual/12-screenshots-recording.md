# Screenshots & Recording

| Hotkey | Function |
|---|---|
| `Print` | Screenshot of a region |
| `Alt + Print` | Screen recording |
| `Super + Print` | Color picker: click anywhere and its `#rrggbb` is copied |
| `Super + Ctrl + Print` | Text: snip a region and the text in it is copied (see [text extraction](11-text-extraction-dictation.md)) |
| `Shift + Print` | Screenshot of everything, saved straight to `Pictures\Screenshots` |

These are Omarchy's keys, and what a new install gets. An install from before this version keeps the layout it had: `Super + Print` saves the whole screen, `Super + Ctrl + Print` is the color picker and `Super + Shift + Print` copies text. `"captureKeys"` in your settings picks one or the other (see [dotfiles](31-dotfiles.md)); `Super + K` always lists the keys you have.

No `Print` key on your laptop? `Super + Ctrl + C` opens the capture menu, as does _Trigger > Capture_ in the Omarchy menu.

Screenshots and recordings go through Windows' Snipping Tool, so you can mark up a screenshot before saving it. While a recording runs, a red dot shows in the bar.

Every new screenshot file is also copied to your clipboard, so you can paste it right away. `"screenshotAutoCopy": false` in your settings turns that off.

`Super + Ctrl + .` transcodes a picture or a video for sharing, as Omarchy does: a picture to jpg or png at high, medium or low size, a video to mp4 or gif at 4k, 1080p or 720p. The result is saved beside the original and copied to the clipboard as a file.
