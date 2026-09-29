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
  winarchy remove-app <key>            remove one again (the menu's Remove section)
  winarchy herdr [status|install|layout|square|multi|swarm|config|reload|keys|shortcuts|link|welcome]
                                          Herdr (Omarchy's tmux replacement) and its agent
                                          layouts; layout/square/multi/swarm run in a Herdr
                                          pane and are also hdl / hds / hdlm / hsl in a shell;
                                          link hooks every agent on PATH into Herdr
  winarchy agent [-Inline] [-Pick] [-Prompt <text>] | agent list
                                          start the default coding agent, unattended
  winarchy default-agent <name>        pick it (claude, codex, copilot, opencode, ...)
  winarchy agent-usage [-Force] [<agent>]
                                          refresh the bar's agent usage (limits, tokens by
                                          day and model); runs by itself every 15 minutes
  winarchy browser-setup               tint Chrome/Brave's toolbar with the theme (one admin prompt)
  winarchy game-setup [remove]         let Super+W / the bar close games that run as administrator
                                          (one admin prompt: a small helper that runs as admin)
  winarchy game-add <name>             add a game process name to config.json (Super+Ctrl+G does
                                          this for the focused window, then applies it)
  winarchy weather | update-check      refresh the bar's weather / update indicator
  winarchy bar [on|off|toggle]         the top bar (Super+Shift+Space); off stays off
  winarchy animations [on|off|toggle|setup|build|allow|status]
                                          window animations (experimental GlazeWM build);
                                          setup: tools + build + Defender exclusion + on;
                                          allow: exclude it from Defender (one admin prompt)
  winarchy autotile [on|off|toggle|status]
                                          Hyprland-style auto-tiling (dwindle emulation)
  winarchy config                      open your settings file
  winarchy keys                        print the keybindings
  winarchy status | version | help

  Your settings: %USERPROFILE%\.winarchy\config.json   Log: %USERPROFILE%\.winarchy\logs
#>
param(
    [Parameter(Position = 0)][string]$Verb = 'help',
    [Parameter(Position = 1)][string]$Arg,
    [Parameter(Position = 2)][string]$Arg2,
    # herdr layout <agent> <second agent> / herdr swarm <count> <command>
    [Parameter(Position = 3)][string]$Arg3,
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
    [string]$Covered
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\lib\common.ps1"
. "$PSScriptRoot\..\lib\detect.ps1"
. "$PSScriptRoot\..\lib\render.ps1"
. "$PSScriptRoot\..\lib\themes.ps1"
. "$PSScriptRoot\..\lib\targets.ps1"
. "$PSScriptRoot\..\lib\journal.ps1"
. "$PSScriptRoot\..\lib\apply.ps1"
. "$PSScriptRoot\..\lib\setup.ps1"
. "$PSScriptRoot\..\lib\uninstall.ps1"
. "$PSScriptRoot\..\lib\doctor.ps1"
. "$PSScriptRoot\..\lib\extras.ps1"
. "$PSScriptRoot\..\lib\apps.ps1"
. "$PSScriptRoot\..\lib\catalog.ps1"
. "$PSScriptRoot\..\lib\agents.ps1"
. "$PSScriptRoot\..\lib\herdr.ps1"
. "$PSScriptRoot\..\lib\tailscale.ps1"
. "$PSScriptRoot\..\lib\winicons.ps1"
. "$PSScriptRoot\..\lib\animations.ps1"
. "$PSScriptRoot\..\lib\autotile.ps1"
. "$PSScriptRoot\..\lib\transition.ps1"
. "$PSScriptRoot\..\lib\system.ps1"
. "$PSScriptRoot\..\lib\netpanel.ps1"
. "$PSScriptRoot\..\lib\audio.ps1"

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
    'sync' { Use-Lock { Invoke-Sync -Offline:$Offline } }
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
    'game-setup' { if ($Arg -eq 'remove') { Disable-GameHelper } else { Enable-GameHelper } }
    'game-add' {
        if (-not $Arg) { throw 'usage: winarchy game-add <process name>' }
        Use-Lock { Add-ConfigGame $Arg; Invoke-Apply -MonitorsOnly }
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
    'apps' { Update-AppList | ForEach-Object { $_.name } }
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
            # Omarchy's omarchy-default-agent starts the agent it just chose.
            # (Set-DefaultAgent already said how to install one that is missing.)
            if (Test-AgentInstalled $key) { Invoke-Agent }
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
            default { New-WinarchyReminder $Arg $Arg2 }
        }
    }
    'speedtest' { Invoke-SpeedTest $Arg }
    # The bar's Network panel: its state file, the speed test dials, and its Wi-Fi actions.
    'network-state' { [void](Update-NetPanelState) }
    'speedtest-run' { Invoke-SpeedRun }
    'wifi' { Invoke-WifiAction $Arg $Arg2 }
    'audio' { Invoke-AudioAction $Arg $Arg2 $Arg3 }
    'transcode' { Invoke-Transcode $Arg $Arg2 }
    'share' { Start-Share }
    'web-app' { if ($Arg -eq 'remove') { Remove-WebApp $Arg2 } else { New-WebApp $Arg $Arg2 } }
    'keys' { (Get-Content (Join-Path $Pack 'keybindings.txt') -ErrorAction SilentlyContinue) ?? (Get-Content (Join-Path $Code 'default\keybindings.txt')) }
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
