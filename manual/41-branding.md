# Branding

Winarchy lets you set your company logo or personal art for both the screensaver and the About screen, just like Omarchy.

### Screensaver

You can change the logo used for the screensaver under _Style > Screensaver_ in the Omarchy menu. It's an ASCII logo, so you edit the text directly.

There are three entries in that menu:

- **Preview** starts the screensaver right away, so you can see it.
- **Edit Text** opens `%USERPROFILE%\.winarchy\branding\screensaver.txt` in your editor. Type or paste whatever you like: ASCII art, your name, a rude word.
- **Restore Default** puts the Omarchy logo back.

The screensaver starts after 2.5 minutes idle, on every monitor, and never while a video, a game or a fullscreen app is in front. See [toggles, idle and screensaver](13-toggles-idle-screensaver.md).

### About screen

The same options are under _Style > About_, for the _About_ screen you get from the Omarchy menu. The file is `%USERPROFILE%\.winarchy\branding\about.txt`, and _Show_ opens the About screen so you can see the change. The About screen is fastfetch, so the art sits next to your PC's details.

Your branding is kept when you uninstall Winarchy (unless you use `-Purge`), and it's back the next time you install.
