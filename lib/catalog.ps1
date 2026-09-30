# catalog.json for the menu's Install and Remove routes. Omarchy's Install menu is a
# catalog of what it can put on the machine, and a row for something already installed
# goes dim with a check rather than disappearing, so the list still reads as "here is
# everything on offer". Remove is the mirror and only lists what is actually there.
#
# One table feeds all of it: the menu rows, the install and uninstall verbs, and the
# bar's update list. Presence is answered from one snapshot of Add/Remove Programs
# instead of `winget list`, which takes seconds and would stall the menu opening.

# Nerd Font glyphs, by codepoint so the file survives any re-encoding.
$CatalogGlyph = @{
    install     = [char]::ConvertFromUtf32(0xF0249)
    remove      = [char]::ConvertFromUtf32(0xF0B4C)
    ai          = [char]::ConvertFromUtf32(0xF16A4)
    gaming      = [char]::ConvertFromUtf32(0xF11B)
    development = [char]::ConvertFromUtf32(0xF0D6E)
    editor      = [char]::ConvertFromUtf32(0xF15C)
    terminal    = [char]::ConvertFromUtf32(0xF489)
    service     = [char]::ConvertFromUtf32(0xF487)
    windows     = [char]::ConvertFromUtf32(0xF17A)
    gui         = [char]::ConvertFromUtf32(0xF08C6)
    tui         = [char]::ConvertFromUtf32(0xF018D)
    shell       = [char]::ConvertFromUtf32(0xF120)
    webapps     = [char]::ConvertFromUtf32(0xF059F)
    item        = [char]::ConvertFromUtf32(0xF0CB)
}

# Presence checks. `arp` matches the display name in Add/Remove Programs (the snapshot
# below); `cmd` asks whether something is on PATH, which is both cheaper and more honest
# for command line tools. Each item picks whichever is reliable for it.
function Test-CatalogArp($snapshot, [string]$pattern) {
    foreach ($name in $snapshot.arp) { if ($name -match $pattern) { return $true } }
    $false
}

# winget puts portable command line tools (lazygit, fzf, ...) in its Links folder, which a
# process started before their first install does not have on PATH yet. Programs and .ps1
# shims only: an untyped lookup that misses searches every module on the way (~45 of these
# run per catalog refresh).
function Test-CatalogCommand([string]$name) {
    [bool](Get-Command $name -CommandType Application, ExternalScript -ErrorAction SilentlyContinue) -or
        (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\$name.exe"))
}

# Microsoft Store apps are not in Add/Remove Programs; they are packages.
function Test-CatalogAppx([string]$pattern) {
    [bool](Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue)
}

# Every winget id here was checked against the winget index with `winget show -e --id`.
# Anything that did not resolve was dropped rather than shipped as a row that fails on
# click: Ghostty has no Windows package yet, and the official ChatGPT and Xbox apps are
# Store-only, which needs an --source msstore path this does not have yet.
# `silent = 'none'` marks a package whose manifest has no silent switch: installing it
# from the menu opens its own setup window, and `winarchy update` leaves it to update itself.
# Rows with no winget package install another way, like Herdr's `install`/`remove` blocks:
# a global npm package (the coding agents), or a Microsoft Store product, which winget
# installs from its msstore source. `id` is still the journal key. Package names and
# Store ids here were each checked (npm view / winget show --source msstore).
function Install-NpmGlobal([string]$Package, [string]$Label) {
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw "$Label installs with npm: install Node.js first (Install > Development > Node.js)" }
    & npm install -g $Package
    if ($LASTEXITCODE -ne 0) { throw "npm could not install $Label; try: npm install -g $Package" }
}
function Uninstall-NpmGlobal([string]$Package, [string]$Label) {
    & npm uninstall -g $Package
    if ($LASTEXITCODE -ne 0) { throw "npm could not remove $Label; try: npm uninstall -g $Package" }
}
function Install-StoreApp([string]$StoreId, [string]$Label) {
    & winget install --id $StoreId --source msstore --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget could not install $Label from the Microsoft Store; try: winget install --id $StoreId --source msstore" }
}
function Uninstall-StoreApp([string]$StoreId, [string]$Label) {
    & winget uninstall --id $StoreId --silent --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw "winget could not remove $Label; try: winget uninstall --id $StoreId" }
}

$Catalog = @(
    @{
        # Omarchy's own desktop apps (the ones its install puts on every machine), where
        # Windows has the same program.
        key = 'gui'; label = 'Desktop Apps'; icon = $CatalogGlyph.gui
        items = @(
            @{ key = 'obsidian';    label = 'Obsidian';    id = 'Obsidian.Obsidian';                 test = { param($s) Test-CatalogArp $s '^Obsidian' } }
            @{ key = 'libreoffice'; label = 'LibreOffice'; id = 'TheDocumentFoundation.LibreOffice'; test = { param($s) Test-CatalogArp $s '^LibreOffice' } }
            @{ key = 'xournalpp';   label = 'Xournal++ (PDF notes)'; id = 'Xournal++.Xournal++';     test = { param($s) Test-CatalogArp $s '^Xournal\+\+' } }
            @{ key = 'pinta';       label = 'Pinta';       id = 'Pinta.Pinta';                       test = { param($s) Test-CatalogArp $s '^Pinta' } }
            @{ key = 'mpv';         label = 'mpv';         id = 'shinchiro.mpv';                     test = { param($s) (Test-CatalogCommand 'mpv') -or (Test-CatalogArp $s '^mpv\b') } }
            @{ key = 'obs';         label = 'OBS Studio';  id = 'OBSProject.OBSStudio';              test = { param($s) Test-CatalogArp $s '^OBS Studio' } }
            @{ key = 'kdenlive';    label = 'Kdenlive';    id = 'KDE.Kdenlive';                      test = { param($s) Test-CatalogArp $s '^Kdenlive' } }
        )
    },
    @{
        # Omarchy's web apps (default/webapps.json, lib/webapps.ps1): a site in its own window,
        # in Start, with Omarchy's key where it has one. Install > Web App adds any other site.
        key = 'webapps'; label = 'Web Apps'; icon = $CatalogGlyph.webapps
        items = @(if (Get-Command Get-WebAppCatalogItems -ErrorAction SilentlyContinue) { Get-WebAppCatalogItems })
    },
    @{
        # Omarchy's terminal apps. Portable winget packages: they land on PATH through
        # winget's Links folder.
        key = 'tui'; label = 'TUI'; icon = $CatalogGlyph.tui
        items = @(
            @{ key = 'lazygit';    label = 'lazygit';    id = 'JesseDuffield.lazygit';    test = { Test-CatalogCommand 'lazygit' }; tui = @{ name = 'lazygit'; command = 'lazygit' } }
            @{ key = 'lazydocker'; label = 'lazydocker'; id = 'JesseDuffield.Lazydocker'; test = { Test-CatalogCommand 'lazydocker' }; note = 'It talks to Docker Desktop (Install > Development > Docker Desktop).'; tui = @{ name = 'lazydocker'; command = 'lazydocker' } }
            @{ key = 'dua';        label = 'dua (disk usage)'; id = 'Byron.dua-cli';      test = { Test-CatalogCommand 'dua' }; tui = @{ name = 'dua'; command = 'dua'; args = 'interactive' } }
            @{ key = 'cliamp';     label = 'Cliamp (music)'; id = 'Bjarneo.Cliamp';       test = { Test-CatalogCommand 'cliamp' }; note = 'Cliamp plays through FFmpeg and streams with yt-dlp (Install > Windows).'; tui = @{ name = 'Cliamp'; command = 'cliamp' } }
        )
    },
    @{
        # The shell tools Omarchy's bash setup uses. `winarchy shell on` wires them into
        # PowerShell (lib/shell.ps1); they work on their own too.
        key = 'shell'; label = 'Shell Tools'; icon = $CatalogGlyph.shell
        items = @(
            @{ key = 'starship'; label = 'Starship (prompt)'; id = 'Starship.Starship';       test = { Test-CatalogCommand 'starship' } }
            @{ key = 'zoxide';   label = 'zoxide (z)';        id = 'ajeetdsouza.zoxide';      test = { Test-CatalogCommand 'zoxide' } }
            @{ key = 'eza';      label = 'eza (ls)';          id = 'eza-community.eza';       test = { Test-CatalogCommand 'eza' } }
            @{ key = 'fzf';      label = 'fzf';               id = 'junegunn.fzf';            test = { Test-CatalogCommand 'fzf' } }
            @{ key = 'bat';      label = 'bat (cat)';         id = 'sharkdp.bat';             test = { Test-CatalogCommand 'bat' } }
            @{ key = 'ripgrep';  label = 'ripgrep (rg)';      id = 'BurntSushi.ripgrep.MSVC'; test = { Test-CatalogCommand 'rg' } }
            @{ key = 'fd';       label = 'fd';                id = 'sharkdp.fd';              test = { Test-CatalogCommand 'fd' } }
            @{ key = 'jq';       label = 'jq';                id = 'jqlang.jq';               test = { Test-CatalogCommand 'jq' } }
            @{ key = 'gh';       label = 'GitHub CLI (gh)';   id = 'GitHub.cli';              test = { Test-CatalogCommand 'gh' } }
        )
    },
    @{
        key = 'ai'; label = 'AI'; icon = $CatalogGlyph.ai
        items = @(
            @{ key = 'chatgpt';     label = 'ChatGPT Desktop'; id = 'store-9nt1r1c2hh7j'
               test = { Test-CatalogAppx '*ChatGPT*' }
               install = { Install-StoreApp '9NT1R1C2HH7J' 'ChatGPT' }; remove = { Uninstall-StoreApp '9NT1R1C2HH7J' 'ChatGPT' }
               note = 'ChatGPT comes from the Microsoft Store.' }
            @{ key = 'claude';      label = 'Claude Desktop'; id = 'Anthropic.Claude';       test = { param($s) Test-CatalogArp $s 'Claude' } }
            @{ key = 'openclaw';    label = 'OpenClaw'; id = 'npm-openclaw'
               test = { Test-CatalogCommand 'openclaw' }
               install = { Install-NpmGlobal 'openclaw' 'OpenClaw' }; remove = { Uninstall-NpmGlobal 'openclaw' 'OpenClaw' } }
            @{ key = 'ollama';      label = 'Ollama';         id = 'Ollama.Ollama';          test = { Test-CatalogCommand 'ollama' } }
            @{ key = 'lm-studio';   label = 'LM Studio';      id = 'ElementLabs.LMStudio';   test = { param($s) Test-CatalogArp $s 'LM Studio' } }
            @{ key = 'perplexity';  label = 'Perplexity';     id = 'Perplexity.Perplexity';  test = { param($s) Test-CatalogArp $s 'Perplexity' } }
        )
    },
    @{
        # Omarchy installs these lazily through Setup > Defaults > Agent; here they are also
        # listed so Install shows every agent on offer. Only ones with a checked package.
        key = 'agents'; label = 'AI Agents'; icon = $CatalogGlyph.ai
        items = @(
            @{ key = 'claude-code'; label = 'Claude Code'; id = 'npm-claude-code'
               test = { Test-CatalogCommand 'claude' }
               install = { Install-NpmGlobal '@anthropic-ai/claude-code' 'Claude Code' }; remove = { Uninstall-NpmGlobal '@anthropic-ai/claude-code' 'Claude Code' } }
            @{ key = 'codex'; label = 'Codex'; id = 'npm-codex'
               test = { Test-CatalogCommand 'codex' }
               install = { Install-NpmGlobal '@openai/codex' 'Codex' }; remove = { Uninstall-NpmGlobal '@openai/codex' 'Codex' } }
            @{ key = 'copilot-cli'; label = 'GitHub Copilot'; id = 'npm-copilot'
               test = { Test-CatalogCommand 'copilot' }
               install = { Install-NpmGlobal '@github/copilot' 'GitHub Copilot' }; remove = { Uninstall-NpmGlobal '@github/copilot' 'GitHub Copilot' } }
            @{ key = 'opencode'; label = 'OpenCode'; id = 'npm-opencode'
               test = { Test-CatalogCommand 'opencode' }
               install = { Install-NpmGlobal 'opencode-ai' 'OpenCode' }; remove = { Uninstall-NpmGlobal 'opencode-ai' 'OpenCode' } }
            @{ key = 'grok-cli'; label = 'Grok'; id = 'npm-grok'
               test = { Test-CatalogCommand 'grok' }
               install = { Install-NpmGlobal '@xai-official/grok' 'Grok' }; remove = { Uninstall-NpmGlobal '@xai-official/grok' 'Grok' } }
            @{ key = 'antigravity-cli'; label = 'Antigravity'; id = 'Google.AntigravityCLI'
               test = { Test-CatalogCommand 'agy' } }
        )
    },
    @{
        key = 'gaming'; label = 'Gaming'; icon = $CatalogGlyph.gaming
        items = @(
            @{ key = 'steam';       label = 'Steam';              id = 'Valve.Steam';                              test = { param($s) Test-CatalogArp $s '^Steam' }; note = 'Steam installs its own graphics prerequisites on first run.' }
            @{ key = 'heroic';      label = 'Heroic (Epic Games)'; id = 'HeroicGamesLauncher.HeroicGamesLauncher';  test = { param($s) Test-CatalogArp $s 'Heroic' } }
            @{ key = 'retroarch';   label = 'RetroArch';          id = 'Libretro.RetroArch';                       test = { param($s) Test-CatalogArp $s 'RetroArch' } }
            @{ key = 'battlenet';   label = 'Battle.net';         id = 'Blizzard.BattleNet';                       test = { param($s) Test-CatalogArp $s 'Battle\.net' }; silent = 'none' }
            @{ key = 'minecraft';   label = 'Minecraft';          id = 'Mojang.MinecraftLauncher';                 test = { param($s) Test-CatalogArp $s 'Minecraft' } }
            @{ key = 'geforce-now'; label = 'NVIDIA GeForce NOW'; id = 'Nvidia.GeForceNow';                        test = { param($s) Test-CatalogArp $s 'GeForce NOW' } }
            @{ key = 'playnite';    label = 'Playnite';           id = 'Playnite.Playnite';                        test = { param($s) Test-CatalogArp $s 'Playnite' } }
            @{ key = 'moonlight';   label = 'Moonlight (game streaming)'; id = 'MoonlightGameStreamingProject.Moonlight'; test = { param($s) Test-CatalogArp $s '^Moonlight' } }
            @{ key = 'xbox';        label = 'Xbox (Cloud Gaming)'; id = 'store-9mv0b5hzvk9z'
               test = { Test-CatalogAppx 'Microsoft.GamingApp' }
               install = { Install-StoreApp '9MV0B5HZVK9Z' 'Xbox' }; remove = { Uninstall-StoreApp '9MV0B5HZVK9Z' 'Xbox' } }
            @{ key = 'xbox-controllers'; label = 'Xbox Controllers'; id = 'store-9nblggh30xj3'
               test = { Test-CatalogAppx 'Microsoft.XboxDevices' }
               install = { Install-StoreApp '9NBLGGH30XJ3' 'Xbox Accessories' }; remove = { Uninstall-StoreApp '9NBLGGH30XJ3' 'Xbox Accessories' } }
        )
    },
    @{
        key = 'development'; label = 'Development'; icon = $CatalogGlyph.development
        items = @(
            @{ key = 'git';     label = 'Git';            id = 'Git.Git';                          test = { Test-CatalogCommand 'git' } }
            @{ key = 'python';  label = 'Python';         id = 'Python.Python.3.13';               test = { param($s) Test-CatalogArp $s '^Python 3\.' } }
            @{ key = 'node';    label = 'Node.js';        id = 'OpenJS.NodeJS';                    test = { Test-CatalogCommand 'node' } }
            @{ key = 'bun';     label = 'Bun';            id = 'Oven-sh.Bun';                      test = { Test-CatalogCommand 'bun' } }
            @{ key = 'deno';    label = 'Deno';           id = 'DenoLand.Deno';                    test = { Test-CatalogCommand 'deno' } }
            @{ key = 'go';      label = 'Go';             id = 'GoLang.Go';                        test = { Test-CatalogCommand 'go' } }
            @{ key = 'rust';    label = 'Rust';           id = 'Rustlang.Rustup';                  test = { Test-CatalogCommand 'rustup' } }
            @{ key = 'dotnet';  label = '.NET SDK';       id = 'Microsoft.DotNet.SDK.9';           test = { Test-CatalogCommand 'dotnet' } }
            @{ key = 'java';    label = 'Java (Temurin)'; id = 'EclipseAdoptium.Temurin.21.JDK';   test = { Test-CatalogCommand 'java' } }
            @{ key = 'php';     label = 'PHP';            id = 'PHP.PHP.8.3';                      test = { Test-CatalogCommand 'php' } }
            @{ key = 'docker';  label = 'Docker Desktop'; id = 'Docker.DockerDesktop';             test = { param($s) Test-CatalogArp $s 'Docker Desktop' } }
            @{ key = 'ruby';    label = 'Ruby';           id = 'RubyInstallerTeam.Ruby.3.4';       test = { Test-CatalogCommand 'ruby' } }
            @{ key = 'elixir';  label = 'Elixir';         id = 'Elixir.Elixir';                    test = { Test-CatalogCommand 'elixir' } }
            @{ key = 'zig';     label = 'Zig';            id = 'zig.zig';                          test = { Test-CatalogCommand 'zig' } }
            @{ key = 'ocaml';   label = 'OCaml (opam)';   id = 'OCaml.opam';                       test = { Test-CatalogCommand 'opam' } }
            @{ key = 'scala';   label = 'Scala (CLI)';    id = 'VirtusLab.ScalaCLI';               test = { Test-CatalogCommand 'scala-cli' } }
        )
    },
    @{
        key = 'editor'; label = 'Editor'; icon = $CatalogGlyph.editor
        items = @(
            @{ key = 'vscode';  label = 'VS Code';      id = 'Microsoft.VisualStudioCode'; test = { Test-CatalogCommand 'code' } }
            @{ key = 'cursor';  label = 'Cursor';       id = 'Anysphere.Cursor';           test = { param($s) Test-CatalogArp $s '^Cursor' } }
            @{ key = 'zed';     label = 'Zed';          id = 'ZedIndustries.Zed';          test = { param($s) Test-CatalogArp $s '^Zed' } }
            @{ key = 'sublime'; label = 'Sublime Text'; id = 'SublimeHQ.SublimeText.4';    test = { param($s) Test-CatalogArp $s 'Sublime Text' } }
            @{ key = 'helix';   label = 'Helix';        id = 'Helix.Helix';                test = { Test-CatalogCommand 'hx' } }
            @{ key = 'neovim';  label = 'Neovim';       id = 'Neovim.Neovim';              test = { Test-CatalogCommand 'nvim' } }
            @{ key = 'vim';     label = 'Vim';          id = 'vim.vim';                    test = { param($s) Test-CatalogArp $s '^Vim\b' } }
            @{ key = 'emacs';   label = 'Emacs';        id = 'GNU.Emacs';                  test = { Test-CatalogCommand 'emacs' } }
        )
    },
    @{
        key = 'browser'; label = 'Browser'; icon = $CatalogGlyph.windows
        items = @(
            @{ key = 'chrome';  label = 'Google Chrome'; id = 'Google.Chrome';        test = { param($s) Test-CatalogArp $s 'Google Chrome' } }
            @{ key = 'edge';    label = 'Microsoft Edge'; id = 'Microsoft.Edge';      test = { param($s) Test-CatalogArp $s 'Microsoft Edge' } }
            @{ key = 'brave';   label = 'Brave';          id = 'Brave.Brave';         test = { param($s) Test-CatalogArp $s 'Brave' } }
            @{ key = 'firefox'; label = 'Firefox';        id = 'Mozilla.Firefox';     test = { param($s) Test-CatalogArp $s 'Mozilla Firefox' } }
            @{ key = 'zen';     label = 'Zen';            id = 'Zen-Team.Zen-Browser'; test = { param($s) Test-CatalogArp $s '^Zen' } }
        )
    },
    @{
        key = 'terminal'; label = 'Terminal'; icon = $CatalogGlyph.terminal
        items = @(
            @{ key = 'windows-terminal'; label = 'Windows Terminal'; id = 'Microsoft.WindowsTerminal'; test = { Test-CatalogCommand 'wt' } }
            @{ key = 'alacritty';        label = 'Alacritty';        id = 'Alacritty.Alacritty';       test = { Test-CatalogCommand 'alacritty' } }
            @{ key = 'wezterm';          label = 'WezTerm';          id = 'wez.wezterm';               test = { param($s) Test-CatalogArp $s 'WezTerm' } }
            # Herdr publishes no winget package, so this row installs itself (lib/herdr.ps1)
            # instead of going through winget. `install`/`remove` on an item mean "do it this
            # way instead"; `id` is still the journal key, so uninstall knows it was ours.
            @{ key = 'herdr'; label = 'Herdr (multiplexer)'; id = 'herdr'
               test = { Test-HerdrInstalled }
               install = { Install-Herdr }; remove = { Uninstall-Herdr }
               note = 'Herdr installs from herdr.dev (no winget package); the binary is unsigned.'
               tui = @{ name = 'Herdr'; exe = { Get-HerdrExe } } }
        )
    },
    @{
        key = 'service'; label = 'Service'; icon = $CatalogGlyph.service
        items = @(
            @{ key = '1password'; label = '1Password'; id = 'AgileBits.1Password';        test = { param($s) Test-CatalogArp $s '1Password' } }
            @{ key = 'bitwarden'; label = 'Bitwarden'; id = 'Bitwarden.Bitwarden';        test = { param($s) Test-CatalogArp $s 'Bitwarden' } }
            @{ key = 'dropbox';   label = 'Dropbox';   id = 'Dropbox.Dropbox';            test = { param($s) Test-CatalogArp $s 'Dropbox' } }
            @{ key = 'spotify';   label = 'Spotify';   id = 'Spotify.Spotify';            test = { param($s) Test-CatalogArp $s 'Spotify' } }
            @{ key = 'signal';    label = 'Signal';    id = 'OpenWhisperSystems.Signal';  test = { param($s) Test-CatalogArp $s 'Signal' } }
            # Tailscale also gets the bar icon and panel (Omarchy's omarchy.tailscale): postInstall
            # runs after winget, to start its sign-in (lib/tailscale.ps1).
            @{ key = 'tailscale'; label = 'Tailscale'; id = 'Tailscale.Tailscale';        test = { param($s) Test-CatalogArp $s 'Tailscale' }; postInstall = { Start-TailscaleApp } }
            @{ key = 'nordvpn';   label = 'NordVPN';   id = 'NordSecurity.NordVPN';       test = { param($s) Test-CatalogArp $s 'NordVPN' } }
            # Omarchy's Trigger > Share is LocalSend too.
            @{ key = 'localsend'; label = 'LocalSend'; id = 'LocalSend.LocalSend';        test = { param($s) Test-CatalogArp $s 'LocalSend' } }
        )
    },
    @{
        # The group Omarchy has no reason to carry: things that only exist here.
        key = 'windows'; label = 'Windows'; icon = $CatalogGlyph.windows
        items = @(
            @{ key = 'powertoys'; label = 'PowerToys';    id = 'Microsoft.PowerToys';      test = { param($s) Test-CatalogArp $s 'PowerToys' } }
            @{ key = 'wsl';       label = 'WSL';          id = 'Microsoft.WSL';            test = { param($s) Test-CatalogArp $s 'Windows Subsystem for Linux' } }
            @{ key = 'sunshine';  label = 'Sunshine';     id = 'LizardByte.Sunshine';      test = { param($s) Test-CatalogArp $s 'Sunshine' }; note = 'Host for Moonlight/Apollo game streaming.' }
            @{ key = 'fastfetch'; label = 'fastfetch';    id = 'Fastfetch-cli.Fastfetch';  test = { Test-CatalogCommand 'fastfetch' } }
            @{ key = 'btop';      label = 'btop';         id = 'aristocratos.btop4win';    test = { param($s) Test-CatalogArp $s 'btop' }
               tui = @{ name = 'btop'; exe = { $d = (Get-Paths).btopDir; if ($d) { Join-Path $d 'btop4win.exe' } } } }
            @{ key = 'ffmpeg';    label = 'FFmpeg';       id = 'Gyan.FFmpeg';              test = { Test-CatalogCommand 'ffmpeg' }; note = 'Trigger > Transcode uses it.' }
            @{ key = 'yt-dlp';    label = 'yt-dlp';       id = 'yt-dlp.yt-dlp';            test = { Test-CatalogCommand 'yt-dlp' }; note = 'Alt + Shift + D downloads the video in the browser tab with it.' }
            @{ key = 'quicklook'; label = 'QuickLook (Space to preview)'; id = 'QL-Win.QuickLook'; test = { param($s) Test-CatalogArp $s '^QuickLook' } }
        )
    }
)

# Omarchy's own apps (lib/ports.ps1) lead the list, once a Windows build of one is published.
$PortItems = @(if (Get-Command Get-PortCatalogItems -ErrorAction SilentlyContinue) { Get-PortCatalogItems })
if ($PortItems) {
    $Catalog = @(@{ key = 'oma'; label = 'Omarchy Apps'; icon = $CatalogGlyph.gui; items = $PortItems }) + $Catalog
}

# One read of Add/Remove Programs answers every row. Omarchy does the same thing with a
# single `pacman -Q` snapshot instead of a process per row, for the same reason: the menu
# has to open now, not after fifty lookups.
function Get-InstalledSnapshot {
    $names = [Collections.Generic.List[string]]::new()
    foreach ($root in @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')) {
        foreach ($key in (Get-ChildItem $root -ErrorAction SilentlyContinue)) {
            $name = (Get-ItemProperty $key.PSPath -Name DisplayName -ErrorAction SilentlyContinue).DisplayName
            if ($name) { $names.Add([string]$name) }
        }
    }
    [ordered]@{ arp = @($names) }
}

function Get-CatalogItem([string]$key) {
    foreach ($group in $Catalog) {
        foreach ($item in $group.items) { if ($item.key -eq $key) { return $item } }
    }
    $null
}

# Every item, flattened, with `installed` filled in from one snapshot.
function Get-CatalogState {
    $snapshot = Get-InstalledSnapshot
    foreach ($group in $Catalog) {
        foreach ($item in $group.items) {
            $installed = try { [bool](& $item.test $snapshot) } catch { $false }
            # winget: false for a row that brings its own installer, so callers that ask
            # winget about ids (the bar's upgrade count) can leave it out - its "id" is a
            # journal key, not something winget has ever heard of.
            [pscustomobject]@{
                group = $group.key; key = $item.key; label = $item.label; id = $item.id
                installed = $installed; winget = -not $item.install
            }
        }
    }
}

# Written by `winarchy apply`, and refreshed in the background every time the menu opens
# an Install or Remove route, so installing something shows up without re-applying.
# Winget ids stay out of it: the widget only ever sends back a catalog key.
function Update-Catalog {
    $state = @(Get-CatalogState)
    $groups = foreach ($group in $Catalog) {
        [ordered]@{
            key = $group.key; label = $group.label; icon = $group.icon
            items = @(foreach ($item in $group.items) {
                    $installed = ($state | Where-Object { $_.key -eq $item.key }).installed
                    [ordered]@{ key = $item.key; label = $item.label; icon = $CatalogGlyph.item; installed = [bool]$installed }
                })
        }
    }
    # Your own terminal apps (Install > TUI > Custom TUI), for Remove > TUI.
    $custom = @(Get-CustomTuis | ForEach-Object { $_.label })
    Write-Json (Join-Path $Pack 'catalog.json') ([ordered]@{ generated = (Get-Date).ToString('s'); groups = @($groups); customTuis = $custom })
    $state
}

# Terminal apps (the `tui` rows) come from winget as a bare exe with no Start entry, so the
# menu's Apps list and Flow Launcher would never show them. Each gets a Start shortcut that
# opens it in the terminal (Programs\Winarchy, beside Omarchy's own apps), made on install,
# taken out on remove, journalled so uninstall does too, and filled in by apply for ones
# installed before this existed.
function Get-TuiShortcutPath($item) { Join-Path ([Environment]::GetFolderPath('Programs')) "Winarchy\$($item.tui.name).lnk" }

function Find-TuiExe($item) {
    if ($item.tui.exe) { $e = try { & $item.tui.exe } catch { $null }; if ($e -and (Test-Path -LiteralPath $e)) { return $e }; return $null }
    $c = Get-Command $item.tui.command -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c) { return $c.Source }
    $link = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\$($item.tui.command).exe"
    if (Test-Path -LiteralPath $link) { $link }
}

function Add-TuiShortcut($item) {
    $exe = Find-TuiExe $item
    if (-not $exe) { Log "$($item.label): no exe found for its Start shortcut yet"; return $false }
    $lnkPath = Get-TuiShortcutPath $item
    New-Item -ItemType Directory -Force (Split-Path $lnkPath) | Out-Null
    Save-File $lnkPath
    $wt = (Get-Command wt.exe -ErrorAction SilentlyContinue).Source
    $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnkPath)
    if ($wt) {
        $s.TargetPath = $wt
        $s.Arguments = "new-tab --title `"$($item.tui.name)`" `"$exe`"$(if ($item.tui.args) { " $($item.tui.args)" })"
    } else {
        $s.TargetPath = $exe
        $s.Arguments = "$($item.tui.args)"
    }
    $s.WorkingDirectory = $env:USERPROFILE
    $s.IconLocation = "$exe,0"
    $s.Description = "$($item.tui.name) in the terminal"
    $s.Save()
    try { Initialize-ShortcutNative; [Winarchy.Shortcut]::SetAppId($lnkPath, "Winarchy.Tui.$($item.key)") } catch { Log "$($item.label) shortcut: no AppUserModelID ($($_.Exception.Message))" }
    $true
}

function Remove-TuiShortcut($item) {
    $lnk = Get-TuiShortcutPath $item
    Remove-Item -LiteralPath $lnk -Force -ErrorAction SilentlyContinue
    $dir = Split-Path $lnk
    if ((Test-Path -LiteralPath $dir) -and -not (Get-ChildItem -LiteralPath $dir -Force)) { Remove-Item -LiteralPath $dir -Force -ErrorAction SilentlyContinue }
}

# apply, and every refresh of the Apps list: a shortcut for every installed terminal app
# that lacks one (installed with winget by hand counts too), and none for one that was
# uninstalled some other way.
function Sync-TuiShortcuts {
    $snapshot = Get-InstalledSnapshot
    foreach ($item in $Catalog | ForEach-Object { $_.items } | Where-Object { $_.tui }) {
        $installed = try { [bool](& $item.test $snapshot) } catch { $false }
        $has = Test-Path -LiteralPath (Get-TuiShortcutPath $item)
        if ($installed -and -not $has) { [void](Add-TuiShortcut $item) }
        elseif (-not $installed -and $has) { Remove-TuiShortcut $item }
    }
    # Your own (Install > TUI > Custom TUI): kept while the command is still there.
    foreach ($item in Get-CustomTuis) {
        if (-not (Test-Path -LiteralPath (Get-TuiShortcutPath $item)) -and (Find-TuiExe $item)) { [void](Add-TuiShortcut $item) }
    }
}

# Omarchy's Install > TUI takes any terminal program: a name and the command that starts it.
# The list lives in tuis.json beside config.json (a setting, so uninstall can keep it), and
# each one gets the same Start shortcut as a catalog row.
function Get-CustomTuiFile { Join-Path $Data 'tuis.json' }

function Get-CustomTuis {
    $raw = Read-Json (Get-CustomTuiFile)
    foreach ($t in @($raw.tuis)) {
        if (-not $t.name -or -not $t.command) { continue }
        @{
            key = 'custom-' + ([string]$t.name).ToLowerInvariant() -replace '[^a-z0-9]+', '-'
            label = [string]$t.name
            tui = @{ name = [string]$t.name; command = [string]$t.command; args = [string]$t.args }
        }
    }
}

function Add-CustomTui([string]$Name, [string]$Command) {
    if (-not $Name) { $Name = Read-Host 'Name (as it shows in Apps)' }
    if (-not $Command) { $Command = Read-Host 'Command (e.g. btop, or a full path, then any arguments)' }
    $Name = $Name.Trim(); $Command = $Command.Trim()
    if (-not $Name -or -not $Command) { throw 'a terminal app needs a name and a command' }
    if ($Name -match '[\\/:*?"<>|]') { throw "a name can't contain \ / : * ? `" < > |" }
    # The program, then whatever follows it; a path with spaces comes in quotes.
    $exe, $rest = if ($Command -match '^"([^"]+)"\s*(.*)$' -or $Command -match '^(\S+)\s*(.*)$') { $Matches[1], $Matches[2] }
    $item = @{ key = 'custom'; label = $Name; tui = @{ name = $Name; command = $exe; args = $rest } }
    if (-not (Find-TuiExe $item)) { throw "can't find '$exe' (is it installed, and on PATH?)" }
    $file = Get-CustomTuiFile
    $list = @(@((Read-Json $file).tuis) | Where-Object { $_ -and $_.name -ne $Name }) + [ordered]@{ name = $Name; command = $exe; args = $rest }
    Write-Json $file ([ordered]@{ tuis = $list })
    $item = Get-CustomTuis | Where-Object { $_.label -eq $Name } | Select-Object -First 1
    Remove-TuiShortcut $item   # a changed command replaces the old shortcut
    [void](Add-TuiShortcut $item)
    [void](Update-AppList)
    [void](Update-Catalog)
    Write-Ok "$Name is in Start and the menu's Apps list"
}

function Remove-CustomTui([string]$Name) {
    $mine = @(Get-CustomTuis)
    if (-not $Name) {
        if (-not $mine) { Write-Host 'No custom terminal apps.'; return }
        $mine | ForEach-Object { Write-Host "  $($_.label)" }
        $Name = Read-Host 'Remove which one'
    }
    $item = $mine | Where-Object { $_.label -eq $Name } | Select-Object -First 1
    if (-not $item) { throw "no custom terminal app named '$Name'" }
    Remove-TuiShortcut $item
    $file = Get-CustomTuiFile
    Write-Json $file ([ordered]@{ tuis = @(@((Read-Json $file).tuis) | Where-Object { $_ -and $_.name -ne $Name }) })
    [void](Update-AppList)
    [void](Update-Catalog)
    Write-Ok "Removed $Name"
}

function Install-CatalogItem([string]$key) {
    $item = Get-CatalogItem $key
    if (-not $item) { throw "unknown catalog item '$key' (winarchy catalog lists them)" }
    $snapshot = Get-InstalledSnapshot
    $present = try { [bool](& $item.test $snapshot) } catch { $false }
    if ($present) { Write-Ok "$($item.label): already installed"; [void](Update-Catalog); return }
    if ($item.note) { Write-Ok $item.note }
    # A row with its own installer (nothing on winget) does its own journalling, because
    # what has to be recorded to undo it is not a winget package.
    if ($item.install) {
        & $item.install
        if ($item.tui -and (Add-TuiShortcut $item)) { Write-Ok "$($item.tui.name) is in Start and the menu's Apps list" }
        [void](Update-Catalog); return
    }
    # Journal before the change, so `winarchy uninstall` knows this one was ours.
    Save-Winget $item.id $false 'menu'
    $ok = Install-WingetPackage $item.id $item.label $item.scope
    [void](Update-Catalog)
    if (-not $ok) { throw "winget could not install $($item.label); try: winget install -e --id $($item.id)" }
    # A terminal app gets its Start entry (the Apps list, Flow Launcher).
    if ($item.tui -and (Add-TuiShortcut $item)) { Write-Ok "$($item.tui.name) is in Start and the menu's Apps list" }
    # Setup after the package itself (Tailscale: start its sign-in, show it in the bar).
    if ($item.postInstall) { & $item.postInstall }
}

function Uninstall-CatalogItem([string]$key) {
    $item = Get-CatalogItem $key
    if (-not $item) { throw "unknown catalog item '$key' (winarchy catalog lists them)" }
    Write-Ok "removing $($item.label) ($($item.id))..."
    if ($item.tui) { Remove-TuiShortcut $item }
    if ($item.remove) {
        & $item.remove
        Remove-JournalEntry "winget|$($item.id)"
        [void](Update-Catalog)
        return
    }
    & winget uninstall -e --id $item.id --silent --disable-interactivity | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "winget could not remove $($item.label); try: winget uninstall -e --id $($item.id)" }
    # It is gone, so the journal must stop claiming it: leaving the entry would make
    # `winarchy uninstall` try to remove it a second time.
    Remove-JournalEntry "winget|$($item.id)"
    [void](Update-Catalog)
}
