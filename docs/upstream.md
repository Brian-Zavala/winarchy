# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

## 2026-10-03

24 new commit(s) on omacom/omarchy@quattro, [b421b1b...a85e29a](https://github.com/omacom/omarchy/compare/b421b1b479ee9ea0863792282eee4ffeb50923dc...quattro).

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent`<br>`bin/omarchy-default-agent` | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-home`<br>`bin/omarchy-agent-account-list`<br>`bin/omarchy-agent-account-mode`<br>`bin/omarchy-agent-account-remove`<br>`bin/omarchy-agent-account-rename`<br>and 2 more | `lib/accounts.ps1` |
| Agent usage | `bin/omarchy-agent-usage-claude`<br>`bin/omarchy-agent-usage-codex`<br>`bin/omarchy-agent-usage-fireworks`<br>`bin/omarchy-agent-usage-grok`<br>`bin/omarchy-agent-usage-update` | `lib/agents/` |
| Install / Remove | `bin/omarchy-install-ai-openclaw`<br>`bin/omarchy-install-openclaw-cli`<br>`bin/omarchy-remove-ai-openclaw` | `lib/catalog.ps1` |
| Other commands | `bin/omarchy-openclaw-onboard` | `lib/` |
| Other | `default/agents/skills/omarchy-app/SKILL.md`<br>`default/agents/skills/omarchy-app/templates.md`<br>`default/bash/fns/agent-accounts` | - |
| Theming | `default/themed/neovim.lua.tpl` | `lib/render.ps1`<br>`lib/themes.ps1`<br>`lib/targets.ps1` |
| Upstream only | `install/omarchy-base.packages`<br>`install/user/mise.sh`<br>`migrations/1790397381.sh`<br>`migrations/1790702362.sh`<br>`migrations/1790702606.sh`<br>`migrations/1790863209.sh`<br>and 19 more | - |
| Manual | `manual/14-omarchy-cli.md`<br>`manual/17-ai.md` | `manual/14-winarchy-cli.md`<br>`manual/17-ai.md` |
| Shell (bar, menu, OSD) | `shell/Ui/PanelKeyCatcher.qml`<br>`shell/plugins/agents/Agent.qml`<br>`shell/plugins/agents/Main.qml`<br>`shell/plugins/agents/Panel.qml`<br>`shell/plugins/agents/README.md`<br>`shell/plugins/agents/assets/grok-light.svg`<br>and 3 more | `zebar/omarchy/` |

Commits:

- [6df574c](https://github.com/omacom/omarchy/commit/6df574cbb472340ba55b7c283e1df43466124159) fix(shell): keep __sourceDir on third-party plugin manifests
- [be18b32](https://github.com/omacom/omarchy/commit/be18b324f8e952523a0f94f8357b29e5c7eb5334) Install OpenClaw as the self-updating copy under ~/.openclaw
- [24d591d](https://github.com/omacom/omarchy/commit/24d591da14ca5bbd2013450006f912bdbd502318) Refuse before touching anything, and move an old gateway cleanly
- [44f5fd8](https://github.com/omacom/omarchy/commit/44f5fd8f0e53380cdd360066208ce885b6113364) Stop an old gateway before seeding, and refuse before installing
- [d2305ad](https://github.com/omacom/omarchy/commit/d2305add6a0ff88fe129cb473548f4fa3eceb459) Keep the OpenClaw that can open the state when removal keeps the state
- [8d25d6a](https://github.com/omacom/omarchy/commit/8d25d6aef3cc56df36f26fd5b979d1457aa20daf) Require a moved OpenClaw service to be running again
- [abf2f75](https://github.com/omacom/omarchy/commit/abf2f756f265ece1a9df476d142d3fcd4f6bcbc1) Judge a service by its program, and name any service left stopped
- [64e102a](https://github.com/omacom/omarchy/commit/64e102aaf2386427a77c323fdabf80ce29566e55) Keep OpenClaw's gateway probes off the wizard's terminal
- [b71b905](https://github.com/omacom/omarchy/commit/b71b905548fd584dda0d23472f81bca4d7676d8d) Revert "Keep OpenClaw's gateway probes off the wizard's terminal"
- [8942b0c](https://github.com/omacom/omarchy/commit/8942b0cd4c249ff760872cb6e96361e84526fd23) Keep a moved OpenClaw gateway on the runtime's own Node
- [72da1ec](https://github.com/omacom/omarchy/commit/72da1ec851132c0ba0d5162c77c78c32ec04674c) Move only services still on the old package's script or Node
- [9f0d464](https://github.com/omacom/omarchy/commit/9f0d4641bd121a9d49a36ef8c9b08e6617f56d21) Know the runtime's OpenClaw by its own script
- [de86454](https://github.com/omacom/omarchy/commit/de8645490b49f6476e53d2526914e2bac9d3d2de) Leave a moved OpenClaw service stopped or disabled if it was
- [9ace84e](https://github.com/omacom/omarchy/commit/9ace84e6c3d47d3a04acdf8ac806837c8adeabbe) Keep OpenClaw's gateway probes off the wizard's terminal
- [199ac6f](https://github.com/omacom/omarchy/commit/199ac6fc282e0b30852f9fa6d2026d7a7cfebcd9) Change the aether nvim part to the omacom org
- [8b4eae6](https://github.com/omacom/omarchy/commit/8b4eae66da2938ba9559f103b18dbf85cdf28a70) Merge pull request #13771 from omacom/fix-aether-nvim-path
- [146fe5d](https://github.com/omacom/omarchy/commit/146fe5d368966560affe3a7e79f64c9c3c366d14) Say only what is true in the __sourceDir comment
- [84e88b4](https://github.com/omacom/omarchy/commit/84e88b4a8e44c33692e3561d3a94f2b2306daa8b) Guard third-party manifests keeping __sourceDir
- [c05d901](https://github.com/omacom/omarchy/commit/c05d90196fc0dd5c21e2e797d80ffcc60d5e39fa) Switch between several Claude and Codex subscriptions, and build apps the Omarchy way (#13770)
- [f45461a](https://github.com/omacom/omarchy/commit/f45461a38f2b0a12ba39837eb41b08c012051780) Bring Grok up to par with Claude and Codex in the agents panel (#13992)
- [821ae58](https://github.com/omacom/omarchy/commit/821ae589059ffdadc970315f866c94b55d268af7) Reorder the agents in the panel, count Grok's tokens, and install Grok through mise (#14004)
- [75250d3](https://github.com/omacom/omarchy/commit/75250d37acdf19121efe2af85b3732b8cf248980) Fix Codex limits, Claude counting, and agent usage reliability from community PRs (#14049)
- [0537ae1](https://github.com/omacom/omarchy/commit/0537ae121b7a777db1c705649216580a2fb41ea8) Merge pull request #11925 from joewinke/fix/plugin-thirdparty-sourcedir
- [a85e29a](https://github.com/omacom/omarchy/commit/a85e29abb556816f4644cf975e98da694b486aa8) Merge pull request #13296 from omacom/openclaw-self-updating
