# Upstream

What changed in Omarchy since Winarchy last reviewed it, newest first. Written by the daily upstream workflow (lib/upstream.ps1); porting a change is a reviewed step (agents/skills/upstream-sync.md).

## 2026-10-10

104 new commit(s) on omacom/omarchy@quattro, [454b67d...077ac1d](https://github.com/omacom/omarchy/compare/454b67d95fd63c269c5315836a098038a0c61716...quattro).

| Area | Upstream files | Winarchy files to review |
|---|---|---|
| Conventions | `AGENTS.md`<br>`docs/file-layout.md`<br>`docs/lifecycle-dispatch.md`<br>`docs/omarchy-shell.md`<br>`docs/passwordless-sudo.md`<br>`docs/theming.md`<br>and 2 more | `AGENTS.md`<br>`docs/` |
| Other | `agents/skills/install-scripts.md`<br>`agents/skills/shell-dev.md`<br>`applications/Disk Usage.desktop`<br>`config/chromium-flags.conf`<br>`config/hypr/looknfeel.lua`<br>`config/omarchy/defaults/dictation`<br>and 32 more | - |
| CLI | `bin/omarchy` | `bin/winarchy.ps1`<br>`lib/cli.ps1` |
| Coding agents | `bin/omarchy-agent` | `lib/agents.ps1` |
| Agent accounts | `bin/omarchy-agent-account-add`<br>`bin/omarchy-agent-account-exec`<br>`bin/omarchy-agent-account-home` | `lib/accounts.ps1` |
| Other commands | `bin/omarchy-apply-hardware`<br>`bin/omarchy-apply-lock`<br>`bin/omarchy-audio-input-set-default`<br>`bin/omarchy-audio-output-sink`<br>`bin/omarchy-audio-sink-availability`<br>`bin/omarchy-battery-present`<br>and 62 more | `lib/` |
| Install / Remove | `bin/omarchy-install-browser`<br>`bin/omarchy-install-dictation-superwhisper`<br>`bin/omarchy-install-dictation-voxtype`<br>`bin/omarchy-install-gaming-steam`<br>`bin/omarchy-install-preinstalls`<br>`bin/omarchy-install-service-microsoft`<br>and 9 more | `lib/catalog.ps1` |
| Launchers | `bin/omarchy-launch-shell` | `ahk/launchers.ahk`<br>`ahk/menu.ahk` |
| Menu | `bin/omarchy-menu-keybindings`<br>`default/omarchy/omarchy-menu.jsonc` | `zebar/omarchy/menu.json`<br>`zebar/omarchy/menu.js`<br>`ahk/menu.ahk` |
| Theming | `bin/omarchy-theme-bg-boot-intro`<br>`bin/omarchy-theme-bg-intro`<br>`bin/omarchy-theme-set`<br>`bin/omarchy-theme-set-herdr-machines`<br>`default/themed/shell.toml.tpl` | `lib/render.ps1`<br>`lib/themes.ps1`<br>`lib/targets.ps1` |
| Window manager | `default/hypr/apps/browser.lua`<br>`default/hypr/apps/davinci-resolve.lua`<br>`default/hypr/apps/hermes.lua`<br>`default/hypr/apps/localsend.lua`<br>`default/hypr/apps/omarchy-shell.lua`<br>`default/hypr/apps/pip.lua`<br>and 14 more | `templates/glazewm.yaml.tpl`<br>`ahk/winarchy.ahk` |
| Keys | `default/hypr/bindings/applications.lua`<br>`default/hypr/bindings/dictation.lua`<br>`default/hypr/bindings/utilities.lua`<br>`default/hypr/bindings/voxtype.lua` | `ahk/winarchy.ahk`<br>`ahk/launchers.ahk`<br>`ahk/game-helper.ahk`<br>`templates/glazewm.yaml.tpl`<br>`default/keybindings.txt` |
| Upstream only | `install/config/all.sh`<br>`install/config/locale.sh`<br>`install/config/thunderbolt-authorization.sh`<br>`install/config/usb-authorization.sh`<br>`install/hardware/all.sh`<br>`install/hardware/apple/fix-brcmfmac-supplicant.sh`<br>and 49 more | - |
| Manual | `manual/04-navigation.md`<br>`manual/05-the-top-bar.md`<br>`manual/07-hotkeys.md`<br>`manual/11-text-extraction-dictation.md`<br>`manual/17-ai.md`<br>`manual/18-development-tools.md`<br>and 6 more | `manual/04-navigation.md`<br>`manual/05-the-top-bar.md`<br>`manual/07-hotkeys.md`<br>`manual/11-text-extraction-dictation.md`<br>`manual/17-ai.md`<br>`manual/18-development-tools.md`<br>`manual/21-tuis.md`<br>(new upstream chapter 22)<br>`manual/24-commercial-apps-services.md`<br>`manual/25-web-apps.md`<br>`manual/39-backgrounds.md`<br>`manual/48-security.md` |
| Shell (bar, menu, OSD) | `shell/Commons/AudioNodes.qml`<br>`shell/Commons/AudioNodesModel.js`<br>`shell/Commons/Border.qml`<br>`shell/Commons/Color.qml`<br>`shell/Commons/Style.qml`<br>`shell/Commons/UntypedInput.qml`<br>and 45 more | `zebar/omarchy/` |
| Top bar | `shell/plugins/bar/Bar.qml`<br>`shell/plugins/bar/BarModel.js`<br>`shell/plugins/bar/indicators/Dictation.qml`<br>`shell/plugins/bar/indicators/PasswordlessSudo.qml`<br>`shell/plugins/bar/indicators/RemoteSession.qml`<br>`shell/plugins/bar/indicators/ScreenRecording.qml`<br>and 5 more | `zebar/omarchy/bar.html`<br>`zebar/omarchy/bar.css` |
| Bar panels | `shell/plugins/panels/audio/Model.js`<br>`shell/plugins/panels/audio/Panel.qml`<br>`shell/plugins/panels/bluetooth/Panel.qml`<br>`shell/plugins/panels/clock/Panel.qml`<br>`shell/plugins/panels/dropbox/DropboxIcon.qml` | `zebar/omarchy/` |

Commits:

- [44f68f4](https://github.com/omacom/omarchy/commit/44f68f4329e75fa61dfa8cc01e4737c15e48f8c2) Require approval for new USB devices by default
- [7309746](https://github.com/omacom/omarchy/commit/7309746ac842a30774be8da850ce358306bc76df) Fix USB approval alerts after policy changes and reconnects
- [4ea410d](https://github.com/omacom/omarchy/commit/4ea410d6a1afe9b4d8a964be23d2fd9f578065ec) Retry USB approval notifications after delivery failure
- [666800e](https://github.com/omacom/omarchy/commit/666800eb0c06e11de5bf7bd04282e4b112eef5de) Persist USB boot policy in Limine snapshot manifests
- [79db1a1](https://github.com/omacom/omarchy/commit/79db1a182696ad696af8f09ee9b8b9efa36beab5) Allow USB authorization setup with an empty device inventory
- [9e20c2a](https://github.com/omacom/omarchy/commit/9e20c2a185fdb2e5abb88e507ce443314e2041c8) Retry USB approval delivery when notifications become available
- [54bacef](https://github.com/omacom/omarchy/commit/54bacefbf4be83b16f1d42b29b89386991dc6aeb) Explain USB availability in older recovery snapshots
- [67d173c](https://github.com/omacom/omarchy/commit/67d173c9f942649f3d030b9b0f7505d959327c50) Defer USB enrollment until owner provisioning completes
- [58a9c95](https://github.com/omacom/omarchy/commit/58a9c95bf6f3f0eab49b2f75ce2a39c9f867cf74) Verify USB approval before reporting success
- [afad853](https://github.com/omacom/omarchy/commit/afad8530622c871b64f7b775a96cbe50e26c1218) Disable restored USB policy until factory owner enrollment
- [90d604f](https://github.com/omacom/omarchy/commit/90d604f41d6ae52c6e53ca26ab3de311c7580420) Expire USB approval deduplication across daemon and watcher restarts
- [db6ab5a](https://github.com/omacom/omarchy/commit/db6ab5a8bf928f78bcabe04a19030d7df579159e) Resume USB approval verification after transient failures
- [de72b64](https://github.com/omacom/omarchy/commit/de72b64872cec8987a1c5db27e9727f5dae80d50) Re-sign historical UKIs before changing USB boot policy
- [e12c8ed](https://github.com/omacom/omarchy/commit/e12c8ed4521403a691fb6992e1952f679ff977d7) Restore signed boot files when USB boot policy changes fail
- [27bbbb2](https://github.com/omacom/omarchy/commit/27bbbb2fe991e0e8a328557a47110a06acba9d08) Merge quattro into USB authorization branch
- [56df5dd](https://github.com/omacom/omarchy/commit/56df5dd71d06964906d23dbdea30a6d32b757ed4) Fix grammar in navigation manual
- [7d47733](https://github.com/omacom/omarchy/commit/7d4773311e77d3543395223254da9a5a2565df33) Pin factory-reset elevation to the packaged command
- [4dd5414](https://github.com/omacom/omarchy/commit/4dd5414bfcd60994b492c1474fe99bbef0e8a5d5) Test factory-reset elevation paths and arguments
- [45a6433](https://github.com/omacom/omarchy/commit/45a64331394f62b0b853bf5a14805f94e66bdc7c) Refuse factory reset handoff to a different installed version
- [99e3c8c](https://github.com/omacom/omarchy/commit/99e3c8ca2f17a89b1e34090d4dee9c59d61a00a4) Test factory reset version mismatches and packaged invocation
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
