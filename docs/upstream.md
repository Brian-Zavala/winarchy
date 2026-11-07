# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

## 2026-11-07

848 new commit(s) on omacom/omarchy@quattro, [454b67d...5cf852c](https://github.com/omacom/omarchy/compare/454b67d95fd63c269c5315836a098038a0c61716...quattro).

Only the first 250 commits and 300 files fit in one comparison: follow the link for the rest.

**New Omarchy release: v4.5.0** (Winarchy tracked v4.0.4). Themes and backgrounds follow it; check its notes: https://github.com/omacom/omarchy/releases/tag/v4.5.0

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| Other | `.github/pull_request_template.md`<br>`.github/workflows/i18n-check.yml`<br>`.github/workflows/i18n-sync.yml`<br>`.github/workflows/test.yml`<br>`.github/workflows/visual-evidence.yml`<br>`.greptile/files.json`<br>and 20 more | - |
| Conventions | `AGENTS.md` | `AGENTS.md`<br>`docs/` |
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent`<br>`bin/omarchy-agent-integrate-herdr`<br>`bin/omarchy-agent-local`<br>`bin/omarchy-default-agent` | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-copy`<br>`bin/omarchy-agent-account-exec`<br>`bin/omarchy-agent-account-home`<br>`bin/omarchy-agent-account-rename`<br>`bin/omarchy-agent-account-state`<br>and 2 more | `lib/accounts.ps1` |
| Agent usage | `bin/omarchy-agent-usage-agy`<br>`bin/omarchy-agent-usage-claude`<br>`bin/omarchy-agent-usage-codex`<br>`bin/omarchy-agent-usage-copilot`<br>`bin/omarchy-agent-usage-cursor`<br>`bin/omarchy-agent-usage-deepseek`<br>and 18 more | `lib/agents/` |
| Other commands | `bin/omarchy-apply-hardware`<br>`bin/omarchy-apply-lock`<br>`bin/omarchy-apply-n1x-gpu-memory`<br>`bin/omarchy-apply-pacman`<br>`bin/omarchy-audio-input-mute`<br>`bin/omarchy-audio-input-set-default`<br>and 163 more | `lib/` |
| Launchers | `bin/omarchy-cmd-browser-handoff`<br>`bin/omarchy-cmd-default-browser`<br>`bin/omarchy-cmd-terminal-cwd`<br>`bin/omarchy-launch-about`<br>`bin/omarchy-launch-battlenet`<br>`bin/omarchy-launch-browser`<br>and 7 more | `ahk/launchers.ahk`<br>`ahk/menu.ahk` |
| Install / Remove | `bin/omarchy-install-ai-herdr`<br>`bin/omarchy-install-ai-openclaw`<br>`bin/omarchy-install-ai-t3-code`<br>`bin/omarchy-install-browser`<br>`bin/omarchy-install-camera`<br>`bin/omarchy-install-dev-env`<br>and 39 more | `lib/catalog.ps1` |
| Menu | `bin/omarchy-menu`<br>`bin/omarchy-menu-herdr-keybindings`<br>`bin/omarchy-menu-images`<br>`bin/omarchy-menu-keybindings`<br>`bin/omarchy-menu-plugin`<br>`bin/omarchy-menu-select`<br>and 3 more | `zebar/omarchy/menu.json`<br>`zebar/omarchy/menu.js`<br>`ahk/menu.ahk` |

Commits:

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
- [0740d1b](https://github.com/omacom/omarchy/commit/0740d1bbaeaa7bf08ccb1b9f3c8507575068351b) Return Hyprland's animations to their earlier feel, a fifth quicker (#17144)
- [0b10569](https://github.com/omacom/omarchy/commit/0b1056967b7902386e44e6c22ae649d76cd6634f) Load Omarchy's shell setup on Apple Silicon (#17041)
- [cec1d26](https://github.com/omacom/omarchy/commit/cec1d2600347885e4419303ac016319bcf2ae4ce) Install Intel hardware video decoding on Wildcat Lake (#17150)
- [c019850](https://github.com/omacom/omarchy/commit/c019850d7aef4ade679829d78223cd2eb1ecdac2) Mute Hyprland's system bell so terminals stop chiming on BEL (#17152)
- [ee8ad06](https://github.com/omacom/omarchy/commit/ee8ad06229e6a107877a48d4a2bfab022994efcb) Turn off Hyprland's support popup (#17153)
- [689e2e8](https://github.com/omacom/omarchy/commit/689e2e861f14551e7363f33f31fa811d075f1129) Draw first-boot setup with the ISO's traced-icon progress screen
- [b11ae7d](https://github.com/omacom/omarchy/commit/b11ae7d17992abff6311abacd4fef807691dc315) Keep the progress text's width limit across console resizes
- [f766bfa](https://github.com/omacom/omarchy/commit/f766bfa510711e4c3f84a38190e65c65449d9338) Keep HDR displays in SDR when a window goes fullscreen (#17157)
- [16bf8af](https://github.com/omacom/omarchy/commit/16bf8af85f7dbea7645014aa7810976cd80f1eb8) Keep an earlier ~/.bashrc.bak when the Apple Silicon bashrc migration runs
- [7b6efb0](https://github.com/omacom/omarchy/commit/7b6efb036a8b40d03454575ea3a2abea97608533) Merge pull request #17156 from omacom/provision-icon-progress
- [8320278](https://github.com/omacom/omarchy/commit/832027859fc297380b87e2e18f086adfb3da58c6) Merge pull request #17158 from omacom/bashrc-backup-name
- [6961922](https://github.com/omacom/omarchy/commit/69619222b255f5cb2a5b2d456438de45ec16bbd9) Stop worktree shells when restarting the shell
- [fb62f3b](https://github.com/omacom/omarchy/commit/fb62f3b47196fa3199c7d0cdff81ea0b07d426db) Say when a theme switch never reaches the shell
- [162291a](https://github.com/omacom/omarchy/commit/162291a39414bbce9a1849a622170dd7f43093d5) Require agents to restore the shell before moving on
- [44a9c90](https://github.com/omacom/omarchy/commit/44a9c9099560d2d6c49b7d4d14d9afe6f67dbcb0) Simplify stopping stray shells on restart
- [61a50de](https://github.com/omacom/omarchy/commit/61a50def423302ccf4738ec7401f342375e2f802) Drop the theme-set report of an unreachable shell
- [5c670c0](https://github.com/omacom/omarchy/commit/5c670c0b116defb324cccedff887bfb616b7c8f5) Wait for every stopped shell to exit before relaunching
- [8c3b22b](https://github.com/omacom/omarchy/commit/8c3b22b3281b58420dffd28a0e2d9ebf891494f2) Merge pull request #17160 from omacom/restart-shell-strays
- [9dbd12d](https://github.com/omacom/omarchy/commit/9dbd12dd2062bb0a1d9bcc776057a338c4f91add) Show one display at a time in the display panel, with a layout map (#17159)
- [a277197](https://github.com/omacom/omarchy/commit/a2771976194515717237e13f144200531e80860e) Update translations (#17165)
- [178d68c](https://github.com/omacom/omarchy/commit/178d68cee45cdba3726a3105bde371dd86f8dee3) Resize monitors without overlap, and migrate older monitors.lua files (#17166)
- [5ef4527](https://github.com/omacom/omarchy/commit/5ef45270e19eb3d51bb3bcc7c44422d5fb23a16a) Document recovery from broken session environment files (#10708)
- [d494d35](https://github.com/omacom/omarchy/commit/d494d35e20f13a44baa29e0c7d9bb883ac2cfe70) Install and remove Dropbox's libappindicator under its current name (#15076)
- [0ca79f2](https://github.com/omacom/omarchy/commit/0ca79f2b61ec123817dfffffda87cda63368f6b3) Ignore vendor hotkey keyboard devices (#9129)
- [d74e41f](https://github.com/omacom/omarchy/commit/d74e41f41a20968f4d82095bd219ae44d4d43e73) Let monitors.lua switch off the monitor panel's saved settings (#17169)
- [f77ed36](https://github.com/omacom/omarchy/commit/f77ed36c1e0e38268e93e374ecde51759f87c8ed) Float Inkscape's file choosers (#15792)
- [068bebb](https://github.com/omacom/omarchy/commit/068bebb310781d95989bcf8ece697b1f76535dfe) Rotate a monitor from the layout map's right-click menu (#17170)
- [5eb6e8f](https://github.com/omacom/omarchy/commit/5eb6e8f9e4a5e7a90fb94094d990f40b21b8138d) Update translations (#17172)
- [c97617b](https://github.com/omacom/omarchy/commit/c97617bdd4c4b076a1c2287bea38e21a622ad0e7) Hide Hibernate when the kernel will not accept the request (#7779)
- [0fc420c](https://github.com/omacom/omarchy/commit/0fc420c3d92d0fcda53f7e357e37e41369440668) Announce no saved recording when stop knows of none (#15073)
- [c726e6a](https://github.com/omacom/omarchy/commit/c726e6a732ce91280d4ee3a8ae94e9e8e4c6c9bf) Stop reloading a local plugin on its own Python bytecode writes (#15093)
- [ed0b436](https://github.com/omacom/omarchy/commit/ed0b436dd395562ceda0a0f9587ef76af0f9c6c1) Update translations (#17174)
- [56a910b](https://github.com/omacom/omarchy/commit/56a910b0e157f98a6fd3cf1133f2d9e7f58a2692) Use ordinary sudo: one password for ten minutes, plain update scripts (#17000)
- [b4b7ad9](https://github.com/omacom/omarchy/commit/b4b7ad96d31bf5aac6bffd5f97395ba05f948386) Offer refresh rates in the display panel (#17175)
- [4a0e486](https://github.com/omacom/omarchy/commit/4a0e48628a6d9c9046b5a08c714d2f3347e0765d) Update translations (#17176)
- [b083e16](https://github.com/omacom/omarchy/commit/b083e16a73ff5bdf1f61c267f49a0cafd7683f08) Trim the monitors.lua template to what the display panel doesn't cover (#17177)
- [8e1f951](https://github.com/omacom/omarchy/commit/8e1f951c8c35b2fa8101a5da681237e7a37e2644) Slide background changes on every monitor without a black flash (#17179)
- [e4fffc6](https://github.com/omacom/omarchy/commit/e4fffc6e6b57cda15cdba400e021596d985f9dbf) Update translations (#17180)
- [72cb55e](https://github.com/omacom/omarchy/commit/72cb55efabcfb7b8a9ceaaee33e5950051f56bed) Keep bar tooltips hidden until their surface has the output's scale (#16243)
- [f53e0b2](https://github.com/omacom/omarchy/commit/f53e0b2b7a9592ba108a4586d2dc374a63d09439) Don't call a battery draining on AC at 100% fully charged (#16278)
- [85241e9](https://github.com/omacom/omarchy/commit/85241e9305563c05b47e2a6445774d2e498d1cfd) Focus multi-word senders' windows from a notification click (#16380)
- [1ee5fd6](https://github.com/omacom/omarchy/commit/1ee5fd69acc1f2885efc13837628359e37f9218f) Notice images overwritten in place in the image picker cache (#15079)
- [0857083](https://github.com/omacom/omarchy/commit/0857083091bca2a0d55986ee6775b072b9610a48) Reset night light to the identity matrix when turning it off (#14489)
- [c304026](https://github.com/omacom/omarchy/commit/c3040266cb80d2019f7826b3b3fad967dc3d7206) Read CPU usage from top in the C locale (#15109)
- [37b1f3a](https://github.com/omacom/omarchy/commit/37b1f3a3bed41f9cf845ade02f1d8fb331a48b30) Remember a DDC display whose brightness cannot be read (#14525)
- [b628987](https://github.com/omacom/omarchy/commit/b628987691d2a2a98025835af4768a7ca9b16f3e) Stop the Dropbox status poll from voiding the pending login link (#15135)
- [65f629e](https://github.com/omacom/omarchy/commit/65f629eab26bbc54019e7f8f12701e0a12e751a9) Open a new terminal in HOME when the focused window is not a terminal (#15007)
- [60a912b](https://github.com/omacom/omarchy/commit/60a912bca71ab8a56257598fe5cf23ad4e2825c7) Center a popped-out window again when it moves to another monitor (#14549)
- [690edc5](https://github.com/omacom/omarchy/commit/690edc5ce7335a39446808b3aae67c90eee6ab6f) Toggle dictation with Alt + Space, push-to-talk with Right Alt (#17188)
- [31020ac](https://github.com/omacom/omarchy/commit/31020accbf8e2f4076097100feb1d5ab5500d36d) Keep the media widget on a paused track when an idle player holds a stream (#14585)
- [ab85004](https://github.com/omacom/omarchy/commit/ab850047816e9b7784f700b55c83a5b718653432) Let the Bitwarden extension popout keep the size it asks for (#14514)
- [4b0d77c](https://github.com/omacom/omarchy/commit/4b0d77c6ca30101621425d2fb52e5aea18fc4f5e) Update translations (#17192)
- [2ec2dc2](https://github.com/omacom/omarchy/commit/2ec2dc2ddef436cf81f8c481b5e14c33ce2e1e82) Update translations (#17193)
- [96906e8](https://github.com/omacom/omarchy/commit/96906e80b11ac823e35ad1aa2894a9cadd18a300) Add Hex as a selectable dictation backend (#17186)
- [0a1dd20](https://github.com/omacom/omarchy/commit/0a1dd2007ae18b088c3ebdcfc71c28b88457c898) Keep the screenshot picker from unbinding the user's own keys (#15126)
- [e74970e](https://github.com/omacom/omarchy/commit/e74970e36bfa6b55521410c97a07437720cffa09) Update translations (#17194)
- [846e030](https://github.com/omacom/omarchy/commit/846e030765c564b499889e8e0aa180973ef49cca) Update translations (#17195)
- [dfdf0b0](https://github.com/omacom/omarchy/commit/dfdf0b0e0337cba6363298edbaa68f22a17f92ba) Name the provider in the account rename hint (#14099)
- [2f1a2c5](https://github.com/omacom/omarchy/commit/2f1a2c5df3a66f15ead5577a01d49750580c9cff) Stop Dropbox relative time showing "0y ago" for 360-364 days (#14183)
- [a3c3a6a](https://github.com/omacom/omarchy/commit/a3c3a6ae9d9a1ef1718a616f26461dea0854a17c) Refuse --reauth without an account instead of adding one (#14100)
- [09ed48f](https://github.com/omacom/omarchy/commit/09ed48f84c6cd81065326c37d238b96b433b3960) Preserve terminal font size when changing font family (#6958)
- [f51ecf1](https://github.com/omacom/omarchy/commit/f51ecf1558bc958fc2dc2ebf3bec7d63207a83ce) Leave a dangling shared symlink alone when setting up an agent account (#14103)
- [b94447f](https://github.com/omacom/omarchy/commit/b94447fe8ec162cf2d534b787e17851b3220047c) Paint dark symbolic tray icons in the bar foreground (#14661)
- [1f7c8c5](https://github.com/omacom/omarchy/commit/1f7c8c5e9b467590a06a6e55e445220b52fe2e1e) Cycle backwards through every window with Alt + Shift + Tab (#8576)
- [51b348b](https://github.com/omacom/omarchy/commit/51b348bbe74483f7c1d24d6463764b96a5fef022) Keep a legacy Windows VM password with $$ working after the Quattro migration (#13432)
- [4157e42](https://github.com/omacom/omarchy/commit/4157e42dcacbdbcdb035951eb98caeb070a27398) Use the latin1 console keymaps for German and French in the setup form (#14684)
- [ada0b51](https://github.com/omacom/omarchy/commit/ada0b511973167bb0902496ced96627dd2bdd5fa) Count Codex sessions compressed to .jsonl.zst in the Agents panel (#16385)
- [8422598](https://github.com/omacom/omarchy/commit/8422598e1aac78d4bf50bcfcdf33c4ec0d63cdd1) Let the Lua assertions in shell tests fail (#7460)
- [620fd0c](https://github.com/omacom/omarchy/commit/620fd0c2c09fa663b757b4f86f2805afca4094f4) Restore the gvfs FUSE gateway after resume (#14496)
- [ec7d472](https://github.com/omacom/omarchy/commit/ec7d472e3c6f0391e489dbd82ec002803f8a5164) Document quiet Limine menu in dual-boot guide (#16369)
- [8337e23](https://github.com/omacom/omarchy/commit/8337e23e79c888b8ef32fe3473c2214e1880326d) docs(manual): recommend Rufus for Windows ISO writes (#16383)
- [7a0e3ea](https://github.com/omacom/omarchy/commit/7a0e3ea227302301e68fa8cc1c1968115a8bbf83) Say what the security manual's defaults actually are (#16155)
- [6a3815b](https://github.com/omacom/omarchy/commit/6a3815bfdd6a675b659241e69bcf1076e3628918) docs(agents): fix stale claims in task guides (#13723)
- [cdca799](https://github.com/omacom/omarchy/commit/cdca7991f70cf34943907bdd5091f6937eb02758) Fix additional assorted typos in navigation (#8995)
- [e05751d](https://github.com/omacom/omarchy/commit/e05751dbda8feaa550c93efbf0bbe579ba578172) Update translations (#17200)
- [d367a56](https://github.com/omacom/omarchy/commit/d367a568d97ff4579f85d7e33425c97cfae717b4) Update translations (#17201)
- [66266a3](https://github.com/omacom/omarchy/commit/66266a36c4a621037715fcde45496f0ef1196752) Reconcile workspaces after a removed monitor's teardown, not inside it (#16750)
- [01e0e96](https://github.com/omacom/omarchy/commit/01e0e96757bc82b7b4f88f3b5816cf017741b072) Align tray icons with bar widget icons (#16089)
- [4866668](https://github.com/omacom/omarchy/commit/486666840441772e2702063b5afb09c592962fee) Build user mise shims without network lookups (#16174)
- [c125859](https://github.com/omacom/omarchy/commit/c125859b910ac4f015a35a4230fde3b3022e9c27) Keep mise's GOROOT out of AUR package builds (#16388)
- [8e74d36](https://github.com/omacom/omarchy/commit/8e74d366802a307eb20fcdff95138163de5f7d58) Restore X11 root cursor on desktop reveal to prevent transparent cursor over XWayland apps (#14561) (#14580)
- [ae680f1](https://github.com/omacom/omarchy/commit/ae680f1e2bb6ac031c263df3d51ab1739902be31) Carry omarchy-bar put past a timing-out shell (#13468)
- [0f2085b](https://github.com/omacom/omarchy/commit/0f2085bfa61a4d9459189f08a9d4c61e23b65a67) Start sshd and open its port only once a key is authorized (#14667)
- [3e42525](https://github.com/omacom/omarchy/commit/3e4252561a8aaaf3d00845ad0569335a83dee8a8) Preserve GUM environment records during factory-reset elevation (#13316)
- [9e0b5e2](https://github.com/omacom/omarchy/commit/9e0b5e2f275964db85310bf9ab6fadb6a299839c) Add only the chosen locale instead of rebuilding them all (#16414)
- [1fc84e9](https://github.com/omacom/omarchy/commit/1fc84e98e4463656044398cd9a9dc0aca49ca66a) Add Extend | Mirror to the monitor panel's layout (#17226)
- [5df8f9e](https://github.com/omacom/omarchy/commit/5df8f9e4ca1aef25bc6a586ee5aeb7b949b38a6e) Update translations (#17227)
- [631dacd](https://github.com/omacom/omarchy/commit/631dacd7a7c7c9a7b1beffba85025a1aec221c63) Set up the ASUS Zenbook A16's firmware, disk unlock and sleep (#17083)
- [796e169](https://github.com/omacom/omarchy/commit/796e169ab4deb64016ae73069c7d558b6007d710) Stop the bar blinking after a monitor move, and polish the display panel (#17229)
- [32e7349](https://github.com/omacom/omarchy/commit/32e73492b33e9b1648e73882ff9f366ebed280a0) Update translations (#17231)
- [7eedd17](https://github.com/omacom/omarchy/commit/7eedd1736d63cd7882c6479b19e1ff31f4b77c21) Hide the display panel's layout for a lone display (#17232)
- [5fa15f2](https://github.com/omacom/omarchy/commit/5fa15f2154c797b0c226abaabbfef5bee24e3601) Ask with gum before rebooting after a channel switch (#17251)
- [4761d7b](https://github.com/omacom/omarchy/commit/4761d7b26f8c89cb201cdccf705e6b10fb17aa8e) Keep UPower's battery rate when sysfs has no live reading (#17265)
- [5a4f136](https://github.com/omacom/omarchy/commit/5a4f13664c834c65d588fc9d062688ce8e8a10bf) Cycle workspace layout with the display key (#17262)
- [bbfdfdd](https://github.com/omacom/omarchy/commit/bbfdfddb2065028a583d2815ddc6d3d47b00ae38) Keep GB10 CPU cores out of deep idle states (#17264)
- [90c29ec](https://github.com/omacom/omarchy/commit/90c29ec42193fa335ad30b23cdca77a07bf07115) Gather keyboard settings under Setup > Keyboard (#17270)
- [0bb944c](https://github.com/omacom/omarchy/commit/0bb944c5b9dc7371eabf712d314d3a8e0baf0bb1) Start keyboards on the media keys and add omarchy keyboard toprow (#17258)
- [d7e39bf](https://github.com/omacom/omarchy/commit/d7e39bf2451df5efe116db0b2bdb9dda3bf98717) Update translations (#17275)
- [36566f5](https://github.com/omacom/omarchy/commit/36566f5170934e5893309e096c22c4e24c47e45c) Update translations (#17276)
- [1843592](https://github.com/omacom/omarchy/commit/1843592f21166dd3abd689e2ae2a9f155a54039c) Keep the lock usable after an NVIDIA suspend's VT switch (#17277)
- [901af70](https://github.com/omacom/omarchy/commit/901af7018dc933b69562fa47bce0c6a74e98928e) Release a stuck trackpad button from Update > Hardware > Trackpad (#17280)
- [48fcf5f](https://github.com/omacom/omarchy/commit/48fcf5fe3a982338ef87477f2848e1fd825a8484) Schedule clock ticks from epoch time so the DST fold cannot flood the log (#16684)
- [3e7f8ed](https://github.com/omacom/omarchy/commit/3e7f8ed8a00000b5e31488bc9204340a66a433fe) Reset only the touchpad in omarchy-restart-trackpad (#17284)
- [f2b8378](https://github.com/omacom/omarchy/commit/f2b83784fa7e5b9db4914467b30f77b798e93894) Install herdr's agent integrations when an agent is first used (#17281)
- [a1a163e](https://github.com/omacom/omarchy/commit/a1a163eb65d4547e400f0ed38bfd82cc694f46f0) Run local models for agents from a curated recipe catalog (#17267)
- [18f3208](https://github.com/omacom/omarchy/commit/18f32088554ff9249105deb6cad60168fa911ec1) Configure Superwhisper in the background on first run (#17286)
- [e583e81](https://github.com/omacom/omarchy/commit/e583e81c7b01440acdfbf0258293e271e55889e1) Update translations (#17289)
- [73ae9cd](https://github.com/omacom/omarchy/commit/73ae9cd3e62ae43f58fe7a985c4bb9468a9e42f3) Open OpenCode 2 with the Omarchy theme (#17293)
- [63f60f4](https://github.com/omacom/omarchy/commit/63f60f4fcc4786d97e5c0384be640bcdef46f9a1) Highlight the whole tray while a dragged widget would drop into it (#17291)
- [e2c7007](https://github.com/omacom/omarchy/commit/e2c7007c105d3e9e5f1706bb8e364bd794f3e995) Open local models in OpenCode 2 on a private server with the model set by config (#17296)
- [175e63b](https://github.com/omacom/omarchy/commit/175e63b62dc3201866722e45ee9a60714cde16fa) Sync Slack's native theme with Omarchy (#17113)
- [c2818bb](https://github.com/omacom/omarchy/commit/c2818bb36b0a5abf95c74b869565f8f007b45fa1) Refresh omarchy-keyring with the Arch keyrings before every update (#17311)
- [81be644](https://github.com/omacom/omarchy/commit/81be6444ebcfef7b86e24279d003ebbe3ba2d787) Install NVIDIA's container toolkit when setting up a local model on an NVIDIA machine (#17330)
- [cf659d6](https://github.com/omacom/omarchy/commit/cf659d60713fd1318dfcb02f40b121773ff0bfbc) Update translations (#17332)
- [93b6617](https://github.com/omacom/omarchy/commit/93b6617267d74fd16952b09313bb8a4740e3d1c2) Name the Gufo Flash Next recipe in the local models guide (#17335)
- [079238e](https://github.com/omacom/omarchy/commit/079238eeeb1634a8e9f67e9142d2c2d049dd429d) Update translations (#17336)
- [6b1d839](https://github.com/omacom/omarchy/commit/6b1d839ba6eec92b66c135db37af4e3cdbab7923) Launch a local model in pi or OpenCode without a default agent (#17337)
- [a69b19f](https://github.com/omacom/omarchy/commit/a69b19f64efa78143155f2f46c85e7e05a09e05f) Show NVIDIA's mark on local NVIDIA models in the agents panel (#17338)
- [4907fcd](https://github.com/omacom/omarchy/commit/4907fcdf74eb5d3de6b33a02a9e3c972624f5881) Add Herdr desktop app theme integration (#17118)
- [48956c8](https://github.com/omacom/omarchy/commit/48956c83b41bbf4889bda56084ee81313e868cf9) Fix the shell tests that fail on a desktop run (#17388)
- [6d6ea47](https://github.com/omacom/omarchy/commit/6d6ea479500ea7714bb0f98e6ef3ebfc9c5943ab) Add the Herdr desktop app to Install > AI (#17132)
- [8d07724](https://github.com/omacom/omarchy/commit/8d07724582326e2604db60fd772395b3e5c94777) Update translations (#17393)
- [6f0e6fb](https://github.com/omacom/omarchy/commit/6f0e6fb840f100a514b9050d5e8132044459a33f) Let WirePlumber find the cameras at login (#16856)
- [09fa23e](https://github.com/omacom/omarchy/commit/09fa23e8291c7210c117867f5fd9c9fca51c5f09) Document how hotkeys are laid out (#17408)
- [3875b9d](https://github.com/omacom/omarchy/commit/3875b9db31cc6cf9cd2293a30b5cdab61c414505) Finish Superwhisper setup for installs that came up with it unconfigured (#17407)
- [ae64a4b](https://github.com/omacom/omarchy/commit/ae64a4be796239a86f40de4b3cc5bd7f43866296) Update translations (#17410)
- [8c76648](https://github.com/omacom/omarchy/commit/8c76648872bf21882f58fb570bd0e983b2b0b997) Add Amp Desktop to Install > AI and Remove > AI (#17446)
- [5c0d91a](https://github.com/omacom/omarchy/commit/5c0d91a18549374af9fb09a102bb4f85291c9748) Reload Hyprland resiliently from outside the session (#17420)
- [b793256](https://github.com/omacom/omarchy/commit/b7932568e8d17e9dc9f84179b7b3f3adcce178dc) Update translations (#17447)
- [8d2012b](https://github.com/omacom/omarchy/commit/8d2012b04855d67228928abe0ea1398be89e1c47) Seed the Quake console with the agent picker, or the local model when one is running (#17457)
- [857afe1](https://github.com/omacom/omarchy/commit/857afe1ef7119518aeab4a2f74395edf53c930f6) Give reload-checking tests a Hyprland signature (#17455)
- [97316b0](https://github.com/omacom/omarchy/commit/97316b0bb66f04c215ce5a5c3a9e3b530153508b) Use prebuilt NVIDIA modules on linux-omarchy (#17409)
- [5eb922f](https://github.com/omacom/omarchy/commit/5eb922f137422ff32a90869a9ba47525a428792d) Wait for theme retints in the intro switch test (#17463)
- [265ce5d](https://github.com/omacom/omarchy/commit/265ce5d41cd3571519012bbda1fe03ffe2f5af4d) Add the 2017 iMac 5K to Mac support (#11464)
- [8153e4c](https://github.com/omacom/omarchy/commit/8153e4ca4a2d053ff5b70b764e90590f29cc3960) Update translations (#17493)
- [5f2fb78](https://github.com/omacom/omarchy/commit/5f2fb785562b2b6cd9a58787a3bfd673568fe9dd) Ask PRs that change the UI for screenshots or a recording (#17494)
- [83366c6](https://github.com/omacom/omarchy/commit/83366c69890978e6db40086a2296a92158545160) Offer stable on Apple Silicon (#17499)
- [24e5617](https://github.com/omacom/omarchy/commit/24e561747f1da03ea073b4055de68d9ce315caa4) Match Battle.net's DPI to the monitor scale on launch (#17418)
- [6ba05d7](https://github.com/omacom/omarchy/commit/6ba05d7732f365c7655202c9ee0eae0afcfdc340) Read the VT's font, keep the icon whole and its tip grey, and draw progress frames without forking (#17036)
- [cc99764](https://github.com/omacom/omarchy/commit/cc99764098af5a2ed5cf2245d9059f4d559650f5) Bind Ctrl and the display brightness keys to the keyboard backlight (#16650)
- [cfd8106](https://github.com/omacom/omarchy/commit/cfd8106faaac4d3da6071d958ff0eff6cf75c161) Turn off animations when Hyprland renders on the CPU (#17035)
- [9b525a9](https://github.com/omacom/omarchy/commit/9b525a93513978a535289210621765d87bfe94a7) Update translations (#17533)
- [41e97aa](https://github.com/omacom/omarchy/commit/41e97aa30a92a9be3808c5c30e91be19b1fdd582) Keep the agents widget from landing on the bar twice (#17522)
- [9d5e062](https://github.com/omacom/omarchy/commit/9d5e0626feb10da607d2e1c82fc808313d18a359) Restart a stale shell before running migrations (#17524)
- [dd3a3eb](https://github.com/omacom/omarchy/commit/dd3a3eb0a6634e80ce37249658345b28d2016bbd) Keep a Hyprland the update replaced from reloading the new config (#17553)
- [91302f6](https://github.com/omacom/omarchy/commit/91302f6c879b9b6a7258f9a927dcbe1b4059a74b) Show the emoji picker's no-match message (#17558)
- [1d88086](https://github.com/omacom/omarchy/commit/1d880868b757be1c90f3b58abee0174aa96cec90) Show the clipboard panel's empty and no-match messages (#17562)
- [0966f35](https://github.com/omacom/omarchy/commit/0966f357ebfd73b3066c4ef1fd42c5162cc206c9) Add Notion to Install > Service and sort the list (#17557)
- [389f1ed](https://github.com/omacom/omarchy/commit/389f1ede9ad05ae96da701331ba22708aa66f236) Hide the clipboard preview divider when nothing is listed (#17564)
- [c23aa52](https://github.com/omacom/omarchy/commit/c23aa52331aee13b242f7f60082ffc924d35abb3) Update translations (#17572)
- [84b3f28](https://github.com/omacom/omarchy/commit/84b3f2872b5023c13967543ed4a98b08fcac5b21) Draw the Notion menu entry with the Nerd Font's Notion glyph (#17574)
- [50bb5db](https://github.com/omacom/omarchy/commit/50bb5db319933569c9d5c3abc3a4485af943004b) Ship the Cam Link 4K packages in the ISO's offline mirror (#17597)
- [181f51d](https://github.com/omacom/omarchy/commit/181f51dd14fbd242001c1204e2cf75777e48f4f5) Add HP ZBook Ultra G3a speaker and microphone UCM profile (#17618)
- [88aa546](https://github.com/omacom/omarchy/commit/88aa546e46765421d7d3d5f0d35853cc1003f94f) Show the F1 installer's finish screen in the getting started guide (#17627)
- [19d13be](https://github.com/omacom/omarchy/commit/19d13be8863740b60d85e4ffc581e4db45cbcfc8) Invite agent and fingerprint setup once online, not after the first update (#17628)
- [fd3475a](https://github.com/omacom/omarchy/commit/fd3475a6493d24766dde9c9b0c2a3ea798bb49f8) Disable the HP ZBook Ultra G3a's phantom USB port so fingerprint enrollment works (#17634)
- [6194f46](https://github.com/omacom/omarchy/commit/6194f4606c585da8b839b87df9120b7d796afedf) Map sRGB into each display's gamut on Apple Silicon (#17640)
- [ad4977b](https://github.com/omacom/omarchy/commit/ad4977b6a6105e88ed94ab59948d3c65f50e5289) Fix Hex dictation staying on after push-to-talk release (#17827)
- [d5b32d2](https://github.com/omacom/omarchy/commit/d5b32d24d37af8f0376a67d98531bb2da629824b) Fix the background intro lifecycle test that fails every CI run (#17840)
- [a40f1f7](https://github.com/omacom/omarchy/commit/a40f1f75bf1557d6824a142b9b422ec35c6fb353) Install the OEM firmware package for each Snapdragon machine (#17389)
- [9d88344](https://github.com/omacom/omarchy/commit/9d883445bd99f78e273f45c5889245cd102d9d79) Move Superwhisper's shortcut without a compositor check in the migration (#17925)
- [f933bbd](https://github.com/omacom/omarchy/commit/f933bbd24c22be0538cbccd1acf4ca7e8949ceeb) Install Osaka Jade from its own repo for anyone still on it (#17746)
- [e284b83](https://github.com/omacom/omarchy/commit/e284b835c6fd967365f8f33c08581d8fe2326026) Show the disk unlock prompt on Snapdragon X2 machines (#17662)
- [1da8539](https://github.com/omacom/omarchy/commit/1da8539d98a782f36f82b4afe5746f75e63a9240) Refresh the Snapdragon device tree list before every boot image build (#17934)
- [14abc07](https://github.com/omacom/omarchy/commit/14abc0762ce38547d1912061969df58962f6f10a) Run the runtime smoke test alone, and keep the CI VM's kernel log (#17935)
- [5cf852c](https://github.com/omacom/omarchy/commit/5cf852c2bf1c6f65e03006819590e48a87f160ca) Remove NVIDIA app setup from the installer (#16311)

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
