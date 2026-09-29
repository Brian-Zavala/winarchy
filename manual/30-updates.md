# Updates

Winarchy checks for updates by itself: two minutes after you log in, and every six hours after that. When there's something new, an update icon appears in the top bar. Click it, or run `winarchy update` from a terminal, to update everything at once.

An update goes through, in order:

- **Winarchy itself**, pulled from GitHub. A copy with commits of its own isn't touched, and the update says so.
- **Anything a newer Winarchy needs** that your PC doesn't have yet. `winarchy doctor -Fix` does the same for anything that went missing since.
- **Omarchy's themes and backgrounds**, when Omarchy has a new release. Winarchy follows Omarchy's releases, not every commit, and `omarchyTag` in your settings says which one you're on.
- **Herdr**, with its own updater, since it doesn't come from winget.
- **Your apps**, with winget. Apps whose installer needs administrator rights are retried together, with one UAC prompt. The few whose installers can't run unattended are left for you to open, and they update themselves.

Then your settings are applied again, so everything picks up the new version.

If you'd rather check yourself, `winarchy update-check` refreshes the icon, and _Update_ in the Omarchy menu has every step on its own.

_Update > Timezone_ and _Update > Time_ set your time zone and sync the clock (see [notices](10-notices.md)).
