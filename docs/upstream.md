# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

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
