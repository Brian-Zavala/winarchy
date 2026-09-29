# Browsers

Winarchy uses your default browser, whatever it is. `Super + Shift + B` opens it, and links from everywhere else open in it. Change the default under _Setup > Defaults > Browser_ in the Omarchy menu, which is Windows' own setting, or set `"apps": { "browser": ... }` in your settings to use another one for Winarchy alone.

_Install > Browser_ adds Chrome, Edge, Brave, Firefox or Zen, and _Install > Web App_ makes a Start menu shortcut that opens a site in its own window (Edge in app mode), as Omarchy's web apps do.

### Toolbar color

Chrome and Brave can follow your theme, with the toolbar in the theme's background color, as Omarchy's Chromium does. Run `winarchy browser-setup` once, or _Style > Browser Toolbar_ in the Omarchy menu. It needs one admin prompt, since the color is a browser policy, and Chrome then says "Managed by your organization". See [security](48-security.md).
