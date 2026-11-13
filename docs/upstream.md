# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

## 2026-11-13

1080 new commit(s) on omacom/omarchy@quattro, [454b67d...3f974d0](https://github.com/omacom/omarchy/compare/454b67d95fd63c269c5315836a098038a0c61716...quattro).

Only the first 250 commits and 300 files fit in one comparison: follow the link for the rest.

**New Omarchy release: v4.5.0** (Winarchy tracked v4.0.4). Themes and backgrounds follow it; check its notes: https://github.com/omacom/omarchy/releases/tag/v4.5.0

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| Other | `.github/pull_request_template.md`<br>`.github/workflows/i18n-check.yml`<br>`.github/workflows/i18n-sync.yml`<br>`.github/workflows/test.yml`<br>`.github/workflows/visual-evidence.yml`<br>`.greptile/files.json`<br>and 26 more | - |
| Conventions | `AGENTS.md` | `AGENTS.md`<br>`docs/` |
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent`<br>`bin/omarchy-agent-instructions`<br>`bin/omarchy-agent-integrate-herdr`<br>`bin/omarchy-agent-local`<br>`bin/omarchy-agent-make`<br>`bin/omarchy-default-agent` | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-copy`<br>`bin/omarchy-agent-account-exec`<br>`bin/omarchy-agent-account-home`<br>`bin/omarchy-agent-account-rename`<br>`bin/omarchy-agent-account-state`<br>and 2 more | `lib/accounts.ps1` |
| Agent usage | `bin/omarchy-agent-usage-agy`<br>`bin/omarchy-agent-usage-claude`<br>`bin/omarchy-agent-usage-codex`<br>`bin/omarchy-agent-usage-copilot`<br>`bin/omarchy-agent-usage-cursor`<br>`bin/omarchy-agent-usage-deepseek`<br>and 18 more | `lib/agents/` |
| Other commands | `bin/omarchy-apply-hardware`<br>`bin/omarchy-apply-lock`<br>`bin/omarchy-apply-n1x-gpu-memory`<br>`bin/omarchy-apply-pacman`<br>`bin/omarchy-audio-input-mute`<br>`bin/omarchy-audio-input-set-default`<br>and 149 more | `lib/` |
| Launchers | `bin/omarchy-cmd-browser-handoff`<br>`bin/omarchy-cmd-default-browser`<br>`bin/omarchy-cmd-editor-mimetypes`<br>`bin/omarchy-cmd-terminal-cwd`<br>`bin/omarchy-launch-about`<br>`bin/omarchy-launch-battlenet`<br>and 14 more | `ahk/launchers.ahk`<br>`ahk/menu.ahk` |
| Install / Remove | `bin/omarchy-install-ai-herdr`<br>`bin/omarchy-install-ai-openclaw`<br>`bin/omarchy-install-ai-t3-code`<br>`bin/omarchy-install-browser`<br>`bin/omarchy-install-camera`<br>`bin/omarchy-install-chromium-google-account`<br>and 38 more | `lib/catalog.ps1` |
| Menu | `bin/omarchy-menu`<br>`bin/omarchy-menu-herdr-keybindings`<br>`bin/omarchy-menu-images`<br>`bin/omarchy-menu-keybindings`<br>`bin/omarchy-menu-plugin`<br>`bin/omarchy-menu-select`<br>and 3 more | `zebar/omarchy/menu.json`<br>`zebar/omarchy/menu.js`<br>`ahk/menu.ahk` |

Commits:

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
- [e6d5a17](https://github.com/omacom/omarchy/commit/e6d5a173006414424f0067abfa29030ee8ac11fc) Bring up the Anduril BlueChip's speakers and microphones with its own UCM profile (#18002)
- [9527726](https://github.com/omacom/omarchy/commit/95277264eccc87cf523174c8a01f785e1d70ff95) Quiet the efivarfs mount error Snapdragon laptops print at boot (#18046)
- [da17bb1](https://github.com/omacom/omarchy/commit/da17bb1e04f2852340a544c73dc3c75de61a1fc6) Stop the watchdog timeout error Snapdragon laptops print at shutdown (#18050)
- [9044b7e](https://github.com/omacom/omarchy/commit/9044b7e8ea55ed6f443c14cbf93a2504aa248825) Skip the Snapdragon efivarfs migration once the hook is in place (#18053)
- [8acbf77](https://github.com/omacom/omarchy/commit/8acbf77167ec8a5540c30f214e557c54007a2ce1) Give Herdr Desktop the same keybindings as the terminal herdr (#18073)
- [e551aff](https://github.com/omacom/omarchy/commit/e551aff0df68ccbf262ea53a2548b00d335b5f89) Update translations (#18077)
- [b5883f7](https://github.com/omacom/omarchy/commit/b5883f774d0e7c06dc9014da382d930d0000c29b) Set up the ASUS Zenbook 14 UX3480QA's disk unlock, audio and sleep (#18079)
- [c802f51](https://github.com/omacom/omarchy/commit/c802f51f7879c0e257b5c7278c2f34c5a0ec3119) Split the About CPU line in two when it overruns the box (#18074)
- [9305a18](https://github.com/omacom/omarchy/commit/9305a184f69ccdce0352a3bba774b4743cd33d7a) Show Wi-Fi bars that agree across NetworkManager's two strength formulas (#18091)
- [598e4eb](https://github.com/omacom/omarchy/commit/598e4ebc510b1cf69eb2b2188f938664f1feb1ec) Keep bell configuration compatible with the running compositor (#18047)
- [d9cc361](https://github.com/omacom/omarchy/commit/d9cc361cddf5d75dcb880de3c7fb8b5542ae6e39) Read translation files synchronously so no change is lost (#18101)
- [7bec2a5](https://github.com/omacom/omarchy/commit/7bec2a5894d53a0018318c867a196367e472b029) Refetch weather and update status when the network comes online (#18083)
- [3fe2aab](https://github.com/omacom/omarchy/commit/3fe2aabda5509105476a18157300d1a4216b8f1d) Install the renamed Arm hardware packages by their new names (#18069)
- [4419fd7](https://github.com/omacom/omarchy/commit/4419fd7dc2da8fe5c4c963f185c7effa373c0786) Embed the Mahua device trees in a Snapdragon laptop's UKI (#17780)
- [fde73ee](https://github.com/omacom/omarchy/commit/fde73ee1dadfcecdeb7ed7db0c41f3eba6472f1b) Compress the initramfs with zstd on ARM too (#17430)
- [545a953](https://github.com/omacom/omarchy/commit/545a9533bf1fc30981cff479fa7a52f512b42933) Turn off suspend on the ASUS Zenbook A16 until it sleeps reliably (#18178)
- [f513f2a](https://github.com/omacom/omarchy/commit/f513f2adfe6a3ae3b95b13424f2cc7cba1f72523) Update translations (#18181)
- [a2a2e19](https://github.com/omacom/omarchy/commit/a2a2e1964c76c613f8b40f914a51a932b817bb3d) Make every window glassy (#18186)
- [f70c317](https://github.com/omacom/omarchy/commit/f70c317fc6b2fb07801fa9b782cc6e710fb9183e) Update translations (#18190)
- [6c0e3d2](https://github.com/omacom/omarchy/commit/6c0e3d2acba62aef721f867c315b024c6fa71862) Replace Evince with Papers as the document viewer (#18200)
- [60bf28e](https://github.com/omacom/omarchy/commit/60bf28eebb4764b6a760a239e8875ddca707b238) Add new plugins without reloading the ones already running (#18198)
- [f24713c](https://github.com/omacom/omarchy/commit/f24713c2352cb89b8d4e3bdfc37035d58286629d) Keep the firmware's USB4 display link on AMD machines (#18211)
- [dace4c1](https://github.com/omacom/omarchy/commit/dace4c1a9514e062d1956802825728f7078612ff) Revert "Keep the firmware's USB4 display link on AMD machines (#18211)" (#18213)
- [8e33e72](https://github.com/omacom/omarchy/commit/8e33e7233c01bf3b563b344bffc790a5d2dd98ea) Show the disk unlock prompt on the Mahua laptops (#18174)
- [cbd0029](https://github.com/omacom/omarchy/commit/cbd0029fddcfcae0b73cf1c01a1c6031eae98f99) Index the largest PNG of an icon, not whichever find returns first (#16382)
- [56a103f](https://github.com/omacom/omarchy/commit/56a103fefff82807a97edaa42ddc88343631e9ad) Install the bundled extensions in Google Chrome from signed CRXs
- [2d6da28](https://github.com/omacom/omarchy/commit/2d6da28d7cbe6c0c486de93a47ad9909bda59b4e) Open Chrome straight to a browser window
- [3776009](https://github.com/omacom/omarchy/commit/37760090a36b4d2c8e1c66f310cb18d1907edf71) Give Chrome the 1Password extension and Snapdragon flags Chromium gets
- [b10da7e](https://github.com/omacom/omarchy/commit/b10da7e59cef43dbad08fc8b08ca86f6f4d9b531) Make Google Chrome the default browser for new installs
- [0951985](https://github.com/omacom/omarchy/commit/0951985c4f1ae68bfe3502c20ce3d2b308e59573) Offer the recommended local model on the agents panel's first page (#18239)
- [b99593e](https://github.com/omacom/omarchy/commit/b99593ed3c5d104210394669efc88a684f76ddbf) Update translations (#18241)
- [88eca66](https://github.com/omacom/omarchy/commit/88eca66cbd1724de3c1d3d1a3173ed91c1fc97f9) Show and control the tailnet's shared models in the agents panel
- [29f3bb6](https://github.com/omacom/omarchy/commit/29f3bb655f23763b7748feba8649870f834c3543) Add Battle.net's DPI to fresh prefixes on launch (#18286)
- [4aa003c](https://github.com/omacom/omarchy/commit/4aa003ca2a68de03a89033e9742cfb2489a5dbf2) Show resolution, refresh rate, and pixel density in the monitor panel (#18292)
- [252e0a3](https://github.com/omacom/omarchy/commit/252e0a3e28fd2c96cb1914ff6439032cef37431d) Show agent spend over the last 30 days, with nothing to configure (#17560)
- [18ac93c](https://github.com/omacom/omarchy/commit/18ac93ce115fd919284ce977570be1eea7212527) Update translations (#18297)
- [f97d3e7](https://github.com/omacom/omarchy/commit/f97d3e7dc80e1f3ff39b142bbd330d537fe7c674) Stop hiding the pointer at startup (#17999)
- [ee71a45](https://github.com/omacom/omarchy/commit/ee71a457dcef3d0753e5f211f2c4f0f86c6382e4) Start the autostarted herdr server in its own session
- [c145df9](https://github.com/omacom/omarchy/commit/c145df9086f605cd31f93c3745fadae26e592145) Share with the Tailscale mark, only where Tailscale can serve
- [511fc00](https://github.com/omacom/omarchy/commit/511fc0075bec534b844905c7547e084dcfd09e7c) Embed only the machine's own device tree in a Snapdragon UKI (#17406)
- [61887f2](https://github.com/omacom/omarchy/commit/61887f238a304c7a26b317b0a9b88f2ad7da3981) Keep hibernation available while Bitwarden runs on encrypted installs (#16212)
- [8018246](https://github.com/omacom/omarchy/commit/80182467af7d8f35d60d370711515c9e2e428576) Say Share and Pair in words instead of icons
- [b7c98c8](https://github.com/omacom/omarchy/commit/b7c98c8d2d4ad694c9b316eaeeb4d23ad0a09d1c) Show a network model's stats instead of its host's memory
- [8be650f](https://github.com/omacom/omarchy/commit/8be650f2771adf233b544bc298439862b6cbde4b) Install ath12k-board-fallback on machines with a Qualcomm Wi-Fi card (#17580)
- [c40eca9](https://github.com/omacom/omarchy/commit/c40eca98bdc3f99b2b19879875cffb2db079f02d) Keep the device tree list beside a Snapdragon machine's own tree (#18309)
- [13f4592](https://github.com/omacom/omarchy/commit/13f4592d234c5faa8fee0a268faaf350ba4b6c66) Take linux-omarchy's device trees before another linux-omarchy kernel's (#18317)
- [df3d01c](https://github.com/omacom/omarchy/commit/df3d01ce8240ebd6795621987dbb602420980dd0) Use qtengine for qt theming (#18325)
- [daf20d1](https://github.com/omacom/omarchy/commit/daf20d189904c7ad3f6f9c32e969c0e92d1cae61) Offer to set up a DGX Spark cabled to this one in the agents panel
- [cfce7ad](https://github.com/omacom/omarchy/commit/cfce7ad36b020b3e37318aec3eeb646783bc1a41) Link a local model's error to its logs
- [255acd9](https://github.com/omacom/omarchy/commit/255acd9b9f752478365a1207f499e5d558bf7f75) Collapse identical notifications arriving together into one card again (#18349)
- [160d66f](https://github.com/omacom/omarchy/commit/160d66f432b4ecc0828fc28b8bc27769f3586f83) Show Dropbox sync progress and transfer speed
- [62ffc6b](https://github.com/omacom/omarchy/commit/62ffc6b603591efc61267db17cb3dc330b901c7a) Open the agents panel's starters on a running local model (#18357)
- [b8dd517](https://github.com/omacom/omarchy/commit/b8dd517ae63f956e143da2f296c30950b5568142) Show the recorded microphone's level on the screen recording indicator
- [b8aa3d1](https://github.com/omacom/omarchy/commit/b8aa3d13b3d30b7432121bc0d8c5ed0058a538f2) Correct Dropbox transfer details and refresh handling
- [50f57c7](https://github.com/omacom/omarchy/commit/50f57c7fc50c934e37c999ba680e4f69547501a5) Exclude Dropbox staging cache from recent files and usage
- [f41c4ab](https://github.com/omacom/omarchy/commit/f41c4ab9f1854612beeb23772a1ea9e8f19b0a00) Exclude Dropbox internal metadata from file scans
- [a3f1d1e](https://github.com/omacom/omarchy/commit/a3f1d1e0ad73a04999aa64624f67d9ec9e98e04c) Update translations (#18358)
- [054d75e](https://github.com/omacom/omarchy/commit/054d75e17723dc98c951337df7bf5676190da2c8) Merge pull request #18356 from omacom/dropbox-sync-progress
- [a1d29b2](https://github.com/omacom/omarchy/commit/a1d29b21ce59dbb13ad20431cbf9dc657d70ec5b) Update translations (#18360)
- [260a7f7](https://github.com/omacom/omarchy/commit/260a7f758cc176c761eb238c6ed860d2144268b1) Merge pull request #18350 from omacom/model-logs-link
- [ec62d37](https://github.com/omacom/omarchy/commit/ec62d379e1a0427bbb0304821f72087f63c68379) Update translations (#18361)
- [25010f4](https://github.com/omacom/omarchy/commit/25010f4f6a958504be789657cf92ba79f075bfdb) Move agent setup into Setup > Agent with Harness and AGENTS.md
- [62ad829](https://github.com/omacom/omarchy/commit/62ad82919f731ed38cdefaf6d823671123085f06) Point default-agent and first-run tests at Setup > Agent > Harness
- [d58cd17](https://github.com/omacom/omarchy/commit/d58cd17e9dd4d1bf48bcd0a1684be5098d237721) Move Keyboard, Input, Language and Network below Config in Setup
- [7c29416](https://github.com/omacom/omarchy/commit/7c294161e64e3240fb6e28da4ba1f067984fa7bf) Promote Agent to the root menu with Make something
- [2e26ef0](https://github.com/omacom/omarchy/commit/2e26ef0baf6b41cc4c7410c62341146875990521) Move Learn above About in the root menu
- [531cb3f](https://github.com/omacom/omarchy/commit/531cb3fc1b34ae7ce96823a7c971b12e2b30d536) Rename Agent > AGENTS.md to Instructions and explain an empty file
- [9500743](https://github.com/omacom/omarchy/commit/9500743f7fdddfcfc0b79e852e538cdd5cc6b4b6) Keep the cabled Spark offer at the top of the agents panel
- [61b38d3](https://github.com/omacom/omarchy/commit/61b38d364184580c5169ced9c2258366e30556ba) Show the sender's glyph, not the Omarchy logo, on Omarchy notifications
- [a9d8a0c](https://github.com/omacom/omarchy/commit/a9d8a0c28a003b669cba67aedced456a213bdd3c) Drop the anonymous sender's name from the icon source too
- [65d1e54](https://github.com/omacom/omarchy/commit/65d1e5450beb89be72d253cd7c0ce5a23e539af8) Merge pull request #18364 from omacom/fix-notification-glyph-logo
- [fef9fca](https://github.com/omacom/omarchy/commit/fef9fca2a2b9b93dd8f2be87b9bf1c786d7b79c3) Allow sharing 1Password while Gliff is connected
- [e42e09f](https://github.com/omacom/omarchy/commit/e42e09f5d9370ee18b6ed80b902c245808b1372c) Support the ASUS ProArt PZ13's speakers and microphones (#17970)
- [54abf72](https://github.com/omacom/omarchy/commit/54abf7237011bca800a8b5b9994f45168f35f060) Merge pull request #18302 from jasasonc/fix-herdr-autostart-setsid
- [500f1df](https://github.com/omacom/omarchy/commit/500f1df643273a2e8e95c0fb985e95abdd65d4f8) Override screen sharing protection for all windows during Gliff
- [6adbdcc](https://github.com/omacom/omarchy/commit/6adbdcc83031a79455276cc8140ab70223ca2516) Preserve capture override across remote service replacement
- [71849e3](https://github.com/omacom/omarchy/commit/71849e3ad110cb1b80a976cfc50c62c20bac54e0) Merge pull request #18338 from omacom/spark-link-offer
- [2990d24](https://github.com/omacom/omarchy/commit/2990d24169b2569fd320aa1dff643798c5a5b36f) Pass a modifier to activateRequested in the captive portal fixture
- [e530f48](https://github.com/omacom/omarchy/commit/e530f4850be6cc9c443cf404ad24dd7ebe86f0cc) Update translations (#18376)
- [7dae860](https://github.com/omacom/omarchy/commit/7dae86043e909fe03683e31c173de61cc46c39f2) Show the disk unlock prompt on the ASUS Vivobook S 15 (#17352)
- [c18b00c](https://github.com/omacom/omarchy/commit/c18b00c565d234093f665dd99d7f89891a8478d0) Merge pull request #18375 from omacom/fix-portal-fixture-activate
- [e96a634](https://github.com/omacom/omarchy/commit/e96a6346d31999990e509574492b6014d8572a39) Wait for replacement capture ownership in reload test
- [e56f833](https://github.com/omacom/omarchy/commit/e56f833af7dccc77894b6a0934f4c4eeb559c6ae) Merge pull request #18370 from omacom/gliff-1password-screen-share
- [795dfb2](https://github.com/omacom/omarchy/commit/795dfb234a3d2bbfbe14cd531472c1dce9615443) Replace Nautilus with Files as the file manager
- [11be972](https://github.com/omacom/omarchy/commit/11be9726f0fae962938407fd4f880fa1aa706526) Drop Nautilus on existing machines
- [a7a2574](https://github.com/omacom/omarchy/commit/a7a257459d10bf9abdd14cdf2325408ccd018666) Stop shipping Moonlight to new installs
- [0349b5f](https://github.com/omacom/omarchy/commit/0349b5fb69343be55248778b8898de1c884b465a) Start new installs with Plain as the editor
- [9f72af2](https://github.com/omacom/omarchy/commit/9f72af245dd48490818a514b383669590836befa) Fall back to Vim for Plain without a display
- [b972601](https://github.com/omacom/omarchy/commit/b9726017e85fed5d97cbc27bfee0c8f8637db604) Fall back to vi for Plain without a display
- [6a4a255](https://github.com/omacom/omarchy/commit/6a4a25564fd346590e6398802b50307d161b0330) Offer Moonlight under Install > Gaming
- [46266f5](https://github.com/omacom/omarchy/commit/46266f5b76e7053020e3771fb13462e9c05dc00f) Follow review: respect older MIME choices, house rules
- [991e738](https://github.com/omacom/omarchy/commit/991e73851e3605ee99415adf69dbab55192c4cb3) Leave plans/remote.md to the Gliff rewrite
- [6ef9ba8](https://github.com/omacom/omarchy/commit/6ef9ba842e80d1e2e57cf2f2d6a4836db2b11dae) Rewrite the remote plan around Gliff
- [492ae12](https://github.com/omacom/omarchy/commit/492ae12651907677d657f6fc9f6a52ed932451b3) Remove the remote plan
- [b04b752](https://github.com/omacom/omarchy/commit/b04b7523cd4f1da58d17f578a9c7c7d3a48d6578) Merge pull request #18401 from omacom/remote-plan-gliff
- [9a05aa0](https://github.com/omacom/omarchy/commit/9a05aa05e018473d4bdd1cac7795a6202dd18033) Merge pull request #18397 from omacom/stop-shipping-moonlight
- [730b3ca](https://github.com/omacom/omarchy/commit/730b3cacefb2085113ad21bb3eca92b09567793e) Update translations (#18402)
- [831efec](https://github.com/omacom/omarchy/commit/831efec5d0f48cfb2abde0dc7768a8676be7629c) Merge pull request #18398 from omacom/plain-default-editor
- [d7d1287](https://github.com/omacom/omarchy/commit/d7d1287ab76a4193190b94745fa093b7f5d30442) Update translations (#18403)
- [f428bb4](https://github.com/omacom/omarchy/commit/f428bb4fe4d2e688fa05190b7d3c61430805b601) Merge pull request #18378 from omacom/folio-replaces-nautilus
- [e55417c](https://github.com/omacom/omarchy/commit/e55417c03119f08827985c04fd6a9611385c5fbe) Merge remote-tracking branch 'origin/quattro' into agent-menu
- [5b27f69](https://github.com/omacom/omarchy/commit/5b27f69f519b5ba1dd229b7e8dab83f3a9420e87) Keep linked instructions and share AGENTS.md with Grok accounts
- [badab50](https://github.com/omacom/omarchy/commit/badab50db75686562331b139c6351d4d3d3a4f57) Merge remote-tracking branch 'origin/quattro' into chrome-default
- [1fb8db1](https://github.com/omacom/omarchy/commit/1fb8db19632e4dcdc856e3c45b8be0b22cb3e4e7) Read the CRXs as files, which libarchive 3.8.10 cannot stream
- [351812c](https://github.com/omacom/omarchy/commit/351812c3e111b4351f258086408855bfde5de6be) Fall back to Chromium for web apps where Chrome isn't installed
- [6a6650e](https://github.com/omacom/omarchy/commit/6a6650e38e8fae4a7b84852b9b6c9bbe47e0262b) Admit the Chrome extension ids in existing native host registrations
- [70fe934](https://github.com/omacom/omarchy/commit/70fe9342fffa83c8feedee6d6b0408ecbfacea70) Test Grok account linking through account-state, not the migration
- [c3f685b](https://github.com/omacom/omarchy/commit/c3f685b7707c892fc152d974bd097b09d5936870) Seed Chrome's flags from /etc/skel, as Chromium's are
- [4058486](https://github.com/omacom/omarchy/commit/4058486ffcefe767cc05916e0964fca9cca780c2) Don't let a flags file that can't be written hold back the other browser
- [7a9a1e9](https://github.com/omacom/omarchy/commit/7a9a1e930921f8d18db98e189a6280e6b1c0cc32) Install xdg-user-dirs, which left with Nautilus (#18416)
- [74a67e9](https://github.com/omacom/omarchy/commit/74a67e9cbc1052674e1e2ae37eeefa358157079e) List Purwa device trees for the UKI (#18426)
- [ceb30ed](https://github.com/omacom/omarchy/commit/ceb30ed19ab1926713a7832dd4de5868c90d7b94) Add Surface Laptop 8 board setup (#16968)
- [4211c9f](https://github.com/omacom/omarchy/commit/4211c9ff84d1ed6a08f3e64c338fcc08cf559f33) Merge pull request #18363 from omacom/agent-menu
- [748fa3c](https://github.com/omacom/omarchy/commit/748fa3c0d0418d7a199818d94c1f87d495d7e804) Update translations (#18437)
- [e30e18c](https://github.com/omacom/omarchy/commit/e30e18c53ac8f3dbf028f797600f42400b3e2d81) Set up the Surface Laptop 8 on existing installs (#18435)
- [04852da](https://github.com/omacom/omarchy/commit/04852da30207df1671fac06d58189dc3a03f310f) Bind Super + Ctrl + X to the agents panel
- [499d43b](https://github.com/omacom/omarchy/commit/499d43b9881a4eeba84a3b9885b2311ca87e0589) Unbind the agents panel ahead of personal Super + Ctrl + X binds
- [52276e8](https://github.com/omacom/omarchy/commit/52276e881d140abcc26b80b691acbceaf92232d2) Unbind the default before every active personal Super + Ctrl + X bind
- [d207d32](https://github.com/omacom/omarchy/commit/d207d32ae974906fc9f61be24482870bcbb91e87) Merge quattro into tailnet-models
- [06989fd](https://github.com/omacom/omarchy/commit/06989fd57342fd051eb94e99dd7d3d9c8248b80d) Merge pull request #18296 from omacom/tailnet-models
- [c2abad9](https://github.com/omacom/omarchy/commit/c2abad9c7e3e1bb180ec93f0ad568ea2517d5109) Cover inline Super + Ctrl + X binds in the agents panel migration
- [3af221e](https://github.com/omacom/omarchy/commit/3af221e36108509c1dc6834e8e1c2b2e91c23b55) Update translations (#18445)
- [a5b65e3](https://github.com/omacom/omarchy/commit/a5b65e301518662dd912887b8c5105faa6ddb23b) Insert the agents panel unbind only as a statement of its own
- [dd3356e](https://github.com/omacom/omarchy/commit/dd3356e40e5fcc1e2328d335d8905d568f249f8e) default-editor: sync XDG MIME defaults so Nautilus respects the menu selection
- [1d51ffb](https://github.com/omacom/omarchy/commit/1d51ffb1414d3c4019096b0c68f7d8a6f456d486) Open text files in the default editor from every app, on existing installs too
- [7b8c0c7](https://github.com/omacom/omarchy/commit/7b8c0c75918fee64683c2f92b54ae827e015fe7c) Open one file per editor launch, keep choices from the older mimeapps.list, and keep the test out of the real config
- [81c1843](https://github.com/omacom/omarchy/commit/81c1843557a86a2377536bd90a0e30173a061240) Limit the agents panel migration to the legacy dictation toggle
- [e990f55](https://github.com/omacom/omarchy/commit/e990f552c4781b3f4e8f770aded55d9bf6fc9d43) Read mimeapps.list the way GLib does when moving text types to the editor
- [239d483](https://github.com/omacom/omarchy/commit/239d4835b9aa0b2c9d8ef89d7e43c2bc6d24880c) Merge pull request #18444 from omacom/worktree-agent-panel-hotkey
- [02d9536](https://github.com/omacom/omarchy/commit/02d9536820319c7404630deb4f1c9e1fbb0578d2) Update translations (#18449)
- [54b5286](https://github.com/omacom/omarchy/commit/54b5286a907971733201485b7bd53978e56c7a17) Keep the Chrome extension keys in 1Password
- [c9f4d4f](https://github.com/omacom/omarchy/commit/c9f4d4fcc93e92ae7b0cc378b50b1a7a9b5b75c4) Seed the 1Password extension for Chrome where Chromium has it
- [a37ca11](https://github.com/omacom/omarchy/commit/a37ca11dcf05b798959aaca100876c76355764cc) Set up the SSH server before sharing a model
- [b6b6002](https://github.com/omacom/omarchy/commit/b6b6002d28fdf81fc8644ee491b6365e15453111) Remove only Nautilus's own packages when replacing it, and bring back Papers and xdg-user-dirs
- [3a29924](https://github.com/omacom/omarchy/commit/3a29924f6b8670d85d154e6564f8a0e58652517a) Read CRLF mimeapps.list files and spaced section headers the way GLib does
- [8fcfa1d](https://github.com/omacom/omarchy/commit/8fcfa1d791b56eee0de4bc1f2cdd19dbbd96e538) Clear text types from the desktop's own mimeapps list when an editor is picked
- [01c7e2f](https://github.com/omacom/omarchy/commit/01c7e2f78cde768648d2bf4dd49610f0dbbe2f8e) Merge pull request #18452 from omacom/keep-defaults-on-drop
- [338cdde](https://github.com/omacom/omarchy/commit/338cdde37356a57e10af56143118f34e7bcc4ea2) Leave a desktop list that is mimeapps.list itself alone
- [0efdd8e](https://github.com/omacom/omarchy/commit/0efdd8e09b251dd0fad029ac2aa4d0777d91895e) Drop the Chromium Account setup now that Chrome signs in to Google
- [33e146b](https://github.com/omacom/omarchy/commit/33e146b20c945a00d4ba13fff408ec578287147b) Merge pull request #18454 from omacom/share-sets-up-sshd
- [fcd19dd](https://github.com/omacom/omarchy/commit/fcd19ddf673ff209fddf4e4a66dadb97276168f7) Show a model as shared only while it runs
- [2417112](https://github.com/omacom/omarchy/commit/2417112b333c6931b24db5ea402de20cab099f72) Offer Disconnect, not stop, on a paired machine's model
- [1edb3d2](https://github.com/omacom/omarchy/commit/1edb3d205fc79d6080d14db3912dfcde0ac3b26a) Land the keyboard on Launch past Pair, Disconnect and Share; say Disconnect is host-wide
- [c7b65ed](https://github.com/omacom/omarchy/commit/c7b65ed044311a1d851a179590a14bc17c68e75e) Route Plain's own text types through the editor handler, and read a repeated type by its last line
- [744e233](https://github.com/omacom/omarchy/commit/744e233cb6d53a8675e153e5ce66ffd369a776bc) Open a terminal over Files in the folder it shows
- [2c29c29](https://github.com/omacom/omarchy/commit/2c29c290d596fe7f68e0ce36aa0dbd8d70394f60) Merge pull request #18457 from omacom/share-only-while-running
- [793ec8f](https://github.com/omacom/omarchy/commit/793ec8f9c14ef3142281a1cf23b7bc9fa7c4ae9d) Weigh a type and its aliases as one when moving text types to the editor
- [3dfb5b7](https://github.com/omacom/omarchy/commit/3dfb5b73c051bd410c1227e9b322a7ccd4ff5313) Install CMake for building Omarchy apps
- [4184aa1](https://github.com/omacom/omarchy/commit/4184aa1e5475e761a65a3bb567c339ff915948db) Build Omarchy apps with CMake instead of qmake
- [cfa769f](https://github.com/omacom/omarchy/commit/cfa769f375b3fbf02ffc8e4c58f492afd3a6b75c) Fall back to Adwaita icons when a theme's icon theme isn't installed
- [ccff668](https://github.com/omacom/omarchy/commit/ccff668827bd23f3a16b8d9eeafabd83683d4fc4) Drop the Yaru icon theme
- [1e71f3c](https://github.com/omacom/omarchy/commit/1e71f3cb0517a3f4c5cd3d73792cab4be72242f8) Remove Yaru from existing installs
- [a25f9ba](https://github.com/omacom/omarchy/commit/a25f9ba2c23f79a07e732506a45cb88bea9aa0d1) Clear the whole leftover Yaru folder once the package is gone
- [971ca58](https://github.com/omacom/omarchy/commit/971ca58c06412f24fbd974f816095333877fa9c0) Clear only the Yaru leftovers setup made
- [822966a](https://github.com/omacom/omarchy/commit/822966a8ab6fb691071739dffcd10a83f846f405) Change only the icon theme when moving GTK off Yaru
- [7292262](https://github.com/omacom/omarchy/commit/72922629a936050ac8bb062f6b9738b1e0ca3876) Give every theme the Adwaita icons, with no icon theme of its own
- [fcb41d6](https://github.com/omacom/omarchy/commit/fcb41d664161ddfa33a64da480cb274d313c03ea) Show a model shared or unshared elsewhere on the tailnet within two seconds
- [006e934](https://github.com/omacom/omarchy/commit/006e934954ddbfc85822f427d50aaf84da7c34ec) Read a type's names in the order GLib does, and clear aliases from the desktop's list too
- [95a8f35](https://github.com/omacom/omarchy/commit/95a8f356217138c63b9e21ed78d055971bc7c6cd) Make a stopped model's error the link to its logs
- [ad7bd22](https://github.com/omacom/omarchy/commit/ad7bd22a66ae0befa4f30156926f7d28571fb96b) Pair and disconnect one tailnet model at a time
- [1166fb6](https://github.com/omacom/omarchy/commit/1166fb6cbc3d592afbfaad473e709c6eaddb93da) Merge pull request #18464 from omacom/panel-error-logs-link
- [4a0ac59](https://github.com/omacom/omarchy/commit/4a0ac59da7c1f5afda5b6f0c30148d3f569cd108) Update translations (#18465)
- [37bf0b5](https://github.com/omacom/omarchy/commit/37bf0b543968a48ff75acb228110e88866329b8e) Merge quattro into panel-remote-disconnect
- [2a2823b](https://github.com/omacom/omarchy/commit/2a2823b6f23aa77b39015cdd180f255199b7c56f) Merge pull request #18461 from omacom/drop-yaru-icons
- [c4fdaab](https://github.com/omacom/omarchy/commit/c4fdaab7b43dd7086b3135ff61427c46686e9c52) Merge pull request #18460 from omacom/app-skill-cmake
- [53e6de0](https://github.com/omacom/omarchy/commit/53e6de0386f294897c865feded8c8a6db29ea8b0) Merge pull request #18459 from omacom/terminal-in-folio-folder
- [ed473a3](https://github.com/omacom/omarchy/commit/ed473a3388220934eb693105b0c232620b8a5df5) Merge pull request #18447 from omacom/default-editor-sets-mimetypes
- [fb005ac](https://github.com/omacom/omarchy/commit/fb005ac593ca77e24f3627be623737ebc62a4c77) Update translations (#18466)
- [2b9a7c2](https://github.com/omacom/omarchy/commit/2b9a7c24b19501424bd67af5c46552f510d1f6b2) Merge remote-tracking branch 'origin/quattro' into chrome-default
- [b0fb424](https://github.com/omacom/omarchy/commit/b0fb42495fd65ca9f98712a82bfbc42d76e1098f) Merge pull request #18240 from omacom/chrome-default
- [f0ba499](https://github.com/omacom/omarchy/commit/f0ba499c10657574b1faf022a7be7cd5a6eac32e) Merge pull request #18458 from omacom/panel-remote-disconnect
- [13bfeae](https://github.com/omacom/omarchy/commit/13bfeaee66968f6e6b7521d4f4fea8f7585873ee) Merge remote-tracking branch 'origin/quattro' into panel-network-live
- [f834730](https://github.com/omacom/omarchy/commit/f83473052679b0fd1fd1849f3ef1e4087f289e0f) Say how many machines use a shared model
- [8cdeec5](https://github.com/omacom/omarchy/commit/8cdeec542b8caef3c24f879a5ec9bd463a04c42b) Update translations (#18468)
- [c09af89](https://github.com/omacom/omarchy/commit/c09af89e828609ee98ebbe3eb75fe0426aeb3bfe) Update translations (#18470)
- [3a1671d](https://github.com/omacom/omarchy/commit/3a1671d50dde945f1a8044e4cab5e1879a204569) Merge pull request #18462 from omacom/panel-network-live
- [ed0843c](https://github.com/omacom/omarchy/commit/ed0843ca75523f9718f3be4329cf41ba22ad8b7b) Offer Disconnect only while a paired model runs on its host
- [08bc7fb](https://github.com/omacom/omarchy/commit/08bc7fbbc42e7dfb9d1a4f57c46dbbe0fc8a1c02) Merge pull request #18475 from omacom/panel-disconnect-running
- [5ea0c80](https://github.com/omacom/omarchy/commit/5ea0c804674af19abc105c5d0c0d702f300e0e81) Merge pull request #18359 from jankeesvw/screenrecording-mic-level
- [fb2b004](https://github.com/omacom/omarchy/commit/fb2b004b9063ace6ea53a9c9e9ead496631f3c03) Install pipewire-jack and gst-plugin-pipewire on ARM (#15782)
- [1b68a5e](https://github.com/omacom/omarchy/commit/1b68a5eae519e1ebbf2a8a09c92b8a91175104ff) Merge pull request #18467 from omacom/share-user-count
- [00fb2c4](https://github.com/omacom/omarchy/commit/00fb2c4c5fe5b80ea8406e7b4cf9f047d6f5b03f) Update translations (#18482)
- [c0549bd](https://github.com/omacom/omarchy/commit/c0549bd09439ad2a8dcd0521ea903a83ea86dc49) Drop the panel's handling of stopped tailnet models
- [82c4828](https://github.com/omacom/omarchy/commit/82c48288c28a14786e2fe3ed264d52c1c9831aa4) Show a tailnet model's speeds as one segment: 53 (898) TPS
- [0be1570](https://github.com/omacom/omarchy/commit/0be1570e523043f082fffe055621d760f9bffe8b) Merge pull request #18486 from omacom/panel-network-leftovers
- [a65e56c](https://github.com/omacom/omarchy/commit/a65e56c0f080db0e2cad994939cfda2916506f38) Drop the MoE and Dense label from model lines
- [84cb3ea](https://github.com/omacom/omarchy/commit/84cb3ea5284e5b75dd0859d14fff4916292807d8) Say Use for unpaired network models and pause to disconnect
- [113d2c2](https://github.com/omacom/omarchy/commit/113d2c27dc707191a567e55ff097ea66593a86f3) Merge pull request #18490 from omacom/panel-remote-tps
- [10e8bee](https://github.com/omacom/omarchy/commit/10e8bee6fbb04945819204d0e3abc929735737a4) Update translations (#18496)
- [2a8b7ba](https://github.com/omacom/omarchy/commit/2a8b7bad1df6540fbef7d4fbf7f7d56c3ffd50b4) Update translations (#18497)
- [219d3bd](https://github.com/omacom/omarchy/commit/219d3bd6b23b30cb06e7ac5317c6891a67827d36) Show a tailnet model's output speed alone, without prefill
- [584f4af](https://github.com/omacom/omarchy/commit/584f4af4a42b3df5af5574569692b3bf9ebbee2f) Merge pull request #18502 from omacom/panel-remote-output-tps
- [a474541](https://github.com/omacom/omarchy/commit/a474541c209a7261d61d35ba150684d0ea3ffbf6) Update translations (#18503)
- [2bc2944](https://github.com/omacom/omarchy/commit/2bc29447090ad204ca4e034143b7eb990373c939) Merge pull request #18501 from omacom/agents-use-pause
- [6d599f7](https://github.com/omacom/omarchy/commit/6d599f76a59a2a823101fa7d3a8bcc65dc54be24) Update translations (#18507)
- [0e7530f](https://github.com/omacom/omarchy/commit/0e7530fb7c23fbf496d44f072ad64efaa7713d14) Count the omarchy-local provider as local usage (#18506)
- [f956db3](https://github.com/omacom/omarchy/commit/f956db39e59b4127072bb6a28b34086621936b30) Give the HP OmniBook X 14's Wi-Fi card board data (#18510)
- [46d28b6](https://github.com/omacom/omarchy/commit/46d28b6d2ff18340fafa5da821760fa9d3d0f3fc) Show the disk unlock prompt on the HP OmniBook X 14 (#18509)
- [aa3bd38](https://github.com/omacom/omarchy/commit/aa3bd387ebc31dd555c78c7c0bdb39f9919a3af5) Use play and the Tailscale mark for network model actions (#18511)
- [ea79ff2](https://github.com/omacom/omarchy/commit/ea79ff24b7b41dc0998868e33d6ce12f9a515031) Update translations (#18516)
- [1a4cccd](https://github.com/omacom/omarchy/commit/1a4cccd23eeefa8d9e31ff445e7a9a8b879ff158) Ship Spotify as a default web app (#18485)
- [3b53276](https://github.com/omacom/omarchy/commit/3b532766e20c654374138bedbd889f5ba92d1fd6) Update translations (#18517)
- [42e6ee4](https://github.com/omacom/omarchy/commit/42e6ee410068c6d934d93871e45ca45fac67c112) Open Qwen Code on local models, and count them and paired ones as local (#18515)
- [7c47964](https://github.com/omacom/omarchy/commit/7c479641b1cc481d0bd74e668520568dc1b89b1d) Bootstrap the update's signing keys without public keyservers (#18508)
- [9379e25](https://github.com/omacom/omarchy/commit/9379e25aae69ea4e888fa3b38c92ec5ce90cdda5) Update translations (#18519)
- [e485c62](https://github.com/omacom/omarchy/commit/e485c622409e8c514cf4f88facdae8402a48da49) Update translations (#18521)
- [3543eba](https://github.com/omacom/omarchy/commit/3543ebac50e1befa3c9bd901d5ed1258789f72fb) Let Folio's preview pick its own size (#18532)
- [db31a20](https://github.com/omacom/omarchy/commit/db31a2095e51b150cbc06e8f04c12c06a2ae7e8e) Namespace the Spotify web app icon (#18539)
- [551dc62](https://github.com/omacom/omarchy/commit/551dc62969046709e7c6176dbdbccacce580a487) Add Netflix as a default web app on new installs (#18480)
- [b19ad97](https://github.com/omacom/omarchy/commit/b19ad9764d783d9b4063a3cd5bc732b832c5136e) Set up the LCD Surface Pro 11 (Snapdragon X Plus) on its own device tree (#18276)
- [e6554e0](https://github.com/omacom/omarchy/commit/e6554e02d5257518609343f6d2ef64524edd0da1) Give the Acer Aspire 16 AI working speakers and microphones (#18544)
- [36b70f1](https://github.com/omacom/omarchy/commit/36b70f1bce6c9b94b800a322d1fa317c7b4f139a) Keep a GitHub artifact outage from failing tests (#18552)
- [2d33fd5](https://github.com/omacom/omarchy/commit/2d33fd5973eb349c3f7e3ae56e6c293516cc4e18) Label Tailscale connections by tailnet when the nickname mirrors the account (#18614)
- [3a1ab84](https://github.com/omacom/omarchy/commit/3a1ab84654915fb31f745ec5b1945317e8ab65c2) Rename Tailscale connections from the panel (#18615)
- [aca03b7](https://github.com/omacom/omarchy/commit/aca03b745f931e02c49fdf611d7bbe0af692d61d) Update translations (#18644)
- [c9fc206](https://github.com/omacom/omarchy/commit/c9fc206a5aae2a476e096746109a10eaf0b98768) Teach the app skill what the nine Omarchy apps taught (#18575)
- [bae7769](https://github.com/omacom/omarchy/commit/bae77692551167ef095280546962eee58173a961) Show yt-dlp downloads as one steady progress bar (#18648)
- [96b4019](https://github.com/omacom/omarchy/commit/96b401941bd22b24ed61c025857ff10d9b20f0d6) Show the focused app's version in the app launcher (#18647)
- [c149add](https://github.com/omacom/omarchy/commit/c149addc2e32512a18d627ba7c183b24a04374a2) Reveal hidden indicators only when hovering their own block (#18524)
- [41c9970](https://github.com/omacom/omarchy/commit/41c9970965643c9b93eb7b5c8305b893b2d8a815) Draw Omarchy's own app icons in the current theme's colors (#18635)
- [e4a1533](https://github.com/omacom/omarchy/commit/e4a15334c9664bfed886ba2392f1c7ad03fce8e4) Update translations (#18655)
- [9270f91](https://github.com/omacom/omarchy/commit/9270f91d671bb7bb92148b9e72403f72e38ce173) Pair with a network model from the agents panel without a terminal (#18641)
- [8251bfe](https://github.com/omacom/omarchy/commit/8251bfec6cc32ddeef4a0b9c35191b355e638882) Update translations (#18661)
- [51b40b7](https://github.com/omacom/omarchy/commit/51b40b711de66455ec1743626b6b4ce5d8052e58) Add Terminal and Browser to the app launcher (#18658)
- [8059033](https://github.com/omacom/omarchy/commit/8059033321a952bce38caec64b1e59d1b468d8bc) Draw dock icons solid whether or not the app is running (#18660)
- [32b3b20](https://github.com/omacom/omarchy/commit/32b3b2017b1d59a1bce35578f6db78b34e7cb81f) Let browsers, Disks and Document Viewer skip the titlebar on floating workspaces (#18663)
- [e7d7160](https://github.com/omacom/omarchy/commit/e7d7160f0df781114cc59e92deb843542e287126) Draw Monologue's themed icon as the new button in a ring (#18666)
- [5ec4362](https://github.com/omacom/omarchy/commit/5ec4362d5dcd1488313a2f77d49f3cc346181ef0) Update translations (#18668)
- [00147cf](https://github.com/omacom/omarchy/commit/00147cf6d0744b094241b8603cc1eac5b639ed26) Pin Omarchy's own apps in the default dock (#18667)
- [7969ddc](https://github.com/omacom/omarchy/commit/7969ddc350e72e7315aef86a0a65c9e492d76ead) Tell new apps to load video only when it's shown (#18673)
- [ac6cb9c](https://github.com/omacom/omarchy/commit/ac6cb9c712848741f994d7ecbaccdbab90b526e8) Keep the dock steady through a theme switch (#18674)
- [3f974d0](https://github.com/omacom/omarchy/commit/3f974d011575c53dcec452dea1c253d03b8d96bf) Give Snapdragon power profiles a CPU floor for bursty work (#18745)

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
