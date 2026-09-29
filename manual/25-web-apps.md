# Web Apps

Omarchy runs a few sites as apps of their own: HEY and Basecamp from 37signals, ChatGPT, WhatsApp, Google's Messages, Photos, Maps and Contacts, X, YouTube, Zoom and Discord. Each opens in a window of its own, with no tabs or address bar, and Winarchy does the same with your browser's app mode.

### Keys

These work straight away; installing the web app isn't needed for its key.

| Hotkey | Web app |
|---|---|
| `Super + Shift + E` | HEY |
| `Super + Shift + Alt + E` | HEY: a new email |
| `Super + Shift + C` | HEY Calendar |
| `Super + Shift + A` | ChatGPT |
| `Super + Shift + Alt + A` | Grok |
| `Super + Shift + Y` | YouTube |
| `Super + Shift + X` | X |
| `Super + Shift + Alt + X` | X: a new post |
| `Super + Shift + P` | Google Photos |
| `Super + Shift + Alt + G` | WhatsApp |
| `Super + Shift + Ctrl + G` | Google Messages |

WhatsApp, Messages and Photos bring back the window you already have open rather than opening another one, as they do in Omarchy.

Omarchy puts Google Maps on `Super + Shift + S`. On Windows that key takes a screenshot of a region, so it stays Windows'. Maps is in _Install > Web Apps_ like the rest.

A key that an AutoHotkey script of your own already has stays yours (see [hotkeys](07-hotkeys.md)).

### In Start and the Apps list

_Install > Web Apps_ in the Omarchy menu puts one in Start, with the site's own icon, so the menu's _Apps_ list and Flow Launcher find it too. An installed one is ticked, and _Remove > Web Apps_ takes it out again.

_Install > Custom Web App_ makes one for any other site: give it a name and an address.

### Which browser

Web apps need a Chromium browser: Chrome, Edge, Brave or Vivaldi. Your default browser is used when it is one of them. Otherwise it's the first of them found. Firefox has no app mode, so with only Firefox a web app opens as a normal tab.

`winarchy uninstall` asks whether to keep your web apps, along with the other apps you installed from the menu.
