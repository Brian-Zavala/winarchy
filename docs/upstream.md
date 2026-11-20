# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

## 2026-11-20

1335 new commit(s) on omacom/omarchy@quattro, [454b67d...ff6533e](https://github.com/omacom/omarchy/compare/454b67d95fd63c269c5315836a098038a0c61716...quattro).

Only the first 250 commits and 300 files fit in one comparison: follow the link for the rest.

**New Omarchy release: v4.5.0** (Winarchy tracked v4.0.4). Themes and backgrounds follow it; check its notes: https://github.com/omacom/omarchy/releases/tag/v4.5.0

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| Other | `.github/pull_request_template.md`<br>`.github/workflows/i18n-check.yml`<br>`.github/workflows/i18n-sync.yml`<br>`.github/workflows/test.yml`<br>`.github/workflows/visual-evidence.yml`<br>`.greptile/files.json`<br>and 58 more | - |
| Conventions | `AGENTS.md` | `AGENTS.md`<br>`docs/` |
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent`<br>`bin/omarchy-agent-instructions`<br>`bin/omarchy-agent-integrate-herdr`<br>`bin/omarchy-agent-launcher`<br>`bin/omarchy-agent-local`<br>`bin/omarchy-agent-local-launchers`<br>and 10 more | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-copy`<br>`bin/omarchy-agent-account-exec`<br>`bin/omarchy-agent-account-home`<br>`bin/omarchy-agent-account-rename`<br>`bin/omarchy-agent-account-state`<br>and 2 more | `lib/accounts.ps1` |
| Agent usage | `bin/omarchy-agent-usage-agy`<br>`bin/omarchy-agent-usage-claude`<br>`bin/omarchy-agent-usage-codex`<br>`bin/omarchy-agent-usage-copilot`<br>`bin/omarchy-agent-usage-cursor`<br>`bin/omarchy-agent-usage-deepseek`<br>and 18 more | `lib/agents/` |
| Other commands | `bin/omarchy-apply-amd-gpu-memory`<br>`bin/omarchy-apply-hardware`<br>`bin/omarchy-apply-lock`<br>`bin/omarchy-apply-n1x-gpu-memory`<br>`bin/omarchy-apply-pacman`<br>`bin/omarchy-audio-input-mute`<br>and 134 more | `lib/` |
| Launchers | `bin/omarchy-cmd-browser-handoff`<br>`bin/omarchy-cmd-default-browser`<br>`bin/omarchy-cmd-editor-mimetypes`<br>`bin/omarchy-cmd-terminal-cwd`<br>`bin/omarchy-launch-about`<br>`bin/omarchy-launch-battlenet`<br>and 12 more | `ahk/launchers.ahk`<br>`ahk/menu.ahk` |
| Install / Remove | `bin/omarchy-install-ai-herdr`<br>`bin/omarchy-install-ai-openclaw`<br>`bin/omarchy-install-ai-t3-code`<br>`bin/omarchy-install-browser`<br>`bin/omarchy-install-browser-extensions`<br>`bin/omarchy-install-camera`<br>and 22 more | `lib/catalog.ps1` |

Commits:

- [e126646](https://github.com/omacom/omarchy/commit/e1266465d0c1150373b8cd857a20eaa02bd0bbff) Make Wine tray icons respond to double-click and right-click (#18597)
- [60cb9bf](https://github.com/omacom/omarchy/commit/60cb9bf305178505de13b85623580a9485d3b3ff) Watch translation files before rereading them, so no change is lost (#18734)
- [8b6ce31](https://github.com/omacom/omarchy/commit/8b6ce318e284e7bb1a0de909529e18ba6af754f6) Keep Wi-Fi rows in step with NetworkManager (#18702)
- [f8af52f](https://github.com/omacom/omarchy/commit/f8af52fc1e0c879b76111b9fb78a0d86c7a8ecdb) Ask at first boot what the installer asks, on the installer's screens (#18783)
- [6baca27](https://github.com/omacom/omarchy/commit/6baca275b88df3c2ad608c9fdf8f8c11b910ee60) Update translations (#18831)
- [2c8d93b](https://github.com/omacom/omarchy/commit/2c8d93be0bad26bd7f9b9a6a9bc94edf3f53e4a8) Show an OEM's branding and agreement in first-boot setup (#18841)
- [723072a](https://github.com/omacom/omarchy/commit/723072a553d77d9086444a166413fe9d6b19f045) Update translations (#18860)
- [9eb4d22](https://github.com/omacom/omarchy/commit/9eb4d22606901162225498a3820f61f5a6e10f0e) Wait out NetworkManager's passing Limited state on connect (#18869)
- [9f98609](https://github.com/omacom/omarchy/commit/9f98609aef4ea482a43c7d85e5b47d5721a67e2e) Remove Slack theme sync (#18788)
- [f03d4fb](https://github.com/omacom/omarchy/commit/f03d4fbceb9172a19599835651a002987e3f04d0) Keep the Yoga Slim 7x asleep in deep suspend with the lid open (#18835)
- [663aff7](https://github.com/omacom/omarchy/commit/663aff7b9943aeff67809d106399fb406410798c) Copy the Surface Laptop 8's second USB4 router image on existing installs (#18782)
- [f2fc529](https://github.com/omacom/omarchy/commit/f2fc529eba98e1e14c60a5aa28e9683d41e88b4d) Add Activity Monitor to the app launcher for btop (#18764)
- [91129fc](https://github.com/omacom/omarchy/commit/91129fcd2e6ff95a1b742036a4943ba2dc2e7c78) Update translations (#18910)
- [0c6dc20](https://github.com/omacom/omarchy/commit/0c6dc203863fdf3cf4aff22a4034f1b4bb70e2af) Set up a first local model entirely in the agents panel (#18907)
- [a6ba969](https://github.com/omacom/omarchy/commit/a6ba9691baa2f4221fa7a72d6bb57328ecf93764) Update translations (#18914)
- [4f9b9f8](https://github.com/omacom/omarchy/commit/4f9b9f837d58a26da8d8cf3a51e7fc98a3c82aee) Add Herdr, Agent and ChatGPT to the launcher, and let apps pick how a dock click answers (#18909)
- [d81c2e2](https://github.com/omacom/omarchy/commit/d81c2e28b84b70175155bddbd742bd2a21bcb999) Update translations (#18919)
- [9ac0883](https://github.com/omacom/omarchy/commit/9ac08836cf786c242e514cee8dfac8808e7ee641) End omarchy update when its terminal closes at a prompt (#16045)
- [2bab9ef](https://github.com/omacom/omarchy/commit/2bab9efdff884a444eb65ab0b7d6fc6dc593bf88) Pick Kalambo's device trees on Snapdragon X2 Plus machines (#18944)
- [2f1006a](https://github.com/omacom/omarchy/commit/2f1006a59ed5df6f4bd2580e7a15ad27d404508e) Show the disk unlock prompt on the Acer Aspire 16 AI A16-11M (#18743)
- [6f646bc](https://github.com/omacom/omarchy/commit/6f646bc9d96a87a63840a15d896b93fb89184f73) Show the disk unlock prompt on the ASUS Vivobook S 16 S3607QA (#18951)
- [74de104](https://github.com/omacom/omarchy/commit/74de10479d3bf7aa7865408e33219064cfe45432) Give the HP OmniBook 3 working speakers and microphones (#18921)
- [dc49cec](https://github.com/omacom/omarchy/commit/dc49cec0fd9b7bc882ac2bcf6fb6c000b16df003) Make app icons an icon set, picked apart from the theme (#18879)
- [c30411b](https://github.com/omacom/omarchy/commit/c30411b92bd3bf87535bef4e13ce7015087fc648) Report what the dropdown test sees when its keyboard walk stalls (#18872)
- [8ef0207](https://github.com/omacom/omarchy/commit/8ef0207c22172d2e2e70827abedc5606424f7a5c) Update translations (#18975)
- [1699ae7](https://github.com/omacom/omarchy/commit/1699ae775b8dc7ac8ef6582db444913e70485a6f) Pick an icon set from previews, in the theme switcher's picker (#18976)
- [854cb5d](https://github.com/omacom/omarchy/commit/854cb5d4d52bffcaecaa07f08ae09fe359e5a142) Update translations (#18981)
- [ab1e100](https://github.com/omacom/omarchy/commit/ab1e10074e88f777870310e077b471b0ba6ea08c) Wait for the update lock to come free in the hangup test (#18980)
- [f928a2f](https://github.com/omacom/omarchy/commit/f928a2f12605ce3fa52050df956a6a5c8684717d) Start the Snapdragon CPU floor at boot instead of dropping it in a cycle (#18978)
- [6306130](https://github.com/omacom/omarchy/commit/6306130eb877be9312197b4ea74eb0d0dc626f0d) Leave the locate database to its timer after install (#18917)
- [197f5ed](https://github.com/omacom/omarchy/commit/197f5ede68d044ad15ad6ccef4b6a2ab0fca92a1) Leave Turing's NVIDIA firmware out of the N1x initramfs (#18916)
- [b80cf8e](https://github.com/omacom/omarchy/commit/b80cf8e097078682a520c264e0f1d307eadb8c13) Drop the N1x rescue boot entry (#18913)
- [d7cbcac](https://github.com/omacom/omarchy/commit/d7cbcac2f96a579123e285fb223eab0c1e80dc20) Install new Snapdragon firmware packages, and pick the 8cx device trees (#18989)
- [b88f490](https://github.com/omacom/omarchy/commit/b88f490811b3e122ac9b54e085c75ef50bfe2d76) Mark migrations done with one touch on first install (#18985)
- [4f26515](https://github.com/omacom/omarchy/commit/4f26515d55f5d03ddf884a8b416f3b66b8ee7ae4) Repair the bundled extensions when switching to a Chromium-based browser (#18735)
- [61d7530](https://github.com/omacom/omarchy/commit/61d7530f0eaa4066e502dc261bae9ae50be4cb60) Print the current background name on its own line (#18790)
- [dd0de87](https://github.com/omacom/omarchy/commit/dd0de87cda921cc5350089ee08cf38d8f99ac4bc) Refuse unknown omarchy-snapshot subcommands (#18792)
- [41cb643](https://github.com/omacom/omarchy/commit/41cb6438b86b138a73da095dc4f1f4a2fc6b52a6) Silently exit when clipboard history file is missing (#18794)
- [aed3b57](https://github.com/omacom/omarchy/commit/aed3b574f646c140ce892eb51bcc2ef1f577e454) Pass the full command to every swarm pane (#18818)
- [0f15210](https://github.com/omacom/omarchy/commit/0f152103e443bb6dd67b342df9a42e17909c7d1c) Escape the commands tdlm queues in each tmux window (#18822)
- [25724bb](https://github.com/omacom/omarchy/commit/25724bb46073e24d5e8024230493892f33042086) Open no editor when eff's file picker is cancelled (#18821)
- [c0cd26e](https://github.com/omacom/omarchy/commit/c0cd26e8e6741d69fdd321267e3b870c3d0cf3ba) Hold Alt in the system menu to reboot to the BIOS (#19003)
- [9e98935](https://github.com/omacom/omarchy/commit/9e989357f377fe3165aa15c61902963a888ed4b4) Update translations (#19005)
- [c421383](https://github.com/omacom/omarchy/commit/c421383753a17212867597ba21ffa146aa6cbd3d) Add Surface Laptop 7 15" board setup (#18967)
- [d76f364](https://github.com/omacom/omarchy/commit/d76f364b41ccf01909b1d84ffcc6bd4fbb8cd91d) Update translations (#19012)
- [04f894e](https://github.com/omacom/omarchy/commit/04f894e218893b24f389384f4b8aa1270e882b4c) Set up an agent subscription with its download shown, then a browser login (#19002)
- [2465549](https://github.com/omacom/omarchy/commit/24655491096331cb633e5cd3db30923b31563bc9) Update translations (#19021)
- [ae47898](https://github.com/omacom/omarchy/commit/ae47898976aa305701c7d153be4e8322f3970d4f) Cut the Herdr icon's prompt cleanly, and take Aether's out of its window (#19020)
- [23f560e](https://github.com/omacom/omarchy/commit/23f560e5fa51f0ebffcf0a525739868ff2e52f7e) Show the system exit OSD only once the exit has taken 2 seconds (#19006)
- [41c76fd](https://github.com/omacom/omarchy/commit/41c76fd4d69a65611ce8148a67284808c1eb0ba2) Boot the LCD IdeaPad Slim 5x on its own device tree (#19015)
- [5ab2f12](https://github.com/omacom/omarchy/commit/5ab2f1222791419d13189c3edf73840a6d361510) Handle the lid on ChromeOS EC laptops like Googlebooks and Chromebooks (#18777)
- [84c4c55](https://github.com/omacom/omarchy/commit/84c4c558662e084feb49c0eba0fe76236e7b0870) Exit 1 when a command that needs an argument is run without one (#18797)
- [e5fb78a](https://github.com/omacom/omarchy/commit/e5fb78ae7168e10b16f86e84d6beb23f659f6b1c) Quit the running ChatGPT app before removing it (#18799)
- [3b717fa](https://github.com/omacom/omarchy/commit/3b717fad3dd36e81d27b28b9724ce2beab794783) Print usage on -h/--help in omarchy-tailscale-send (#18806)
- [f1afc61](https://github.com/omacom/omarchy/commit/f1afc61ed900a201d8a2393925aadc11566f48c6) Show keyboard and input method errors in the current language (#18815)
- [49e538b](https://github.com/omacom/omarchy/commit/49e538be59db7b0773d8dec79d93218d0b533ab0) Print usage for omarchy-notification-send --help instead of sending a notification (#18819)
- [d920320](https://github.com/omacom/omarchy/commit/d920320e65302645ab772748f4d9ba1f32ab5de4) Update translations (#19028)
- [673e4b5](https://github.com/omacom/omarchy/commit/673e4b5a7640545e89ab58ee953daaa7d3507afe) Follow Omarchy's chrome and corners in T3 Code
- [62cac36](https://github.com/omacom/omarchy/commit/62cac366663fa18e030838ef28c3424ecccea602) Stub the video decode setup in the default apps test (#18991)
- [c054e66](https://github.com/omacom/omarchy/commit/c054e662365235543cc28df2120bc9b6ceb2d197) Make the pacman keyring in the background during a first install (#19022)
- [9b02de0](https://github.com/omacom/omarchy/commit/9b02de05922a122ba12998a20390de2ec8d099bf) Keep a theme's own T3 CSS and match the shell's button group
- [6a46afb](https://github.com/omacom/omarchy/commit/6a46afbc711ef79438318a4c819269b55da2a61d) Draw icons for Brave Origin, Ghostty, Herdr, Kdenlive, Moonlight, OBS, RAWmakase, Spotify and WeChat (#19036)
- [9ca4de1](https://github.com/omacom/omarchy/commit/9ca4de1d5f097b48f962ea414ac14ae7594458dc) Use Files for other apps' Open and Save dialogs (#19035)
- [9599f76](https://github.com/omacom/omarchy/commit/9599f76616825c99f78ff04cfa9512ecf899c0f7) Replace imv and mpv with Omaview (#19034)
- [9f68da8](https://github.com/omacom/omarchy/commit/9f68da882545cf4aae8a6c15cce06fada0f116dd) Update translations (#19040)
- [d7586fb](https://github.com/omacom/omarchy/commit/d7586fb52fd6a0cde0603ac263febf14bab28e4d) Keep the charging icon while the battery's charge rate is still stale (#19046)
- [29fbc4e](https://github.com/omacom/omarchy/commit/29fbc4e2de4e57525acc6195351e86a31773e158) Show how to stop touchpad taps from dragging and pasting (#19017)
- [4bf10ed](https://github.com/omacom/omarchy/commit/4bf10ed28342b597009dcf573ffc0d70b94b31e3) List the Snapdragon 850, 835 and 7c laptops' device trees in the boot image (#19051)
- [43e257a](https://github.com/omacom/omarchy/commit/43e257a2bf2763ea9c3463c94fdfbb233b0c6fd1) Keep keyboard setup working with read-only sysfs
- [3d5e640](https://github.com/omacom/omarchy/commit/3d5e640f74f398976dea36fb9db3719fbefa7da7) Cover installer caller and keyboard live write failures
- [480a7e0](https://github.com/omacom/omarchy/commit/480a7e0809b1978acdb72ff3e74a9a33fed7ae4d) Fix installer fixture isolation and locale-dependent assertion
- [c2e2dd9](https://github.com/omacom/omarchy/commit/c2e2dd9ad90b5f12a241b2a369e0c58e2412ff05) Draw Media Viewer's and Chromium's icons in the icon sets (#19042)
- [37285b5](https://github.com/omacom/omarchy/commit/37285b5cc4c9679a03df502e1765f0ac566f5fde) Open Markdown files in Omawrite (#19087)
- [fc463b8](https://github.com/omacom/omarchy/commit/fc463b800da105d14fe0bb9f1bfd9edbb79f1141) Update translations (#19089)
- [6f82d46](https://github.com/omacom/omarchy/commit/6f82d46abb5804d0f44306d017c79dfcb40c8868) Install Node with opencode, qwen, ghui and playwright on their first run (#18550)
- [74dff35](https://github.com/omacom/omarchy/commit/74dff359ff085df85eab1bdebf4aee966ac283f6) Record every frame with wf-recorder so a stop on a still screen ends it (#18551)
- [b52dd3a](https://github.com/omacom/omarchy/commit/b52dd3aa3f9144471199aea7dd455028e515a2d5) Refuse weather coordinates off the globe (#18553)
- [e6c8285](https://github.com/omacom/omarchy/commit/e6c8285c0a3396b6ff285813a7112e4a631232a8) Refuse an empty agent prompt with the prompt route's own usage (#18554)
- [464d993](https://github.com/omacom/omarchy/commit/464d99300b8f55815857026bdbda72d2584f3b0d) Stop agent usage-update on an empty --except (#18555)
- [0a004aa](https://github.com/omacom/omarchy/commit/0a004aa522e66365a78c59d366abe51c222bccc9) Read a notification's code whole, and only when it starts by its keyword (#18556)
- [4838ee1](https://github.com/omacom/omarchy/commit/4838ee1bf98788fb182dfa343e55b875ba362a91) Find a theme by the name omarchy theme list shows (#18557)
- [96cc8a7](https://github.com/omacom/omarchy/commit/96cc8a7e914d99eaca45926b0d4db99e32f6833a) Run the chosen keybinding when Hyprland 0.57 names Lua binds by what they bind (#18558)
- [cf631a7](https://github.com/omacom/omarchy/commit/cf631a70f5801fc94f209a69426791766f59773c) Say there is no microphone instead of toggling a missing one (#18559)
- [e6dbc04](https://github.com/omacom/omarchy/commit/e6dbc04a0db9c787d6798e963f23198a2e396cc2) Say there is nothing to pick instead of opening an empty plugin or background picker (#18561)
- [853d289](https://github.com/omacom/omarchy/commit/853d2893677980c073afbc1500a3719270293755) Close the T3 Code installer quietly when its channel picker is cancelled (#18562)
- [1c4a9e0](https://github.com/omacom/omarchy/commit/1c4a9e0cbde31b8d80afd19702f73146b394d6cc) Select the row under the click after clicking into a menu submenu (#18565)
- [43c5963](https://github.com/omacom/omarchy/commit/43c5963b4f1429a05df4c966bde3e9825dfbefc8) Update translations (#19090)
- [a7f3c06](https://github.com/omacom/omarchy/commit/a7f3c0609bf6cf2de4fc14fec875faeefa5f11ff) Validate pane counts before creating layouts (#9039)
- [7062d5f](https://github.com/omacom/omarchy/commit/7062d5fda836b220360085b0c1b386c91d611d13) Update translations (#19091)
- [44486c2](https://github.com/omacom/omarchy/commit/44486c2a5577701ba5ecc619f11039dcf3105506) Cap the command list column width to keep summaries from wrapping (#13237)
- [3567296](https://github.com/omacom/omarchy/commit/35672963760e99da12cd5fed73045904d4b69b94) Exit cleanly when the Docker DB picker is cancelled (#16435)
- [5053518](https://github.com/omacom/omarchy/commit/5053518c6484cfa561b33d43b5506b1235423915) Open config files with omarchy-launch-editor, without a notification (#19088)
- [87ee744](https://github.com/omacom/omarchy/commit/87ee744206a416a803696b7c5a2ce91e9ef74dbb) Update translations (#19095)
- [c5f98c6](https://github.com/omacom/omarchy/commit/c5f98c652aac914c0fa74cf5f4bf2ca65824ef8f) Rearm idle monitor after timeout changes (#9570)
- [0746020](https://github.com/omacom/omarchy/commit/07460209733354e3ea9b2b4aa3eaae4e7a307210) Fix the races behind five tests that fail on unrelated pull requests (#19096)
- [a395d9f](https://github.com/omacom/omarchy/commit/a395d9f268a41d542a571e16e22280f229fd6d42) Point help and examples at omarchy-debug rather than omarchy debug (#19097)
- [b65cf19](https://github.com/omacom/omarchy/commit/b65cf19f7d2cd02cb73152eac687b3774afaa39c) Hide agent starter tiles until an agent is ready (#19100)
- [b0b9f44](https://github.com/omacom/omarchy/commit/b0b9f443eaca8f86124e8ff7437baa2e23e3ef13) Update translations (#19104)
- [64e3a5e](https://github.com/omacom/omarchy/commit/64e3a5edd18b102d63dc8b2c422024a0cd8c41cf) Don't animate omaview's window (#19099)
- [b1f70c3](https://github.com/omacom/omarchy/commit/b1f70c37977a12721e1d55fc045f3007e62d5086) Wi-Fi passphrase prompt: spaced dots and a show-password toggle (#19103)
- [a2e84df](https://github.com/omacom/omarchy/commit/a2e84dfb13c4b1544573fce6911b899bb6711cbd) Stop the whole monitor watcher in tests, not a snapshot of its children (#19105)
- [d5338d0](https://github.com/omacom/omarchy/commit/d5338d0d4a05182f988f5175fead4cb07b9bebbf) Start a screenrecording with no audio on Super + Shift + Ctrl + Alt + C (#19108)
- [8cb0ead](https://github.com/omacom/omarchy/commit/8cb0ead6560b1453813867423a7f7b6847e13bb8) Update translations (#19109)
- [8f2df93](https://github.com/omacom/omarchy/commit/8f2df93aafd448b5c301c07e5f93e8fda2274ec4) Update translations (#19112)
- [1b38e58](https://github.com/omacom/omarchy/commit/1b38e58317817cc48a45d27e73cae5da3fbb34fe) Snap a bare capture click on any monitor, not only the focused one (#19030)
- [08e92a2](https://github.com/omacom/omarchy/commit/08e92a2e46fba88896b091da6282fb9251874126) Avoid Baffin GPU hangs during screen recording (#10125)
- [263c3bd](https://github.com/omacom/omarchy/commit/263c3bde0974974fd9c8eb2d247b0eec8e17f988) Honor OMARCHY_SCREENRECORD_USE_PORTAL when recording fullscreen (#7188)
- [dd623d5](https://github.com/omacom/omarchy/commit/dd623d50a31246a1cfd1e3ba4b82b668090b6d9a) Document omarchy-debug directly in bundled agent skills (#13702) (#13817)
- [24c508e](https://github.com/omacom/omarchy/commit/24c508e9e5afb82284bdd736465f76ec6492125e) Update translations (#19115)
- [5bc6c46](https://github.com/omacom/omarchy/commit/5bc6c46e27e99c5025f1661c73f62d3cbb74b001) List the Samsung Galaxy Book2 Go's device tree in the boot image (#19102)
- [fc3fd08](https://github.com/omacom/omarchy/commit/fc3fd084a4d66ae77c5333838b7f439753b5e67a) Force the GL renderer for GTK4 on NVIDIA (#9814)
- [3489996](https://github.com/omacom/omarchy/commit/3489996a20923dc5abb52afc5aff61955e2f1d07) Install Checkmate by default (#19113)
- [f45ed4a](https://github.com/omacom/omarchy/commit/f45ed4ad37a84cfcf3c4b3dbac11c3379909dbff) Update translations (#19118)
- [e25a57b](https://github.com/omacom/omarchy/commit/e25a57bf974b11a2a8fff17dc9e69cec4b689c6b) Hold the network panel's layout while switching Wi-Fi networks (#19106)
- [5ef4e43](https://github.com/omacom/omarchy/commit/5ef4e439099f8d51a6a08b4db2a4141807a46028) Draw Checkmate as a single king (#19123)
- [6f5f11e](https://github.com/omacom/omarchy/commit/6f5f11e7888c14f71d4ba26392befaeabff2fe47) Update translations (#19124)
- [451f94a](https://github.com/omacom/omarchy/commit/451f94a86bcf0fe9c39e41305600ac18f531dbff) Update translations (#19126)
- [eba75cd](https://github.com/omacom/omarchy/commit/eba75cdafe87e5495f7f708bb2222e21fda74f1c) Keep the app launcher open after deleting an app (#19122)
- [15d240a](https://github.com/omacom/omarchy/commit/15d240a48cb0ec8ca1bb4a1959588ed969555c78) Keep the Samsung Galaxy Book4 Edge 14 from sleeping the AOSS (#19044)
- [7c8e059](https://github.com/omacom/omarchy/commit/7c8e05925391188d6e95e581dc51c12fb2facd48) List the Samsung, Lenovo, TCL and Apcsilmic Snapdragon 7c device trees in the boot image (#19130)
- [e19607f](https://github.com/omacom/omarchy/commit/e19607fc5ab3cbe6d2d4ebb13bd9e990db3854d1) List the TCL Book 14 Go's device tree by its file name (#19135)
- [dceae18](https://github.com/omacom/omarchy/commit/dceae1857bc5df80eedbba07ff8a03c2dc428fdd) Build Snapdragon boot images with systemd-stub-omarchy, whose header holds every device tree (#19139)
- [1552089](https://github.com/omacom/omarchy/commit/1552089559ddae5fcf0bc21ff4b0c56de35756e4) Show the disk unlock prompt on the ASUS Zenbook A14 (#19014)
- [fad23cf](https://github.com/omacom/omarchy/commit/fad23cf8195326a7fc70b4452986bcdbf0bda9ad) Install Cards by default (#19151)
- [9a63185](https://github.com/omacom/omarchy/commit/9a63185aca72481346b963967c0ce0b2a40249c5) Update translations (#19153)
- [ab927af](https://github.com/omacom/omarchy/commit/ab927af25d36af5542de6c1ae0f18b5c968c71f9) Draw the Cards and Checkmate icons right after installing them (#19152)
- [9f09d60](https://github.com/omacom/omarchy/commit/9f09d606aaa5bcf8df80affdb1171788b78b956e) Show the disk unlock prompt on the Lenovo IdeaCentre Mini 01Q8X10 (#18629)
- [5ff8c3c](https://github.com/omacom/omarchy/commit/5ff8c3c81b22e3fbf60cec51f824ee7c6ada4040) Show the disk unlock prompt on the Lenovo IdeaPad Slim 5x (#19048)
- [520c3ed](https://github.com/omacom/omarchy/commit/520c3ed969d30b58defe03eb19d603f32b4cb002) Update translations (#19156)
- [fcf6f10](https://github.com/omacom/omarchy/commit/fcf6f1049a4fc6fcc78b8a3a4c70208bef09725e) Let the DSPs start when a Snapdragon root disk is on a USB-A port (#18776)
- [3b36b9e](https://github.com/omacom/omarchy/commit/3b36b9e19ea00a6c21492098308a7f44a8091564) Take the T2 Mac packages from the Omarchy repository (#19168)
- [c3c8acf](https://github.com/omacom/omarchy/commit/c3c8acf1ef376d19c400464eab9bc382a8667c6f) Let AMD GPUs map all of RAM but 8 GiB, not half (#19164)
- [459b90c](https://github.com/omacom/omarchy/commit/459b90cb5896a16840cce8b8a0f5ea4eae9fc191) Reserve 256 MiB of CMA on the Raspberry Pi 4 (#19237)
- [fc1e050](https://github.com/omacom/omarchy/commit/fc1e050598e11785bbc28c1dac924d867e17d913) Install the Raspberry Pi 4's Bluetooth firmware (#19240)
- [6dd9621](https://github.com/omacom/omarchy/commit/6dd96213b3f9f6041caa3e7f14227bfb52aa4f7e) Move About into the System menu, above Screensaver (#19220)
- [547dde2](https://github.com/omacom/omarchy/commit/547dde2d9225987169f39956f616209eae85dcee) Wake the HP ZBook Ultra G3a 16 from sleep without an 80 second freeze (#19233)
- [3437cfb](https://github.com/omacom/omarchy/commit/3437cfb482d603a34c1292db2d425cacd0f80281) Give each local model a launcher of its own, with a loading show (#19138)
- [b49c74d](https://github.com/omacom/omarchy/commit/b49c74df85f8a3db1a2548bed666d8b145373351) Turn off herdr's own update check, since pacman updates it (#19255)
- [59f377f](https://github.com/omacom/omarchy/commit/59f377f98d0c92e30db230ab62119ab6b3f2a26c) Point the Fastfetch manual entry at System > About (#19254)
- [f525d43](https://github.com/omacom/omarchy/commit/f525d43688b38716d5dd7c3452b26c5c2d051b0f) Give every installed agent harness a launcher of its own (#19245)
- [a6193ca](https://github.com/omacom/omarchy/commit/a6193cab1b99cc9f8f8de218f84e1c91b0fc7adc) Switch to an added agent account and say it's ready for more (#19243)
- [3d06ece](https://github.com/omacom/omarchy/commit/3d06ece95eb384264b7fd8266a4f655c9c362f56) Move hardware controls into omarchy device (#19229)
- [92deb43](https://github.com/omacom/omarchy/commit/92deb4302f6633a8bd31915c2dddaf3d58efe844) Let a hand-chosen agent account overrule autoswitch (#19158)
- [cbd01ab](https://github.com/omacom/omarchy/commit/cbd01ab3abd994e5815177358544434489d2406f) Help local models make themes, apps, games and plugins (#19086)
- [c0c6340](https://github.com/omacom/omarchy/commit/c0c63402abee6e8335f9bd3c6da85348b9269b11) Wait for the last detached launch before the desktop-entry test cleans up (#19259)
- [9e74d57](https://github.com/omacom/omarchy/commit/9e74d57d3ccad18da1716a029e8356f4b7c00e90) Move running Claude sessions along when switching accounts
- [6a9e764](https://github.com/omacom/omarchy/commit/6a9e7642c96fb7a9b66468d5fba742b621a108a9) Merge quattro and carry the read-only keyboard fix to the device command
- [d7e04a4](https://github.com/omacom/omarchy/commit/d7e04a46f095025b03190336492915d61677bbb9) Judge a duplicated login by its token, and lock re-sign-ins
- [c7a52db](https://github.com/omacom/omarchy/commit/c7a52db202503eea6ffed62f92b54f94374f9014) Make the T2 t2bce_vhci initramfs module optional so other kernels build (#17164)
- [85cb4dd](https://github.com/omacom/omarchy/commit/85cb4ddf0e6e58d235ad07ed8b75d8f848f4ea88) Rebuild the T2 boot images with mkinitcpio where Limine is missing (#19269)
- [4d64235](https://github.com/omacom/omarchy/commit/4d64235cd8bbe2dac37b4a6fd77b5d77f22f9316) Merge pull request #19013 from YashasVM/fix/toprow-readonly-sysfs
- [af0b8db](https://github.com/omacom/omarchy/commit/af0b8db43737bbdf3195e57341214451397f69bc) Let Pi 4 brightness keys reach an HDMI monitor
- [c6be7ab](https://github.com/omacom/omarchy/commit/c6be7abb9e518edc40f81be1b8ea0008e9b8b790) Merge pull request #19279 from omacom/pi4-ddc-access
- [419a5a7](https://github.com/omacom/omarchy/commit/419a5a7095d118a218d5f84548dbd83ce90067e6) Merge pull request #19029 from omacom/t3/t3code-follow-corners
- [c6945de](https://github.com/omacom/omarchy/commit/c6945dec274644ed825dd93df0b84ce81b53269c) Let local models see what they build as the user would (#19300)
- [778f827](https://github.com/omacom/omarchy/commit/778f827bae76525864850d1f6e0a7a9aac33d1b7) Run pages in real time when agents look at them (#19307)
- [01a9029](https://github.com/omacom/omarchy/commit/01a902913d36cbd69acaaf3ca26d7a3bd564569d) Relink agent skills when omarchy dev link points at a checkout (#19310)
- [82f7e6d](https://github.com/omacom/omarchy/commit/82f7e6d234c4f3c3e35d7c58a596f68bf2ac6b1a) Skip the local model launcher migration without omarchy-local-ai (#19305)
- [78a3148](https://github.com/omacom/omarchy/commit/78a31480bdd40228350c11f4425f8b0ae3b188fc) Authorize the quiet boot migration without sudo -v (#15729)
- [699319d](https://github.com/omacom/omarchy/commit/699319d401c9e72ea2b1c17bcfb3433e19528923) Install Ghostscript so driverless printers print again (#18472)
- [f12dc43](https://github.com/omacom/omarchy/commit/f12dc43ebf6940695911f2d206d911ad77378c8a) Weather: send a User-Agent to Open-Meteo so the forecast fetch is not 403'd (#19133)
- [eb701f1](https://github.com/omacom/omarchy/commit/eb701f1f99b71bc2fd6b814a5b1d6c8794f2c993) Harden omarchy-refresh-config against path traversal (#10413)
- [a5225d9](https://github.com/omacom/omarchy/commit/a5225d9b14a6f49a82af7a290d36bad98c9f8337) Rebuild markerless Mac image entry on first boot (#16224)
- [e59606d](https://github.com/omacom/omarchy/commit/e59606d37ded8c97553ecce88fa26d06b32ededf) Save a settled seat before its copy goes, and copy to older backends
- [6a76750](https://github.com/omacom/omarchy/commit/6a76750741f43ed5a1a1d269e4b2f727366360f8) Move the theme intro videos to their own repository
- [b471238](https://github.com/omacom/omarchy/commit/b47123857889ed52fdf56fb70d304dfe2e82c614) Merge pull request #19314 from omacom/move-theme-intros-out
- [1fe34f7](https://github.com/omacom/omarchy/commit/1fe34f7bf93a5be050ba31f4659363fa0b0d3072) Stage newly packaged intros and install them by default
- [8c3fc78](https://github.com/omacom/omarchy/commit/8c3fc785251aa0d210dbc003b41e405048b11d16) Drop the comment on omarchy-themes-intros
- [018da8a](https://github.com/omacom/omarchy/commit/018da8a7acf5c42f25f82429c2e6f40a3c71eb4a) Reword the intro migration's description
- [2de9081](https://github.com/omacom/omarchy/commit/2de9081e0fdbda85fa2200b217b0b349c952de6a) Just refresh the theme in the intro migration
- [c775e9a](https://github.com/omacom/omarchy/commit/c775e9aae389ea700e328fa5d3351d5bf2b2811e) Drop the intro migration
- [fd5c8b3](https://github.com/omacom/omarchy/commit/fd5c8b36cfcb5dfd416437121d8c37196e4030cd) Install omarchy-themes-intros on existing machines
- [404b998](https://github.com/omacom/omarchy/commit/404b9980dd020f89f18d53f5262fc36de0a541ff) Merge pull request #19316 from omacom/stage-packaged-intros
- [b46fc17](https://github.com/omacom/omarchy/commit/b46fc17c6f3c8dfde06f5e1bf2ce8759c45b5cd6) Take theme intros from the package on a dev link
- [0ab4bee](https://github.com/omacom/omarchy/commit/0ab4bee25de289a2cba2aea3cb35b26461aea0f7) Test that a checkout's theme stages the packaged intros
- [932c155](https://github.com/omacom/omarchy/commit/932c1559fb6cddcb3d876042c5a2aa7f4b0db03f) Merge pull request #19327 from omacom/packaged-intros-on-dev-link
- [33e9f56](https://github.com/omacom/omarchy/commit/33e9f56c6d71a62bff6fdfbdf6dd3288b3ac46e5) Merge pull request #12101 from chessing234/fold/cups-browsed-migration
- [4beb2a1](https://github.com/omacom/omarchy/commit/4beb2a159a3555b16d6341914bb21e58ced0385d) Read each Claude login under the lock that moves it
- [b972bd8](https://github.com/omacom/omarchy/commit/b972bd8cfb902be4526f743054601d59cf31099a) Merge pull request #19268 from omacom/agent-account-follow
- [9adb342](https://github.com/omacom/omarchy/commit/9adb3424b2caa257a78af8a742807fac2db7520f) Use DeepSeek's whale mark in the agents panel
- [b083c61](https://github.com/omacom/omarchy/commit/b083c613923ffa3bc1afe65562e8bcc9ebc2fdc6) Merge pull request #19333 from omacom/deepseek-logo
- [55455b0](https://github.com/omacom/omarchy/commit/55455b024d1514c1423cd315da4ea6d7e3d9b36b) Return freed GPU memory to the system at once on GB10
- [d3ed678](https://github.com/omacom/omarchy/commit/d3ed67858bdcf0d85f751b2cdb3abfec3e9e2f93) Drop the migration test: shipped migrations are frozen
- [42715ad](https://github.com/omacom/omarchy/commit/42715ad4d60bef596a32d9d42700a4345ae4fb2a) Merge pull request #19335 from omacom/gb10-nvidia-memory-pools
- [e6aec97](https://github.com/omacom/omarchy/commit/e6aec9716dbb8748e0d4e66ff927cb7b04a2e17a) Show agents how a bar plugin opens a popup on click (#19338)
- [899d8cb](https://github.com/omacom/omarchy/commit/899d8cb68f49e231db91ed46131134cffbc386cf) Open Fantasi from an image model's line in the agents panel
- [c4d3e3a](https://github.com/omacom/omarchy/commit/c4d3e3a4f157398cf1c3fc0bebbc9dc1c36619bf) Add Black Forest Labs and Alibaba marks for image models
- [d4eb2cd](https://github.com/omacom/omarchy/commit/d4eb2cd7f082886aeef7413965a90aa312a74b11) Open Fantasi on the image model whose line it's opened from
- [10414b8](https://github.com/omacom/omarchy/commit/10414b8a5703608a7e3648f4910f4e2e4039494e) Open Fantasi for a paired host's shared image model too
- [64c0b62](https://github.com/omacom/omarchy/commit/64c0b627c9344303665d12419230fa0c756f206f) Add a Game starter that makes three.js games for the launcher (#16308)
- [ed95c1e](https://github.com/omacom/omarchy/commit/ed95c1e6fcc73edf2863a15b0fe0d2b15a35c856) Leave Open Fantasi's translations to the sync, and test image models' launch
- [7d4feb8](https://github.com/omacom/omarchy/commit/7d4feb8e36ab940ffafaf6a2c84bc5ef0c72c3da) Merge pull request #19345 from omacom/panel-fantasi
- [017fb41](https://github.com/omacom/omarchy/commit/017fb412e02612b9b2c4cc782ccebc5f9ec24083) Install Fantasi as a default app
- [2f1a2db](https://github.com/omacom/omarchy/commit/2f1a2db8f5c3a7bfd07859e8e6372733973e0e33) Merge pull request #19353 from omacom/fantasi-default
- [b78e2fd](https://github.com/omacom/omarchy/commit/b78e2fd8fbbb400935729e7b3b058c733d8e4b2c) Open Fantasi from an image model's launcher, not an agent
- [bf6d348](https://github.com/omacom/omarchy/commit/bf6d3485925cfccc9606a53b2947cb4ec48c2c65) Merge pull request #19354 from omacom/image-launchers
- [0558c72](https://github.com/omacom/omarchy/commit/0558c72c416fd08f3daa06bf6a6c21b27f1543a5) Focus only Fantasi's own window from the agents panel, not one that mentions it
- [a490d5b](https://github.com/omacom/omarchy/commit/a490d5bdbf77801b1614d6d126c9c7d413b5658f) Merge pull request #19355 from omacom/panel-fantasi-focus
- [d54cde7](https://github.com/omacom/omarchy/commit/d54cde78f174761803e4caa96c38006a3461d0d2) Rank shallower menu search matches above deeper submenus (#19308)
- [7ffb4b4](https://github.com/omacom/omarchy/commit/7ffb4b4a8be4c7a8c204f697957f5e788c7e3557) Add the ACE-Step mark for its music model (#19372)
- [69bb34c](https://github.com/omacom/omarchy/commit/69bb34c6e804306339d56e20182db5575460ea6f) Draw Fantasi in the papercraft and arcade icon sets (#19407)
- [b6440cf](https://github.com/omacom/omarchy/commit/b6440cfbd0d5806b7e4a361046148e4e600dcf29) Turn Game Vibes into a cracktro (#19367)
- [26516b2](https://github.com/omacom/omarchy/commit/26516b2221b17409f8695770a233e55f2453fcc0) Move Git setup to Setup > Git and drop its first-run notification (#19413)
- [7c45ded](https://github.com/omacom/omarchy/commit/7c45ded34d56e568adc45edf25dee9888e3a4b37) Open image, video and music models in Fantasi, and say what each model makes (#19356)
- [d694980](https://github.com/omacom/omarchy/commit/d6949800212668c277420be4c720d1014458cc40) Simplify Game Vibes: one command, a shorter skill (#19414)
- [c5a437a](https://github.com/omacom/omarchy/commit/c5a437a86efa2b82bf9814944aad4557181b0c62) Remove Direct Boot (#19416)
- [512b57b](https://github.com/omacom/omarchy/commit/512b57b7aa6555767973726bc3f8c8df37b34746) Move Reset Computer to Remove > Factory Reset (#19417)
- [ee9d6e0](https://github.com/omacom/omarchy/commit/ee9d6e026142a736bda1e06815fa0a69fe79a633) Open Game Vibes full screen (#19420)
- [95e5ba4](https://github.com/omacom/omarchy/commit/95e5ba4d799f5c6ea238dbd44f739fb9c7a235ef) Add Death Wish to Game Vibes (#19366)
- [c4ad071](https://github.com/omacom/omarchy/commit/c4ad07122bee1de099455ec7e25be4457ece5f9b) Keep the kernel's default free-memory watermark on GB10 (#19415)
- [128a321](https://github.com/omacom/omarchy/commit/128a321a1bd63863bc3ce431bda8c3cc62fb0c1a) Name the Qwen3.6 35B recipe for the Arc B390 in the local models guide (#19424)
- [adaf220](https://github.com/omacom/omarchy/commit/adaf220316e66a896fc137902cd1f57153d67afe) Say what a local model takes in RAM instead of drawing a memory bar (#19421)
- [b4be9bb](https://github.com/omacom/omarchy/commit/b4be9bb6480da7c803146e73ea78fc58a91f5dff) Install a Game Vibes game from a git repository, like a theme (#19422)
- [6030609](https://github.com/omacom/omarchy/commit/6030609ca5e161e1f33c91f73a055630d42fe80d) Don't flag the no-op Apple Silicon initcpio hook as a failed initramfs (#19425)
- [11fb61c](https://github.com/omacom/omarchy/commit/11fb61c1639ec55f6048f4dd5c3aacc1104d6fa5) Show Fantasi's own icon on the button that opens a model in it (#19419)
- [f0b1cd8](https://github.com/omacom/omarchy/commit/f0b1cd8e20e0f299daa06a783b761b2d8eb7ec7c) Update the translation sync Muse launcher pin
- [34d8f44](https://github.com/omacom/omarchy/commit/34d8f445541a763ec10b8070296e4855fad25114) Offer a local model's update in the agents panel
- [b4010b2](https://github.com/omacom/omarchy/commit/b4010b232767a5f4127e9b115f66857c8d06a15b) Add Setup > Region with Language, Formats and Timezone (#19358)
- [372dfce](https://github.com/omacom/omarchy/commit/372dfcec58235abb8bb16b4537fb8600ce59e146) Merge pull request #19432 from omacom/fix/muse-launcher-pin
- [4be96ba](https://github.com/omacom/omarchy/commit/4be96ba8372e45c8b3062c65c74e3c110e05d56d) Show an update's download size, behind the system update's arrows
- [5801501](https://github.com/omacom/omarchy/commit/580150119b38c8b8cda8477b1294e4ef15ee65e6) Drop a local model's error from the panel once its logs are opened
- [9e21f53](https://github.com/omacom/omarchy/commit/9e21f53c7ade1dd13834533d52f3024b882788ed) Merge pull request #19435 from omacom/dismiss-read-errors
- [c80308f](https://github.com/omacom/omarchy/commit/c80308f99f855f0f3a55a7df154f182ec9933922) Split creation skills into omarchy-make-theme/plugin/app/game
- [1eb89ae](https://github.com/omacom/omarchy/commit/1eb89ae495414cabeb216a17b66b251125ee757a) Merge quattro
- [a7e1a02](https://github.com/omacom/omarchy/commit/a7e1a02619d447ee8ab443a915a42923a62f635d) Check for the right nested link name in the skills-link test
- [e3f0f7f](https://github.com/omacom/omarchy/commit/e3f0f7fd234ba9cf165e226e104e9703baf34187) Merge pull request #19433 from omacom/local-model-updates
- [d253587](https://github.com/omacom/omarchy/commit/d2535871dae3be7b81c7cd629f0e512a5af10f0a) Merge bug reporting into one omarchy-contribute skill
- [47e3392](https://github.com/omacom/omarchy/commit/47e33926a3cfa47b96c364eb11fb1200083b944f) Attach captures of visual bugs and features with gh --attach
- [b80f75e](https://github.com/omacom/omarchy/commit/b80f75e3e84922784c1e279f33fb7b0cccede1d1) Merge pull request #19438 from omacom/omarchy-make-skills
- [8a350ca](https://github.com/omacom/omarchy/commit/8a350ca22a1afdf61d170af66f46557c9f4318f3) Ship theme loops from omarchy-themes-loops for OWE to play (#19434)
- [4fc50ed](https://github.com/omacom/omarchy/commit/4fc50ed43217f1b6a0bc961b40077085685933b1) Update translations (#19441)
- [c38c362](https://github.com/omacom/omarchy/commit/c38c3624827493ffea3fb7d5aa043877a3ce37b0) Update translations (#19443)
- [fc781d3](https://github.com/omacom/omarchy/commit/fc781d3ac15f650b1448569fbddc3985f633671b) Bring the omarchy skill up to date with current features and defaults (#19442)
- [53303e5](https://github.com/omacom/omarchy/commit/53303e5a060b8ec2541a172a6ec83f4f23c1b9c2) Update translations (#19502)
- [5381623](https://github.com/omacom/omarchy/commit/538162367bbca114edc5e8b38e7f202ff6730076) Keep the PipeWire camera in the browser flags on Snapdragon (#19498)
- [2eb7eb3](https://github.com/omacom/omarchy/commit/2eb7eb320a4eb03a721cbaf3fb3af1bc726404d6) Update translations (#19508)
- [b20d787](https://github.com/omacom/omarchy/commit/b20d7876f5ec6a45d18b9e4383dc4b6d9e8492ab) Keep colors in terminal windows an agent opens (#19507)
- [14b1ee1](https://github.com/omacom/omarchy/commit/14b1ee10bd88fce69f7dc17b3fc3bedf76be35b4) Restage the current theme so it picks up its packaged loops (#19563)
- [0c230d5](https://github.com/omacom/omarchy/commit/0c230d540d39ed2577953cf8781a170142e569be) Add Antigravity Desktop to Install > AI (#19557)
- [1eb7ed8](https://github.com/omacom/omarchy/commit/1eb7ed873a2e401e2ac5715142af1e7687245df0) Document that theme loops show their still on battery (#19565)
- [38b2ceb](https://github.com/omacom/omarchy/commit/38b2cebfa07111a3afd8104bbc29a2f3ebb1f0e8) format-drive: refuse non-block devices and report a failed format as a failure (#18784)
- [32baee9](https://github.com/omacom/omarchy/commit/32baee97d568dfe5c5da53d00ae5db5ca1cfa7bb) Focus the browser by its desktop entry's window class (#18640)
- [3edd803](https://github.com/omacom/omarchy/commit/3edd803107b84e1b4e24931e4bdcc730fe4be1c0) Keep commas in keybinding descriptions in the keybindings menu (#18348)
- [eda4adb](https://github.com/omacom/omarchy/commit/eda4adb32537046b3f58c3dd636e006a94a96fee) Leave unplugged inputs out of the audio panel, like unplugged outputs (#18725)
- [f458b57](https://github.com/omacom/omarchy/commit/f458b5757d1ad3710f6e41c2309b68c5495950f5) Turn off Quickshell's crash dialog for the supervised shell (#14331)
- [3869d66](https://github.com/omacom/omarchy/commit/3869d66520b65abed8292a249dc70f7ec06d202d) Keep the lock screen dark after a media key wakes it (#18595)
- [19fe283](https://github.com/omacom/omarchy/commit/19fe283404c387e027e31d91f776645c402456f5) Detect FocalTech match-on-chip fingerprint readers (#11387)
- [90cab2f](https://github.com/omacom/omarchy/commit/90cab2fc879ccedf2676250b3b47c98493199347) Update translations (#19569)
- [9aad31a](https://github.com/omacom/omarchy/commit/9aad31a99e4ef425b29ace421ce3d9bb10b8bc0d) Update translations (#19572)
- [ff6533e](https://github.com/omacom/omarchy/commit/ff6533ee8f8193bc181751fefb6182e9a7bffb93) Stop installing the iA Writer fonts (#19571)

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
