# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

## 2026-11-28

1797 new commit(s) on omacom/omarchy@quattro, [454b67d...5cf57af](https://github.com/omacom/omarchy/compare/454b67d95fd63c269c5315836a098038a0c61716...quattro).

Only the first 250 commits and 300 files fit in one comparison: follow the link for the rest.

**New Omarchy release: v4.5.0** (Winarchy tracked v4.0.4). Themes and backgrounds follow it; check its notes: https://github.com/omacom/omarchy/releases/tag/v4.5.0

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| Other | `.github/ci-qemu/Dockerfile`<br>`.github/pull_request_template.md`<br>`.github/workflows/ci-qemu-image.yml`<br>`.github/workflows/i18n-check.yml`<br>`.github/workflows/i18n-sync.yml`<br>`.github/workflows/test.yml`<br>and 71 more | - |
| Conventions | `AGENTS.md` | `AGENTS.md`<br>`docs/` |
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent`<br>`bin/omarchy-agent-crash`<br>`bin/omarchy-agent-instructions`<br>`bin/omarchy-agent-integrate-herdr`<br>`bin/omarchy-agent-launcher`<br>`bin/omarchy-agent-logo`<br>and 10 more | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-copy`<br>`bin/omarchy-agent-account-dispatch`<br>`bin/omarchy-agent-account-exec`<br>`bin/omarchy-agent-account-home`<br>`bin/omarchy-agent-account-list`<br>and 7 more | `lib/accounts.ps1` |
| Agent usage | `bin/omarchy-agent-usage-agy`<br>`bin/omarchy-agent-usage-claude`<br>`bin/omarchy-agent-usage-codex`<br>`bin/omarchy-agent-usage-copilot`<br>`bin/omarchy-agent-usage-cursor`<br>`bin/omarchy-agent-usage-deepseek`<br>and 18 more | `lib/agents/` |
| Other commands | `bin/omarchy-apply-fingerprint-pam`<br>`bin/omarchy-apply-gpu-memory`<br>`bin/omarchy-apply-hardware`<br>`bin/omarchy-apply-high-memory`<br>`bin/omarchy-apply-lock`<br>`bin/omarchy-apply-n1x-gpu-memory`<br>and 158 more | `lib/` |
| Launchers | `bin/omarchy-cmd-browser-handoff`<br>`bin/omarchy-cmd-default-browser`<br>`bin/omarchy-cmd-editor-mimetypes`<br>`bin/omarchy-cmd-terminal-cwd` | `ahk/launchers.ahk`<br>`ahk/menu.ahk` |

Commits:

- [3642699](https://github.com/omacom/omarchy/commit/36426992c4f2c4a275afb9bdc748e16a9e1559b0) Show host and drop swap and terminal from About (#20087)
- [5f1460d](https://github.com/omacom/omarchy/commit/5f1460d9f29f0c74d040847bf189ab7a19984d7c) Install coding agents and CLI tools as packages instead of mise tools (#19917)
- [556d88a](https://github.com/omacom/omarchy/commit/556d88a7e310b646746cc1d276b57eb15c89eae3) Find Install > CLI > GitHub by searching for ghui (#20092)
- [9ac6280](https://github.com/omacom/omarchy/commit/9ac6280b57f03c9cb5888c5ca61bb1045e6aefdd) Keep visible bars clickable around fullscreen windows (#19897)
- [c30863d](https://github.com/omacom/omarchy/commit/c30863db5b4c0fa9b085c261fa1cab98459f8286) Update translations (#20094)
- [53b0b4e](https://github.com/omacom/omarchy/commit/53b0b4e8544c74a159e61a04474e11030e7f6929) Update translations (#20098)
- [c2ea2d8](https://github.com/omacom/omarchy/commit/c2ea2d87ce0330a318c7bd9e8c6352b7bfa29d35) Isolate local AI models in app-models.slice so browsers and terminals stay responsive (#20095)
- [b20666c](https://github.com/omacom/omarchy/commit/b20666c209d52bba2793af0b011945076a24cb46) Ship the theme backgrounds from omarchy-themes-backgrounds (#20097)
- [81bf8c3](https://github.com/omacom/omarchy/commit/81bf8c3731290de8b2ad66097438f60d89b6f872) Install Basecamp and HEY in the installer terminal (#20093)
- [9ac88f5](https://github.com/omacom/omarchy/commit/9ac88f5f92b299a94103cfe9246443d51a954f5c) Update translations (#20102)
- [4ce79ac](https://github.com/omacom/omarchy/commit/4ce79ac068db98972dca9999cef093f1f4a2a011) Say where the unattended LUKS passphrase goes (#15321)
- [e279971](https://github.com/omacom/omarchy/commit/e27997133d51f36aa00b7c3b8cbbd0d52e7d2a1e) Update translations (#20104)
- [3b1a913](https://github.com/omacom/omarchy/commit/3b1a91306aae670640b49d0e334d7d5b5797d566) Detect N1x Dell XPS Synaptics haptic touchpad (DELL06CB:00) (#20108)
- [14504bf](https://github.com/omacom/omarchy/commit/14504bfd89ff3fbdc96ea49f5dbd1f035a151734) Add omarchy rollcall, a read-only hardware check run on the machine itself (#20107)
- [abfe1a7](https://github.com/omacom/omarchy/commit/abfe1a7036ee5a0cb17bc02b194d00334c10d9dc) Wait for SoundWire peripherals to enumerate before starting WirePlumber (#20117)
- [7c8822b](https://github.com/omacom/omarchy/commit/7c8822b04b33a5472faa8881212862be0a18e1ce) Show Recommended pill and inline download bar for local models in agents panel (#20113)
- [55f2709](https://github.com/omacom/omarchy/commit/55f2709c2bbe3e8a732a1118e4b5ad7bab124adb) Update translations (#20119)
- [cb15b1a](https://github.com/omacom/omarchy/commit/cb15b1ad7a00cb8a2b9fb033c885dee4340ad2b1) Offer Chromium users a switch to Google Chrome after updating (#20115)
- [e76a3cf](https://github.com/omacom/omarchy/commit/e76a3cf75e8800354c54d6fe9ee9155da6e10f73) Update translations (#20123)
- [8503ff1](https://github.com/omacom/omarchy/commit/8503ff15ec67ae1a97971cc94d0a2338a5d0ccd8) Add speaker tuning for the Dell XPS 16 (DX16263, N1x) (#20122)
- [d98664c](https://github.com/omacom/omarchy/commit/d98664c2ded6923172c610c38cedf81b14b4664f) Ask for encrypted drive passwords in the shell's password card (#20099)
- [61a1476](https://github.com/omacom/omarchy/commit/61a1476f2eeef1f65577b4a9370f2d69a96ebd5d) Update translations (#20125)
- [571d969](https://github.com/omacom/omarchy/commit/571d969e2df43bd828f6ccec164baa79b1c80886) Cap large screen recording regions to 4K so GPU H.264 is used (#20105)
- [cc5ea15](https://github.com/omacom/omarchy/commit/cc5ea151c02e3a5a819701c17da31eac9e58b7f2) Wait for DRM handoff from simpledrm before starting SDDM (#20059)
- [0696d92](https://github.com/omacom/omarchy/commit/0696d924652666138f26e36b3b1ef92efcce29b5) Recover dropped WirePlumber HiFi profile in omarchy-audio-tuning (#20153)
- [9703d6c](https://github.com/omacom/omarchy/commit/9703d6ced1aa40472b306c6cf825cb05065756da) Remove ghui (#20155)
- [4056b35](https://github.com/omacom/omarchy/commit/4056b357f769f069faabfb351d18b2b1d22472d0) Stop NSS host lookup falling back after systemd-resolved (#20128)
- [4dc3e4d](https://github.com/omacom/omarchy/commit/4dc3e4d1f61e57eaa7c51e392ce56c3640c1ab63) Close stdio on background snapshot cleanup in omarchy-theme-set (#20133)
- [0f333bf](https://github.com/omacom/omarchy/commit/0f333bfe8592f3fa6b982d7b6b854545199faa0c) Replace only exact --private tokens in omarchy-launch-browser (#20139)
- [8660f2f](https://github.com/omacom/omarchy/commit/8660f2fd42f60578dc89c9be6ecf653cb0d28394) Skip leaving toasts in notification invokeAction IPC (#20145)
- [a88b665](https://github.com/omacom/omarchy/commit/a88b665b1428780250e78d78c1c1781fdd25cfd5) Update translations (#20158)
- [c49f09b](https://github.com/omacom/omarchy/commit/c49f09b821bc5c189359ea6fa6d3d9d00c4c8746) Queue rapid monitor text-size updates and preserve slider preview on release (#20143)
- [c8217b8](https://github.com/omacom/omarchy/commit/c8217b8311b96c340f79e41dd270c4a1c3279e48) Eliminate redundant subprocess spawns on Hyprland reload and theme helpers (#20131)
- [c318b8c](https://github.com/omacom/omarchy/commit/c318b8cded05b1772d8a4124fb666e77d779f7a2) Use atomic pkill -x in app reloaders and guard foot pty writes (#20135)
- [3f5694e](https://github.com/omacom/omarchy/commit/3f5694e78a64c47da84c6abdaa3708c94ca51adc) Point git's GitHub credentials at the packaged gh (#20152)
- [a86d486](https://github.com/omacom/omarchy/commit/a86d486b5ca1d7da6408d6199a674fd3ea758171) Stop BackgroundIntro framePoll after persistent owe failures (#20137)
- [8f5d8f4](https://github.com/omacom/omarchy/commit/8f5d8f444fe3e2ff706034bf8476f77ba12f4da6) Guard worktree failures, support / in branch names, and parse lsw argv safely (#20146)
- [090417f](https://github.com/omacom/omarchy/commit/090417f6dc298068a35610ed60712dbe91ac4da4) Scan CLI command headers in one awk pass (#20132)
- [ab41ba5](https://github.com/omacom/omarchy/commit/ab41ba512666650ec17da1f3db15f786db51d53d) Cut fork overhead in hotkey, OSD, menu guard, and launcher scripts (#20134)
- [de5d1cd](https://github.com/omacom/omarchy/commit/de5d1cd61fb77a82a35e98877f4c4145da264765) Read clipboard history entries atomically in one jq call (#20140)
- [1e19589](https://github.com/omacom/omarchy/commit/1e195892405c5cf2c6c419a6f56a9c164be4bf41) Fix heredoc parsing, octal timing, and benchmark harness bugs (#20147)
- [b5cc041](https://github.com/omacom/omarchy/commit/b5cc04180af58bb6ac1de194613851c1c79d6d8f) Invalidate keybindings menu cache on Lua config edits (#20136)
- [394a861](https://github.com/omacom/omarchy/commit/394a861806999fe94edc022db1f74677b7cecfdc) Exit cleanly in omarchy-hyprland-window-pop when no window is focused (#20138)
- [46fb112](https://github.com/omacom/omarchy/commit/46fb11263ae833c241ef948c38bcfcacbecab0d2) Dismiss polkit and drive unlock dialog immediately on auth success or cancel (#20141)
- [8807715](https://github.com/omacom/omarchy/commit/8807715c71210071487c92afca594ba569219709) Make shell UI interactions snappier and cut redundant forks (#20126)
- [4918a61](https://github.com/omacom/omarchy/commit/4918a612da73bedbc19fc1683de9449a8d151c82) Speed up theme switcher, shell startup, icon scans, and brightness keys (#20129)
- [9ae3135](https://github.com/omacom/omarchy/commit/9ae313522b63c4ef58201ca07215a7960efc6330) Use p1 partition suffix for numeric-ending block devices in format-drive (#20142)
- [756adab](https://github.com/omacom/omarchy/commit/756adababb7378c21cd981a842c0bc2b1504278a) Remove workers=0 from foot.ini to restore multithreaded rendering (#20130)
- [cd496c9](https://github.com/omacom/omarchy/commit/cd496c97bce6901a483a17f9815df13cdda05392) Preserve caller nullglob setting in _omarchy_complete (#20144)
- [04cd61a](https://github.com/omacom/omarchy/commit/04cd61ae9efad52e407cc5b5639f88309cd20dad) Remove workers=0 from foot.ini to restore multithreaded rendering (#20130)
- [b8093ac](https://github.com/omacom/omarchy/commit/b8093ac32b75d5bbbae7a697043b2bdd474a408d) Speed up interactive bash startup and prompt hooks (#20127)
- [81f25a5](https://github.com/omacom/omarchy/commit/81f25a573f4b4933968c139b4fc32831f9973ec9) Use monotonic microsecond timing and 2x ratio for CLI alias timing guard (#20163)
- [5ea1f6c](https://github.com/omacom/omarchy/commit/5ea1f6cdaa0cea49e6ee80ce4c3df6aea4e2922c) Speed up hardware install pass and avoid premature package flushes (#20166)
- [f836723](https://github.com/omacom/omarchy/commit/f836723fe1ff953ff592d4745a6a715071851a4c) Keep newly set-up local models on the Agents panel index (#20167)
- [d93ceb9](https://github.com/omacom/omarchy/commit/d93ceb9e8fc392203dd1f622f48ecd455fe2a7b9) Say which drive a udisks format prompt is for (#20168)
- [10d8cfe](https://github.com/omacom/omarchy/commit/10d8cfe600127ac1abd4bdc91eea46d90cbbeb4b) Update translations (#20173)
- [5318bda](https://github.com/omacom/omarchy/commit/5318bdacaae7f9422c7f2fd0892fba62cd4f9b3f) Show which agent a polkit prompt comes from, and its label on two lines (#20103)
- [d9d2e3d](https://github.com/omacom/omarchy/commit/d9d2e3dbe4a1fcd1dcfc1a1a35324d07c6181eed) Update translations (#20174)
- [d4512a7](https://github.com/omacom/omarchy/commit/d4512a7559f7d96711fedeb1f4c4fd368b51de22) Wait for the delayed-launch events instead of fixed windows (#20170)
- [f767c7a](https://github.com/omacom/omarchy/commit/f767c7a6ceec2f5d1d8f533c69e341e2dedd3b1d) Speed up Qualcomm device tree hook and batch hardware packages (#20176)
- [448a1e0](https://github.com/omacom/omarchy/commit/448a1e09f28abf9a0921572428cf8f5867eed941) Add Thinking Machines Inkling mark for local models (#20191)
- [b64e765](https://github.com/omacom/omarchy/commit/b64e765f635e1f26f49a029ce363f9c0cc1b3101) Show CLI-installed local models on the Agents panel (#20192)
- [2dfb187](https://github.com/omacom/omarchy/commit/2dfb187fa02a0308dbe9c5920785bd884aa42bdf) Reclaim workspaces left without a monitor (#20185)
- [38cda63](https://github.com/omacom/omarchy/commit/38cda63f1974adf418c617e32591990d4597629f) Give the smoke test's direct panel IPC 10s and say why a call failed (#20193)
- [e0d083f](https://github.com/omacom/omarchy/commit/e0d083ff481c34da0293f9a542e7adfc7e4e0312) Keep an installed Node that provides nodejs when moving agents to packages (#20120)
- [c3108ac](https://github.com/omacom/omarchy/commit/c3108ac4231fd015601eda27ef1aae7df9992a44) Boot through systemd-boot, with snapshot boot and restore (#19667)
- [2d0311f](https://github.com/omacom/omarchy/commit/2d0311ffaa69fe3757232cfd3a83d5021c39c777) Update translations (#20197)
- [d020358](https://github.com/omacom/omarchy/commit/d0203589b677a523805774079781f3c41a5b7c85) Let a systemd-boot install store a pre-built initramfs (#20196)
- [6720124](https://github.com/omacom/omarchy/commit/6720124120c344a78915c8f33073351c52031d02) Update translations (#20198)
- [efa4198](https://github.com/omacom/omarchy/commit/efa4198771b5965ebdbb675861be197381a6f78e) Show remote model pairing status on the metadata line (#20195)
- [f989b43](https://github.com/omacom/omarchy/commit/f989b43e91ab16ce3675bd1ec5535e093e907ce0) Share the console keymap XKB table through the setup form (#20187)
- [e33c5a8](https://github.com/omacom/omarchy/commit/e33c5a8fe2b91a92857d960ee7295e92e25d8d32) Size the bar's surface to its strip (#20230)
- [6180516](https://github.com/omacom/omarchy/commit/618051603bd5b97576125cc3365cae39b30d8d57) Collapse newlines and prevent overflow in polkit justification pill (#20236)
- [a30167e](https://github.com/omacom/omarchy/commit/a30167e00caf0bd65ecd56dc22690917add7c974) Use two-line layout for all pkexec polkit prompts (#20240)
- [015974e](https://github.com/omacom/omarchy/commit/015974e819272a76ec9d7ac6732bea6390d2f300) Update translations (#20247)
- [8ecfdf2](https://github.com/omacom/omarchy/commit/8ecfdf235eb997f67cbdad7930a7c93482534b43) Restart the bar clock and calendar on a resync request
- [0eaa278](https://github.com/omacom/omarchy/commit/0eaa278b3e63515a97f0c6608923d7bd5b214ee3) Resync the bar clock when the system clock jumps
- [7872762](https://github.com/omacom/omarchy/commit/7872762674e27c86dec0e24845bfccb1b221ecc1) Check the timer is enabled only when the clock resync migration ran
- [e553671](https://github.com/omacom/omarchy/commit/e5536711bee05cc928c30349956c62f324b96cb6) Date the clock resync migration after the ones quattro has run
- [407d2a4](https://github.com/omacom/omarchy/commit/407d2a47288e52eb59572750ab8652904dffe451) Keep only the systemd unit check in the clock resync test
- [9ffdab6](https://github.com/omacom/omarchy/commit/9ffdab639e40a664d625d2182140a82938acb1d1) Catch WallClock up on resync instead of toggling enabled
- [790e824](https://github.com/omacom/omarchy/commit/790e82485f5ccadf28949ae37d8e94804a17af33) Settle the bar's surface only once it has a frame up, and never get stuck (#20246)
- [b7b2ddb](https://github.com/omacom/omarchy/commit/b7b2ddb67a3d9c1dd70254ab858c3b736566fbda) Ship the clock resync units from the settings package
- [6ccf303](https://github.com/omacom/omarchy/commit/6ccf30376b9a0018c1796257307802fbdbca217e) Date the clock resync migration after the newest on quattro
- [d2c2ec4](https://github.com/omacom/omarchy/commit/d2c2ec43f83faac4ddc0286c083138f7247ee0da) Drop the clock resync unit check
- [cf3dd6e](https://github.com/omacom/omarchy/commit/cf3dd6e1d135c614709eb899343fad746daf520b) Fail the clock resync check plainly when resync is missing
- [14e295c](https://github.com/omacom/omarchy/commit/14e295c64abeb349df4241825370bc5d8fc8de67) Install asus-zenbook-a16-support on the ASUS Zenbook A16 (UX3607OA) (#20251)
- [b6f920a](https://github.com/omacom/omarchy/commit/b6f920a16dbc82149c840f96ba3a25251485ab28) Let a global ISO's deferred install take its region from the owner's timezone (#20209)
- [0f24002](https://github.com/omacom/omarchy/commit/0f240028bab0c8e78588fec43c610c57fcdbf1c6) Merge pull request #20255 from omacom/clock-resync
- [991bc6e](https://github.com/omacom/omarchy/commit/991bc6ecf1e52590ac1ac9284af749943791add2) Install anduril-bluechip-support on the Anduril BlueChip (#20261)
- [82656f6](https://github.com/omacom/omarchy/commit/82656f6ccf05d9a69ae124b1b0dfca91e1846791) Add speaker tuning for the Flower Sakura (FRANQE0006) (#20272)
- [27bc972](https://github.com/omacom/omarchy/commit/27bc9726db4569d57e7ad7eebecc18cdf0a7a65b) Add speaker tuning task guide in agents/skills/audio-tuning.md (#20273)
- [b982dc9](https://github.com/omacom/omarchy/commit/b982dc9196b0975ee924021c500be6f5c59006ae) Keep the menu narrow during search (#20277)
- [982ea1e](https://github.com/omacom/omarchy/commit/982ea1eb025d597310f7b9ca30a9b2923c5580ac) Rebuild boot images on omarchy-settings upgrades only when initramfs inputs change (#20287)
- [7e5a6bf](https://github.com/omacom/omarchy/commit/7e5a6bf9d529e882e95ae633d3cee9982f9a3486) Hide provider sections while blank-slate picker is shown in agents panel (#20288)
- [a1dda99](https://github.com/omacom/omarchy/commit/a1dda991eeb52ac9c9d0c9fe7872d099cb4050e9) Improve ASUS Zenbook A16 (UX3607OA) speaker tuning with per-driver voicing (#20283)
- [155c4b4](https://github.com/omacom/omarchy/commit/155c4b4c01ddcb7aef8d05fc092129996749e6e4) Move camera relay and image tunings into userland (omarchy-camera-tuning) (#20290)
- [522d47a](https://github.com/omacom/omarchy/commit/522d47afee83cefd46485146a853c1f867f57d31) Fix flaky shell-idle-spawn and runtime-smoke startup/reload races (#20293)
- [aa02142](https://github.com/omacom/omarchy/commit/aa021422c3ba922573f5d4e6ac332db8a7c0bebe) Add Shure MV7+ microphone DSP bar panel (omarchy.mv7plus) (#20298)
- [7be712c](https://github.com/omacom/omarchy/commit/7be712c19eedde3ead89a96578c39e190e569ec2) Update translations (#20305)
- [6c426bf](https://github.com/omacom/omarchy/commit/6c426bf23c66419f8a2827adae7d44e4e18ea527) Add live camera tuning bar panel and zero-restart relay daemon (#20304)
- [24d317e](https://github.com/omacom/omarchy/commit/24d317e5d59f818b3d239d5be7529edf624b2165) Update translations (#20307)
- [44d3c21](https://github.com/omacom/omarchy/commit/44d3c21d77377fd72b8b31de09cbd29ea50b16be) Polish Shure MV7+ panel: High-Pass Filter dropdown and Reverb under Voice Processing (#20308)
- [7595356](https://github.com/omacom/omarchy/commit/759535689fbed92f55db397aaef14f4eff027c12) Add omarchy audio mv7plus CLI for Shure MV7+ onboard DSP (#20311)
- [7be2318](https://github.com/omacom/omarchy/commit/7be2318464a1abb3f7e5f2d8b318eaac7fb5e058) Update translations (#20313)
- [081715b](https://github.com/omacom/omarchy/commit/081715b584ec3c836e07d27e0be70e1de7418d93) Move Shure MV7+ HID logic into CLI and have panel call it (#20317)
- [1b95290](https://github.com/omacom/omarchy/commit/1b9529000afe092ceed9b5b09d854ed60b9c9133) Split aarch64-only packages and clean up install/omarchy-other.packages (#20292)
- [7f762a7](https://github.com/omacom/omarchy/commit/7f762a75a3628f05d07ed47d321e8970411058a6) Add live brightness, warmth, and tint controls to camera panel (#20315)
- [9c2792f](https://github.com/omacom/omarchy/commit/9c2792f405e9b2c43ba990ab4086c691a7705749) Update translations (#20318)
- [0c67de0](https://github.com/omacom/omarchy/commit/0c67de009c3e10fcc076d951692f606cc6d227a5) Stop autostarting herdr server on Hyprland launch (#20314)
- [9bacda1](https://github.com/omacom/omarchy/commit/9bacda1546240158334d253224ac973b081e565c) Expose all camera image controls via omarchy-camera CLI and route panel through it (#20319)
- [5180626](https://github.com/omacom/omarchy/commit/518062644565b3ebf0e380becf4c914e6d6eaaf1) Eliminate early-exit pipe races in setup-form.sh and setup-form-test.sh (#20321)
- [a43cedd](https://github.com/omacom/omarchy/commit/a43cedd24b225cdf3a9a5e364e5bb0be46578790) Add out-of-the-box web_search tool to Pi's default extensions (#20326)
- [f75565b](https://github.com/omacom/omarchy/commit/f75565babc0531084c19d6351120245afd3c8955) Include tr in the snapshot restore initramfs
- [9dfce75](https://github.com/omacom/omarchy/commit/9dfce75c064bcc3fa66c3241522ca7d04c15f922) Don't suspend a closed laptop on external power (#20325)
- [33dbabc](https://github.com/omacom/omarchy/commit/33dbabc9f34814ac1f82adb8efb60c8720f308e3) Update translations (#20334)
- [c921707](https://github.com/omacom/omarchy/commit/c921707f610eebcedaa94c43e4133b42760627f8) Enable Panel Self Refresh on the ASUS Zenbook A16 (UX3607OA) (#20336)
- [5cdb507](https://github.com/omacom/omarchy/commit/5cdb507d23f30abc559e11899cca3961990d0338) Use the same editor icons under Install > Editor as under Setup > Defaults > Editor (#20338)
- [c304e8c](https://github.com/omacom/omarchy/commit/c304e8ca12ea6f9cc00de8e833c492db4e66e599) Enable Wi-Fi power save on the ASUS Zenbook A16 (UX3607OA) (#20339)
- [10870ca](https://github.com/omacom/omarchy/commit/10870ca4861735d55084082ff997e702d8bedd5e) Add a full-screen fingerprint setup panel (#20337)
- [6a2c2de](https://github.com/omacom/omarchy/commit/6a2c2de936a11dddf46ed6b543b9f17668eae856) Update translations (#20341)
- [d4779d4](https://github.com/omacom/omarchy/commit/d4779d424377f3c8490eded07d66d504a622869e) Teach agents to give pkexec a reason for its password dialog (#20239)
- [c5fbeec](https://github.com/omacom/omarchy/commit/c5fbeec6e9edff616d22c9899d4a5252f755a879) Add omarchy bluetooth CLI command (#20332)
- [03e6707](https://github.com/omacom/omarchy/commit/03e6707141bb687304087a571335bc2a8e7eb856) Add omarchy network wifi and ethernet CLI commands (#20331)
- [c9af681](https://github.com/omacom/omarchy/commit/c9af681cbadc2a17d7fe3eb72a2caf1b43738d17) Keep progress icon layout single-pass and bound finish sweep
- [960f772](https://github.com/omacom/omarchy/commit/960f77263bb0cc3049c430b615eb90ec980d1ffb) Use arithmetic checks and restore term_size helper in progress-icon test
- [b9b627a](https://github.com/omacom/omarchy/commit/b9b627aa4491c57ed9695cd6f2c6818a37779b2c) Merge pull request #20346 from omacom/perf/progress-icon-finish
- [c60aaf0](https://github.com/omacom/omarchy/commit/c60aaf0ca9a54a0f927a730a794da841083ad14c) Merge pull request #20329 from omacom/fix/issue-20324
- [9b1c2f3](https://github.com/omacom/omarchy/commit/9b1c2f30f9941c44540b21e4613e4dd8e74eef79) Fix Wi-Fi connect failing on nmcli autoconnect save prompt
- [c63f32f](https://github.com/omacom/omarchy/commit/c63f32f7ad994d6b3ddb1a2e600602cb8e37fe46) Use command -v instead of omarchy-cmd-present in omarchy-upload-log
- [745271c](https://github.com/omacom/omarchy/commit/745271ccd293fc2e7a233b269004a9926a5c6cb4) Merge pull request #20351 from omacom/fix/network-wifi-autoconnect
- [bacc2ac](https://github.com/omacom/omarchy/commit/bacc2acddef471d2f08331fd7930acbf90dd96aa) Source base-test.sh and follow [[ ]] quoting in upload-log-test.sh
- [2ebf597](https://github.com/omacom/omarchy/commit/2ebf5971a41af5f39dcce36331e4cb2cf840cc53) Merge pull request #20352 from omacom/fix/upload-log-cmd-present
- [a11b6a6](https://github.com/omacom/omarchy/commit/a11b6a601579aa026db3231c161f80bb7882ead0) Reset partial shell palettes on reload and select clicked dropdown rows (#20353)
- [0d03063](https://github.com/omacom/omarchy/commit/0d03063cd1af0c2cd61decf43cff1d2525e8560a) Enable Intel HWP dynamic boost for snappier I/O wakeups (#20377)
- [aed2a30](https://github.com/omacom/omarchy/commit/aed2a30ecead18cee9c9557c1e7ba4e7097dab18) Remove Arch, Neovim, Bash and Tmux from the Learn menu (#20383)
- [7da2568](https://github.com/omacom/omarchy/commit/7da2568266bc396caf9cd1a5a953d4b443561cc3) Delete pre-switch snapshots when the move to systemd-boot finishes (#20386)
- [d360a0b](https://github.com/omacom/omarchy/commit/d360a0b37e9660253ae5efd6736057e8616e4d42) Block only hci* rfkill switches when turning Bluetooth off (#20378)
- [ecd8a53](https://github.com/omacom/omarchy/commit/ecd8a5324ae5668695d4b8cd3a0bd4fe8c7bdf23) Polish spacing and alignment in the bar panels (#20389)
- [295e8b2](https://github.com/omacom/omarchy/commit/295e8b28a687f195b138c808bf7f0c77336cb03d) Cache mise hook-env across rapid idle prompts (#20395)
- [039b1f0](https://github.com/omacom/omarchy/commit/039b1f0ce56e9beef01a30fa7487eac712bde367) Enable intel-lpmd dynamic WLT optimization on Meteor Lake laptops (#20393)
- [f7bdd83](https://github.com/omacom/omarchy/commit/f7bdd8378e5e14463e4c5587e747feede409489c) Add sleep drain visibility, battery health, and charge limit to power panel (#20379)
- [4f7e813](https://github.com/omacom/omarchy/commit/4f7e81385daef1e650809ae36d8bb29c7173485f) Enable intel-lpmd on Arrow Lake-U and Wildcat Lake Intel laptops (#20397)
- [481f66a](https://github.com/omacom/omarchy/commit/481f66abf894431a044a7459e828a351f5b95ace) Update translations (#20398)
- [d461b92](https://github.com/omacom/omarchy/commit/d461b9261c432a3b509756a2b19c85aa01093b7d) Make the look tools and make skills work for agents on local models (#20203)
- [e6b8386](https://github.com/omacom/omarchy/commit/e6b8386b94b3a54c58cdff36c0348ddb81ed6de5) Repair Git credentials left pointing at the retired gh shim (#20362)
- [cbd7139](https://github.com/omacom/omarchy/commit/cbd7139ac67b8ef421cf828507ac6f59e02c7c9b) Build plugin services before panels and bar widgets load (#20396)
- [43821cb](https://github.com/omacom/omarchy/commit/43821cb7e0fb0c93af67aa8f1b145f7a4d651407) Enable hardware video decode and encode in Chromium-based browsers (#20376)
- [8e92b74](https://github.com/omacom/omarchy/commit/8e92b74491425d37cb138526a550944b21420c79) Enable Wi-Fi power save on Intel Meteor Lake CNVi Wi-Fi 6E (AX211) (#20394)
- [f5438c9](https://github.com/omacom/omarchy/commit/f5438c96d0248998255b9e26941463dd33f2ccb4) Disable NMI watchdog to save power (#20392)
- [3c8da43](https://github.com/omacom/omarchy/commit/3c8da43aa93ec1c41a87705dd6e251e0a24884a1) Avoid whole-filesystem syncfs and reflink boot image imports (#20238)
- [aeda788](https://github.com/omacom/omarchy/commit/aeda788b633dea408b10bc80eeff316896c37636) Remove the Image Viewer launcher even when the user changed it (#20402)
- [0ca92c3](https://github.com/omacom/omarchy/commit/0ca92c3c460cacd2b768e4e55ae3a8c42211455b) Ask for the password once when switching channel (#20403)
- [e0ac77d](https://github.com/omacom/omarchy/commit/e0ac77dc5301103463e423c9ba6032635790ee1f) Allow process-wide GPU/Wayland flags and parse flags in pure bash in browser handoff (#20390)
- [438a59c](https://github.com/omacom/omarchy/commit/438a59c67f743ee79ae26c5fb45bdd0a6ede3c72) Defer Wi-Fi scanner disable past Network panel close fade (#20399)
- [48f622d](https://github.com/omacom/omarchy/commit/48f622d089644ed380ea28f96df2c119c3ec9177) Extend terminal fast path to --app-id and TUI launches (#20400)
- [c1b2b03](https://github.com/omacom/omarchy/commit/c1b2b03d457f4c134420c7a294cee025f7005434) Eliminate Agents panel open and usage-update stalls (#20401)
- [fa897dc](https://github.com/omacom/omarchy/commit/fa897dc0544cd7520ad4f22bcc1cb8597db242ea) Use Qt6 VCL backend for LibreOffice (#20391)
- [105d18d](https://github.com/omacom/omarchy/commit/105d18d537c208c563083e6b45570a67d874b374) Add Passwordless Login to Setup > Security (#20406)
- [b02dd99](https://github.com/omacom/omarchy/commit/b02dd992d37ca09299e0aa3c0f18850bd8bf49ce) Show tooltips on bar indicator icons (#19205)
- [41cb7fd](https://github.com/omacom/omarchy/commit/41cb7fd2b0b055babb8ea6ec114985567753a17f) Update translations (#20415)
- [67c1fee](https://github.com/omacom/omarchy/commit/67c1fee658ab6b618d2f651b2c14fe5900cf8ff7) Keep balanced power profile on balance_performance when on battery (#20384)
- [4a2de62](https://github.com/omacom/omarchy/commit/4a2de629c77fcbfc65fde5ebc5955d054b9202bd) Load on-demand overlays and unplaced bar widgets lazily (#20410)
- [a9f721d](https://github.com/omacom/omarchy/commit/a9f721d93d911f7cecf0fceb4ef2edf683e60a48) Skip spawning Python input-method watcher on single-layout installs (#20411)
- [fd25d60](https://github.com/omacom/omarchy/commit/fd25d608b94a879e158e8f60b3937a65abc791f8) Replace Python udiskie with lightweight UDisks2 automounter (#20412)
- [9c6677e](https://github.com/omacom/omarchy/commit/9c6677eab095e231ed182ef8f0d00866cfeafb74) Set transparent huge pages to madvise and cap systemd journal size (#20414)
- [44ff206](https://github.com/omacom/omarchy/commit/44ff2065a10af681f0180a0c784a1fd79aafc8e6) Re-enable deep sleep (s2idle) on the ASUS Zenbook A16 (UX3607OA) (#20416)
- [ca4a0fb](https://github.com/omacom/omarchy/commit/ca4a0fb908a37baa33d349452efeb0e706044d46) Update translations (#20419)
- [33c2f66](https://github.com/omacom/omarchy/commit/33c2f660f93f12d45b147658ccea6a678038a738) Tune shell jemalloc and unmap idle dock surface (#20409)
- [10287a4](https://github.com/omacom/omarchy/commit/10287a47259da6338ee225a137f9e3f1ef58b129) Tune zram and swappiness for 8 GiB machines (#20420)
- [06ea210](https://github.com/omacom/omarchy/commit/06ea210feca4548c3ce01686759a2c9660dfc6e6) Enable browser Memory Saver policy on 8 GiB machines (#20421)
- [30831d8](https://github.com/omacom/omarchy/commit/30831d8b89be34d5433010ca0bd53e059dc0b575) Socket-activate CUPS instead of running cupsd eagerly at boot (#20422)
- [6369500](https://github.com/omacom/omarchy/commit/63695003a60475a94549c23d940444d0379d2b72) Enable Panel Self Refresh on the Anduril BlueChip (#20423)
- [f5b4db6](https://github.com/omacom/omarchy/commit/f5b4db67c6476234b09085e12dc0f768d98925b1) Shorten Hardware menu labels so they fit without clipping (#20425)
- [9c384c3](https://github.com/omacom/omarchy/commit/9c384c39d3326c01e5ecb76be7abec558d98dc6f) Update translations (#20433)
- [dbc3aea](https://github.com/omacom/omarchy/commit/dbc3aeaf144957672083fc2f70a44254929f5cd3) Protect session.slice file cache with MemoryLow and tighten oomd pressure response (#20426)
- [4e1ee51](https://github.com/omacom/omarchy/commit/4e1ee517e3f8aebb6bff54741e2d40c2bd45d00a) Enable power tuning and PSCI deep sleep on the ASUS Zenbook 14 (UX3480QA) (#20434)
- [5c799c2](https://github.com/omacom/omarchy/commit/5c799c21ea0b7b152da65b365d11ca9c794821d8) Add Snapdragon power and sleep tuning task guide (#20443)
- [1da3ffd](https://github.com/omacom/omarchy/commit/1da3ffdad35c55ce1aebf4f8b5d1fab5507d43b7) Add an Anduril BlueChip theme offered only on that machine (#20439)
- [37eb0a3](https://github.com/omacom/omarchy/commit/37eb0a3bd7fbf20cb6226e1847eb858fb90fa187) Skip sleep and lid-close lock when passwordless login is active (#20448)
- [0d22517](https://github.com/omacom/omarchy/commit/0d225171ef6c2141002f758e298db2bbc5c1f018) Cap app-graphical.slice MemoryMax at boot on >=56 GiB hosts (64 GiB+ RAM) (#20437)
- [eac590b](https://github.com/omacom/omarchy/commit/eac590b60a0f20fbb92d242be76f01fbcc5f86df) Start the Anduril BlueChip on its own unlock screen (#20449)
- [7f81f1b](https://github.com/omacom/omarchy/commit/7f81f1b6bc167ded2111af5d198f0ce4b4cf522e) Notify clearly on out-of-memory kills instead of reporting a crash (#20446)
- [9a3b533](https://github.com/omacom/omarchy/commit/9a3b533adfaa8ff7f300c702c91d9dcff7d7e55c) Update translations (#20455)
- [8f191d8](https://github.com/omacom/omarchy/commit/8f191d827465cb089f4b73b4a5cdc125d6017e18) Add one-shot omarchy agent resume for next login (#20454)
- [97a2b2a](https://github.com/omacom/omarchy/commit/97a2b2acbf1c6468dae0a6cb3cc8f6adffffe888) Update translations (#20458)
- [7abc952](https://github.com/omacom/omarchy/commit/7abc952fd766eaf5ff5414093a3ba5bc8d76ada2) Put mise shims ahead of system binaries in login shells and SSH commands (#20430)
- [b01e8b1](https://github.com/omacom/omarchy/commit/b01e8b11604447377c163c2f00044511c7c2c8d7) Unlock encrypted drives with a keyfile before asking for the password (#20457)
- [495ea05](https://github.com/omacom/omarchy/commit/495ea05bd865b2ba073be2141cc70d732f34fa64) Update translations (#20461)
- [a1d7fc1](https://github.com/omacom/omarchy/commit/a1d7fc1a8d285702d687f0ae85ea66d95205de53) Start Steam games under Proton fullscreen (#20451)
- [153d177](https://github.com/omacom/omarchy/commit/153d177e70f6921b5e01b3e71a4a646ea7441ce9) Print a status line before sudo in floating terminal commands (#20462)
- [12ffcf2](https://github.com/omacom/omarchy/commit/12ffcf2c060182b8653b40b1f8b71ffdbf8ad700) Retire obsolete Dell XPS 13 DX13260 audio workarounds (#20466)
- [d0e2275](https://github.com/omacom/omarchy/commit/d0e2275add0648faa2065613e57fc70115d82c8e) Turn off Hyprland's update and donation screens on the login screen
- [ea58387](https://github.com/omacom/omarchy/commit/ea5838709b4558425b662ed3a14095f0b9be7b2f) Show progressive CLI install status in Agents panel (#20467)
- [6cf7a93](https://github.com/omacom/omarchy/commit/6cf7a9324b423bfd28984d4f3d4f55c029832197) Update translations (#20470)
- [f7e2d87](https://github.com/omacom/omarchy/commit/f7e2d873c228eb94fc1114939debdddce3aea1a0) Avoid SIGPIPE in test/shell slowest-tests summary (#20469)
- [9112065](https://github.com/omacom/omarchy/commit/9112065e6d27634419c1296220a116751398598a) Merge pull request #20471 from omacom/sddm-no-hyprland-popups
- [c0987ea](https://github.com/omacom/omarchy/commit/c0987eac74a5454b5dc98eb2dffdbacc1cc2a34c) Remove the .NET 9 runtime that now fails omarchy update (#20447)
- [e2559a4](https://github.com/omacom/omarchy/commit/e2559a478a9d56da82752cb28064ad61702ad76f) Filter Agents panel provider picker for China region (#20476)
- [7d682dd](https://github.com/omacom/omarchy/commit/7d682ddb38d499ce02ddab732333252085d71fe1) Label the Chrome offer's dismiss button Don't Switch
- [03ae9f6](https://github.com/omacom/omarchy/commit/03ae9f6276bcca0f236c2c669113777a86c8422d) Merge pull request #20478 from omacom/chrome-offer-dont-switch
- [c56cbe9](https://github.com/omacom/omarchy/commit/c56cbe9235d9eea93d4963283effca5b980e40ef) Update translations (#20479)
- [fa265f4](https://github.com/omacom/omarchy/commit/fa265f4f28353b0683a64a69421ff751421a6f32) Show the Omarchy icon on black when shutting down or rebooting (#20489)
- [cafb698](https://github.com/omacom/omarchy/commit/cafb6981b6ebfbac8fc7164b32f94f20397f731c) Keep a machine's own agent CLIs out of the agent account test (#20463)
- [1853cae](https://github.com/omacom/omarchy/commit/1853caea765d1f5298b89b86dbfc692e14594795) Fall back to fbdev in kmscon on Snapdragon msm DRM
- [ffe7fa8](https://github.com/omacom/omarchy/commit/ffe7fa8722febcd9706fac5ad2ac28b77cc4bc24) Skip live udev reload in Zenbook 14 UX3480QA power script during install
- [4954aa6](https://github.com/omacom/omarchy/commit/4954aa645eb2531a17fa3cebc0a7a89025c42643) Quote msmdrmfb literal in kmscon framebuffer check
- [8b6b909](https://github.com/omacom/omarchy/commit/8b6b909562dadc968078be4066cc8da74a7dfa1d) Detect install chroot via systemd-detect-virt --chroot
- [d90e533](https://github.com/omacom/omarchy/commit/d90e53383556a53147664907d2f3c3063d225c5b) Migrate linux-omarchy machines from v4l2loopback-dkms to linux-omarchy-v4l2loopback (#20526)
- [f9ba2ff](https://github.com/omacom/omarchy/commit/f9ba2ffd918de5e2792e16b3d6a0a2a4d14670bc) Disable sudo first-time lecture (#20531)
- [d019047](https://github.com/omacom/omarchy/commit/d0190471dc347c3ff84a16155d310e857f82296a) Replace Plymouth with the Omarchy boot splash, and SDDM with greetd's login screen (#20404)
- [447f798](https://github.com/omacom/omarchy/commit/447f798874a7d61d3db8e74dc30a2ca49118f630) Update translations (#20534)
- [5a2b6cc](https://github.com/omacom/omarchy/commit/5a2b6cc2d1596dac13316527b0eb044d4f36aa81) Scope Zenbook 14 UX3480QA USB runtime PM to internal webcam controller
- [f84b3bd](https://github.com/omacom/omarchy/commit/f84b3bd9e8a5ee3aa3918ed95ebca61a7556d376) Size single-line notification toasts dynamically to their content (#20532)
- [5f03dfb](https://github.com/omacom/omarchy/commit/5f03dfb6b7937754d81a32cc912a73df889e8967) Check live USB PM state in UX3480QA migration and test behavior
- [19c5056](https://github.com/omacom/omarchy/commit/19c505658b20d084eeca2a4400b39b21f32ac46b) Drop migration cases from permanent shell test suite
- [aa68269](https://github.com/omacom/omarchy/commit/aa682694b8230b91ed18bb8bbecedff623b31e64) Add Ladybird to the browser install, remove, and default menus (#20537)
- [b80cec5](https://github.com/omacom/omarchy/commit/b80cec5300545f04fba353c3fef47d4294bf8f7e) Merge pull request #20512 from omacom/fix/kmscon-snapdragon-fbdev
- [23a195a](https://github.com/omacom/omarchy/commit/23a195a2d93f8ba2e0dc33469e7cde9670a347a8) Merge pull request #20513 from omacom/fix/zenbook-power-udev-chroot
- [277c4c3](https://github.com/omacom/omarchy/commit/277c4c34f43d2dbfea646ecc58eeb1b23c270b10) Update translations (#20538)
- [36b383e](https://github.com/omacom/omarchy/commit/36b383ecf75fc1261c246f4653002a2243a8f88f) Follow pointer movement in the image picker carousel (#20544)
- [cc0be74](https://github.com/omacom/omarchy/commit/cc0be74d2fc5d1c755a2fc44466276f5c8966486) Share desktop still wallpaper cache with lock screen (#20543)
- [c70066f](https://github.com/omacom/omarchy/commit/c70066fe702df5b2ba64bc5d6c01f8aa152dc94f) Fix QML syntax, layout positioning, and equality lint warnings (#20547)
- [41912a5](https://github.com/omacom/omarchy/commit/41912a5c659ed16f1fd4b6e9a7b0548ae984e258) Remove unused QML imports from shell (#20556)
- [7e2c163](https://github.com/omacom/omarchy/commit/7e2c163e030ec69726bcf704b6d3e8d6afcd0cde) Enforce qmllint on shell QML files in CI (#20549)
- [05fc23b](https://github.com/omacom/omarchy/commit/05fc23b07f9e7cfc432e382575f6ddbf9d262ac9) Wait for boot splash readiness before switch_root (#20555)
- [fe8fa08](https://github.com/omacom/omarchy/commit/fe8fa08ef70f403f2cceb7c1a5413718e8e908f3) Fix trackpad in boot splash initramfs and add Tab / Shift+Tab shortcuts (#20550)
- [172e470](https://github.com/omacom/omarchy/commit/172e4706c15c5ebebe3b69ae4ca36a505b1a1a13) Start a clear bar clear (#20536)
- [eb3bc1d](https://github.com/omacom/omarchy/commit/eb3bc1d86bddeee2167ef51b90da557f9d26e918) Floating titlebars everywhere, and a dock on every workspace (#20529)
- [1ac6ee4](https://github.com/omacom/omarchy/commit/1ac6ee49f73bfb1c1b4cccd4e0cc4f5bd4e613a1) Update translations (#20566)
- [4212df4](https://github.com/omacom/omarchy/commit/4212df48a9de28bcb745f469689537337ad40f5a) Start the dock at the bottom again (#20569)
- [573da40](https://github.com/omacom/omarchy/commit/573da409e0e65db3bbc54e34592bd8b4d5efd342) Update translations (#20573)
- [aaf366a](https://github.com/omacom/omarchy/commit/aaf366af074e190872e5c4c6f43c03f1cce6abb8) Let the dock's visibility be chosen (#20572)
- [690ded5](https://github.com/omacom/omarchy/commit/690ded58a92a898189389c7b43e17f3b65f31614) Tile main Steam window and fullscreen native Linux Steam games (#20552)
- [59c292c](https://github.com/omacom/omarchy/commit/59c292c49f26d6ceb075e9587b4c4f812b629ab3) Update translations (#20576)
- [a65cfcb](https://github.com/omacom/omarchy/commit/a65cfcb5fe6d5f46f4c67974167ba3ce895b4260) Update default dock pinned apps (#20567)
- [5735046](https://github.com/omacom/omarchy/commit/5735046ee0027dbb5ff0f962fc48a3fbfea5a07a) Reveal a Cancel pill on mouse movement in the Polkit prompt (#20559)
- [6331838](https://github.com/omacom/omarchy/commit/633183879c648978ab8e6b33a3ca3c54e5bb24bc) Update translations (#20577)
- [493eb31](https://github.com/omacom/omarchy/commit/493eb3160879359ff07334dc1b55791ca47ba8f1) Fade straight from desktop to logo screen on shutdown and reboot (#20574)
- [f04c859](https://github.com/omacom/omarchy/commit/f04c859934442a71066fcb44574a00b6673b622c) Give Chromium browsers Omarchy's titlebar on the system title bar, and show app icons (#20557)
- [e905096](https://github.com/omacom/omarchy/commit/e905096342c35eecd2ecd3b60b22ec7f40654222) Fix mouse cursor, context menu, and emoji scroll in shell (#20558)
- [62e0d5e](https://github.com/omacom/omarchy/commit/62e0d5ed5a2137347790cacac6d5609a7282a611) Add mouse remove and inline submit buttons in the Agents panel (#20561)
- [5d2997d](https://github.com/omacom/omarchy/commit/5d2997d972a91e651d91b988274832614d440b4e) Fix mouse interaction issues across Clock, Network, Weather, Elsewhen, and Tailscale panels (#20562)
- [703e2e6](https://github.com/omacom/omarchy/commit/703e2e63d69a6d23e61c17fe0cf6ee7b60679a32) Fix mouse tooltips, tray popup, slider wheel, and dropdown hover/scroll (#20563)
- [d5bcf04](https://github.com/omacom/omarchy/commit/d5bcf0433a2aca7d0de641731030afe131a70821) Add mouse back/uninstall in Menu and mouse actions/scroll in Clipboard (#20560)
- [47204bb](https://github.com/omacom/omarchy/commit/47204bb7d20c6b054b9065c55c2acbc0f6222511) Switch existing Chromium profiles to the system title bar (#20583)
- [69817fd](https://github.com/omacom/omarchy/commit/69817fda0fe4e099f9414a337bee0202d87772c6) Update translations (#20592)
- [8ebf389](https://github.com/omacom/omarchy/commit/8ebf3896e3425f4d0cd1263371b906f374b28ad0) Unlink disk speed test scratch files on open (#20590)
- [561d1b4](https://github.com/omacom/omarchy/commit/561d1b4d612c09cda48a8b3920af57a2c6034b5a) Add speaker tuning for the ASUS Zenbook 14 (UX3480QA) (#20541)
- [5cf57af](https://github.com/omacom/omarchy/commit/5cf57afc6bda663f25eb4af5b732b3f395ccb5ed) Own org.freedesktop.ScreenSaver in the idle service (#20606)

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
