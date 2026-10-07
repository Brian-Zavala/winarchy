<#
.SYNOPSIS
  winarchy: Omarchy's look, keys and themes on Windows 11 (GlazeWM + Zebar + Flow Launcher).

.DESCRIPTION
  winarchy install [-Yes] [-Adopt]     set everything up (asks a few questions; -Yes = defaults)
  winarchy uninstall [-KeepApps] [-DryRun] [-Purge] [-Yes]
                                          undo every change, from the backup journal; asks
                                          whether to keep the apps you installed through
                                          winarchy and your settings (a reinstall restores
                                          them); -Yes keeps both without asking
  winarchy update                      pull the latest winarchy, install anything it now needs,
                                          re-apply, upgrade apps
  winarchy deps                        install whatever winarchy needs and this PC is missing
  winarchy apply [-MonitorsOnly] [-Resplit]
                                          regenerate configs from config.json (after editing it);
                                          -Resplit: split workspaces over the monitors connected now
  winarchy doctor [-Fix]               check the setup and explain what's wrong
  winarchy detect                      re-detect apps, paths, monitors (paths.json)
  winarchy theme <name> | theme list   switch theme (bar, borders, terminal, Flow, accent, ...)
  winarchy bg <path> | bg next         set the background (and lock screen)
  winarchy sync [-Offline]             download Omarchy themes + backgrounds, rebuild pickers
  winarchy font [<family> | list]      terminal, bar, menus and launcher font
  winarchy font-install <Name>         install a Nerd Font (CascadiaMono, Meslo, FiraCode, ...)
  winarchy text-size [<9-20> | reset]  text size of the bar, menus, panels and terminals
                                          (px, 12 = default; the bar's Display panel sets it)
  winarchy apps                        rebuild the menu's Apps list from what Windows has installed
  winarchy catalog                     rebuild the menu's Install/Remove lists (and show them)
  winarchy install-app <key>           install one catalog item (the menu's Install section)
  winarchy tui-add [<name> <command>] | tui-remove [<name>]
                                          any terminal program in Start and the Apps list
  winarchy ports [list|update]         Omarchy's own apps built for Windows (Omawrite, Omacalc, ...)
  winarchy shell [on|off|status]       Omarchy's shell setup in PowerShell (starship, zoxide, eza, fzf, aliases)
  winarchy remove-app <key>            remove one again (the menu's Remove section)
  winarchy herdr [status|install|layout|square|multi|swarm|config|reload|keys|shortcuts|link|welcome]
                                          Herdr (Omarchy's tmux replacement) and its agent
                                          layouts; layout/square/multi/swarm run in a Herdr
                                          pane and are also hdl / hds / hdlm / hsl in a shell;
                                          link hooks every agent on PATH into Herdr
  winarchy agent [-Inline] [-Pick] [-Prompt <text>] | agent list
                                          start the default coding agent, unattended
  winarchy default-agent <name>        pick it (claude, codex, copilot, opencode, ...)
  winarchy agent-make <theme|plugin|app>
                                          start it asking what to make (the usage panel's tiles)
  winarchy agent-login <claude|codex>[/<account>]  sign in again, then refresh its limits
  winarchy agent-account [list [-Json] | add [claude|codex] [name] | use <provider>/<id|next>
                          | rename <provider>/<id> <name> | remove <provider>/<id> [-Yes]
                          | mode <provider> <manual|auto> [threshold]]
                                     several subscriptions per agent (the usage panel's +)
  winarchy agent-usage [-Force] [<agent>]
                                          refresh the bar's agent usage (limits, tokens by
                                          day and model); runs by itself every 15 minutes
  winarchy browser-setup               tint Chrome/Brave's toolbar with the theme (one admin prompt)
  winarchy game-setup [remove]         the admin game helper (the install sets it up): Super+W / the bar
                                          close, minimize and restore games that run as administrator
                                          (one admin prompt: a small helper that runs as admin)
  winarchy game-add <name> [-NoRestart]
                                          add a game process name to config.json (Super+Ctrl+G does
                                          this for the focused window, then applies it);
                                          -NoRestart: leave GlazeWM alone until the next apply
  winarchy weather | update-check      refresh the bar's weather / update indicator
  winarchy bar [on|off|toggle]         the top bar (Super+Shift+Space); off stays off
  winarchy taskbar [on|off|toggle|status]
                                          hide the Windows taskbar (on after install)
  winarchy animations [on|off|toggle|setup|build|allow|status]
                                          window animations (experimental GlazeWM build);
                                          setup: tools + build + Defender exclusion + on;
                                          allow: exclude it from Defender (one admin prompt)
  winarchy autotile [on|off|toggle|status]
                                          Hyprland-style auto-tiling (dwindle emulation)
  winarchy config                      open your settings file
  winarchy keys                        print the keybindings
  winarchy keys-refresh                re-read the keys your own Startup scripts bind (winarchy
                                          leaves those to them; runs by itself when one is saved)
  winarchy status | version | help

  Your settings: %USERPROFILE%\.winarchy\config.json   Log: %USERPROFILE%\.winarchy\logs
#>
param(
    [Parameter(Position = 0)][string]$Verb = 'help',
    [Parameter(Position = 1)][string]$Arg,
    [Parameter(Position = 2)][string]$Arg2,
    # herdr layout <agent> <second agent> / herdr swarm <count> <command>
    [Parameter(Position = 3)][string]$Arg3,
    # agent-account mode <provider> <manual|auto> <threshold>
    [Parameter(Position = 4)][string]$Arg4,
    # agent-account list -Json
    [switch]$Json,
    [switch]$Yes, [switch]$Adopt, [switch]$KeepApps, [switch]$DryRun, [switch]$Purge,
    [switch]$Offline, [switch]$MonitorsOnly, [switch]$Resplit, [switch]$Fix, [switch]$NoRestart,
    # Wait for a key at the end (verbs the menu runs in a terminal window).
    [switch]$Pause,
    # agent: run it here rather than in its own window (a Herdr pane wants -Inline);
    # -Pick opens the chooser when no default agent is set yet.
    [switch]$Inline, [switch]$Pick, [string]$Prompt,
    # agent-usage: -Force rescans everything and re-asks for limits; -LimitsOnly reuses a
    # recent scan and only refreshes the limits (what opening the usage panel wants).
    [switch]$Force, [switch]$LimitsOnly,
    # bg: "x,y" on the monitor the background picker covers (it plays the reveal there).
    [string]$Covered,
    # sync: install's own background download (Start-ThemeDownload), not for a person to run.
    [switch]$Background
)

$ErrorActionPreference = 'Stop'
$AllLibs = 'common', 'detect', 'keys', 'render', 'themes', 'targets', 'journal', 'apply', 'setup',
    'uninstall', 'doctor', 'extras', 'apps', 'webapps', 'ports', 'catalog', 'agents', 'accounts', 'herdr',
    'shell', 'tailscale', 'winicons', 'animations', 'autotile', 'transition', 'system', 'netpanel', 'audio'
# The verbs the bar, its panels and winarchy.ahk run all day (the Audio panel every few
# seconds) load only the libraries they use: parsing all of them is a good part of a
# second's start. tests\lazyload.Tests.ps1 walks each one. Every other verb loads the lot.
$VerbLibs = @{
    'audio'         = @('common', 'netpanel', 'audio')
    'network-state' = @('common', 'netpanel')
    'speedtest-run' = @('common', 'netpanel')
    'wifi'          = @('common', 'system', 'netpanel')
    'dns-set'       = @('common', 'system')
    'winicon'       = @('common', 'winicons')
    'keys'          = @('common')
    'version'       = @('common')
}
foreach ($lib in ($VerbLibs[$Verb] ?? $AllLibs)) { . "$PSScriptRoot\..\lib\$lib.ps1" }
# Started by the bar, a key or an old terminal, this PATH can be from before an install.
Update-ProcessPath
# Started from a Claude Code shell, nothing this starts should inherit that session.
Clear-AgentSessionEnv

$version = (Get-Content -Raw (Join-Path $Code 'VERSION') -ErrorAction SilentlyContinue)?.Trim()

# Menu and bar actions run hidden: a failure is logged (doctor shows the recent ones)
# and the exit code tells menu.ahk to say so.
$failed = $false
try {
switch ($Verb) {
    'install' { Invoke-Install -Yes:$Yes -Adopt:$Adopt }
    { $_ -in 'uninstall', 'revert' } { Invoke-Uninstall -KeepApps:$KeepApps -DryRun:$DryRun -Purge:$Purge -Yes:$Yes }
    'update' { Invoke-Update }
    'apply' { Use-Lock { Invoke-Apply -MonitorsOnly:$MonitorsOnly -NoRestart:$NoRestart -Resplit:$Resplit } }
    'doctor' { Invoke-Doctor -Fix:$Fix }
    'detect' { $p = Update-Paths; $p | ConvertTo-Json -Depth 4 }
    # The background one takes no lock: the install that started it holds that one, and
    # it only adds files (each lands whole, renamed from .part).
    'sync' { if ($Background) { Save-OmarchyFiles $ThemeDownloadProgress; New-MissingThumbs } else { Use-Lock { Invoke-Sync -Offline:$Offline } } }
    { $_ -in 'theme', 'theme-set' } {
        if (-not $Arg -or $Arg -eq 'list') {
            Get-ChildItem $Themes -Directory | Where-Object Name -NotLike '_*' | ForEach-Object {
                $mark = if ($_.Name -eq (Read-State).theme) { '*' } else { ' ' }
                "$mark $($_.Name)"
            }
        } else { Use-Lock { Invoke-ThemeSet $Arg } }
    }
    { $_ -in 'bg', 'bg-set' } {
        if (-not $Arg) { throw 'usage: winarchy bg <image path> | bg next' }
        if ($Arg -eq 'next') { Use-Lock { Invoke-BackgroundNext } } else { Use-Lock { Set-Background $Arg (Read-State) @($Covered -split ',' -ne '' | ForEach-Object { [int]$_ }) } }
    }
    'bg-next' { Use-Lock { Invoke-BackgroundNext } }
    'browser-setup' { Enable-BrowserPolicy }
    'game-setup' {
        switch ($Arg) {
            # Taken away by hand: stays away (update and doctor follow config gameHelper).
            'remove' { Disable-GameHelper; Set-ConfigValue 'gameHelper' $false }
            'update' {                                 # what winarchy update runs
                Invoke-GamingStep -Update
                Write-Unfinished
                if ($script:Unfinished.Count) { throw 'the game helper was not set up' }
            }
            default { Enable-GameHelper; if ((Get-Config).gameHelper -eq $false) { Set-ConfigValue 'gameHelper' $true } }
        }
    }
    'game-add' {
        if (-not $Arg) { throw 'usage: winarchy game-add <process name>' }
        Use-Lock { Register-Game $Arg -NoGlaze:$NoRestart }
    }
    'extras' { Install-Extras; Use-Lock { Invoke-Apply } }
    # Install whatever winarchy needs and is missing (update and doctor -Fix run this).
    'deps' {
        Install-Dependencies
        Write-Unfinished
        if ($script:Unfinished.Count) { throw "$($script:Unfinished.Count) dependency step(s) did not finish" }
    }
    'weather' { Update-Weather }
    'update-check' { Invoke-UpdateCheck }
    'animations' { Invoke-Animations $Arg }
    'autotile' { Invoke-AutoTile $Arg }
    'taskbar' { Invoke-Taskbar $Arg }
    'bar' {
        # The running winarchy.ahk owns the bar (Omarchy: Super+Shift+Space).
        $wm = @{ '' = 'bar'; 'toggle' = 'bar'; 'on' = 'bar-on'; 'off' = 'bar-off' }[[string]$Arg]
        if (-not $wm) { throw "usage: winarchy bar [on|off|toggle]" }
        $p = Get-Paths
        Start-Process -FilePath $p.ahk -ArgumentList "`"$Code\ahk\menu.ahk`"", 'wm', $wm
    }
    { $_ -in 'font', 'font-set' } {
        if (-not $Arg -or $Arg -eq 'list') { Update-FontList | ForEach-Object { "$(if ($_.name -eq (Get-FontFamily)) { '*' } else { ' ' }) $($_.name)" } }
        else { Use-Lock { Invoke-FontSet $Arg } }
    }
    # Quattro's Display panel > Text size (omarchy-display-text-size).
    'text-size' { Use-Lock { Invoke-TextSize $Arg } }
    'font-install' {
        if (-not $Arg) { "fonts: $($NerdFonts.Keys -join ', ')"; return }
        Use-Lock { $family = Install-NerdFont $Arg; [void](Update-FontList); Invoke-FontSet $family }
    }
    # The Apps route's list; the menu refreshes it in the background each time it opens.
    # Terminal apps get their Start entries first, so one installed any way shows up.
    'apps' {
        try { Sync-TuiShortcuts } catch { Log "terminal app shortcuts FAILED: $($_.Exception.Message)" }
        Update-AppList | ForEach-Object { $_.name }
    }
    # Install > TUI > Custom TUI, and Remove > TUI for one of those.
    'tui-add' { Add-CustomTui $Arg $Arg2 }
    'tui-remove' { Remove-CustomTui $Arg }
    # The Install/Remove routes' list, refreshed the same way. '*' marks what is installed.
    'catalog' { Update-Catalog | ForEach-Object { "$(if ($_.installed) { '*' } else { ' ' }) $($_.group)/$($_.key)  $($_.label)" } }
    # windows.json's icon cache (bar chevron): one-shot, called by winarchy.ahk at most once per exe.
    'winicon' { if ($Arg -and $Arg2) { Update-WindowIcon $Arg $Arg2 } }
    'install-app' {
        if (-not $Arg) { throw 'usage: winarchy install-app <key>   (winarchy catalog lists them)' }
        Use-Lock { Install-CatalogItem $Arg }
    }
    'remove-app' {
        if (-not $Arg) { throw 'usage: winarchy remove-app <key>   (winarchy catalog lists them)' }
        Use-Lock { Uninstall-CatalogItem $Arg }
    }
    # Omarchy's shell setup in your PowerShell profile (lib/shell.ps1).
    'shell' { Invoke-Shell $Arg }
    # Omarchy's own apps built for Windows (lib/ports.ps1); update runs `ports update`.
    'ports' { Use-Lock { Invoke-Ports $Arg } }
    # Herdr and the agent layouts built on it. The layout verbs are meant to be run from
    # inside a Herdr pane (hdl / hds / hdlm / hsl do exactly that).
    'herdr' { Invoke-Herdr $Arg $Arg2 $Arg3 }
    'agent' {
        if ($Arg -eq 'list') {
            Get-AgentState | ForEach-Object {
                "$(if ($_.current) { '*' } else { ' ' }) $($_.key.PadRight(13)) $($_.label)$(if (-not $_.installed) { '   (not installed)' })"
            }
        } else { Invoke-Agent -Inline:$Inline -Pick:$Pick -Prompt $Prompt }
    }
    # The usage panel's "Make something" tiles and its "Sign in" (lib/agents.ps1).
    'agent-make' { Invoke-AgentMake $Arg }
    'agent-login' { Invoke-AgentLogin $Arg }
    'agent-account' { Invoke-AgentAccountCommand $Arg $Arg2 $Arg3 $Arg4 -Json:$Json -Yes:$Yes }
    # The bar's agent indicator: run every usage collector and rebuild agents.json.
    # winarchy.ahk runs this on a timer; -Force rescans and re-asks for limits now.
    'agent-usage' {
        $shown = @(Update-AgentUsage -Force:$Force -LimitsOnly:$LimitsOnly -Only $Arg)
        if (-not $shown) { 'no agent usage to show (winarchy doctor explains why, if you expected some)' }
        foreach ($a in $shown) {
            $lim = @($a.limits | ForEach-Object { '{0} {1:0}%' -f $_.label, ([double]$_.percent * 100) }) -join ', '
            "$($a.name)$(if ($a.tierLabel) { " ($($a.tierLabel))" }): $($a.todayTotalTokens) tokens today$(if ($lim) { "; $lim" })$(if ($a.usageStatusText) { "; $($a.usageStatusText)" })"
        }
    }
    'default-agent' {
        if (-not $Arg) { "default agent: $((Get-DefaultAgent) ?? 'none yet (winarchy agent list)')" }
        else {
            $key = Set-DefaultAgent $Arg
            Use-Lock { Invoke-Apply -NoRestart }
            # Omarchy's omarchy-default-agent starts the agent it just chose; picked from a
            # Make something tile, it starts on what the tile asked for.
            # (Set-DefaultAgent already said how to install one that is missing.)
            if (Test-AgentInstalled $key) {
                if ($make = Pop-AgentMakePending) { Invoke-AgentMake $make } else { Invoke-Agent }
            }
        }
    }
    'config' {
        if (-not (Test-Path $ConfigFile)) { Write-Json $ConfigFile ([ordered]@{ _help = 'Only the settings you change. See docs/config.md, then run: winarchy apply' }) }
        $p = Get-Paths
        if ($p.nvim) { & $p.nvim $ConfigFile } else { Start-Process notepad.exe $ConfigFile }
    }
    # Update > Timezone / Time, Setup > Network > DNS, and the Trigger / Install extras
    # (lib/system.ps1). The menu runs them in a terminal.
    'timezone-set' { Set-WinarchyTimeZone $Arg }
    'time-sync' { Sync-WinarchyTime }
    'dns-set' { Set-WinarchyDns $Arg }
    'reminder' {
        switch ($Arg) {
            'show' { Show-WinarchyReminders }
            'clear' { Clear-WinarchyReminders }
            # After one goes off (menu.ahk notify): the bar's bell moves on to the next.
            'refresh' { Update-ReminderFile }
            default { New-WinarchyReminder $Arg $Arg2 }
        }
    }
    'speedtest' { Invoke-SpeedTest $Arg }
    # The bar's Network panel: its state file, the speed test dials, and its Wi-Fi actions.
    'network-state' { [void](Update-NetPanelState) }
    'speedtest-run' { Invoke-SpeedRun }
    'wifi' { Invoke-WifiAction $Arg $Arg2 }
    'audio' { Invoke-AudioAction $Arg $Arg2 $Arg3 }
    # Omarchy's order: winarchy transcode [file] [format] [size]; it asks for what is missing.
    'transcode' { Invoke-Transcode $Arg $Arg2 $Arg3 }
    'share' { Start-Share }
    'web-app' { if ($Arg -eq 'remove') { Remove-WebApp $Arg2 } else { New-WebApp $Arg $Arg2 } }
    'keys' { (Get-Content (Join-Path $Pack 'keybindings.txt') -ErrorAction SilentlyContinue) ?? (Get-Content (Join-Path $Code 'default\keybindings.txt')) }
    # winarchy.ahk runs this when a script in the Startup folder changes (lib/keys.ps1).
    'keys-refresh' { Use-Lock { Invoke-KeysRefresh } }
    'status' { $s = Read-State; "theme: $($s.theme)"; "background: $($s.background)"; "font: $(Get-FontFamily)" }
    'version' { "winarchy $version" }
    default { Get-Help $PSCommandPath -Detailed | Out-String | Write-Host }
}
} catch {
    $failed = $true
    Log "FAILED: $($_.Exception.Message)"
}
if ($Pause -and -not [Console]::IsInputRedirected) {
    Write-Host "`n$(if ($failed) { 'Failed (see above).' } else { 'Done.' }) Press any key to close." -ForegroundColor $(if ($failed) { 'Yellow' } else { 'Green' })
    [void][Console]::ReadKey($true)
}
if ($failed) { exit 1 }
