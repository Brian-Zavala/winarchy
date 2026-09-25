<#
.SYNOPSIS
  omarchy-win: Omarchy's look, keys and themes on Windows 11 (GlazeWM + Zebar + Flow Launcher).

.DESCRIPTION
  omarchy-win install [-Yes] [-Adopt]     set everything up (asks a few questions; -Yes = defaults)
  omarchy-win uninstall [-KeepApps] [-DryRun] [-Purge]
                                          undo every change, from the backup journal
  omarchy-win update                      pull the latest omarchy-win, re-apply, upgrade apps
  omarchy-win apply [-MonitorsOnly]       regenerate configs from config.json (after editing it)
  omarchy-win doctor [-Fix]               check the setup and explain what's wrong
  omarchy-win detect                      re-detect apps, paths, monitors (paths.json)
  omarchy-win theme <name> | theme list   switch theme (bar, borders, terminal, Flow, accent, ...)
  omarchy-win bg <path> | bg next         set the background (and lock screen)
  omarchy-win sync [-Offline]             download Omarchy themes + backgrounds, rebuild pickers
  omarchy-win font [<family> | list]      terminal, bar, menus and launcher font
  omarchy-win font-install <Name>         install a Nerd Font (CascadiaMono, Meslo, FiraCode, ...)
  omarchy-win browser-setup               tint Chrome/Brave's toolbar with the theme (one admin prompt)
  omarchy-win weather | update-check      refresh the bar's weather / update indicator
  omarchy-win animations [on|off|toggle|build|status]
                                          window animations (experimental GlazeWM build)
  omarchy-win config                      open your settings file
  omarchy-win keys                        print the keybindings
  omarchy-win status | version | help

  Your settings: %USERPROFILE%\.omarchy-win\config.json   Log: %USERPROFILE%\.omarchy-win\logs
#>
param(
    [Parameter(Position = 0)][string]$Verb = 'help',
    [Parameter(Position = 1)][string]$Arg,
    [switch]$Yes, [switch]$Adopt, [switch]$KeepApps, [switch]$DryRun, [switch]$Purge,
    [switch]$Offline, [switch]$MonitorsOnly, [switch]$Fix, [switch]$NoRestart,
    # Wait for a key at the end (verbs the menu runs in a terminal window).
    [switch]$Pause
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
. "$PSScriptRoot\..\lib\animations.ps1"
. "$PSScriptRoot\..\lib\transition.ps1"

$version = (Get-Content -Raw (Join-Path $Code 'VERSION') -ErrorAction SilentlyContinue)?.Trim()

# Menu and bar actions run hidden: a failure is logged (doctor shows the recent ones)
# and the exit code tells menu.ahk to say so.
$failed = $false
try {
switch ($Verb) {
    'install' { Invoke-Install -Yes:$Yes -Adopt:$Adopt }
    { $_ -in 'uninstall', 'revert' } { Invoke-Uninstall -KeepApps:$KeepApps -DryRun:$DryRun -Purge:$Purge }
    'update' { Invoke-Update }
    'apply' { Use-Lock { Invoke-Apply -MonitorsOnly:$MonitorsOnly -NoRestart:$NoRestart } }
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
        if (-not $Arg) { throw 'usage: omarchy-win bg <image path> | bg next' }
        if ($Arg -eq 'next') { Use-Lock { Invoke-BackgroundNext } } else { Use-Lock { Set-Background $Arg (Read-State) } }
    }
    'bg-next' { Use-Lock { Invoke-BackgroundNext } }
    'browser-setup' { Enable-BrowserPolicy }
    'extras' { Install-Extras; Use-Lock { Invoke-Apply } }
    'weather' { Update-Weather }
    'update-check' { Invoke-UpdateCheck }
    'animations' { Invoke-Animations $Arg }
    { $_ -in 'font', 'font-set' } {
        if (-not $Arg -or $Arg -eq 'list') { Update-FontList | ForEach-Object { "$(if ($_.name -eq (Get-FontFamily)) { '*' } else { ' ' }) $($_.name)" } }
        else { Use-Lock { Invoke-FontSet $Arg } }
    }
    'font-install' {
        if (-not $Arg) { "fonts: $($NerdFonts.Keys -join ', ')"; return }
        Use-Lock { $family = Install-NerdFont $Arg; [void](Update-FontList); Invoke-FontSet $family }
    }
    'config' {
        if (-not (Test-Path $ConfigFile)) { Write-Json $ConfigFile ([ordered]@{ _help = 'Only the settings you change. See docs/config.md, then run: omarchy-win apply' }) }
        $p = Get-Paths
        if ($p.nvim) { & $p.nvim $ConfigFile } else { Start-Process notepad.exe $ConfigFile }
    }
    'keys' { Get-Content (Join-Path $Pack 'keybindings.txt') -ErrorAction SilentlyContinue ?? (Get-Content (Join-Path $Code 'default\keybindings.txt')) }
    'status' { $s = Read-State; "theme: $($s.theme)"; "background: $($s.background)"; "font: $(Get-FontFamily)" }
    'version' { "omarchy-win $version" }
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
