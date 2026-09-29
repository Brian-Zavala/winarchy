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
    item        = [char]::ConvertFromUtf32(0xF0CB)
}

# Presence checks. `arp` matches the display name in Add/Remove Programs (the snapshot
# below); `cmd` asks whether something is on PATH, which is both cheaper and more honest
# for command line tools. Each item picks whichever is reliable for it.
function Test-CatalogArp($snapshot, [string]$pattern) {
    foreach ($name in $snapshot.arp) { if ($name -match $pattern) { return $true } }
    $false
}

function Test-CatalogCommand([string]$name) {
    [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# Every winget id here was checked against the winget index with `winget show -e --id`.
# Anything that did not resolve was dropped rather than shipped as a row that fails on
# click: Ghostty has no Windows package yet, and the official ChatGPT and Xbox apps are
# Store-only, which needs an --source msstore path this does not have yet.
# `silent = 'none'` marks a package whose manifest has no silent switch: installing it
# from the menu opens its own setup window, and `winarchy update` leaves it to update itself.
$Catalog = @(
    @{
        key = 'ai'; label = 'AI'; icon = $CatalogGlyph.ai
        items = @(
            @{ key = 'claude';      label = 'Claude Desktop'; id = 'Anthropic.Claude';       test = { param($s) Test-CatalogArp $s 'Claude' } }
            @{ key = 'ollama';      label = 'Ollama';         id = 'Ollama.Ollama';          test = { Test-CatalogCommand 'ollama' } }
            @{ key = 'lm-studio';   label = 'LM Studio';      id = 'ElementLabs.LMStudio';   test = { param($s) Test-CatalogArp $s 'LM Studio' } }
            @{ key = 'perplexity';  label = 'Perplexity';     id = 'Perplexity.Perplexity';  test = { param($s) Test-CatalogArp $s 'Perplexity' } }
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
               note = 'Herdr installs from herdr.dev (no winget package); the binary is unsigned.' }
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
            @{ key = 'btop';      label = 'btop';         id = 'aristocratos.btop4win';    test = { param($s) Test-CatalogArp $s 'btop' } }
        )
    }
)

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
    Write-Json (Join-Path $Pack 'catalog.json') ([ordered]@{ generated = (Get-Date).ToString('s'); groups = @($groups) })
    $state
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
    if ($item.install) { & $item.install; [void](Update-Catalog); return }
    # Journal before the change, so `winarchy uninstall` knows this one was ours.
    Save-Winget $item.id $false 'menu'
    $ok = Install-WingetPackage $item.id $item.label $item.scope
    [void](Update-Catalog)
    if (-not $ok) { throw "winget could not install $($item.label); try: winget install -e --id $($item.id)" }
    # Setup after the package itself (Tailscale: start its sign-in, show it in the bar).
    if ($item.postInstall) { & $item.postInstall }
}

function Uninstall-CatalogItem([string]$key) {
    $item = Get-CatalogItem $key
    if (-not $item) { throw "unknown catalog item '$key' (winarchy catalog lists them)" }
    Write-Ok "removing $($item.label) ($($item.id))..."
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
