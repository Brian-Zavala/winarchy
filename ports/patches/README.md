# Patches for Omarchy's apps on Windows

`.github/workflows/ports.yml` applies every `*.patch` in `ports/patches/<app>/` (`git apply`, in name order) to the pinned source before it builds. Keep them small, and mark each change `winarchy:` the way `lib/agents/usage-*.py` does.

What each app is expected to need, from reading the sources (to be confirmed by the first build):

- **Omacut, Hype**: their file pickers ask the desktop portal over D-Bus, which Windows doesn't have. A patch falls back to `QFileDialog`.
- **Hype**: `QProcess::setUnixProcessParameters` (`src/deck.cpp`) exists only on Unix; it goes behind `#ifdef Q_OS_UNIX`.
- **Aether**: its "apply to Omarchy" target writes Omarchy's theme folders. On Windows it writes `%USERPROFILE%\.winarchy\themes\<name>` (backgrounds into `wallpapers\<name>`) and runs `winarchy theme <name>`.

All four Qt apps read the theme from `%USERPROFILE%\.local\state\omarchy\current\theme\colors.toml`, which Winarchy keeps up to date (`Set-OmarchyStateTheme`, `lib/themes.ps1`), so the theme needs no patch.
