# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

## 2026-10-17

270 new commit(s) on omacom/omarchy@quattro, [454b67d...cce8b1c](https://github.com/omacom/omarchy/compare/454b67d95fd63c269c5315836a098038a0c61716...quattro).

Only the first 250 commits and 300 files fit in one comparison: follow the link for the rest.

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| Other | `.github/workflows/i18n-check.yml`<br>`.github/workflows/i18n-sync.yml`<br>`agents/skills/install-scripts.md`<br>`agents/skills/shell-dev.md`<br>`applications/Basecamp.desktop`<br>`applications/Discord.desktop`<br>and 50 more | - |
| Conventions | `AGENTS.md` | `AGENTS.md`<br>`docs/` |
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent`<br>`bin/omarchy-default-agent` | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-copy`<br>`bin/omarchy-agent-account-exec`<br>`bin/omarchy-agent-account-home`<br>`bin/omarchy-agent-account-state`<br>`bin/omarchy-agent-account-transfer`<br>and 1 more | `lib/accounts.ps1` |
| Agent usage | `bin/omarchy-agent-usage-kimi`<br>`bin/omarchy-agent-usage-update` | `lib/agents/` |
| Other commands | `bin/omarchy-apply-hardware`<br>`bin/omarchy-apply-lock`<br>`bin/omarchy-apply-n1x-gpu-memory`<br>`bin/omarchy-audio-input-mute`<br>`bin/omarchy-audio-input-set-default`<br>`bin/omarchy-audio-output-set-default`<br>and 148 more | `lib/` |
| Launchers | `bin/omarchy-cmd-browser-handoff`<br>`bin/omarchy-cmd-default-browser`<br>`bin/omarchy-launch-browser`<br>`bin/omarchy-launch-config-editor`<br>`bin/omarchy-launch-screensaver`<br>`bin/omarchy-launch-shell` | `ahk/launchers.ahk`<br>`ahk/menu.ahk` |
| Install / Remove | `bin/omarchy-install-browser`<br>`bin/omarchy-install-dev-env`<br>`bin/omarchy-install-dictation-superwhisper`<br>`bin/omarchy-install-dictation-voxtype`<br>`bin/omarchy-install-docker-dbs`<br>`bin/omarchy-install-gaming-battlenet`<br>and 21 more | `lib/catalog.ps1` |
| Menu | `bin/omarchy-menu-herdr-keybindings`<br>`bin/omarchy-menu-keybindings`<br>`bin/omarchy-menu-plugin`<br>`bin/omarchy-menu-select`<br>`bin/omarchy-menu-share`<br>`bin/omarchy-menu-timezone`<br>and 1 more | `zebar/omarchy/menu.json`<br>`zebar/omarchy/menu.js`<br>`ahk/menu.ahk` |
| Theming | `bin/omarchy-theme-bg-boot-intro`<br>`bin/omarchy-theme-bg-intro`<br>`bin/omarchy-theme-bg-next`<br>`bin/omarchy-theme-bg-set`<br>`bin/omarchy-theme-install`<br>`bin/omarchy-theme-refresh`<br>and 11 more | `lib/render.ps1`<br>`lib/themes.ps1`<br>`lib/targets.ps1` |
| Toggles | `bin/omarchy-toggle-animations`<br>`bin/omarchy-toggle-bar`<br>`bin/omarchy-toggle-crash-capture`<br>`bin/omarchy-toggle-hybrid-gpu`<br>`bin/omarchy-toggle-input-device`<br>`bin/omarchy-toggle-nightlight`<br>and 3 more | `ahk/winarchy.ahk`<br>`ahk/menu.ahk` |
| Herdr and shell | `config/herdr/config.toml` | `lib/herdr.ps1`<br>`templates/herdr.toml.tpl`<br>`lib/agents.ps1` |
| Top bar | `config/omarchy/shell.json` | `zebar/omarchy/bar.html`<br>`zebar/omarchy/bar.css` |
| Window manager | `default/hypr/apps/browser.lua`<br>`default/hypr/apps/davinci-resolve.lua`<br>`default/hypr/apps/hermes.lua`<br>`default/hypr/apps/localsend.lua`<br>`default/hypr/apps/omarchy-shell.lua`<br>`default/hypr/apps/pip.lua`<br>and 3 more | `templates/glazewm.yaml.tpl`<br>`ahk/winarchy.ahk` |

Commits:

- [60d6b25](https://github.com/omacom/omarchy/commit/60d6b255da422592c63234903fc908104247c2e6) Require approval for new Thunderbolt accessories
- [c3cdcb1](https://github.com/omacom/omarchy/commit/c3cdcb1e826a5655f87eeb787a5b28ad6e5c892b) Keep USB approvals portable and preserve approval prompts
- [aeeacce](https://github.com/omacom/omarchy/commit/aeeacce566fd62ceeddf01c662e34d3e8b06fe19) Name apple-bcm-firmware-fetcher in the T2 package list
- [25db463](https://github.com/omacom/omarchy/commit/25db463cd9b509340ed006e29d3e5d7365fa6784) fix(t2): drop the superseded firmware package before adding the fetcher
- [45d2e80](https://github.com/omacom/omarchy/commit/45d2e807db5c4c4bde14d1c0b28e8cc3e57d5c68) Install the Dell XPS 13 Panther Lake speaker firmware
- [89fcd6a](https://github.com/omacom/omarchy/commit/89fcd6a1b78ae699965121c9a1b56eea14f0133f) Keep the firmware reboot marker destination fixed
- [8be14d5](https://github.com/omacom/omarchy/commit/8be14d5ac67a7a1a6928a40b5d8197b19683acfb) Explain why the Cirrus firmware repair uses pacman directly
- [96af8d4](https://github.com/omacom/omarchy/commit/96af8d4c0269b534ce0cdfdc70a555204823b3cf) Escape firmware test fixture paths
- [8f7dd71](https://github.com/omacom/omarchy/commit/8f7dd71fdaa244f301ad2ce212e6813ec0c83454) Apply XPS 13 Panther Lake display parameters
- [81df055](https://github.com/omacom/omarchy/commit/81df05533c55a4e41b0b66afd8fc139f3c11f388) Invalidate the display rebuild marker before repairing its drop-in
- [5657a91](https://github.com/omacom/omarchy/commit/5657a91f8ddbcc8ff9b9add0396456a71b1d1ed9) Drop Lazydocker from new installs (#14230)
- [f964629](https://github.com/omacom/omarchy/commit/f9646299bf80f94c2694eb2592fb949e820a7604) Apply agent account selection to CLI subprocesses (#14233)
- [27a3fef](https://github.com/omacom/omarchy/commit/27a3feffc65d3df2009684174dcefd4d14169a4a) Fix icon spacing
- [e73c4d8](https://github.com/omacom/omarchy/commit/e73c4d863b0b2296ef6612c3258d8dba9175aada) Line up bar labels and icons (#14234)
- [2456307](https://github.com/omacom/omarchy/commit/245630786c71913bab29a48c163cb4fcda934569) Resolve effect_input/effect_output audio filter pairs (#14241)
- [baf0287](https://github.com/omacom/omarchy/commit/baf0287138118c95b395b5c1a6bb552ab10d8620) Ask RTKit directly for the speaker tuning's realtime priority (#12958)
- [6520ac7](https://github.com/omacom/omarchy/commit/6520ac7d2527795b71781dc2659a42fa4ed859a3) Configure xdg-desktop-portal to use gnome-keyring (#9594)
- [54e3b53](https://github.com/omacom/omarchy/commit/54e3b53b88402a4be69f06279e31bf052ceb30c4) Make application transparency opt-in (#14253)
- [879d658](https://github.com/omacom/omarchy/commit/879d6583dacea9a6fe421319fe463d6cae73831b) Fix fingerprint enrollment and lock-screen recovery (#7158)
- [72c152a](https://github.com/omacom/omarchy/commit/72c152a288c2a673f19e8334db4c530003628da2) Retry systemd reload in the fingerprint recovery migration (#14260)
- [0e7d6c2](https://github.com/omacom/omarchy/commit/0e7d6c270b77d3808402a19a4754c5fd0484f0ce) Update test fixtures to current runtime contracts (#14259)
- [e86c8f1](https://github.com/omacom/omarchy/commit/e86c8f1ab776b03102142452c9a5c86cf536a8c4) Reveal indicators only before the clock (#14267)
- [035ce29](https://github.com/omacom/omarchy/commit/035ce29f03bdd97a09af80ef5f2d22d7a98930d6) Add Install > Service > Microsoft with Outlook, Office, and Teams web apps (#10367)
- [2f7302a](https://github.com/omacom/omarchy/commit/2f7302a777dc3b8d2416a94eec22dd606bc33b80) Install Word, Excel, and PowerPoint as separate web apps (#14271)
- [885e339](https://github.com/omacom/omarchy/commit/885e3390371adb3174afdb0116417ddb150638e2) Drop superseded T2 firmware handling from the install script
- [65c0f33](https://github.com/omacom/omarchy/commit/65c0f3306e9b4af676f32d3b9fa187b53d9ca155) Merge pull request #13233 from Raj-Jagadeesh-A-P/fix/issue-7952
- [ec76c07](https://github.com/omacom/omarchy/commit/ec76c070d280fa17386a65f3607fe83e516dc9ec) Give Elsewhen remove buttons a circular corner bubble (#14258)
- [5a0e734](https://github.com/omacom/omarchy/commit/5a0e7348af0e82c3de472e732dbac7045cd77498) Show Elsewhen remove button only on mouse hover
- [b9e0ac4](https://github.com/omacom/omarchy/commit/b9e0ac4f1d8b33ab01af0cbb3a95c8667ee69eb3) Prevent clipboard capture hangs (#9488)
- [81145eb](https://github.com/omacom/omarchy/commit/81145eb1fd41532fcae4310b26f860608e2eaf82) Merge pull request #13963 from SorenHJohansen/fix/t2-firmware-fetcher
- [033b5ec](https://github.com/omacom/omarchy/commit/033b5ecd3de1a64f464c1fd3d9c716258e9451b6) Retain XPS 13 Panther Lake firmware during package refresh
- [19e5941](https://github.com/omacom/omarchy/commit/19e59410750e6421b9e3ec3cb88f645a554afbe0) Fail updates that leave required Panther Lake firmware unrepaired
- [0d8232b](https://github.com/omacom/omarchy/commit/0d8232b9db162fe7d9db774ea8e2cebc62051ecd) Install the XPS 13 PTL speaker alias package
- [499f50f](https://github.com/omacom/omarchy/commit/499f50ffd649091afaf7912fa2fe729a0bd28756) Move speaker reboot bookkeeping into the migration
- [db21abd](https://github.com/omacom/omarchy/commit/db21abdef00de03dcee54fd7222b2ab3205c300e) Request a reboot directly in the PTL firmware migration
- [0f8af9b](https://github.com/omacom/omarchy/commit/0f8af9be307d5d4f12cc0f6394892cac651ed5e6) Merge pull request #14017 from omacom/xps13-ptl-cirrus-firmware
- [8395714](https://github.com/omacom/omarchy/commit/83957145a7bee89cf91af9d0370e926efd1a01aa) Replace Disk Usage TUI with Disktree (#14426)
- [2fa6d0e](https://github.com/omacom/omarchy/commit/2fa6d0ecc598800914ce0680cd4bc2b68dfc8318) Approve Grok migration removal automatically
- [402128b](https://github.com/omacom/omarchy/commit/402128b6a2f104495038f4d52b194ac3dbd2ed28) Automatically approve orphan removal during updates (#14428)
- [7b68fee](https://github.com/omacom/omarchy/commit/7b68fee056847e4be9debc5df7da3bac37194470) Add Slack to Install > Service (#14434)
- [b6f2c1c](https://github.com/omacom/omarchy/commit/b6f2c1cef7bbf3c3560b0d9e039d6f4c742b70bf) Describe the agents panel's limit rows and sign-in link as they are (#14430)
- [982290f](https://github.com/omacom/omarchy/commit/982290fa42aa45510b25c10127588d9eded8fcef) Nicer order
- [d9b970d](https://github.com/omacom/omarchy/commit/d9b970dd626da8fdf8174dada67c5e564664e2f8) Let users choose passwordless sudo duration (#14435)
- [0a55a3c](https://github.com/omacom/omarchy/commit/0a55a3c5544931bd314342e2a1f00bada577c574) Keep overlays sharp without parked surfaces (#14458)
- [060c57b](https://github.com/omacom/omarchy/commit/060c57b4aa416022343893c1a2e4eadae255257e) Enable overlay scrollbars in Chromium (#14456)
- [a137760](https://github.com/omacom/omarchy/commit/a137760c892a34c5f223aa01dbb2b4d8fc0d3f01) Reuse SSH connections for Herdr theme sync (#14460)
- [902fd8a](https://github.com/omacom/omarchy/commit/902fd8aebd98b6eedaa58276886a2f9f2876755f) Play matching background intros at boot and on theme switches (#9639)
- [b83d3df](https://github.com/omacom/omarchy/commit/b83d3df0840504299d3099ebf391eb8110527edd) Qualify shell palette references for Qt 6.12 (#14553)
- [34016cf](https://github.com/omacom/omarchy/commit/34016cfb27137510278dde88a075d832b1a23e76) Prioritize the Omarchy package repository
- [717a0e9](https://github.com/omacom/omarchy/commit/717a0e9c50457f8d5b6a24da539980a0427bb538) Keep OPR priority migration independent of Quickshell
- [1554a52](https://github.com/omacom/omarchy/commit/1554a522ccd641a603d94aae28c495ce30afa428) Update packages after prioritizing OPR
- [a54bf5f](https://github.com/omacom/omarchy/commit/a54bf5fd9572996d65bc446ce115509254b05e11) [verified] Repair background links after WebP conversion
- [b6844dc](https://github.com/omacom/omarchy/commit/b6844dcc331aa4192fe5ea90e06f4cd3b45780a6) Fix WebP background migration boundaries
- [c248890](https://github.com/omacom/omarchy/commit/c24889096e12fbb053df1308877adefc3da1caac) Add selectable Voxtype and Superwhisper dictation (#14552)
- [5ad44d6](https://github.com/omacom/omarchy/commit/5ad44d62f6323e7a293eca4bdbc7e07693446d76) Alphabetical order
- [02d28d2](https://github.com/omacom/omarchy/commit/02d28d273a1b0f45d9beb19243b2ee6caf5e7a7d) Fix Superwhisper setup with existing Right Alt shortcut
- [50d687a](https://github.com/omacom/omarchy/commit/50d687a1f27063513cf42e6f33c3a4fcb17c24ed) Ship Superwhisper cloud dictation by default (#14625)
- [057681b](https://github.com/omacom/omarchy/commit/057681b33c05ae85f666035503cec715aed8af7d) Unpack the bundled Node tarball for the machine's architecture
- [15b3529](https://github.com/omacom/omarchy/commit/15b3529ef29ba18aa29f5445b310e3dfd763825a) Test that each architecture unpacks its own Node tarball
- [c352b62](https://github.com/omacom/omarchy/commit/c352b62d67456f56ca898d0e23effc1b20c25ca6) Merge pull request #14637 from omacom/install/node-tarball-by-architecture
- [be05233](https://github.com/omacom/omarchy/commit/be052339d88226d6a2e8f9212766230d1220e19f) Fix lopsided cursor highlight on network panel header actions (#8787)
- [7f95505](https://github.com/omacom/omarchy/commit/7f95505dec2ddc10ce00c5dc01e39fc457d8ad34) Slow down the reveal effect a little on background changes
- [d38b70c](https://github.com/omacom/omarchy/commit/d38b70c3c2d7c10a52f4234dbeb6a04be8f900c7) Add Starship as a default theme (#14705)
- [fcf9eeb](https://github.com/omacom/omarchy/commit/fcf9eeb5c454739f3f23cdfd7d57d77b12961025) Show the image picker instantly, with no backdrop (#14709)
- [988f44e](https://github.com/omacom/omarchy/commit/988f44ea1a16250785eee1c73cbaf558080589db) Delete extra themes from the theme picker (#14713)
- [54fc12d](https://github.com/omacom/omarchy/commit/54fc12db76fbb6ed06575ff57839e73c7dbbf817) Stop push-to-talk even when other keys are pressed during the hold (#14645)
- [9d48fc4](https://github.com/omacom/omarchy/commit/9d48fc402edf51ae089a7c8c1f7b1a8611744bd8) Install gliff by default and show when a remote session is active (#14712)
- [5cb3131](https://github.com/omacom/omarchy/commit/5cb31317b488dce2734c867fd9dc21f9fb7a7e9a) Merge pull request #11874 from acrogenesis/feature/usb-device-authorization
- [2519fd9](https://github.com/omacom/omarchy/commit/2519fd9a97b78c7906330dbb8abdea49dd039983) Merge pull request #13047 from AFOliveira/fix/factory-reset-packaged-path-20260923
- [f03bf06](https://github.com/omacom/omarchy/commit/f03bf06742a2ed4535d326e3220c685bca5aa0ed) Stop the boot from waiting on a black screen for the console to answer
- [295a926](https://github.com/omacom/omarchy/commit/295a926ffdd8115edf1a3ecd710e43856fae5dbf) Test the boot image migration as omarchy-migrate runs it, and a failed rebuild
- [3824577](https://github.com/omacom/omarchy/commit/3824577c123bcaa0badd821338127c52a32ac620) Mark the boot image migration done only when a boot entry has the parameter
- [452835d](https://github.com/omacom/omarchy/commit/452835da8b5e9d7de621191c78f1d9b045c30eae) Read the boot loader's config only where the migration needs it
- [187a145](https://github.com/omacom/omarchy/commit/187a145ad5550177ba7442d4c2b24f79c6dc14fb) Merge pull request #14603 from manuaudio/fix/repair-webp-background-links
- [6126321](https://github.com/omacom/omarchy/commit/61263219b55250b79a7332d4d8ab3904b8cdecbb) Merge pull request #14771 from omacom/boot/console-no-ansi-query
- [e1b0e5e](https://github.com/omacom/omarchy/commit/e1b0e5e9bb72b15dc494458925655bf32656382b) Converge omarchy-mac and omarchy-mx-mac into upstream Omarchy (#14431)
- [55fc353](https://github.com/omacom/omarchy/commit/55fc353e47b8c8dc7f83ef8bdcc82039df41ae8c) Enable first-run units one at a time, and test that units are shipped
- [5489418](https://github.com/omacom/omarchy/commit/5489418c9de9bd82d6ec403087905bc2e68e6cdd) Require the unit copy to come before the enable, and compare first-run to a clean run
- [7cc6a55](https://github.com/omacom/omarchy/commit/7cc6a55f24fab194fdaacddc801a28acb0fe4810) Merge pull request #14796 from omacom/fix/user-units-not-shipped
- [dd05114](https://github.com/omacom/omarchy/commit/dd05114e95de5679c0eb7d0b5a0a7da9445618cb) Find the caller of the Bash startup check the way /proc numbers it
- [0801356](https://github.com/omacom/omarchy/commit/0801356155c0ea58583f9297da1cbe3dda51a52a) Test the startup check from a subshell, with a decoy -p, and rejecting in a PID namespace
- [a15636b](https://github.com/omacom/omarchy/commit/a15636b59eb4b25355383231c24e1993e193d821) Merge pull request #14799 from omacom/fix/bash-startup-check-in-chroot
- [51717f1](https://github.com/omacom/omarchy/commit/51717f10bad8b703ba75af3bade2dd909f3ccc71) Patch all QtQuick imports to 6.11 to work around plugin Color bug
- [077ac1d](https://github.com/omacom/omarchy/commit/077ac1da939de00d061c1035e1a1d00587a119b8) Merge pull request #14845 from omacom/fix-qt612-color
- [77bfaca](https://github.com/omacom/omarchy/commit/77bfaca408d2993018d928e72cf84561480e5188) Place Elsewhen after the clock by default (#14870)
- [6fee710](https://github.com/omacom/omarchy/commit/6fee7105af1cea7bea6600d941a39ec5b0424753) Re-check Bolt less often while there is no Thunderbolt controller (#14931)
- [f2a39c4](https://github.com/omacom/omarchy/commit/f2a39c4dca051d6fc2dd06bad7d38bb4bcc4ea14) Drop the Azerbaijani keyboard choice, which installed French AZERTY (#14877)
- [f5170dd](https://github.com/omacom/omarchy/commit/f5170dd07066a9703ab57f059d14a9cc9218fad8) Recover the startup cursor across Hyprland reloads
- [0b9dace](https://github.com/omacom/omarchy/commit/0b9dace01837edd87eb65f20789063abcd5cf491) Unify input methods with installer keyboard selection (#14433)
- [1b5222b](https://github.com/omacom/omarchy/commit/1b5222be74a900ab23fe3b3203864a06ffcd855c) Return Caps Lock to normal and make Shift + Caps Lock the compose key (#14939)
- [04b374a](https://github.com/omacom/omarchy/commit/04b374a989c49bdeda72542f194106ea0c3da3ff) Add Starship theme preview (#14942)
- [0bcb6a2](https://github.com/omacom/omarchy/commit/0bcb6a2559f85851fc46b7196ce0c5299af47b54) Keep the default cursor alias on ordinary boots
- [9830142](https://github.com/omacom/omarchy/commit/98301428347de3a189074bcc0bcfe50c020329f0) Merge pull request #14935 from omacom/startup-cursor-recovery
- [9476e47](https://github.com/omacom/omarchy/commit/9476e47a103e79c34952d27194643c6e99037df8) docs: add 2020 iMac models to the T2 Mac list (#10783)
- [77b13fd](https://github.com/omacom/omarchy/commit/77b13fd026f493f80777c39a928fc409d667ee80) Fix typo on 04_navigation.md (#7463)
- [9d47dd1](https://github.com/omacom/omarchy/commit/9d47dd14970a29e9c0339094c2c7d55f5e40d9e6) Point the plugin manual at plugins.omarchy.org (#10499)
- [a3d4bea](https://github.com/omacom/omarchy/commit/a3d4bea9d07e4d6e36689342f6d05376b216e64d) docs(agents): add plugin UI safety baseline (#7792)
- [4d3a859](https://github.com/omacom/omarchy/commit/4d3a85969a51df189ce1c2e72cc64e2657b3e926) Clarify that omarchy-toggle-bar's on/off tracks the bar-off flag (#11803)
- [ccf2636](https://github.com/omacom/omarchy/commit/ccf263611d516bab40c534fa5bab21bb073d9ca4) Correct omarchy-pkg-add AUR claim in AGENTS.md (#13895)
- [c1096aa](https://github.com/omacom/omarchy/commit/c1096aa36f50f864735a39117913626b3c10ccae) Refresh all default theme previews (#14944)
- [3609968](https://github.com/omacom/omarchy/commit/3609968a42a8c2199683e637466942f40bda4187) Stop shipping OBS Studio and Kdenlive to new installs (#14962)
- [d74d6ea](https://github.com/omacom/omarchy/commit/d74d6ea249c5ce43842f59aa8187a8140fda8888) Build the calendar month grid in UTC (#10476)
- [10f1cbf](https://github.com/omacom/omarchy/commit/10f1cbf7cfbeb8771697dbd493d2f2562db99d7b) Install clang with the Rust dev environment instead of for everyone (#14967)
- [35a55fd](https://github.com/omacom/omarchy/commit/35a55fd236598598130711249a647e0071532e9a) Remove redundant agent guidance in user customization skill (#5925)
- [dc50bbe](https://github.com/omacom/omarchy/commit/dc50bbe5746a17a09f2698edb8e1a12aa69150de) Switch out of an input method and back with a lone Shift (#14975)
- [c09ddcf](https://github.com/omacom/omarchy/commit/c09ddcff9018c6ac6f5d56c67de950a50d802503) Move the look of the desktop to Trigger > Appearance (#14973)
- [1498718](https://github.com/omacom/omarchy/commit/14987189695a8ae1f2270262fdf77446fafb1ba3) Add a floating mode with titlebars to the workspace layout cycle (#14482)
- [d1a614c](https://github.com/omacom/omarchy/commit/d1a614ce6629f33810c832c690b087586bd6f4c5) Decide lock requests from the current lock state (#14978)
- [cf473b5](https://github.com/omacom/omarchy/commit/cf473b5c5d2c6be6114ea38675af4dccc92eb7f6) Rearrange menu items a bit
- [18e059d](https://github.com/omacom/omarchy/commit/18e059d9a45668a87ecbb0b02b723ac79a715cd6) Show the remote session indicator only during a remote session (#14981)
- [bef30c1](https://github.com/omacom/omarchy/commit/bef30c1c50a88364a19648fd6d4e9d5fb99dc9b9) Move the Menu Bar from Style to Appearance, with Hide and Show (#14982)
- [b6ceb8f](https://github.com/omacom/omarchy/commit/b6ceb8f4d68e2e0efda3bf5006d55d903344cc20) Use the menu's animations icon in the toggle notifications
- [eb1a34e](https://github.com/omacom/omarchy/commit/eb1a34ecd03a0139220db26b2ffe61d297cbbc9c) Move Battery Percentage under Appearance > Menu Bar > Indicators
- [5ec8bd3](https://github.com/omacom/omarchy/commit/5ec8bd300bd1a98a3c7ffe0ed8430963bb5a2631) Pick the bar clock format from Appearance > Menu Bar > Indicators > Clock
- [3882c27](https://github.com/omacom/omarchy/commit/3882c27cfd53a0ec7d2a86f086201aefee25280d) Better ordering
- [4df5459](https://github.com/omacom/omarchy/commit/4df545905d70b92d7c2dc62b339ff529d0075551) Pick window corners from Appearance > Window Corners (#14990)
- [be7c7bf](https://github.com/omacom/omarchy/commit/be7c7bf3785f11c9f2dc210824cdf912ec4af043) Replace Xournal++ with Signed for signing PDFs (#14999)
- [a98e55e](https://github.com/omacom/omarchy/commit/a98e55eb913fa755f4e9978504572640bbb209f5) Pick window transparency from Appearance > Window Transparency, and a Glassy bar background (#14991)
- [754d2d0](https://github.com/omacom/omarchy/commit/754d2d04b3828ae5ccfff4c4ab9f0c3b5c14dc7b) Only recover a session lock no other locker may hold (#15020)
- [1ac31e5](https://github.com/omacom/omarchy/commit/1ac31e55ae0ceccffc080bce32ac61f5178dbb33) Never leave the desktop without a wallpaper after a theme intro (#15000)
- [88de9ec](https://github.com/omacom/omarchy/commit/88de9ecc6c4717e349a21f9e8af3ffc0a9d25415) Let herdr's tab bar show the terminal background, so it turns glassy too (#15022)
- [5f25ef1](https://github.com/omacom/omarchy/commit/5f25ef1da81619d7aebbf297ef37ae9d9a2dba2f) Let Neovim's current line and status line show the terminal background on existing installs (#15024)
- [c4803d7](https://github.com/omacom/omarchy/commit/c4803d7d74391d357cb16b034425c550f62ae5dd) Update comment
- [8bd1b7c](https://github.com/omacom/omarchy/commit/8bd1b7c0450519e8afd7e21f84f27fa033e1c3a8) Tell agents to react to events instead of polling (#15029)
- [3c1f7b7](https://github.com/omacom/omarchy/commit/3c1f7b780f8de0689d89d51975d1fd8f54045874) Refresh the passwordless sudo indicator on change instead of polling (#15026)
- [1b1cc5e](https://github.com/omacom/omarchy/commit/1b1cc5ecb53f4db22c80a6bdc824f3d11d75a24a) Track the power profile through Quickshell instead of polling busctl (#15027)
- [e71a816](https://github.com/omacom/omarchy/commit/e71a816e9032f040225e086c7256f73e8080ae45) Cache workspace layouts instead of running a script on every switch (#15028)
- [201de1c](https://github.com/omacom/omarchy/commit/201de1c0d60be79eebbffae18c3548b06909756a) Normalize bar icon size and alignment
- [6575f06](https://github.com/omacom/omarchy/commit/6575f06d53e9c10cf47e3549361a11ece09d831d) Correct custom bar icon bounds
- [9480d1b](https://github.com/omacom/omarchy/commit/9480d1b6a98156314dbabe6bfef08f39f8b9cd07) Merge pull request #15065 from bjarneo/fix/bar-icon-consistency
- [defbf90](https://github.com/omacom/omarchy/commit/defbf90e893e741067e48f4a27d2ec694c71358e) Fully revert USB and Thunderbolt device approval (#15091)
- [b018284](https://github.com/omacom/omarchy/commit/b0182842b2e43afe3b23e1a9916b9ed3ee076922) Make the menu's slowest hardware and network guards cheap (#15039)
- [fb09f26](https://github.com/omacom/omarchy/commit/fb09f26be14f222fa666cd3a110e091017866cb4) Keep the menu's package snapshot until a transaction changes it (#15042)
- [56be332](https://github.com/omacom/omarchy/commit/56be332582790b55ad8d2533c78cb1c542b45bce) Run the menu's guard readers and guards side by side (#15049)
- [f3cdce2](https://github.com/omacom/omarchy/commit/f3cdce2888751e893818ae33c43099b5eaa334a5) Run the menu's guard batch once at startup, not once per menu file (#15048)
- [15d9544](https://github.com/omacom/omarchy/commit/15d9544cd6d394ff2b5b6487f71c383858df4fda) Refresh the signing keyrings only when a newer version is out (#15034)
- [b96b9c5](https://github.com/omacom/omarchy/commit/b96b9c59931cd10235d00671ca55a363edc14707) Stop slow app retints from holding up theme switches (#15045)
- [11f456f](https://github.com/omacom/omarchy/commit/11f456f6b6e45ffd9d754c8f5a01fc30d77e3918) Clear the update indicator after an update instead of rechecking (#15047)
- [21b8766](https://github.com/omacom/omarchy/commit/21b8766c4161c50d4e1f0d950b573885a0b9f6bd) Sync the theme into tmux with one source-file instead of a client per variable (#15040)
- [916a47f](https://github.com/omacom/omarchy/commit/916a47f5b844d31331e2b194e8024df30714de30) Take the screen recording preview while the recording finalizes (#15038)
- [17704ac](https://github.com/omacom/omarchy/commit/17704ac46fab08ef9e1b31294e51809b7894dcbb) Resolve alias and metadata-moved routes without reading every command header (#15041)
- [efea37f](https://github.com/omacom/omarchy/commit/efea37fa73476b810dc9a40f7c6f46ed45e115a3) Read the xkb layout table only when the keyboard widget shows a label (#15043)
- [ec344f3](https://github.com/omacom/omarchy/commit/ec344f320b9e25a2fdcdac8eb0b2f1586c8838a3) Probe the browser's private-window flag only for private launches (#15037)
- [ea41263](https://github.com/omacom/omarchy/commit/ea4126396ebcda02e49bba909f8d39bc5f06fee7) Skip the nightlight toggle's wait when hyprsunset is already running (#15035)
- [84ba0c4](https://github.com/omacom/omarchy/commit/84ba0c453f5e4e4560db629d2661eccadb7c7d96) Resolve the audio volume sink on Pipewire changes instead of every 15 seconds (#15033)
- [4c1b4cb](https://github.com/omacom/omarchy/commit/4c1b4cb3a94447aff39af98e2fcc0490a9fb32e7) Build bar panel content on first open instead of at startup (#15044)
- [86234a9](https://github.com/omacom/omarchy/commit/86234a917f3570d43625b7ea7ad166ec1bcfe6a7) Read plugin manifests without a process per file (#15163)
- [7e7a560](https://github.com/omacom/omarchy/commit/7e7a5600a3c989eb8658dd12409fa7e0479078bb) Scan app icon directories once per index refresh (#15167)
- [d100314](https://github.com/omacom/omarchy/commit/d10031418c8ac51b2a4a27edeaa729348c681076) Mount binfmt before registering binary formats (#15175)
- [60e96ac](https://github.com/omacom/omarchy/commit/60e96ac0df4e7da61f30864ebc21e6a713424320) Avoid mount-event throttling during boot (#15182)
- [e7d8f5b](https://github.com/omacom/omarchy/commit/e7d8f5be84ff8c4c60c7f6c5d0318c93acdad69e) Compute desktop entry IDs without spawning subshells (#15181)
- [0d59e35](https://github.com/omacom/omarchy/commit/0d59e356c134692ed6c5416faa9a627a27e53c44) Restore the toggle menu alias that Super+Ctrl+O opens (#15168)
- [5b88f01](https://github.com/omacom/omarchy/commit/5b88f01e30ca72aa86b1180f489341586065bba0) Keep the agent account test from inheriting the running session's account pin (#15165)
- [45be14d](https://github.com/omacom/omarchy/commit/45be14d447b27e5fa017be765682de03ce92cdea) Expect the Grok migration's non-interactive mise unuse in its test (#15166)
- [cc95d7b](https://github.com/omacom/omarchy/commit/cc95d7b2e88508906450f105d39c302ad2dc6cc2) Don't read omarchy-hook-install as install(1) in the unowned /usr path check (#15169)
- [5a7afdf](https://github.com/omacom/omarchy/commit/5a7afdf07393f8ea39f2a43c110e4c1917709e11) Find the omarchy-pkgs checkout in one place and skip package checks without it (#15170)
- [b705000](https://github.com/omacom/omarchy/commit/b705000e938a48dc08369bb1bf89afc94908345e) Check the battery percentage order where the bar button lays it out (#15173)
- [c2dd705](https://github.com/omacom/omarchy/commit/c2dd70522c2db4bf7987589c99267ebc6e4e91b2) Give the input-device toggle test's Hyprland stub the window list layouts read (#15177)
- [5e362ff](https://github.com/omacom/omarchy/commit/5e362ff297721a7deb45cbfb9e2417d492ccd777) Stop the runtime smoke test's leftover shell children with a bounded wait (#15202)
- [8f5ca14](https://github.com/omacom/omarchy/commit/8f5ca14e248fac69b73441ebc8677877bb8c2e28) Read the keyboard seat again when /dev/input changes instead of every 10 seconds (#15203)
- [f5006bd](https://github.com/omacom/omarchy/commit/f5006bd41a1755d46e0a4f2c0c4c54fca703cd9b) Fail tests when the shell polls while idle or the fast paths get slow again (#15196)
- [9a10b48](https://github.com/omacom/omarchy/commit/9a10b488b1113f67dd9c16e60447e9f37c2edbe9) Enable Superwhisper on aarch64
- [7dd477b](https://github.com/omacom/omarchy/commit/7dd477b35bbf9737dd45c41bff3e7a0e96787e09) Merge pull request #15247 from omacom/fix/superwhisper-aarch64
- [47caa9b](https://github.com/omacom/omarchy/commit/47caa9be439e1876b6048a32a868688e9c697d48) Add scroll wheel handling to workspaces bar widget
- [81504b0](https://github.com/omacom/omarchy/commit/81504b08e0fdfc411e07bb0395d6d9347e1cf020) Sharpen the theme intros (#14567)
- [124328f](https://github.com/omacom/omarchy/commit/124328fd83214b41d8969d40ea8ae1b2a57a1c20) Add a dock to floating workspaces (#15263)
- [b6af62e](https://github.com/omacom/omarchy/commit/b6af62e285a35bb752fb86525dd169ae3ea71551) Reset empty workspaces to a new default layout, and call dwindle tiling (#15266)
- [ed92b07](https://github.com/omacom/omarchy/commit/ed92b0753f95eb79664878a93f61b114e3894bb2) Change no saved layouts when the workspaces cannot be read (#15267)
- [4bf51ed](https://github.com/omacom/omarchy/commit/4bf51ed1a11d24179586c4fecc5e45c7737cb2d9) Exit sessions as soon as applications finish closing (#15231)
- [8940e85](https://github.com/omacom/omarchy/commit/8940e85fee7ec4cdef17fecb6541d186b898d22f) Reach the shell when the session environment names a display that is gone (#15226)
- [7354fb7](https://github.com/omacom/omarchy/commit/7354fb780be6ce0cf0e494e0c1bb3528ad4799a2) Show Stay Awake as a mug without a saucer (#15269)
- [d8027c9](https://github.com/omacom/omarchy/commit/d8027c90d6196e9507fa455a4246bec879d9cff5) Retint terminals first and finish other apps behind a theme switch (#15189)
- [cffdaa6](https://github.com/omacom/omarchy/commit/cffdaa6ccb3e74c5e5f1e63cf3e8a296799e7228) Turn titlebars on when a workspace starts floating, not on the next reload (#15271)
- [85ffa80](https://github.com/omacom/omarchy/commit/85ffa8078098a8523c35c4989564d3820dbd5396) Change window transparency without a notification
- [a06ec13](https://github.com/omacom/omarchy/commit/a06ec13319c437fa01e998ca6f43e8385be4c467) Call the window transparency menu Window Opacity so it fits
- [a268c19](https://github.com/omacom/omarchy/commit/a268c198387215ab3e08d65672efe0b23ae3cd26) Add Liftoff wallpaper to Tokyo Night (#14755)
- [77cddd3](https://github.com/omacom/omarchy/commit/77cddd3735222efcba00ad64a6eaaef1042a155d) Find foot terminals' shells with one process scan (#15190)
- [b11ba67](https://github.com/omacom/omarchy/commit/b11ba679913b03e0b63515a17e9b3da5d1838e38) Look for a glass block before building its sed addresses (#15191)
- [32481c8](https://github.com/omacom/omarchy/commit/32481c89ed70ced37a9f5b3c7bc48e8d867024cf) Limit each theme to max 1 intro video
- [097c733](https://github.com/omacom/omarchy/commit/097c733fc6f24cd437028e0233910b7143fe83f7) Lead Tokyo Night's backgrounds with Liftoff
- [62c609f](https://github.com/omacom/omarchy/commit/62c609f7750ddb7851899267fde460cf18fc5f51) Clone the dev checkout without old file contents (#15283)
- [4485e28](https://github.com/omacom/omarchy/commit/4485e28de8a0c0b2511ebbe4b34b1645c23984c8) Decode clipboard and track art previews at the size they are drawn (#15200)
- [00f410b](https://github.com/omacom/omarchy/commit/00f410b77770f0055f84b1d132f31cddec2a0bba) Keep account switch notifications from wrapping awkwardly (#15284)
- [6784597](https://github.com/omacom/omarchy/commit/67845970ab3db34c4e86500eadbc1a7d10e292d5) Turn on mpv hardware decoding through a system config (#15172)
- [d7abdbd](https://github.com/omacom/omarchy/commit/d7abdbd420781b57f5b155042fcd6d610573304c) Poll Fcitx only when there is an input method to switch to (#15184)
- [c9a4af2](https://github.com/omacom/omarchy/commit/c9a4af2cdf67ac9278b248f5e8e1c3178de59b15) Release the image picker's previews a minute after it closes (#15201)
- [c2cfa60](https://github.com/omacom/omarchy/commit/c2cfa604840dfa8782e3d971da34700898908d8b) Read EPOCHREALTIME the same way under a comma-decimal locale (#15213)
- [535d0ac](https://github.com/omacom/omarchy/commit/535d0ac827d1ee013e0d094017cd3daa5b05fadf) Work out battery time left from the draw shown beside it (#15285)
- [1a161eb](https://github.com/omacom/omarchy/commit/1a161eb5192ac555b99458c52f5fa80344cb3556) Let bar widgets live in the tray's drawer (#15281)
- [492b883](https://github.com/omacom/omarchy/commit/492b8837deea69663c7a5418871f07ed075a9686) Stop asking for a reboot after every update on ARM (#14447)
- [ecf0eb3](https://github.com/omacom/omarchy/commit/ecf0eb362283efad6404b939981c7ef8d58039b3) Add a Flexoki Light intro (#15315)
- [5328732](https://github.com/omacom/omarchy/commit/5328732d9921d8e7d2e2291b2116b03ea6a706a3) Stop the tray section host reading its widget after it is gone (#15320)
- [0b5f827](https://github.com/omacom/omarchy/commit/0b5f827502a363c75d49d67c37bcdd0293d0e7b5) Stop the power panel closing itself inside its opened handler (#15319)
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
- [8a787b6](https://github.com/omacom/omarchy/commit/8a787b6a8bec830b04543bf14c760ee0a10591f6) List the ProArt P14's amplifier firmware with the optional packages (#15557)
- [51bfd1d](https://github.com/omacom/omarchy/commit/51bfd1dbaa1b5f790e19623faf2745945d40c796) Take a screenshot with Super + Shift + S (#8827)
- [499c618](https://github.com/omacom/omarchy/commit/499c6185a8d8735b1e9b99673315985ed49d5df6) Set up installed NVIDIA applications (#12723)
- [33783b1](https://github.com/omacom/omarchy/commit/33783b1707d2fd5cdbab99aec183fc761d14bca0) Keep installed ARM recovery packages during orphan cleanup (#12722)
- [595eefa](https://github.com/omacom/omarchy/commit/595eefa9f2d170662a749822a1f32000a6273d25) Decode video on the Snapdragon video chip in mpv and Chromium (#15697)
- [a8ac588](https://github.com/omacom/omarchy/commit/a8ac5880827cfac84cad99fef129ab459c0144c8) Enable desktop camera access on Snapdragon ThinkPad T14s (#15331)
- [cce8b1c](https://github.com/omacom/omarchy/commit/cce8b1c971df64a7610b818ff8819e4bea04584a) Add HP EliteBook Ultra G1q microphone UCM profile (#15574)

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
