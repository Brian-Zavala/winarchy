# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

## 2026-10-24

489 new commit(s) on omacom/omarchy@quattro, [454b67d...e1891c9](https://github.com/omacom/omarchy/compare/454b67d95fd63c269c5315836a098038a0c61716...quattro).

Only the first 250 commits and 300 files fit in one comparison: follow the link for the rest.

**New Omarchy release: v4.0.6** (Winarchy tracked v4.0.4). Themes and backgrounds follow it; check its notes: https://github.com/omacom/omarchy/releases/tag/v4.0.6

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| Other | `.github/workflows/i18n-check.yml`<br>`.github/workflows/i18n-sync.yml`<br>`.greptile/files.json`<br>`agents/skills/install-scripts.md`<br>`agents/skills/migrations.md`<br>`agents/skills/mise-tools.md`<br>and 35 more | - |
| Conventions | `AGENTS.md` | `AGENTS.md`<br>`docs/` |
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent`<br>`bin/omarchy-default-agent` | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-copy`<br>`bin/omarchy-agent-account-exec`<br>`bin/omarchy-agent-account-home`<br>`bin/omarchy-agent-account-state`<br>`bin/omarchy-agent-account-transfer`<br>and 1 more | `lib/accounts.ps1` |
| Agent usage | `bin/omarchy-agent-usage-codex`<br>`bin/omarchy-agent-usage-kimi`<br>`bin/omarchy-agent-usage-update` | `lib/agents/` |
| Other commands | `bin/omarchy-apply-hardware`<br>`bin/omarchy-apply-lock`<br>`bin/omarchy-apply-n1x-gpu-memory`<br>`bin/omarchy-apply-pacman`<br>`bin/omarchy-audio-input-mute`<br>`bin/omarchy-audio-input-set-default`<br>and 159 more | `lib/` |
| Launchers | `bin/omarchy-cmd-browser-handoff`<br>`bin/omarchy-cmd-default-browser`<br>`bin/omarchy-launch-browser`<br>`bin/omarchy-launch-config-editor`<br>`bin/omarchy-launch-openclaw`<br>`bin/omarchy-launch-screensaver`<br>and 2 more | `ahk/launchers.ahk`<br>`ahk/menu.ahk` |
| Install / Remove | `bin/omarchy-install-ai-openclaw`<br>`bin/omarchy-install-ai-t3-code`<br>`bin/omarchy-install-browser`<br>`bin/omarchy-install-camera`<br>`bin/omarchy-install-dev-env`<br>`bin/omarchy-install-dictation-superwhisper`<br>and 30 more | `lib/catalog.ps1` |
| Menu | `bin/omarchy-menu`<br>`bin/omarchy-menu-herdr-keybindings`<br>`bin/omarchy-menu-keybindings`<br>`bin/omarchy-menu-plugin`<br>`bin/omarchy-menu-select`<br>`bin/omarchy-menu-share`<br>and 2 more | `zebar/omarchy/menu.json`<br>`zebar/omarchy/menu.js`<br>`ahk/menu.ahk` |
| Theming | `bin/omarchy-theme-bg-boot-intro`<br>`bin/omarchy-theme-bg-intro`<br>`bin/omarchy-theme-bg-next`<br>`bin/omarchy-theme-bg-set`<br>`bin/omarchy-theme-install`<br>`bin/omarchy-theme-refresh`<br>and 11 more | `lib/render.ps1`<br>`lib/themes.ps1`<br>`lib/targets.ps1` |
| Toggles | `bin/omarchy-toggle-animations`<br>`bin/omarchy-toggle-bar`<br>`bin/omarchy-toggle-crash-capture`<br>`bin/omarchy-toggle-hybrid-gpu`<br>`bin/omarchy-toggle-input-device`<br>`bin/omarchy-toggle-nightlight`<br>and 3 more | `ahk/winarchy.ahk`<br>`ahk/menu.ahk` |
| Herdr and shell | `config/herdr/config.toml` | `lib/herdr.ps1`<br>`templates/herdr.toml.tpl`<br>`lib/agents.ps1` |
| Top bar | `config/omarchy/shell.json` | `zebar/omarchy/bar.html`<br>`zebar/omarchy/bar.css` |

Commits:

- [2b8177f](https://github.com/omacom/omarchy/commit/2b8177f36ae571e7a38ec7d595d93510e075921e) Put a widget the default bar does not already carry in the smoke test (#15297)
- [00a8a63](https://github.com/omacom/omarchy/commit/00a8a63162e85f115817bd7f2ec2c883a3671940) Load platform FileViews without binding loops (#15298)
- [47e86a2](https://github.com/omacom/omarchy/commit/47e86a275e13f8ffd4216e6dcf1d513776cb93b4) Reap orphaned plugin watchers at shell start (#15299)
- [3a140cc](https://github.com/omacom/omarchy/commit/3a140cc46664269306f0e4ed5ef0087a065d6750) Pin the toggle menu aliases Super+Ctrl+O routes through (#15300)
- [3b4c5d0](https://github.com/omacom/omarchy/commit/3b4c5d0dab641d8323d3fd62781f591627848460) Boot in 1 second, quietly, with a way back to the menu (#15301)
- [43584ba](https://github.com/omacom/omarchy/commit/43584ba8cfeec39ca4f5714e8f74047429381436) Guard shell start to a drawn bar (#15310)
- [75565a0](https://github.com/omacom/omarchy/commit/75565a040f7c9882090c74084d0f150c17924b8b) Guard launcher open to first frame (#15311)
- [7338958](https://github.com/omacom/omarchy/commit/7338958792ae9fc779c24f581b39538bee3dc592) Guard each bar panel's first open and reopen (#15314)
- [d709a04](https://github.com/omacom/omarchy/commit/d709a043c0f5a3b9b1df36335dccfeb7ecda20e8) Guard lock screen appearance (#15316)
- [df79d43](https://github.com/omacom/omarchy/commit/df79d4343131d7a284a32701839b30243b4313b5) Guard login to a drawn bar through the launcher (#15318)
- [f0ef162](https://github.com/omacom/omarchy/commit/f0ef1622bbd88906bffff95b0cbbb50f6cfe5e81) Run the shell test suite in parallel (#15302)
- [62c5165](https://github.com/omacom/omarchy/commit/62c5165d0a4faa2c93945f113f1bda5e6c30a1b8) Pick the matching Noto CJK variant for language-tagged text (#15116)
- [9e61222](https://github.com/omacom/omarchy/commit/9e61222f9274b19a3b396dd620755599fa72d85f) Name neither scan type when fprintd can't say which
- [7d64670](https://github.com/omacom/omarchy/commit/7d64670e4cf2f99e4e2c00d2a1efe442dcc98505) Say where the Touch ID driver's name comes from
- [326c853](https://github.com/omacom/omarchy/commit/326c853cac2442bcb9131939e4cb0be114420e34) Teach the app skill what building Signed taught (#15372)
- [096b624](https://github.com/omacom/omarchy/commit/096b624972d1a15d3eb10afea91f61fc63b75d7d) Fix seven busted tests on quattro (#15386)
- [9099461](https://github.com/omacom/omarchy/commit/9099461397fcab8fd260d89cd54938ef21be7e3f) Add Kimi as a selectable default coding agent (#7261)
- [9f49906](https://github.com/omacom/omarchy/commit/9f49906d22419c45931b92a8816ec852e232c6d6) Route links from every app through the running default browser (#14441)
- [64ec383](https://github.com/omacom/omarchy/commit/64ec3839ad72648bf5cccb2000759f49e318c223) Recover interrupted agent account sign-ins (#15399)
- [10a8579](https://github.com/omacom/omarchy/commit/10a8579a1275d7d77ad5f66dd2d4fe52bcece8dc) Copy agent subscription logins over SSH (#15405)
- [c88e7dd](https://github.com/omacom/omarchy/commit/c88e7dd566ab9415e657db5824b6c2c8958bff67) Add a Kimi usage collector to the agents panel (#7274)
- [985cd60](https://github.com/omacom/omarchy/commit/985cd6036821280be28345cb9f334d48b06f64d6) Pull only the blobs the dev checkout needs (#15426)
- [8dae158](https://github.com/omacom/omarchy/commit/8dae158c403632526a251ed6b1114777f165c88b) Match source account names when copying over SSH (#15430)
- [880e2e7](https://github.com/omacom/omarchy/commit/880e2e7f9e407f5f749c9e003b53cec6ce660a0f) Speed up the Codex scanner test from 41s to 8s (#15388)
- [b8fd058](https://github.com/omacom/omarchy/commit/b8fd058027cff3906e8311e7ee585887aaad9ecf) Speed up the input-devices test from 45s to 14s (#15391)
- [6f74b6b](https://github.com/omacom/omarchy/commit/6f74b6bdb6ae32d670667c82be64013622f31126) Speed up the openclaw-onboard test from 34s to 8s (#15392)
- [6155860](https://github.com/omacom/omarchy/commit/615586030bfc11c230438379901babab8db486a1) Speed up the clipboard test from 17s to 4s (#15393)
- [4623512](https://github.com/omacom/omarchy/commit/46235121d6fc56f1b6f8aea28d897e0aa760ef5f) Overlap the idle-spawn guard with the parallel test pool (#15396)
- [076e06c](https://github.com/omacom/omarchy/commit/076e06ccfe4ccd2e4504019e9e208dc2ed34c515) Speed up the hermes install test from 16s to 7s (#15398)
- [ef22c4f](https://github.com/omacom/omarchy/commit/ef22c4fe00627e1ad53054965098336f59c9c984) Fix menu-images cleanup never releasing its gates (23s to 3s) (#15402)
- [271645b](https://github.com/omacom/omarchy/commit/271645b4ba1796f4d64c64f11f93225ca95f6d27) Speed up the background startup failure test from 11s to 3s (#15403)
- [dc40a20](https://github.com/omacom/omarchy/commit/dc40a209b49cfe5de138b51f146272d1a62b46c3) Speed up the ssh-reconnect test from 14s to 12s (#15404)
- [e133869](https://github.com/omacom/omarchy/commit/e1338693c9ee58504efd1fd5061a2614fb4c88bd) Speed up the hybrid GPU tests from 12s and 6s to 1s each (#15410)
- [8b79a3c](https://github.com/omacom/omarchy/commit/8b79a3c40643be1dc7395547b9916e6bd120a7e4) Speed up the launch-shell test from 10s to 3s (#15412)
- [f7f6430](https://github.com/omacom/omarchy/commit/f7f64308247b473925a50b600bc36e011e20b1d4) Speed up the monitor-modeless test from 11s to 5s (#15414)
- [93fea89](https://github.com/omacom/omarchy/commit/93fea89c6de874b43c9c6ce586670416ed06887c) Speed up the input-indicator test from 10s to 3s (#15416)
- [edf3757](https://github.com/omacom/omarchy/commit/edf3757ea803c45cbeac0d0d0f7e408f42db01b9) Speed up the background-intro test from 7s to 4s (#15417)
- [5550ca1](https://github.com/omacom/omarchy/commit/5550ca18fe1472c89f149dfebf78c5e93aea0fbf) Speed up the screenrecording-concurrency test from 13s to 6s (#15418)
- [fe9ef72](https://github.com/omacom/omarchy/commit/fe9ef728676f399c83e37f273cd723698414edc8) Speed up the update-lock test from 7s to 4s (#15419)
- [3a16a47](https://github.com/omacom/omarchy/commit/3a16a47de0d4f894cb3c0bc28f3dc69cf6d98dfc) Speed up the system-sleep ownership test from 6s to 2s (#15420)
- [d679824](https://github.com/omacom/omarchy/commit/d679824776df72dbe0b9364d9360c7c4fdff34d8) Speed up the sleep-lock test from 19s to 7s (#15421)
- [7655773](https://github.com/omacom/omarchy/commit/7655773310070d925d58c60fa417a007aaae7bb4) Leave the fingerprint reader alone while the lock has the displays off (#15294)
- [58a289e](https://github.com/omacom/omarchy/commit/58a289e2876c4375c0144777eb4a509b6e3d63ca) Remove Rust through rustup's own path instead of a mise shim (#15436)
- [256e05b](https://github.com/omacom/omarchy/commit/256e05bd0b25486313f1ee978ff43e62eddf4091) Keep floating layout for workspaces with minimized windows (#15442)
- [84cfb93](https://github.com/omacom/omarchy/commit/84cfb93959f4fe0bbb71de71593b36647d2ba78d) Omarchy in 50 languages (#15326)
- [41d2f9d](https://github.com/omacom/omarchy/commit/41d2f9d9dcad91d07ebea30a6a663ca335e2cfa4) Respect clipping when forwarding bar clicks (#15501)
- [9141e46](https://github.com/omacom/omarchy/commit/9141e46531f80de4099a60727a5ddb89ddd9230e) Force C locale when classifying stay-awake parent dirs (#13352)
- [aec2190](https://github.com/omacom/omarchy/commit/aec21902191916d1a53e0eafd033b1ebb2751a9f) [verified] Keep hibernation prompt memory size locale-safe (#14520)
- [c582e1d](https://github.com/omacom/omarchy/commit/c582e1d7f89887ec0be65f34081565a43e211d6a) Perfect Japanese, Chinese and Korean setups (#15508)
- [b7e900c](https://github.com/omacom/omarchy/commit/b7e900cedd0c98e843aba4ae3ec301172044238a) Rework bar dragging, sections and widget orientation (#15517)
- [c5ccef6](https://github.com/omacom/omarchy/commit/c5ccef650b27484661f0c0e69e33b2cd7c19812e) Run parsed pactl commands in the C locale (#14850) (#14855)
- [246f33a](https://github.com/omacom/omarchy/commit/246f33a2fef66411c990860d88e0823ae83987fc) Support the NVIDIA N1x laptops (#14820)
- [341903f](https://github.com/omacom/omarchy/commit/341903f5c0e2a449a03cfac75aabc376e140c727) Add 1Password to Remove > Services
- [8a787b6](https://github.com/omacom/omarchy/commit/8a787b6a8bec830b04543bf14c760ee0a10591f6) List the ProArt P14's amplifier firmware with the optional packages (#15557)
- [51bfd1d](https://github.com/omacom/omarchy/commit/51bfd1dbaa1b5f790e19623faf2745945d40c796) Take a screenshot with Super + Shift + S (#8827)
- [499c618](https://github.com/omacom/omarchy/commit/499c6185a8d8735b1e9b99673315985ed49d5df6) Set up installed NVIDIA applications (#12723)
- [33783b1](https://github.com/omacom/omarchy/commit/33783b1707d2fd5cdbab99aec183fc761d14bca0) Keep installed ARM recovery packages during orphan cleanup (#12722)
- [595eefa](https://github.com/omacom/omarchy/commit/595eefa9f2d170662a749822a1f32000a6273d25) Decode video on the Snapdragon video chip in mpv and Chromium (#15697)
- [a8ac588](https://github.com/omacom/omarchy/commit/a8ac5880827cfac84cad99fef129ab459c0144c8) Enable desktop camera access on Snapdragon ThinkPad T14s (#15331)
- [cce8b1c](https://github.com/omacom/omarchy/commit/cce8b1c971df64a7610b818ff8819e4bea04584a) Add HP EliteBook Ultra G1q microphone UCM profile (#15574)
- [dc2b180](https://github.com/omacom/omarchy/commit/dc2b18098b1d74678b3186dd3b28095215ec14a6) Use a glyph for incoming Taildrop notifications
- [f4357a3](https://github.com/omacom/omarchy/commit/f4357a3b2667047aa3c295d89337fc0ff751b41f) Test Taildrop notification hints without image decoding
- [6c7893e](https://github.com/omacom/omarchy/commit/6c7893ee5003bd0da5769dc0eeb490fab0b8d1e9) Fix 'Go' translation error in Omarchy
- [6bfc12a](https://github.com/omacom/omarchy/commit/6bfc12a60e1d7570a4543774c2bbd47d6d46782d) Offer Dropbox on ARM machines with 4K pages (#15757)
- [5fcdaca](https://github.com/omacom/omarchy/commit/5fcdaca6495cac8931e0624c88414c95e0247585) Hide the GeForce NOW, Battle.net and Lutris installs on ARM (#15753)
- [a808491](https://github.com/omacom/omarchy/commit/a808491ba7aa1dbe7a2edf5ae27c71865e822cac) Say why fingerprint verification stopped
- [b7c60fe](https://github.com/omacom/omarchy/commit/b7c60feb108f4b3e6161502f4ce631eaeceb11e1) Keep Tokyo Night background picks after the renumbering
- [4a9c83d](https://github.com/omacom/omarchy/commit/4a9c83deceb5bda84f706794c2ddc61084914fe0) Merge pull request #15767 from omacom/fix/renumbered-background-selection
- [bf9ee5c](https://github.com/omacom/omarchy/commit/bf9ee5c7ee137eacad3943fb23ce15384a8e792e) Install Spotify as a web app on ARM (#15768)
- [386176a](https://github.com/omacom/omarchy/commit/386176ab48fe0e18f2194dc96b730b4dda7414a7) Float Bitwarden's own Linux builds like the Arch package (#15769)
- [f4a5ef6](https://github.com/omacom/omarchy/commit/f4a5ef6b86ca1086771f475cbccb78f189cd87f1) Merge pull request #15731 from Vinx911/quattro
- [7e62a1a](https://github.com/omacom/omarchy/commit/7e62a1a930e638892e9554a8971194c6ae1e1a57) Keep Go and Docker DB as names in 15 translations
- [fb45b98](https://github.com/omacom/omarchy/commit/fb45b98128eff90d809556237d9b809eb80923ca) Merge pull request #15777 from omacom/i18n/keep-go-name
- [f41da93](https://github.com/omacom/omarchy/commit/f41da937b122c6d3b6e80e4d32853c7e4ddc6df1) Show Codex individual spend limits and their reset times (#15722)
- [c0630b8](https://github.com/omacom/omarchy/commit/c0630b81a55f90a561f0bd2d60c569dad666710e) Fix typo in navigation manual: 'you to do' -> 'you can do' (#8974)
- [4e059ac](https://github.com/omacom/omarchy/commit/4e059acff2f4e4c4e5a303ce9bc97223097e45eb) Fix grammar in security documentation (#8805)
- [dd07b62](https://github.com/omacom/omarchy/commit/dd07b6269f0dd2a059b8ed5b4124f5adde74d389) Push a new language's LANG into Hyprland and the shell (#15791)
- [f2bd3ce](https://github.com/omacom/omarchy/commit/f2bd3cef6f8f0e6788f85073f87e7a1a064d11b4) Give each monitor its own workspaces (#15655)
- [0c93f61](https://github.com/omacom/omarchy/commit/0c93f6142a3771f63781fecd237701211e2da600) Remove the Reboot to Boot Menu menu item (#15795)
- [da2db1a](https://github.com/omacom/omarchy/commit/da2db1a2fe022089165b9edca3326886ad78dae2) Install default CLI tools through mise's native lazy shims (#9596)
- [f5b2376](https://github.com/omacom/omarchy/commit/f5b237674074f1019f31af266ed00802a5f11e2e) Retire the OpenClaw migration that stops every update on 4.0.5 (#15809)
- [a6dcc31](https://github.com/omacom/omarchy/commit/a6dcc31b6429fcf25e9e6bf90179f84c602cbf4e) Preserve the current channel when refreshing pacman (#15210)
- [12a293b](https://github.com/omacom/omarchy/commit/12a293b0aae73bc2b220c3a0e605d672e7fd1705) Revert "Retire the OpenClaw migration that stops every update on 4.0.5 (#15809)" (#15854)
- [01a0a6a](https://github.com/omacom/omarchy/commit/01a0a6adf0f2b3389005c9481a1c83219801e273) Let the OpenClaw migration finish under omarchy update
- [131e718](https://github.com/omacom/omarchy/commit/131e718432fa3694aaa16fd2512418fd49276a4a) Look for mise's shims wherever its data directory is
- [6ceb3cd](https://github.com/omacom/omarchy/commit/6ceb3cd145d32275cb1cdf19d8d3f4d618eb1102) Look in the shim directory mise actually uses
- [3c57b55](https://github.com/omacom/omarchy/commit/3c57b5586318423f227ee7ce732b4e43676eef8a) Let a migration wait for another repository's package
- [09ba618](https://github.com/omacom/omarchy/commit/09ba618379de1a21aedb17712c6223fadc9adeed) Defer only on a note, and stop waiting once a package changes
- [a2d720e](https://github.com/omacom/omarchy/commit/a2d720e9f3ccd266b286f4cbb7554a259053beae) Look again at a deferral that a later migration's package change made stale
- [2cc752c](https://github.com/omacom/omarchy/commit/2cc752c7c2114476d0af0c01f7c77d39f71b5935) Use the openclaw package as OpenClaw until it becomes the seed
- [5883425](https://github.com/omacom/omarchy/commit/58834251bedb68c0417bf1bc58b14652f06dd70f) Start a gateway again after a run that stopped it failed
- [b693064](https://github.com/omacom/omarchy/commit/b693064d3ac9936527454cd19c48afdb075a7c38) Keep the pre-seed package and the stopped-service record to their cases
- [47aef92](https://github.com/omacom/omarchy/commit/47aef9230ff21d8e275fb5238426172f5e8834e5) Move OpenClaw installed while waiting for the seed when the seed arrives
- [505d6f4](https://github.com/omacom/omarchy/commit/505d6f4f659dfafe87fd6f94293d68317ec8b21e) Reach whoever installs OpenClaw while waiting for the seed, however they install it
- [06f5660](https://github.com/omacom/omarchy/commit/06f5660bd987a003b243b8557058ca24c8556bb1) Let the agent key reach OpenClaw's launcher when only the package is there
- [fb18957](https://github.com/omacom/omarchy/commit/fb189573956b8dde01aefd6677f359589e441481) Keep a failed OpenClaw setup on screen in the agent's terminal
- [a38d9d1](https://github.com/omacom/omarchy/commit/a38d9d1d48600cb706d1d77b14130bcfe11c9c95) Stamp a deferral with the installed packages, and look again only on a change
- [3a6bbce](https://github.com/omacom/omarchy/commit/3a6bbce39393d1054ae4c75c8ff13e1e7b8409f9) Drop a stopped service's record once its unit is gone
- [0b8074c](https://github.com/omacom/omarchy/commit/0b8074ce72914ce118d107e8893bc2571966909f) Hold the package's own openclaw to the one-OpenClaw rule until the seed arrives
- [3bb2b6a](https://github.com/omacom/omarchy/commit/3bb2b6aed798c6a059c7c579da488680934517bc) Retire 1790397381 and move OpenClaw under a new migration
- [7be3cbb](https://github.com/omacom/omarchy/commit/7be3cbb95d0ccf38c1431634865530f9820502b3) Have a moved gateway answer, running doctor once if it does not
- [e3eea45](https://github.com/omacom/omarchy/commit/e3eea45eb231601cb0babd58e15bb2384d694ab2) Merge pull request #14212 from omacom/fix/openclaw-migration-update-path
- [f61be3f](https://github.com/omacom/omarchy/commit/f61be3fd40093e83af4f66f0b5bbc649adf427a9) Keep per-monitor workspaces on the right monitor after unplugs
- [357231b](https://github.com/omacom/omarchy/commit/357231b696981a63c0b9d056e06ae232d2bf4481) Check the reloaded module in the twin monitor test
- [2c1b5ea](https://github.com/omacom/omarchy/commit/2c1b5ea0648c180851c70e80de79331e547cfd2d) Revert migration-core changes from #14212 (#15864)
- [41344fd](https://github.com/omacom/omarchy/commit/41344fd18b03c63471e618d27579410788966c48) Merge pull request #15867 from omacom/monitor-workspaces-review-fixes
- [593a64e](https://github.com/omacom/omarchy/commit/593a64e37e310d96b1d7b7f16141beeed51c036b) Add roadster starlight background to ethereal
- [f6798dd](https://github.com/omacom/omarchy/commit/f6798dd2e06f04dbd49385de0b0a2e40aa14424a) Point Greptile reviews at AGENTS.md and the task guides (#15891)
- [2430f4f](https://github.com/omacom/omarchy/commit/2430f4feaed0790f0ff35f9334377c5d72db5efe) Let the console migration finish when the Limine config leaves the parameter out (#15852)
- [1d134a5](https://github.com/omacom/omarchy/commit/1d134a5261cb7764099aee8def09950fa518529a) Keep a non-Latin vconsole.conf out of the initramfs again (#14885)
- [60f5b49](https://github.com/omacom/omarchy/commit/60f5b4966624710d79d3afc7a31af84593a7fc7d) Let the OpenClaw move finish when an OpenClaw of the user's own is in the way (#15875)
- [73b14f9](https://github.com/omacom/omarchy/commit/73b14f9c322982c73a97becc152969b89a0759ea) Install T3 Code as its self-updating AppImage (#15907)
- [b5f8593](https://github.com/omacom/omarchy/commit/b5f8593dfc92b090b4cf0b8fcecd4b268485556d) Let Chromium use the Snapdragon laptops' cameras (#15895)
- [81fd2d2](https://github.com/omacom/omarchy/commit/81fd2d23ca6e3462183a4dc8360de3113fa8d80c) Find fingerprint readers a platform names (#14675)
- [aef8d09](https://github.com/omacom/omarchy/commit/aef8d09a294185e5e6af2576f6a3f70fc101c8cc) Keep the fingerprint setup test's check marks under the C locale
- [64685fa](https://github.com/omacom/omarchy/commit/64685fa2736d908445fce52441084a22d69b2e1a) Say lift and try again in one line when fprintd asks to lift the finger
- [3ba58c6](https://github.com/omacom/omarchy/commit/3ba58c625f7543b449a24c34eef5a60c8094c316) Give TUIs launched under their own app-id their terminal's touchpad scroll speed
- [f58c408](https://github.com/omacom/omarchy/commit/f58c408e30476fde76fbb13eb639bc1898d3a5f8) Let Elsewhen find real places, set here, and name the people in a city
- [096adaf](https://github.com/omacom/omarchy/commit/096adaf2c9a3b6139584ac4e9939098da0930cd1) Fetch people added to Elsewhen while another fetch is finishing
- [c8fb2b7](https://github.com/omacom/omarchy/commit/c8fb2b7806aab01d0576f5009ac7341483189e63) Move the clock when Elsewhen's here is on another zone
- [a3fa32f](https://github.com/omacom/omarchy/commit/a3fa32f7fcf54dd999536db43f0775bccfbda8d1) Harden Elsewhen's network reads and keep places, edits and weather straight
- [b904374](https://github.com/omacom/omarchy/commit/b904374db73cd33695690cfcca6033b2806f410e) Send Elsewhen's globe jump to the town that was picked
- [a91616c](https://github.com/omacom/omarchy/commit/a91616cbed90cfed1b4b3c175d89b6beb8441ca6) Install Node lazily through mise instead of during setup
- [02da3ad](https://github.com/omacom/omarchy/commit/02da3adab54846eb9fe605e95d2229f596708b54) Ship mise's upgrade pruning setting instead of writing the user's config
- [310fd8d](https://github.com/omacom/omarchy/commit/310fd8d8f62e3d375f5c5b3345ca9d1ce3e8c48a) Find the user's mise config where mise keeps it
- [06c0b7e](https://github.com/omacom/omarchy/commit/06c0b7edb29c7b1a7093a1f32a0553085783d120) Merge pull request #15876 from omacom/lazy-node
- [4039002](https://github.com/omacom/omarchy/commit/4039002da9c31560534272c0be75208a9eebc678) Merge pull request #16027 from omacom/elsewhen-places-and-people
- [4671ae2](https://github.com/omacom/omarchy/commit/4671ae2d38e6c0151a16da668ff97193724577cb) Replace the notification engine with Omapager's stacks, snoozes and panel
- [0c18e38](https://github.com/omacom/omarchy/commit/0c18e3807fb270212b44d961e2b34627d4675c5e) Add a notification demo for exercising the new engine
- [44261da](https://github.com/omacom/omarchy/commit/44261da979b605f7d061a8d5012f36e94a652439) Install Pillow and Bubblewrap and retire the Omapager plugin
- [9be81e1](https://github.com/omacom/omarchy/commit/9be81e1c6bc734946ea7b6ad243eaa2829f991ee) Decode notification images with ImageMagick instead of Pillow
- [06f401b](https://github.com/omacom/omarchy/commit/06f401bb0b17ff41967b234611d35ba88c187a0e) Keep recoloured notification glyphs anti-aliased
- [01d59ea](https://github.com/omacom/omarchy/commit/01d59ead79375956ab00ee52f9bb85bc4c90e3a4) Harden the notification image helpers against hostile input
- [4bc55dc](https://github.com/omacom/omarchy/commit/4bc55dcc6736c28b5baca39090dfe4a4f1dc8c84) Accept only cache PNGs and real PNG data from notification helpers
- [4c2ab42](https://github.com/omacom/omarchy/commit/4c2ab4286e7f4bb862b21518f25b7145066db3a0) Refuse sender images that resolve into /proc, /sys or /dev
- [bef3cba](https://github.com/omacom/omarchy/commit/bef3cba4226e869b0f20cd075028a66d2788028e) Publish notification icons from pixels outside the sandbox
- [96f0c19](https://github.com/omacom/omarchy/commit/96f0c1960cb88d9cc85985a81a2022f645a0054d) Bound sender-file reads and reap helpers on every failure
- [469494c](https://github.com/omacom/omarchy/commit/469494cc7adaa69a770c92a1b4a5954c003ab123) Seal the sender-image copy and tie its reader to the launcher
- [80c55b5](https://github.com/omacom/omarchy/commit/80c55b5a08274351a8aa38b0c4e23c99414ee3ed) Fetch site icons and decode them in separate sandboxes
- [21bee67](https://github.com/omacom/omarchy/commit/21bee67a4a5a5bcc83bb9b14f4e6f97f0f50fada) Tie notification sources to browsers and bound snoozes and click argv
- [40bc7ef](https://github.com/omacom/omarchy/commit/40bc7ef60c727eb06e38e6407c31de62862d38b0) Kill x32 syscalls, bind icon downloads to the source, and bound the whole icon job
- [654a77e](https://github.com/omacom/omarchy/commit/654a77e799b2a3001ab43efddb4d08b8d2aff33d) Centre short notification titles against the icon and drop the empty icon slot
- [eb3a488](https://github.com/omacom/omarchy/commit/eb3a488214bcb9798a6d1455cc9b724c223a504f) Trim the notification service
- [c177d7a](https://github.com/omacom/omarchy/commit/c177d7a68758942d8bc1f2c1dbcad1e1070639b8) Trim the notification cards and panel
- [2c68464](https://github.com/omacom/omarchy/commit/2c68464454195215fe81a0dc4ebd075ddf3d556f) Trim the notification logic and its tests
- [c85662a](https://github.com/omacom/omarchy/commit/c85662aff744fce117d31591c2e558da4b6a5a4c) Trim the notification helpers and their tests
- [ef6d0be](https://github.com/omacom/omarchy/commit/ef6d0be195aff00b07407439c5436c7a71bcdf0f) Trim the notification demo, docs and migration
- [c4cb519](https://github.com/omacom/omarchy/commit/c4cb519f693ab5b13d524a586602904333dcf0ae) Pass icon fields to the helper in the form it accepts
- [1e964d8](https://github.com/omacom/omarchy/commit/1e964d82830de514d1b8ed6a207d74e6395b4790) Open the panel from the bell when only sources are snoozed
- [3f02f8c](https://github.com/omacom/omarchy/commit/3f02f8cfc12a429406304e947b6404ba3641d151) Decode numeric entities beyond the BMP as whole characters
- [a9e5414](https://github.com/omacom/omarchy/commit/a9e54140b36f9546084184e8533528cff831832b) Format notification counts for the current language
- [eca5961](https://github.com/omacom/omarchy/commit/eca596150c0787a82a9dc126563f9833ced1c60f) Expect sender images to decode only when a sandbox works
- [b0490b4](https://github.com/omacom/omarchy/commit/b0490b4bf166d2e0bb7465b3c301e2b7fea388eb) Give held cards their resolved icon and resolve pruned icons again
- [0e5e49c](https://github.com/omacom/omarchy/commit/0e5e49ce389e2612c48cd4e79179c30e0ddda745) Merge queued store writes so a burst cannot drop closes
- [3069f20](https://github.com/omacom/omarchy/commit/3069f2031b514faa3fd3cb4ab287a43782b0c284) Treat plural I18n calls as translated in the literal scan
- [601f387](https://github.com/omacom/omarchy/commit/601f387bba1daf11a439c4c71408172d655849a9) Format the snooze day offset for the current language
- [f07acb4](https://github.com/omacom/omarchy/commit/f07acb453d114683ea1c3ef920e611b8559b85dd) Retry a missing icon once a minute instead of once a session
- [6904696](https://github.com/omacom/omarchy/commit/6904696025c8cb9179005946e0a8bf09ed3ad845) Stop asking the icon helper to fetch site icons
- [f3eeed0](https://github.com/omacom/omarchy/commit/f3eeed02ee8a195d88327d4754e670013cfc9990) Stop fetching site icons for notifications
- [a4a368b](https://github.com/omacom/omarchy/commit/a4a368bca5c05ebd573bca63fba4b561ab55f5fe) Document that notification site icons are never fetched
- [9a2346b](https://github.com/omacom/omarchy/commit/9a2346b6849e19748bbaa98a3c54dd8ff2ab618a) Drop the site icon cache instead of migrating it
- [0cb8ee6](https://github.com/omacom/omarchy/commit/0cb8ee6274ea3c0b034ddcd71497262fc70e6315) Drop the icon scheme argument nothing reads
- [8533da7](https://github.com/omacom/omarchy/commit/8533da71ba17ef91e2c834ec581549dc6c51c50b) Fix the demo's replay after the helper environment rename
- [f109b08](https://github.com/omacom/omarchy/commit/f109b08539268783fb2ddf092a8c4770a3f201d8) Replace the notification engine in place, without a migration
- [3c2247f](https://github.com/omacom/omarchy/commit/3c2247f1afb86fe5fce3dbed03d6eba9b140f144) Export OMARCHY_PATH so the factory reset's prompt shows under sudo (#16032)
- [bf7e8e6](https://github.com/omacom/omarchy/commit/bf7e8e6d6e2b2474c0e7afd3dc13c7aacea6e81d) Let the input method test compose on a UK install (#16031)
- [efd94d4](https://github.com/omacom/omarchy/commit/efd94d47b691c811287fb56b36d114ad2f8888d6) Merge remote-tracking branch 'origin/quattro' into fix/t3code-migration-no-launch
- [168fa54](https://github.com/omacom/omarchy/commit/168fa54b7d852a04a203ced07437467363dfe14a) Install the T3 Code app during updates without a prompt or a launch
- [2952b1c](https://github.com/omacom/omarchy/commit/2952b1c0020989fd1a87377039f5d9bb973df941) Give an updated notification a fresh countdown
- [c3ac1f9](https://github.com/omacom/omarchy/commit/c3ac1f9782b396499c78468675b231990b3138d6) Keep reply lookups for cards still waiting to be shown
- [6d75964](https://github.com/omacom/omarchy/commit/6d75964ef9b210fb4d0e49f454c7dabfaa7c094d) Fit saved notifications within the store's size limit
- [e3e08d3](https://github.com/omacom/omarchy/commit/e3e08d305052153f2e5ef601f270eb3976a56206) Read the previous engine's Do Not Disturb until quiet state is saved
- [f487703](https://github.com/omacom/omarchy/commit/f4877037434ba02ce5da0f114b9b6e96d0e5dfac) Clear leftover fetched site icons instead of pruning them
- [7b995c7](https://github.com/omacom/omarchy/commit/7b995c7dc20711d37200126eb521c030311d605f) Drop the T3 Code package only once the app is themed
- [60cce7a](https://github.com/omacom/omarchy/commit/60cce7afad06216203e0d86a6a03553bfc791551) Count a custom T3CODE_HOME as having run T3 Code in its migration
- [ab669e8](https://github.com/omacom/omarchy/commit/ab669e825a39b9030dfb8bb93daab67e8d02d2e7) Translate the redacted notification placeholder where it is shown
- [4258c79](https://github.com/omacom/omarchy/commit/4258c7940a6bc68bd316987423650c1dddf28f2f) Resolve notification icons in the shell
- [329fd1a](https://github.com/omacom/omarchy/commit/329fd1a9b83ae6dd456cc82895c54734cf5676a2) Fall back to the desktop-entry hint for notification icons
- [3b3349d](https://github.com/omacom/omarchy/commit/3b3349d59cc53afd2f7ce12af3fdb13d419a6457) Load sender images directly
- [8282fab](https://github.com/omacom/omarchy/commit/8282fab206cb42f22684e32068c2f2aa3839b34b) Merge quattro into fix/factory-reset-shared-esp
- [8bcba1d](https://github.com/omacom/omarchy/commit/8bcba1dbde2ce3812ee85ade6cb5c6b5342aa8d9) Remove the icon helper
- [e787ccd](https://github.com/omacom/omarchy/commit/e787ccd996fef518ea17fe0475a3151704dc2f72) Merge pull request #14178 from manuaudio/fix/t3code-migration-no-launch
- [98d76ec](https://github.com/omacom/omarchy/commit/98d76ec30b8d40e5a69893f05d056e8027e6bfca) Run the KDE Connect helper directly
- [1dd3ca6](https://github.com/omacom/omarchy/commit/1dd3ca62ec0dc788803c7f73cda7bf14424c4b75) Remove the helper sandbox
- [33ae361](https://github.com/omacom/omarchy/commit/33ae36133fb383e858512480e3845700f2fdfb1a) Trim the Neovim migration test to the omarchy-nvim regression
- [8e5bdd0](https://github.com/omacom/omarchy/commit/8e5bdd00efbf5b15f43d082e28b3a3a6364e48e2) Merge pull request #15141 from imzihuailin/fix/15072-nvim-migration
- [b6bde6d](https://github.com/omacom/omarchy/commit/b6bde6d05650c31a4e4d19c0d1416cf7751d5ccf) Keep notification history in the shell
- [773a1fd](https://github.com/omacom/omarchy/commit/773a1fd6cabf56f45a8cb6834adcbe66dc31906f) Reload an updated notification's picture from the same path
- [b5719a5](https://github.com/omacom/omarchy/commit/b5719a5c4f37bee8387a67f6180fdb218442ac6c) Drop the Remove > Services pairing test
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
