# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

## 2026-10-31

682 new commit(s) on omacom/omarchy@quattro, [454b67d...037b104](https://github.com/omacom/omarchy/compare/454b67d95fd63c269c5315836a098038a0c61716...quattro).

Only the first 250 commits and 300 files fit in one comparison: follow the link for the rest.

**New Omarchy release: v4.0.6** (Winarchy tracked v4.0.4). Themes and backgrounds follow it; check its notes: https://github.com/omacom/omarchy/releases/tag/v4.0.6

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| Other | `.github/workflows/i18n-check.yml`<br>`.github/workflows/i18n-sync.yml`<br>`.github/workflows/test.yml`<br>`.greptile/files.json`<br>`.oligarchyrc`<br>`agents/skills/icon-font.md`<br>and 18 more | - |
| Conventions | `AGENTS.md` | `AGENTS.md`<br>`docs/` |
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent`<br>`bin/omarchy-default-agent` | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-copy`<br>`bin/omarchy-agent-account-exec`<br>`bin/omarchy-agent-account-home`<br>`bin/omarchy-agent-account-state`<br>`bin/omarchy-agent-account-transfer`<br>and 1 more | `lib/accounts.ps1` |
| Agent usage | `bin/omarchy-agent-usage-agy`<br>`bin/omarchy-agent-usage-claude`<br>`bin/omarchy-agent-usage-codex`<br>`bin/omarchy-agent-usage-copilot`<br>`bin/omarchy-agent-usage-cursor`<br>`bin/omarchy-agent-usage-deepseek`<br>and 18 more | `lib/agents/` |
| Other commands | `bin/omarchy-apply-hardware`<br>`bin/omarchy-apply-lock`<br>`bin/omarchy-apply-n1x-gpu-memory`<br>`bin/omarchy-apply-pacman`<br>`bin/omarchy-audio-input-mute`<br>`bin/omarchy-audio-input-set-default`<br>and 154 more | `lib/` |
| Launchers | `bin/omarchy-cmd-browser-handoff`<br>`bin/omarchy-cmd-default-browser`<br>`bin/omarchy-launch-about`<br>`bin/omarchy-launch-browser`<br>`bin/omarchy-launch-config-editor`<br>`bin/omarchy-launch-openclaw`<br>and 4 more | `ahk/launchers.ahk`<br>`ahk/menu.ahk` |
| Install / Remove | `bin/omarchy-install-ai-openclaw`<br>`bin/omarchy-install-ai-t3-code`<br>`bin/omarchy-install-browser`<br>`bin/omarchy-install-camera`<br>`bin/omarchy-install-dev-env`<br>`bin/omarchy-install-dictation-superwhisper`<br>and 30 more | `lib/catalog.ps1` |
| Menu | `bin/omarchy-menu`<br>`bin/omarchy-menu-herdr-keybindings`<br>`bin/omarchy-menu-images`<br>`bin/omarchy-menu-keybindings`<br>`bin/omarchy-menu-plugin`<br>`bin/omarchy-menu-select`<br>and 3 more | `zebar/omarchy/menu.json`<br>`zebar/omarchy/menu.js`<br>`ahk/menu.ahk` |
| Theming | `bin/omarchy-theme-bg-boot-intro`<br>`bin/omarchy-theme-bg-intro`<br>`bin/omarchy-theme-bg-next`<br>`bin/omarchy-theme-bg-set`<br>`bin/omarchy-theme-install`<br>`bin/omarchy-theme-refresh`<br>and 11 more | `lib/render.ps1`<br>`lib/themes.ps1`<br>`lib/targets.ps1` |
| Toggles | `bin/omarchy-toggle-animations`<br>`bin/omarchy-toggle-bar`<br>`bin/omarchy-toggle-crash-capture`<br>`bin/omarchy-toggle-hybrid-gpu`<br>`bin/omarchy-toggle-input-device`<br>`bin/omarchy-toggle-nightlight`<br>and 3 more | `ahk/winarchy.ahk`<br>`ahk/menu.ahk` |

Commits:

- [4f920a2](https://github.com/omacom/omarchy/commit/4f920a2022c51409dfc57c7f812ced159621b99f) Merge pull request #15526 from wstock/menu-remove-service-1password
- [8dfc94e](https://github.com/omacom/omarchy/commit/8dfc94e95deb849c0a4c90aed0df940dcb9ade00) Merge pull request #7716 from OldJobobo/fix/gate-calculator-bindings
- [f95e105](https://github.com/omacom/omarchy/commit/f95e1059d5a3a4393aef84013949ce00372de3ef) Merge pull request #15972 from omacom/tui-touchpad-scroll
- [e9fee63](https://github.com/omacom/omarchy/commit/e9fee63301097d635c54e6f90fd16942dcb6c03b) Merge pull request #15220 from omacom/battery-media-marquee
- [2ba11a4](https://github.com/omacom/omarchy/commit/2ba11a4d1ea69af9437cdb0f8b2bf5b299e7d2ff) Renumber the Brave Origin Copy URL rerun after quattro's migrations
- [84c2f54](https://github.com/omacom/omarchy/commit/84c2f54070f495881feb041088f76a31934b2b11) Leave Brave Origin's roots to the rerun alone
- [4fa9615](https://github.com/omacom/omarchy/commit/4fa96158f27c70229c4bb623a4aad016353be84e) Cut the Copy URL migration test down to the Brave Origin rerun
- [a951263](https://github.com/omacom/omarchy/commit/a951263326b5dc682880b0e6e65aee12dcc3780e) Merge pull request #10308 from omacom/brave-origin-copy-url-repair
- [a10f7a1](https://github.com/omacom/omarchy/commit/a10f7a10f7baeca556f7b48020f6d4d7ae9a5cb3) Remove inline reply and the KDE Connect helper from notifications
- [6cb521d](https://github.com/omacom/omarchy/commit/6cb521d973045722e11ed4c110844a5537a9175f) Treat KDE Connect as an ordinary notification sender
- [0ffa677](https://github.com/omacom/omarchy/commit/0ffa677e347f570fa22a031359a006e5d6414e7a) Merge pull request #14949 from omacom/omabot/pr-13699
- [03ff1ef](https://github.com/omacom/omarchy/commit/03ff1eff3812933f7088484533784d2f63eaf19a) Merge pull request #15932 from omacom/notifications-omapager
- [0a7beb7](https://github.com/omacom/omarchy/commit/0a7beb7d6fe2b677bdc57ff05518b073b2d6ee60) Take the keyboard screenshot on Super + Ctrl + Alt + C and give Google Maps back Super + Shift + S (#16048)
- [6bee248](https://github.com/omacom/omarchy/commit/6bee248a3c23e403f30b72be80c3815bf7ad6cac) Make Appearance a top-level menu holding the Style options (#15973)
- [7901c44](https://github.com/omacom/omarchy/commit/7901c449a6ffe77ac65cc914de44a10a7d493e80) Move Calculator and Activity to the apps tier (#16071)
- [5264cbb](https://github.com/omacom/omarchy/commit/5264cbbd139624b4d3e840cb66fc4ce8f256d14d) Add Super + Ctrl + T for themes and W for backgrounds, move Network to N (#16072)
- [3ac4365](https://github.com/omacom/omarchy/commit/3ac43659dcbf88e84d951e3ce979b48a60a7d1f2) Let install media preset the language, keyboard and timezone (#15522)
- [dde0d12](https://github.com/omacom/omarchy/commit/dde0d123bb7e130cb7c8a679ed9d3b8b2a11887e) Offer stable and rc on aarch64 (#16065)
- [e98a325](https://github.com/omacom/omarchy/commit/e98a3254c53d02399aafc56190eebd733edf949f) More relevant demo
- [ce39c5e](https://github.com/omacom/omarchy/commit/ce39c5e9e9e4f5db7e023a07d0eeda9351ef9c80) Keep a switch to stable or rc from stranding edge on an old omarchy-dev (#15903)
- [be5fefb](https://github.com/omacom/omarchy/commit/be5fefbebe3c3103bbd68c2ef7624881c71848b3) Merge pull request #15512 from scottjones/fix/fingerprint-enroll-guide
- [087f73d](https://github.com/omacom/omarchy/commit/087f73d899b456ce5275ebf27294d379585fbdb1) Merge pull request #14874 from scottjones/fix/drive-password-resume-slot
- [6905265](https://github.com/omacom/omarchy/commit/6905265089ad40bae10dcec24fff626d1b760b87) Switch the default kernel from Update > Kernel (#15966)
- [f1d1e9c](https://github.com/omacom/omarchy/commit/f1d1e9c67ef2825923421d54ce97a30d286ca581) Preserve monitor layout when re-enabling a display (#16147)
- [2e7c1fe](https://github.com/omacom/omarchy/commit/2e7c1fe43ec7a2ce1a9b3abafd766450eabee081) Refresh floating workspace exclusions for late personal rules (#16143)
- [fa94263](https://github.com/omacom/omarchy/commit/fa942634668eeede328f2fb4460e0a6bf1ba457a) Load translation catalogs before their first lookup (#16059)
- [82662dd](https://github.com/omacom/omarchy/commit/82662dd2627db3b22c63616d3cae025aeb0f1e47) Install GPU libraries before Lutris and Battle.net dependencies (#16046)
- [9c18df2](https://github.com/omacom/omarchy/commit/9c18df2f985f1822c3dd5086600ba857af0ab91e) Add Microsoft Surface Pro 11 board support
- [8f0b805](https://github.com/omacom/omarchy/commit/8f0b805e2d923913590707ccf73493f51d45a145) Ask omarchy-hw-aarch64-qualcomm for the Surface Pro 11
- [eb429ce](https://github.com/omacom/omarchy/commit/eb429ceee2e4dba36178fb85194c8b90e9be6ae0) Remove the Surface Pro 11's stock kernel with omarchy-pkg-drop
- [d0c377e](https://github.com/omacom/omarchy/commit/d0c377efb055e626f69cebc48f5aff75d4058356) Boot the Surface Pro 11 on Omarchy's aarch64 kernel
- [2b58569](https://github.com/omacom/omarchy/commit/2b5856984fd3a42f8394408d5208ac01de34b73c) Say why the Surface Pro 11 pins its device tree now that the list holds the kernel's own
- [a46e20f](https://github.com/omacom/omarchy/commit/a46e20f3647478eb28bec373376e5cb7d78b09f7) Check the Surface Pro 11 model with omarchy-hw-match-device-tree
- [7c79df9](https://github.com/omacom/omarchy/commit/7c79df9ae4af3a84f0627d9324b4f74e489df4dc) Call the device tree helper by the name it was merged under
- [6233153](https://github.com/omacom/omarchy/commit/623315337fc783416ea8d0cbc5031e4c7a985a9e) Restore the UKI configuration when the Surface Pro 11 kernel fails to install
- [d9202dc](https://github.com/omacom/omarchy/commit/d9202dc486bb1044088ffa92c668330e68ae2ea0) Make the Surface Pro 11's video clock controller optional in early boot
- [15f00c5](https://github.com/omacom/omarchy/commit/15f00c520699551128cdb07108bc7c28b18e27ed) Use stock libcamera for the Surface Pro 11 cameras
- [8a636f1](https://github.com/omacom/omarchy/commit/8a636f105c1a741c8b9f923536ff31b2ae1f3a81) Leave Surface Pro 11 power profiles to omarchy-power-profiles-daemon
- [4f469fe](https://github.com/omacom/omarchy/commit/4f469fea0df77b4e5115fe9ea13078c5367db408) Install the aarch64 kernel by its name since the rename, linux-omarchy
- [bdc9165](https://github.com/omacom/omarchy/commit/bdc9165ca9391f7adb52a84d4222b75a337715a5) List the Surface Pro 11's packages with the optional packages
- [9be79e4](https://github.com/omacom/omarchy/commit/9be79e469404eec4651daaf457c3a53fe743a4c8) Set up the Surface Pro 11 the way the other Snapdragon boards are
- [feb215d](https://github.com/omacom/omarchy/commit/feb215dc6c43ac1d6c53d505926f9c87598bb6f6) Keep the Surface Pro 11's boot setup safe across kernel changes
- [7075b61](https://github.com/omacom/omarchy/commit/7075b61c6aaa5d8589f6e816867508fc96dc49d9) Offer the first-run update only when there is something to update (#16211)
- [a17a001](https://github.com/omacom/omarchy/commit/a17a001b72799ccad1b1c9e859d4a5760a57e820) Move us to the front of a non-Latin layout list instead of duplicating it (#14076)
- [be54892](https://github.com/omacom/omarchy/commit/be54892f36b2803f1b798b0c0603cf8b25e4093c) Fix shell tests that read the developer's session, and add testing rules for agents (#16229)
- [5d8cc33](https://github.com/omacom/omarchy/commit/5d8cc3313b2c60786d4e5019a68906873aed36bd) Drop [aur] from the Apple Silicon pacman template (#16189)
- [976872f](https://github.com/omacom/omarchy/commit/976872fa3bfa01f126a4bf0ced3d5542e5566bab) Set the clock from ntp.omarchy.org instead of Arch's pool (#16247)
- [46ef114](https://github.com/omacom/omarchy/commit/46ef11455fe924648bd33052774423f818a00a97) Find the weather location and the installer's timezone with geo.omarchy.org (#16240)
- [b12539b](https://github.com/omacom/omarchy/commit/b12539b3c8ef747a5edab9c9e06b93bc761acc11) Make the keybindings menu's Lua bind scan safe against load-time config reads (#7564)
- [c39fd2a](https://github.com/omacom/omarchy/commit/c39fd2afdd40b4b0f18b3f5dc1369c4d6ae35e26) Keep the menu's rows when a source file is read mid-write (#16268)
- [3357f90](https://github.com/omacom/omarchy/commit/3357f90590d61330097dbe7763d39bf4e5bfd85a) Check connectivity against ping.omacom.io and fix the captive portal sign-in flow (#16186)
- [eb0c515](https://github.com/omacom/omarchy/commit/eb0c5155c8e52509972f06971512bd8a0c6f0c50) Battery notification says Fully charged and leaves out readings it doesn't have (#16272)
- [c872d57](https://github.com/omacom/omarchy/commit/c872d57cf3ff5089854b6e70706dd736b6d0245b) tailscale: virtualize the machine list so huge tailnets don't melt the shell (#7623)
- [aba6184](https://github.com/omacom/omarchy/commit/aba618402b5ad8d9517ddd3d21bd6ac5bd492a78) End an indexed walk over the keybindings scan's stub collections (#16276)
- [03b21c1](https://github.com/omacom/omarchy/commit/03b21c1b6707d4ba19ae7b16df2c15b44330ab03) Keep the fcitx5 unit inert when fcitx5 isn't installed (#11694)
- [ff545d5](https://github.com/omacom/omarchy/commit/ff545d5cba713337829717bf4d10dc4b4178392c) Notification polish and trims after Omapager (#16277)
- [446361a](https://github.com/omacom/omarchy/commit/446361a5f75bc835fe85da7a499b82351e6eb596) Shorten the battery toggle and say Stay Awake / Allow Sleep (#16271)
- [a4c2a30](https://github.com/omacom/omarchy/commit/a4c2a306c27e191490dc1e8c65f8ec1bef9ce658) Trim the notification engine's options, IPC and leftovers, and put snooze on one line (#16296)
- [d743f8e](https://github.com/omacom/omarchy/commit/d743f8e8245dd98f27b73b1d37dcfbd579c825d3) Fix Taildrop notifications: empty text, full path, missing previews, red title (#16301)
- [331fa3d](https://github.com/omacom/omarchy/commit/331fa3d52f9acbb10dd0062c8ab64e03aeb4fbca) Leave the indicator peek shut while hovering right of the clock (#16293)
- [3c7027d](https://github.com/omacom/omarchy/commit/3c7027db2a4fa9fa6a49d7af7f87c27ac48e677d) Show and dismiss notifications instantly instead of sliding and fading (#16306)
- [967bbdd](https://github.com/omacom/omarchy/commit/967bbdd7346e6e2ff1a6af33c5d762ea784832cc) Download packages from Omarchy's China mirrors on installs in China (#16256)
- [7bab7c2](https://github.com/omacom/omarchy/commit/7bab7c2f38d772cb443448d13409e1e413b4ab31) Remove notification snooze and the screen-sharing offer (#16429)
- [cbd44ba](https://github.com/omacom/omarchy/commit/cbd44ba1d649c334f3c9dcd8628c5c390524d344) Remove the notification panel and its preferences (#16430)
- [0d8edf3](https://github.com/omacom/omarchy/commit/0d8edf3812e0caafd155760c96bc2862933f611a) Delete the reader's own copy of the prints when removing fingerprints (#16403)
- [dcfc438](https://github.com/omacom/omarchy/commit/dcfc4387d21ff651e2c70f7a1470002972721bd0) Remove migration tests (#16302)
- [83d429c](https://github.com/omacom/omarchy/commit/83d429c63f915657446da05933f9335e58a7c548) Seed the Hermes app where ARM rebuilds it (#16124)
- [7c59c2b](https://github.com/omacom/omarchy/commit/7c59c2b03672cc7ad266dfc84664f3af7c248220) Drag a bar widget off the bar to remove it with a poof
- [e2d618a](https://github.com/omacom/omarchy/commit/e2d618ac298f08518e9974ade8025c35fed2a770) Keep the bar surface full-size so drags survive empty workspaces
- [b92adbb](https://github.com/omacom/omarchy/commit/b92adbb1f183dc4905bb08cf0a2078cc51b22f3e) Poof a removed bar widget away in a billowing cloud
- [1acb5a2](https://github.com/omacom/omarchy/commit/1acb5a2cac6622c6ad9a44353b0757248ecb0681) Simplify dragging a bar widget off to remove it
- [75d2206](https://github.com/omacom/omarchy/commit/75d2206e08606acc606c550f02a7b0be3f5c7f71) Let a platform turn its fingerprint reader on with the owner's agreement (#16360)
- [7a1960b](https://github.com/omacom/omarchy/commit/7a1960b30f730cbf2170c8be901acaee791616d8) Merge pull request #6782 from omacom/bar-drag-off-remove
- [02defc5](https://github.com/omacom/omarchy/commit/02defc51d62913f12dd9c1915c8509e038e6b086) Animate notifications in and out along Emil Kowalski's motion rules (#16469)
- [99f479b](https://github.com/omacom/omarchy/commit/99f479b65b59842b2c2c41852d209db960010b6d) Merge pull request #15878 from bjarneo/ethereal-roadster-starlight
- [e1891c9](https://github.com/omacom/omarchy/commit/e1891c910d65c37be401d2b614fa149d7cd7c671) Let omarchy-notification-send add action buttons (#16466)
- [f643adc](https://github.com/omacom/omarchy/commit/f643adc38ad65c4900609c5c1b0b5c359fef147a) Control notifications with the keyboard (#16471)
- [aaccd24](https://github.com/omacom/omarchy/commit/aaccd247174de475bb3f17bead1a1f6848f7b2b3) Grow panels out of the bar, close them faster, and morph between them (#16470)
- [59d6f7f](https://github.com/omacom/omarchy/commit/59d6f7f1f09c8e280941565f3d82b624939f7476) Grow panels to fit content that arrives after they open (#16483)
- [420ee0b](https://github.com/omacom/omarchy/commit/420ee0bee8bc29585bd16dcb25a83c620c0cdd1a) Keep the network panel open after picking a DNS provider (#16485)
- [2a1ff8d](https://github.com/omacom/omarchy/commit/2a1ff8d83647209f2f3247b4231977732d58df29) Show a video wallpaper's still frame on the lock screen instead of playing it (#15289)
- [a08ff34](https://github.com/omacom/omarchy/commit/a08ff3448718284f452a9b72fd0e55c67c061776) Let buttons give a little under the pointer (#16484)
- [1993633](https://github.com/omacom/omarchy/commit/19936335bb3906e79c8099b0a0b4a7007b94b2db) Write down the shell's motion rules for Omarchy and plugin work (#16486)
- [1b6a22f](https://github.com/omacom/omarchy/commit/1b6a22f4e91cf8156b8654e897a6b43fec43681a) Show the next bar tooltip at once while one is up (#16488)
- [54d4b7b](https://github.com/omacom/omarchy/commit/54d4b7b027fc64dcd0afa8206ad8f05e71381676) Ease the dock's motion and stop it when animations are off (#16491)
- [2ee9faf](https://github.com/omacom/omarchy/commit/2ee9fafa6a3ddb82cb10ce24deadf8d7a42cacaa) Fade the bar's colors on a theme change in 250ms, inside the motion budget (#16489)
- [8918fba](https://github.com/omacom/omarchy/commit/8918fbaec3224f34c5b8da763cd63ab4fffd7786) Route the remaining looping animations through Style.duration (#16490)
- [e16a7e7](https://github.com/omacom/omarchy/commit/e16a7e710887ee640d921b3da85a893eee56aed6) Ask for the git identity after first login, with GitHub sign-in (#16288)
- [6ddadd4](https://github.com/omacom/omarchy/commit/6ddadd450308695447939b67e5cca89694012b6b) Fail the shell tests on an animation duration outside Style.duration (#16492)
- [5bd0b64](https://github.com/omacom/omarchy/commit/5bd0b6458bda5010ddd8951020cc443e82d0a177) Show Open and Omacut buttons on the saved screen recording toast (#16499)
- [80e9460](https://github.com/omacom/omarchy/commit/80e946083ba5e8869a95d23783954ded680e434e) Add every coding agent and provider to the agents panel and the default agent (#14040)
- [13daf59](https://github.com/omacom/omarchy/commit/13daf594a4dfb7f23d7083e91f8f4e94940ea2a3) Let bar icons give a little under the pointer (#16503)
- [4e46082](https://github.com/omacom/omarchy/commit/4e46082b289e34d99313fcdd7a6507ea7450e429) Show each toast from an unnamed sender on its own instead of stacking them (#16515)
- [bd97868](https://github.com/omacom/omarchy/commit/bd97868a4f1d2dff160f15f59a289169375c6cd9) Open the indicator peek only left of the clock, not over it (#16517)
- [4fa93e9](https://github.com/omacom/omarchy/commit/4fa93e9f4c4f1e573009100d300141eff5270e6f) Translate the setup form from Omarchy's catalogs and let callers give a timezone fallback (#16049)
- [9ebdc30](https://github.com/omacom/omarchy/commit/9ebdc307bd45f36c29a583b0f3877219bb2514a2) Merge quattro and keep the console split through the new keybindings menu
- [ea7a030](https://github.com/omacom/omarchy/commit/ea7a030bbba890ebf682ea7236b9272a4186ba57) Merge pull request #7579 from mwikala/preserve-full-scratchpad
- [ef93001](https://github.com/omacom/omarchy/commit/ef930018396bb48bfcc72393628375b067ac3188) Launch a browser again when the configured one is gone (#16422)
- [50e229d](https://github.com/omacom/omarchy/commit/50e229d08f9bc4996b35be1468236d783a3e79d6) Keep the titlebar plugin loaded once a session has floated a workspace (#16397)
- [bcb6ac3](https://github.com/omacom/omarchy/commit/bcb6ac313d886240e3e002817a4115664e076dee) Translate the first-run, git setup, weather and input-method notifications (#16550)
- [701f159](https://github.com/omacom/omarchy/commit/701f15995c00aa702fed9c09fa98ba656f222b24) Switch to omarchy-power-profiles-daemon for working power profiles on ARM laptops (#14737)
- [63ac02e](https://github.com/omacom/omarchy/commit/63ac02e5452b9c83b4af620bc0df60a45ea171d1) Run the translate job when nothing needed extracting (#16559)
- [1e2d9f9](https://github.com/omacom/omarchy/commit/1e2d9f9ba4d72bde4406112e957aaa1f3b928894) Stack Taildrop notifications into one deck (#16561)
- [e5df29b](https://github.com/omacom/omarchy/commit/e5df29b64a0546531655152feaed0922f09225fc) Finish system updates when mise tool downloads fail (#16318)
- [0e6ca28](https://github.com/omacom/omarchy/commit/0e6ca28d170524b10ca3d630f8ffc98565db2ee2) Hold an error reply's body to the same deadline as a success (#16506)
- [59e30b3](https://github.com/omacom/omarchy/commit/59e30b39f14677ba7c23263b9b426320c7b4bb91) Send the low battery warning as a normal toast that goes after 30 seconds (#16562)
- [0f014d1](https://github.com/omacom/omarchy/commit/0f014d1f81d236b07835ae2abd210527b19b2308) Let the power-profiles-daemon migration finish without an active session
- [1381fa0](https://github.com/omacom/omarchy/commit/1381fa089c0fabb7bd63e7295e1d839c172a59f8) Merge pull request #16565 from omacom/fix-powerprofiles-migration-ssh
- [24f59da](https://github.com/omacom/omarchy/commit/24f59da29c14fad704e4db29c04f339780e9080e) Authorize omarchy update once, AUR and boot check included (#16568)
- [69f0317](https://github.com/omacom/omarchy/commit/69f0317ec4c914500c933e50165199c54b6320fd) Make shell tests pass from a symlinked checkout, an agent session, and a packaged install (#16570)
- [d52d57c](https://github.com/omacom/omarchy/commit/d52d57c378e5ff1136609c446e6027b752255907) Update translations (#16574)
- [1c880c0](https://github.com/omacom/omarchy/commit/1c880c0b32a2ee5415427a5c6ea1aafe345fe15b) Start the herdr server with the desktop session (#16572)
- [3372ceb](https://github.com/omacom/omarchy/commit/3372ceb223c498e87538d367c7a087fde831ce5f) Merge the translation sync pull request in the land job (#16573)
- [969aab5](https://github.com/omacom/omarchy/commit/969aab5829beed2d1c95a1578094b1e697deb927) Update translations (#16579)
- [632bf2d](https://github.com/omacom/omarchy/commit/632bf2dd5cff1066249fe586ff6c6470d2af252d) Read the language file with builtins in omarchy-i18n (#16584)
- [b72863a](https://github.com/omacom/omarchy/commit/b72863a22b52c75b6afbcb93b275f4ec456d17db) Update translations (#16586)
- [d93ad7c](https://github.com/omacom/omarchy/commit/d93ad7c2242e531e26c4e83759bb97cb7a58a4da) Announce saved screenshots with Open and Edit buttons (#16505)
- [e4e4622](https://github.com/omacom/omarchy/commit/e4e462209af3d85b2491ddce9e7e3f67d0896692) Update translations (#16588)
- [d407074](https://github.com/omacom/omarchy/commit/d407074a7a7d4bea0f59bc65649926ded896d6bd) Use the upscaled roadster starlight background in ethereal (#16592)
- [e59c675](https://github.com/omacom/omarchy/commit/e59c675c69e3009a19b1fc4f542ff12e15b12ea2) Give agents mise shims so they find tools installed after launch (#16593)
- [b8c3c22](https://github.com/omacom/omarchy/commit/b8c3c22e9327c6361040c11a794e7c65ed99875b) Hide gum help lines in the git setup flow (#16589)
- [cf1909a](https://github.com/omacom/omarchy/commit/cf1909a9bea8ae6472014af1b63c487b0c033b33) End the git setup notification body with a period
- [b987526](https://github.com/omacom/omarchy/commit/b987526c1e049480c91fc52025aaa20611de513f) Update translations (#16595)
- [a1ea609](https://github.com/omacom/omarchy/commit/a1ea6096d0bd88bd61ed871fc35628cd56e8bb72) Replace Osaka Jade with Jade Horse (#16594)
- [f48f25e](https://github.com/omacom/omarchy/commit/f48f25ed1b5c7cfc3174180f52e7d2e2ff2cf388) Update translations (#16597)
- [7aae3f5](https://github.com/omacom/omarchy/commit/7aae3f54eed03fe422cb838b4aa45a9a7d8bf2c5) Stop echoing the screensaver's exit key into the corner (#16596)
- [35ba844](https://github.com/omacom/omarchy/commit/35ba8447e4f2eca0c0cb798defeb07eb7391361e) Stop a closing popup card from taking clicks (#15111)
- [36faffc](https://github.com/omacom/omarchy/commit/36faffc071e8de10399b10f211c63ba202a2abdb) Ignore Hyprland's FALLBACK output when checking for external monitors (#13749)
- [2e86b52](https://github.com/omacom/omarchy/commit/2e86b52f111f29625b4b338a5459d482972d7178) Update translations (#16598)
- [88bf600](https://github.com/omacom/omarchy/commit/88bf60039536c332ef2cdf79d9376400492e135d) Ignore the full stop after a URL when checking translated manual chapters (#16580)
- [344116a](https://github.com/omacom/omarchy/commit/344116a088a842de89a2e206027a4b0e17d20bd3) Translate the About box headings, keys, age, uptime and update date (#16560)
- [6851ac9](https://github.com/omacom/omarchy/commit/6851ac91e458cf4508f36789d053aea2a1a2e4ec) Update translations (#16602)
- [2fca7fe](https://github.com/omacom/omarchy/commit/2fca7fe073e5ef71cd066ddb0d2294ad067deaf5) Update translations (#16604)
- [6573c3d](https://github.com/omacom/omarchy/commit/6573c3d4866ee73ae448c80c1e96771a2b4230ca) Name the hibernation resume device by its filesystem UUID (#16658)
- [c0b1088](https://github.com/omacom/omarchy/commit/c0b10882e6e9e69eeca5773312ff4b527a25eff7) Update translations (#16659)
- [58858ae](https://github.com/omacom/omarchy/commit/58858aecfa2a3e26c4d0a1371b369c672474fd04) Anchor the clock and weather popups under their widgets (#8942)
- [3bc4d0f](https://github.com/omacom/omarchy/commit/3bc4d0f79c5adc294d580c21c6fe61819ceda9e8) Make Super+comma dismiss, invoke, or focus the newest notification by its buttons (#16699)
- [ce03516](https://github.com/omacom/omarchy/commit/ce035166839393d72436ba57fee722a75b7a4a0c) Update translations (#16702)
- [425d59a](https://github.com/omacom/omarchy/commit/425d59af557b583d0faf979956c896902984b488) Count a notification's click as one of its actions on Super+comma (#16701)
- [6a44388](https://github.com/omacom/omarchy/commit/6a44388710ecf59a57560a98f8944564d06c67e3) Measure network speed with Omarchy's own service (#16681)
- [5d07f5e](https://github.com/omacom/omarchy/commit/5d07f5e18035d02c59d31a752af27b5aee6d7980) Update translations (#16705)
- [4601078](https://github.com/omacom/omarchy/commit/4601078a7d84ece7a3329b9a7ca6fce0a47d254f) Update translations (#16706)
- [67faeb0](https://github.com/omacom/omarchy/commit/67faeb0d2b55c38691b471891125ea8b8c77c711) Stop the background intro's frame poll once nothing is covered (#16731)
- [b8706a3](https://github.com/omacom/omarchy/commit/b8706a3f9eb185f56b61c6141561deba652beddf) Let Snapdragon laptops' keyboards type at the disk unlock prompt (#16688)
- [6cf686c](https://github.com/omacom/omarchy/commit/6cf686c69f326cc0e53765c091c841778e9dbf28) Clear the SoundWire routes the retired N1x UCM profiles left behind (#16233)
- [bedf37a](https://github.com/omacom/omarchy/commit/bedf37a286940f4eb0650d613ed2b752817f3841) Accept the Lenovo Pro 9 N1x GPU memory reservation layout (#16423)
- [412c7fe](https://github.com/omacom/omarchy/commit/412c7fe8d80ee3f903d5c046e7431ea9ccc4e049) Keep non-ASCII background names from aborting the quattro upgrade (#15277)
- [4d9ea5a](https://github.com/omacom/omarchy/commit/4d9ea5aac4962e0e0a527983ea191adea86ccf51) Keep the browser chosen on 3.x through the Quattro upgrade (#15074)
- [1d00a40](https://github.com/omacom/omarchy/commit/1d00a40244f9cf5fd91dffecb758537cf3839a76) Turn a panel-disabled laptop display back on once its external display is unplugged (#16310)
- [22ef225](https://github.com/omacom/omarchy/commit/22ef22541744d511293e6541dec83121e679771c) Keep unresolved FIDO2 migrations pending (#16421)
- [39d5665](https://github.com/omacom/omarchy/commit/39d56653d649312453316f2536fcfb9982f08fb8) Skip kernel migration without Limine tooling (#14188)
- [463a9a1](https://github.com/omacom/omarchy/commit/463a9a1d28d45e9c4714286745023272fc23fde7) Never overwrite a shell.json the shell could not read (#14534)
- [29cf76f](https://github.com/omacom/omarchy/commit/29cf76f141d1df7aecc67d631bffa0ebed6bedee) Remove tests that only read source text (#16334)
- [6250ec6](https://github.com/omacom/omarchy/commit/6250ec6da777ed5a0414fc40a5ae134bff7b4371) Remove live-desktop pixel tests (#16336)
- [25c4066](https://github.com/omacom/omarchy/commit/25c406631a3af51e58237a2b82d5eb6c29761295) Merge duplicate tests into shared and table-driven files (#16337)
- [fd58845](https://github.com/omacom/omarchy/commit/fd5884589bbfd94555a08cedc853ce2434191df1) Replace fixed sleeps in flaky tests with readiness signals (#16338)
- [c6f091e](https://github.com/omacom/omarchy/commit/c6f091e5c6de4950ac5467e2ad36ab11cfab2b1b) Remove tests that can't fail (#16756)
- [3138acf](https://github.com/omacom/omarchy/commit/3138acf5c45b2eba09b326aeaecbf2eff49a137e) Share the QML fixture and scratch-shell test harnesses (#16339)
- [5d83ad9](https://github.com/omacom/omarchy/commit/5d83ad95fd894cecaa9d908d9e92f35b952bd0db) Drop N1x settings that linux-omarchy 7.3-3 now handles in the kernel
- [958254e](https://github.com/omacom/omarchy/commit/958254e92ab3dba59ebe3257cbbaffd3357be2d5) Merge pull request #16758 from omacom/n1x-settings-to-kernel
- [6cc767f](https://github.com/omacom/omarchy/commit/6cc767f5ebe86312975315450332cc66ac2010ca) Keep the clock still when right click cycles its format (#16603)
- [40054aa](https://github.com/omacom/omarchy/commit/40054aa7a461bbc654aa728e4dfb9e62798feca0) Bound wallpaper resource use when sampling bar colors (#14281)
- [18ecf39](https://github.com/omacom/omarchy/commit/18ecf39440174ae6a5a7e097434d1d4375292375) Keep the clock still on every click (#16791)
- [84d4435](https://github.com/omacom/omarchy/commit/84d4435f9b90fb8e727423a26398f6fd4609bd37) Show agents panel sections only for subscriptions, keeping stale limits behind an info mark (#16795)
- [fdbe182](https://github.com/omacom/omarchy/commit/fdbe182d39c82a847e8b12708020d916105f7784) Launch the native Wayland screensaver
- [e3a5298](https://github.com/omacom/omarchy/commit/e3a5298c7b7aa3e6cd17f074a284f1297e3d631b) Stop tracking screensaver windows in the idle service
- [bc220e7](https://github.com/omacom/omarchy/commit/bc220e7028d5ab0ee467a0f094dd1a8da98b6c0a) Stop re-sampling the wallpaper for the transparent bar on unrelated state writes (#8307)
- [5c3303b](https://github.com/omacom/omarchy/commit/5c3303b84b5f44e21acd5d57fd6772c4a65ffd2f) Close the screensaver whenever the user is back
- [e29588a](https://github.com/omacom/omarchy/commit/e29588a144be10a535bd9e51e7317c67a755f306) Restore the cursor whenever system lock stops the screensaver
- [85d3824](https://github.com/omacom/omarchy/commit/85d382402e0d25994a6f4b7ee5331a15c88dd803) Drop the terminal screensaver's leftovers
- [c1e9e5c](https://github.com/omacom/omarchy/commit/c1e9e5ccc00ef153d4a68ca4139feeea82514cc7) Stop the screensaver when the launch grace ends with the user back
- [a001044](https://github.com/omacom/omarchy/commit/a001044030c5b0645ed1c46280678bfc3307e6a1) Restore bar-widget entries on enable when a plugins[] record lingers (#12540)
- [8ac025e](https://github.com/omacom/omarchy/commit/8ac025e84c7e529dd6a47ebb6e92e4fec9cb11e2) Drop the screensaver frame-rate override
- [a87ab40](https://github.com/omacom/omarchy/commit/a87ab405cf645dea6befe8a1782f3200de396dc5) Do not lock a user who came back during the launch grace
- [3b07d4e](https://github.com/omacom/omarchy/commit/3b07d4ed1984ea5958e831e63fccb0d88235c734) Restore the bash tag on the toggle example
- [a9cedf9](https://github.com/omacom/omarchy/commit/a9cedf93e0356d475411510e818e7e054a924d55) Count OS Age from the install, not the root image's build (#16828)
- [f85b887](https://github.com/omacom/omarchy/commit/f85b887c032a3e51b469634f45df29b1e5fce995) Offer Open and Cut buttons on the yt-dlp download toast (#16843)
- [a345dac](https://github.com/omacom/omarchy/commit/a345dacb75fe735c6a740b98440576f879e1a771) Update translations (#16846)
- [83f0400](https://github.com/omacom/omarchy/commit/83f040099f80a95f1983435e20fd2f631c2f8dee) Fix two shell tests that fail on every desktop run (#16826)
- [63b6e5b](https://github.com/omacom/omarchy/commit/63b6e5be0ea2faf1f7f9c0b3c2db2052cce31827) Wait for Elsewhen's first save before the smoke test edits shell.json (#16859)
- [e71dc3f](https://github.com/omacom/omarchy/commit/e71dc3fa7f727539de27029fa34489122b6b98e9) Let Omasnap's scroll capture see the screen behind its overlay (#16715)
- [baa0670](https://github.com/omacom/omarchy/commit/baa0670f2de3c73bf0e1acd18bb83addab5735aa) Keep the idle spawn test's exec logger off the vfork child's stack (#15382)
- [aba49d2](https://github.com/omacom/omarchy/commit/aba49d22cf77b4a8fd1859c721d6bbc6e986a27e) Run the translation check only on PRs that touch what it checks (#16862)
- [600ca88](https://github.com/omacom/omarchy/commit/600ca886632d4e0e2bba5afb759b3bb8d382cddc) Merge pull request #14390 from turbineBMW/upstream/surface-pro-11
- [b0846b2](https://github.com/omacom/omarchy/commit/b0846b2f8e8f360c1fd2421f4e2885add0e65666) Keep OWE intro errors out of the terminal after a theme switch (#16872)
- [e909874](https://github.com/omacom/omarchy/commit/e909874c3b2046d88df2579daf291e97766d4c52) Label the screen recording toast's Omacut button Cut (#16873)
- [ef4e148](https://github.com/omacom/omarchy/commit/ef4e148ddcae07f49cbd85ae955fd783a4c287a5) Update translations (#16874)
- [7481ace](https://github.com/omacom/omarchy/commit/7481ace828df9ace800242d35bad6ff418dbd9ec) Play a background's intro when changing backgrounds (#16875)
- [2e0eecd](https://github.com/omacom/omarchy/commit/2e0eecd500e400bbcc950007bb1aa614e4872661) Update translations (#16876)
- [9a90b5e](https://github.com/omacom/omarchy/commit/9a90b5e1e8a2bd1ae4f29cd89e99dec2ac8ecd5c) Fade background intros in like theme intros (#16877)
- [91acd2c](https://github.com/omacom/omarchy/commit/91acd2c7a3be5c9d40676b09ad3643fd43df762f) Sequence background intros in the shell (#16884)
- [ce0ef48](https://github.com/omacom/omarchy/commit/ce0ef48a8e7ed5affd3ee34ebaec8b07ada94aeb) Merge pull request #16800 from omacom/omabot/native-screensaver
- [9333e19](https://github.com/omacom/omarchy/commit/9333e198c41dde2f45abfe3436aaad7bb2ed373c) Bring Hyprland's default animations under the motion rules (#16889)
- [92468ee](https://github.com/omacom/omarchy/commit/92468eeed8ce4162cf47acdfe9fb52aed1293132) Update translations (#16890)
- [af21bdc](https://github.com/omacom/omarchy/commit/af21bdc59dbd7f0b2dd4863eed464748af4bdfd4) Use the upscaled geometric background in hackerman (#16892)
- [1e452a0](https://github.com/omacom/omarchy/commit/1e452a0c445cc152da6f566429495c655d551620) Add default touchpad gestures (#16891)
- [59b72aa](https://github.com/omacom/omarchy/commit/59b72aa276298351af23ccde9c865da064631ce3) Update translations (#16893)
- [e6c6a18](https://github.com/omacom/omarchy/commit/e6c6a1875fd371d16a69f29ff7a42d84a52f9bbe) Replace the i18n startup test's watched files whole (#16886)
- [79dcccf](https://github.com/omacom/omarchy/commit/79dcccfe5ab3b07a2660a9e99a1c6e3e717237fa) Wait for the input-indicator test's fake Fcitx to finish its exec (#16887)
- [24d09be](https://github.com/omacom/omarchy/commit/24d09bef2ab14c72da2dce03968e2e5e4da36ad5) Replace the roadster starlight background in ethereal
- [3c9898b](https://github.com/omacom/omarchy/commit/3c9898b0c95671bdfd3b9f2119ba9701fc0b1b68) Persist monitor scaling per monitor (#16923)
- [abe42d9](https://github.com/omacom/omarchy/commit/abe42d9c81af6c6839548a039064c79d19abf93c) The initial oligarchy tests
- [d11c3c7](https://github.com/omacom/omarchy/commit/d11c3c74892d157a77ae3b317e6fe805c1bfd021) Update translations (#16931)
- [6d47174](https://github.com/omacom/omarchy/commit/6d4717401dfdd7d4f34673fe1edaf8d6748c95af) updates for silent moves
- [b58e5b9](https://github.com/omacom/omarchy/commit/b58e5b999c03a1795badfd342a3f02986d854715) Give PipeWire realtime with rtkit and stop the silent app kills (#16824)
- [526fe64](https://github.com/omacom/omarchy/commit/526fe64706b0fcbaf0483ac7253cd62abe7854ae) Update translations (#16938)
- [9abdf96](https://github.com/omacom/omarchy/commit/9abdf964f4b3858437f6640a1c7cacc8239bccd8) Apply suggestion from @greptile-apps[bot]
- [068a122](https://github.com/omacom/omarchy/commit/068a1220d59f1d510c291d9ebd1a752148e86960) Time the lock's first appearance once the scratch shell is quiet (#16896)
- [dc0c509](https://github.com/omacom/omarchy/commit/dc0c509a8d2d0de2a625b8d5f04d457cb184e1d0) Set GDK_SCALE from the lowest monitor scale (#16950)
- [b79c846](https://github.com/omacom/omarchy/commit/b79c846e364aa71c708d7671afa9fb07026cde5e) Update translations (#16951)
- [fc91b6a](https://github.com/omacom/omarchy/commit/fc91b6ae9971bd6d9eb75b4952d04edf425d877b) Budget the lock view build against the shell's own start (#16952)
- [dff02d3](https://github.com/omacom/omarchy/commit/dff02d38a404b9604567cd9841c8c280d0e77115) Count the Windows VM test's descriptors in its own shell (#16953)
- [d498588](https://github.com/omacom/omarchy/commit/d4985887d6a1cfe6fc2f87b84585ec15958ab6ae) Merge pull request #16926 from ThePrimeagen/quattro
- [ede6d58](https://github.com/omacom/omarchy/commit/ede6d58c320d00e963caa223540a7ae30afc0821) Run the background intro fixtures' steps in order (#16958)
- [d2b6669](https://github.com/omacom/omarchy/commit/d2b6669d2ebdee851e1919588e9b27aa38affd5c) Read whole outputs before grep -q in three tests (#16959)
- [e9474ec](https://github.com/omacom/omarchy/commit/e9474ecae6520e44a40cc098fdfb5751b784a9a7) Test every pull request on a real Omarchy install (#16835)
- [8478247](https://github.com/omacom/omarchy/commit/84782475aeb885c8d05f9e85b6ad0f1a0add60e5) Create the T3 Code mount file before the mounter runs (#16962)
- [1676904](https://github.com/omacom/omarchy/commit/1676904e4f1d2fec52c316dee580722079a663fe) Offer rc on Apple Silicon (#16986)
- [eb65e64](https://github.com/omacom/omarchy/commit/eb65e64699b0d4d368c5fccd8c6038130aa3d565) Stop the hidden bar from catching clicks over fullscreen windows (#16991)
- [4872b40](https://github.com/omacom/omarchy/commit/4872b4061fde279e1eb60fd5151c5b72d9f7060e) Fix file manager shortcut in hotkeys manual (#8006)
- [62161e0](https://github.com/omacom/omarchy/commit/62161e0d8e928356b971ba1707fcd034c0a92e44) Document that resize Super+Minus/Equal are physical AE11/AE12 (#11026)
- [45ca581](https://github.com/omacom/omarchy/commit/45ca581e92fc2d8cc1908fdbdc0ef0455425e318) Warn that a snapshot restore leaves migrations marked as run (#15159)
- [2861f26](https://github.com/omacom/omarchy/commit/2861f26a83cda78a4c63cbdb552dc8c1280c4ed2) docs: document --prepare-only in menu-images usage (#13717)
- [1d6b470](https://github.com/omacom/omarchy/commit/1d6b47093d0c1d05bda7c6a56e575c41681f06c1) universal select all (#14307)
- [633d87f](https://github.com/omacom/omarchy/commit/633d87fcf427412743e1cddd8b883854dd1bf9f3) Document ASUS Fn+Super Windows-key lock in troubleshooting (#11045)
- [a4b086b](https://github.com/omacom/omarchy/commit/a4b086beb48e52c9d30865a5b86793180d3db7f3) Draw inline code in the generated VS Code theme as foreground on a muted fill (#15818)
- [4cff40c](https://github.com/omacom/omarchy/commit/4cff40cf9d74c2babf4b007e286662174bfebf37) Update translations (#16994)
- [11312b4](https://github.com/omacom/omarchy/commit/11312b4317af24caec91510ff19adbed8b9df8a7) Silence pgrep in font-set's terminal checks (#15820)
- [791b8fa](https://github.com/omacom/omarchy/commit/791b8fafa6bc8ef8637c913482c9eb71fb2161e7) Update translations (#16995)
- [2afe858](https://github.com/omacom/omarchy/commit/2afe858950829f3bc97ebfcedf86e51e30eef836) Answer the webcam menu guard from udev instead of opening cameras (#15910)
- [0c29fa5](https://github.com/omacom/omarchy/commit/0c29fa52d6a681cd18399c0eeb107d55dd1d8de2) Keep the keyboard backlight level when the lock blanks again before a wake (#15908)
- [3de3c32](https://github.com/omacom/omarchy/commit/3de3c326f89ab4f51d2179ff05dee6d2b6ca9a67) Keep bar icons level, centered, and at full size (#17003)
- [eadee5b](https://github.com/omacom/omarchy/commit/eadee5b9b6e54671b987f18cdfc1414f6782fb5c) Return window opening to its earlier 410ms (#17001)
- [0ba7646](https://github.com/omacom/omarchy/commit/0ba7646112c5e4c4b21917cf0a94fbb59885df50) Fix slider knob stopping short of the track end (#9345)
- [c050166](https://github.com/omacom/omarchy/commit/c050166a6b48736d3edc7c53f972df755be37ef9) fix: collapse dropdown toggle on second click (#6725)
- [5a4e7ae](https://github.com/omacom/omarchy/commit/5a4e7ae3305680540a9cf788200abef36ee07031) fix add built in transparency theme options (#6451)
- [33d6472](https://github.com/omacom/omarchy/commit/33d6472a3bb3e82675e8023335ba5515fb463d80) Measure hidden Buttons at their full width again (#15786)
- [431a008](https://github.com/omacom/omarchy/commit/431a00898cc70315fe108fd882bff3f2ced15a47) Include popup padding in dropdown height (#13916)
- [f94f9f8](https://github.com/omacom/omarchy/commit/f94f9f8faed23ab88f0d2ea7871025ae5a4a73c6) Use accent color for VS Code list hover (#7240)
- [9bf2754](https://github.com/omacom/omarchy/commit/9bf2754c2a3c43897c4c7a8ce28603d5d5a9dd9a) Tint the Claude Code diff panel with the Omarchy theme (#11131)
- [64833fa](https://github.com/omacom/omarchy/commit/64833fa9bf382999f453864ba66e8d760861d300) Keep one pending-migrations reminder instead of one per login (#16981)
- [573b518](https://github.com/omacom/omarchy/commit/573b518be16ec47547d50fe6197bc7f53e982340) Merge pull request #16805 from bjarneo/ethereal-roadster-gullwing
- [225dcb8](https://github.com/omacom/omarchy/commit/225dcb80ef1ced9436f27eb34ff140659d3956dd) Support the ASUS Zenbook A16's speakers, with ASUS's voicing (#17039)
- [7f4b1dd](https://github.com/omacom/omarchy/commit/7f4b1dd22cf256c074e71c7a2f56dc387033768c) Let the installer's timezone picker always be searched by typing (#17040)
- [717175d](https://github.com/omacom/omarchy/commit/717175d4a8c5a12f6c0fff10dcc3c1c08ef3a0d1) Seed the Quake console from workspace.created instead of on_created_empty (#17077)
- [432ae66](https://github.com/omacom/omarchy/commit/432ae6623e70b84bf89e2ef6c7a4d2ba18410cda) Keep the still on screen until OWE takes a video background (#17082)
- [ede3567](https://github.com/omacom/omarchy/commit/ede3567fa81bae231d5f9cd04e788408a392cb36) Load the Glymur pin control and interconnect drivers before disk unlock (#16940)
- [cf71857](https://github.com/omacom/omarchy/commit/cf71857c2589725558db9a8001ca353abedee360) Keep Hyprland off rtkit realtime until its RT watchdog kills are fixed (#17103)
- [bda3aaf](https://github.com/omacom/omarchy/commit/bda3aaf6955404712dbd46541e6c8a75a2b16b7c) Park the pointer off the dropdown list before the keyboard walk (#17117)
- [037b104](https://github.com/omacom/omarchy/commit/037b1044caf4914c8dfb0dda2836ea8cc5b4ed60) Skip the realtime repair when the omarchy package predates it (#17096)

## 2026-10-04

72 new commit(s) on omacom/omarchy@quattro, [b421b1b...454b67d](https://github.com/omacom/omarchy/compare/b421b1b479ee9ea0863792282eee4ffeb50923dc...quattro).

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent`<br>`bin/omarchy-default-agent` | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-home`<br>`bin/omarchy-agent-account-list`<br>`bin/omarchy-agent-account-mode`<br>`bin/omarchy-agent-account-remove`<br>`bin/omarchy-agent-account-rename`<br>and 2 more | `lib/accounts.ps1` |
| Agent usage | `bin/omarchy-agent-usage-claude`<br>`bin/omarchy-agent-usage-codex`<br>`bin/omarchy-agent-usage-fireworks`<br>`bin/omarchy-agent-usage-grok`<br>`bin/omarchy-agent-usage-update` | `lib/agents/` |
| Other commands | `bin/omarchy-audio-output-sink`<br>`bin/omarchy-openclaw-onboard`<br>`bin/omarchy-provision-first-run`<br>`bin/omarchy-provision-owner`<br>`bin/omarchy-provision-user`<br>`bin/omarchy-restart-shell`<br>and 5 more | `lib/` |
| Install / Remove | `bin/omarchy-install-ai-openclaw`<br>`bin/omarchy-install-gaming-gpu-lib32`<br>`bin/omarchy-install-gaming-steam`<br>`bin/omarchy-install-openclaw-cli`<br>`bin/omarchy-remove-ai-openclaw` | `lib/catalog.ps1` |
| Menu | `bin/omarchy-menu-images` | `zebar/omarchy/menu.json`<br>`zebar/omarchy/menu.js`<br>`ahk/menu.ahk` |
| Other | `default/agents/skills/omarchy-app/SKILL.md`<br>`default/agents/skills/omarchy-app/templates.md`<br>`default/bash/fns/agent-accounts`<br>`default/sddm/hyprland.lua` | - |
| Theming | `default/themed/neovim.lua.tpl` | `lib/render.ps1`<br>`lib/themes.ps1`<br>`lib/targets.ps1` |
| Upstream only | `install/omarchy-base.packages`<br>`install/user/mise.sh`<br>`migrations/1788256455.sh`<br>`migrations/1790397381.sh`<br>`migrations/1790702362.sh`<br>`migrations/1790702606.sh`<br>and 38 more | - |
| Manual | `manual/14-omarchy-cli.md`<br>`manual/17-ai.md` | `manual/14-winarchy-cli.md`<br>`manual/17-ai.md` |
| Shell (bar, menu, OSD) | `shell/Ui/PanelKeyCatcher.qml`<br>`shell/plugins/README.md`<br>`shell/plugins/agents/Agent.qml`<br>`shell/plugins/agents/Main.qml`<br>`shell/plugins/agents/Panel.qml`<br>`shell/plugins/agents/README.md`<br>and 9 more | `zebar/omarchy/` |
| Top bar | `shell/plugins/bar/Bar.qml`<br>`shell/plugins/bar/widgets/Indicators.qml` | `zebar/omarchy/bar.html`<br>`zebar/omarchy/bar.css` |
| Bar panels | `shell/plugins/panels/audio/Model.js`<br>`shell/plugins/panels/audio/Panel.qml`<br>`shell/plugins/panels/monitor/Panel.qml`<br>`shell/plugins/panels/network/Model.js`<br>`shell/plugins/panels/network/Panel.qml` | `zebar/omarchy/` |

Commits:

- [c9faea7](https://github.com/omacom/omarchy/commit/c9faea7c55c560107d8c0172173db054c5359e69) Keep PwNode objects out of the audio panel's Repeater models
- [6e15d76](https://github.com/omacom/omarchy/commit/6e15d76a624762d8332322e3d2cd605f3c56fbbb) Drop key auto-repeat in the lock screen password field
- [8a13eac](https://github.com/omacom/omarchy/commit/8a13eac872988c722be4cb4765211593b61d6de9) Defer to system-auth in the polkit stack written by fingerprint/FIDO2 setup
- [21e7975](https://github.com/omacom/omarchy/commit/21e7975352da486e2ff30820a9abab4c020fa28e) Harden the polkit migration: exact-layout match, retry on failure, and tests
- [6df574c](https://github.com/omacom/omarchy/commit/6df574cbb472340ba55b7c283e1df43466124159) fix(shell): keep __sourceDir on third-party plugin manifests
- [bce0f51](https://github.com/omacom/omarchy/commit/bce0f512e080df078a2c012c2ade7a44e54faa51) Clear setgid when hardening Windows VM directories
- [45fd98f](https://github.com/omacom/omarchy/commit/45fd98f34408e02a0c07da185aeb40e5100246bc) Report why Windows VM directory hardening failed
- [14921a9](https://github.com/omacom/omarchy/commit/14921a956ea998362e82b82fac4b092d9bcdfe02) Treat idle timeout 0 as disabled, not immediate
- [4c5f363](https://github.com/omacom/omarchy/commit/4c5f363df79d7a0b41716912664511b723d86eac) Install lib32 graphics drivers before Steam
- [92f9864](https://github.com/omacom/omarchy/commit/92f9864c72976b388075be4015006296eff40449) Prevent lid closure from interrupting shutdown
- [65883c3](https://github.com/omacom/omarchy/commit/65883c389082650edb14db012466397afff8ac8b) Keep the lib32 driver helper from failing when no GPU is detected
- [eaaca77](https://github.com/omacom/omarchy/commit/eaaca77efb1d1b6cfda37a2b60c6a26772562fd6) Report shutdown failures and test blocked window closing
- [be18b32](https://github.com/omacom/omarchy/commit/be18b324f8e952523a0f94f8357b29e5c7eb5334) Install OpenClaw as the self-updating copy under ~/.openclaw
- [24d591d](https://github.com/omacom/omarchy/commit/24d591da14ca5bbd2013450006f912bdbd502318) Refuse before touching anything, and move an old gateway cleanly
- [44f5fd8](https://github.com/omacom/omarchy/commit/44f5fd8f0e53380cdd360066208ce885b6113364) Stop an old gateway before seeding, and refuse before installing
- [d2305ad](https://github.com/omacom/omarchy/commit/d2305add6a0ff88fe129cb473548f4fa3eceb459) Keep the OpenClaw that can open the state when removal keeps the state
- [8d25d6a](https://github.com/omacom/omarchy/commit/8d25d6aef3cc56df36f26fd5b979d1457aa20daf) Require a moved OpenClaw service to be running again
- [abf2f75](https://github.com/omacom/omarchy/commit/abf2f756f265ece1a9df476d142d3fcd4f6bcbc1) Judge a service by its program, and name any service left stopped
- [91fd24c](https://github.com/omacom/omarchy/commit/91fd24c2b1bc86ea458f0f6a3bf0ac83ab46ef31) Resolve the audio output sink through EasyEffects 8
- [64e102a](https://github.com/omacom/omarchy/commit/64e102aaf2386427a77c323fdabf80ce29566e55) Keep OpenClaw's gateway probes off the wizard's terminal
- [b71b905](https://github.com/omacom/omarchy/commit/b71b905548fd584dda0d23472f81bca4d7676d8d) Revert "Keep OpenClaw's gateway probes off the wizard's terminal"
- [bedc2a3](https://github.com/omacom/omarchy/commit/bedc2a39792d0af05f80446af4806f7482c38327) Keep shutdown worker on the same script path
- [8942b0c](https://github.com/omacom/omarchy/commit/8942b0cd4c249ff760872cb6e96361e84526fd23) Keep a moved OpenClaw gateway on the runtime's own Node
- [72da1ec](https://github.com/omacom/omarchy/commit/72da1ec851132c0ba0d5162c77c78c32ec04674c) Move only services still on the old package's script or Node
- [9f0d464](https://github.com/omacom/omarchy/commit/9f0d4641bd121a9d49a36ef8c9b08e6617f56d21) Know the runtime's OpenClaw by its own script
- [de86454](https://github.com/omacom/omarchy/commit/de8645490b49f6476e53d2526914e2bac9d3d2de) Leave a moved OpenClaw service stopped or disabled if it was
- [9ace84e](https://github.com/omacom/omarchy/commit/9ace84e6c3d47d3a04acdf8ac806837c8adeabbe) Keep OpenClaw's gateway probes off the wizard's terminal
- [92e1a27](https://github.com/omacom/omarchy/commit/92e1a27618d07530bb9dc18437bbe1fdf91a4708) Make the audio row test fail when a row is the node itself
- [a383e3e](https://github.com/omacom/omarchy/commit/a383e3efcb275c5b14018db0e520ea4682bc6b6f) Say what nodeFor resolves a row to after PipeWire recreates its node
- [1095f73](https://github.com/omacom/omarchy/commit/1095f73aa65778800f6b068bbf642f445138efe3) Fix Display panel display toggle using rejected hyprctl keyword
- [199ac6f](https://github.com/omacom/omarchy/commit/199ac6fc282e0b30852f9fa6d2026d7a7cfebcd9) Change the aether nvim part to the omacom org
- [8b4eae6](https://github.com/omacom/omarchy/commit/8b4eae66da2938ba9559f103b18dbf85cdf28a70) Merge pull request #13771 from omacom/fix-aether-nvim-path
- [146fe5d](https://github.com/omacom/omarchy/commit/146fe5d368966560affe3a7e79f64c9c3c366d14) Say only what is true in the __sourceDir comment
- [84e88b4](https://github.com/omacom/omarchy/commit/84e88b4a8e44c33692e3561d3a94f2b2306daa8b) Guard third-party manifests keeping __sourceDir
- [377b15b](https://github.com/omacom/omarchy/commit/377b15be4b4ad7e88a3bac47f49059e45a954644) Don't fire a pending idle action whose timeout was set to 0
- [3839d0b](https://github.com/omacom/omarchy/commit/3839d0b4e0054c292d93ce143f39d91dce88f1dd) Keep a pending idle action on its deadline when the timings change
- [3cebdc3](https://github.com/omacom/omarchy/commit/3cebdc3412e6bb53dbffc57c36edff29b9c0446f) End a running idle cycle when both timeouts are set to 0
- [c05d901](https://github.com/omacom/omarchy/commit/c05d90196fc0dd5c21e2e797d80ffcc60d5e39fa) Switch between several Claude and Codex subscriptions, and build apps the Omarchy way (#13770)
- [f45461a](https://github.com/omacom/omarchy/commit/f45461a38f2b0a12ba39837eb41b08c012051780) Bring Grok up to par with Claude and Codex in the agents panel (#13992)
- [60c7386](https://github.com/omacom/omarchy/commit/60c73865e4732eb8717fae8f960d2c786e8f387d) Rewrite polkit-1 in place with sed -i so an interrupted migration cannot truncate it
- [d95c68f](https://github.com/omacom/omarchy/commit/d95c68f9fbd1d05bad37dfaba5cd62bfdf72833d) Match only active include lines when deciding polkit-1 is already fixed
- [821ae58](https://github.com/omacom/omarchy/commit/821ae589059ffdadc970315f866c94b55d268af7) Reorder the agents in the panel, count Grok's tokens, and install Grok through mise (#14004)
- [75250d3](https://github.com/omacom/omarchy/commit/75250d37acdf19121efe2af85b3732b8cf248980) Fix Codex limits, Claude counting, and agent usage reliability from community PRs (#14049)
- [0537ae1](https://github.com/omacom/omarchy/commit/0537ae121b7a777db1c705649216580a2fb41ea8) Merge pull request #11925 from joewinke/fix/plugin-thirdparty-sourcedir
- [a85e29a](https://github.com/omacom/omarchy/commit/a85e29abb556816f4644cf975e98da694b486aa8) Merge pull request #13296 from omacom/openclaw-self-updating
- [357d84f](https://github.com/omacom/omarchy/commit/357d84f17a8c6d133ee201a44ea6563204930a8e) Follow EasyEffects' links to Bluetooth sinks too
- [63c31bc](https://github.com/omacom/omarchy/commit/63c31bc68e9a1f1a2fdee82024e092568510a94b) Give the audio output sink test the standard header
- [2ba1015](https://github.com/omacom/omarchy/commit/2ba1015ef26486b940c68943e72295329856e0ce) Keep image picker work bounded for large theme collections
- [a8e09b9](https://github.com/omacom/omarchy/commit/a8e09b9ce2938bdab35e4bd7e827adcd0765c1c2) Keep refreshed image picker selection inside the active filter
- [520e4bc](https://github.com/omacom/omarchy/commit/520e4bca5bd0bc7388357b8bcfe50d14f70ee388) Retain lazy thumbnail jobs across concurrent refreshes
- [e0b0f34](https://github.com/omacom/omarchy/commit/e0b0f349f8717fdbbc1a19aede53e2331b1381ca) Escape the output name in the Display panel's hl.monitor eval
- [393a43d](https://github.com/omacom/omarchy/commit/393a43d469d2256f517cdce3b4f74115daed929a) Pin root= before the packages that can drop it (#6951)
- [dccd88b](https://github.com/omacom/omarchy/commit/dccd88b6c97f3b7b8ae6168bd110a872237bf673) Merge pull request #14117 from keylimesoda/fix/image-picker-large-collections
- [e5663c7](https://github.com/omacom/omarchy/commit/e5663c7e3a3bed93db557d7ab218d3aa46f27014) Keep image picker previews sharp on HiDPI displays
- [8e02fc8](https://github.com/omacom/omarchy/commit/8e02fc84f5bdc511ed102e2a14f8935bba4f92bd) Merge pull request #14156 from bjarneo/fix/image-picker-hidpi
- [1832855](https://github.com/omacom/omarchy/commit/18328559b9e2f283b4272f034689e3166ddf62a6) Keep the Wi-Fi icon steady on OWE transition-mode networks (#14133)
- [75b327b](https://github.com/omacom/omarchy/commit/75b327bc28dcb8bf4fe1df2aa1495384168b9242) Apply the system keyboard layout to the SDDM greeter (#6896)
- [5c4da02](https://github.com/omacom/omarchy/commit/5c4da021469517449770579793b37ce26d0a0d48) Merge pull request #7783 from omacom/fix/issue-6952
- [1f100bd](https://github.com/omacom/omarchy/commit/1f100bdf3fc43fcc7c2576348ac3b099f1763b64) Stop advertising forced user-setup reruns (#14194)
- [d21e581](https://github.com/omacom/omarchy/commit/d21e5810b19ab17055c5a7ce74df38fe446f85ad) Reset elapsed agent usage and show stale ages on hover
- [6809987](https://github.com/omacom/omarchy/commit/68099878922c0168315552f982b55979f333166a) Align panel underlines with native bar icons
- [7f91a8d](https://github.com/omacom/omarchy/commit/7f91a8d49edbcc0a50f2e49eb2819aa0be6a8ce9) Show recovery guidance when paused usage has no cache
- [4a568a1](https://github.com/omacom/omarchy/commit/4a568a138840943a69f277951f4b10cf007a0217) Merge pull request #14225 from omacom/fix/agents-usage-display
- [cb865c2](https://github.com/omacom/omarchy/commit/cb865c2fa4779b2176a18bd2385e92c390ef11b2) Merge pull request #9873 from Wheel-Smith/fix/polkit-faillock-system-auth
- [58aa857](https://github.com/omacom/omarchy/commit/58aa85721dd50b0fb5d8273ceb3a0fd1e70250ca) Merge pull request #13076 from chemineer1/codex/shutdown-lid-inhibit
- [ea5e438](https://github.com/omacom/omarchy/commit/ea5e438f4f989ad07f5ebed54f7d6547e876762c) Merge pull request #13396 from stefanoverna/easyeffects-sink-resolver
- [7901d7d](https://github.com/omacom/omarchy/commit/7901d7d0b6f80530e10b4be560f9eae1bcff1524) Merge pull request #12538 from paulogeyer/fix/10860-idle-timeout-zero
- [35a0d59](https://github.com/omacom/omarchy/commit/35a0d59053f57b097c7398dabab5cb3208766862) Merge pull request #12323 from atoslins/fix-windows-vm-setgid
- [00cee6d](https://github.com/omacom/omarchy/commit/00cee6d319bffd883814ab9d2d2a02cf8978ca58) Merge pull request #7806 from berndb/lock-ignore-autorepeat
- [dda5b40](https://github.com/omacom/omarchy/commit/dda5b40820d61eefee28d9acb37171d54896a45a) Merge pull request #12569 from selfcrypto/install-gpu-drivers-before-steam
- [2b2d462](https://github.com/omacom/omarchy/commit/2b2d462652f2789668a8252724be16f4f6c6ae84) Merge pull request #13725 from houz42/fix/monitor-panel-display-toggle
- [454b67d](https://github.com/omacom/omarchy/commit/454b67d95fd63c269c5315836a098038a0c61716) Fix the bar startup stall and the shell restart race (#11015)
