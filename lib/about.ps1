<#
  Omarchy's About (fastfetch with the branding logo), for Windows. Opened by
  `menu.ahk about` in a floating "Omarchy About" terminal; any key closes it.
  The config is written fresh each time so theme/font/version are current.
#>
$Verb = 'about'
. "$PSScriptRoot\common.ps1"

$ff = (Get-Command fastfetch.exe -ErrorAction SilentlyContinue).Source
if (-not $ff) {
    Write-Host 'fastfetch is not installed:  winget install -e --id Fastfetch-cli.Fastfetch' -ForegroundColor Yellow
    [void][Console]::ReadKey($true); exit
}

$logo = Join-Path $Data 'branding\about.txt'
if (-not (Test-Path $logo)) {
    New-Item -ItemType Directory -Force (Split-Path $logo) | Out-Null
    Copy-Item (Join-Path $Themes '_templates\icon.txt') $logo -ErrorAction SilentlyContinue
}
$state = Read-State
$version = (Get-Content -Raw (Join-Path $Code 'VERSION') -ErrorAction SilentlyContinue)?.Trim()
$font = if ($state.font) { $state.font } else { 'JetBrainsMono Nerd Font' }
$install = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).InstallDate
$age = if ($install) { [int](([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $install) / 86400) } else { '?' }
$updated = try { (git -C $Code log -1 --format=%cr 2>$null) } catch { $null }
$dots = (38, 37, 36, 35, 34, 33, 32, 31 | ForEach-Object { "`e[${_}m●" }) -join ''
$line = { param($title) $l = [int][Math]::Floor((52 - $title.Length) / 2); "`e[90m┌" + ('─' * $l) + $title + ('─' * (52 - $title.Length - $l)) + '┐' }

$modules = @(
    'break', 'break',
    @{ type = 'custom'; format = (& $line 'Hardware') },
    @{ type = 'host'; key = ' PC'; keyColor = 'green' },
    @{ type = 'cpu'; key = '│ ├'; keyColor = 'green' },
    @{ type = 'gpu'; key = '│ ├'; format = '{name}'; keyColor = 'green' },
    @{ type = 'display'; key = '│ ├󱄄'; keyColor = 'green' },
    @{ type = 'disk'; key = '│ ├󰋊'; keyColor = 'green' },
    @{ type = 'memory'; key = '│ ├'; keyColor = 'green' },
    @{ type = 'swap'; key = '└ └󰓡 '; keyColor = 'green' },
    @{ type = 'custom'; format = "`e[90m└────────────────────────────────────────────────────┘" },
    'break',
    @{ type = 'custom'; format = (& $line 'Software') },
    @{ type = 'custom'; key = ' OS'; keyColor = 'blue'; format = "Winarchy $version (Omarchy $((Get-Config).omarchyTag) themes)" },
    @{ type = 'os'; key = '│ ├'; keyColor = 'blue' },
    @{ type = 'kernel'; key = '│ ├'; keyColor = 'blue' },
    @{ type = 'custom'; key = '│ ├'; keyColor = 'blue'; format = 'GlazeWM + Zebar' },
    @{ type = 'terminal'; key = '│ ├'; keyColor = 'blue' },
    @{ type = 'packages'; key = '│ ├󰏖'; keyColor = 'blue' },
    @{ type = 'custom'; key = '│ ├󰸌'; keyColor = 'blue'; format = "$($state.theme) $dots`e[0m" },
    @{ type = 'custom'; key = '└ └'; keyColor = 'blue'; format = $font },
    @{ type = 'custom'; format = "`e[90m└────────────────────────────────────────────────────┘" },
    'break',
    @{ type = 'custom'; format = (& $line 'Age / Uptime / Update') },
    @{ type = 'custom'; key = '󱦟 OS Age'; keyColor = 'magenta'; format = "$age days" },
    @{ type = 'uptime'; key = '󱫐 Uptime'; keyColor = 'magenta' },
    @{ type = 'custom'; key = ' Update'; keyColor = 'magenta'; format = $(if ($updated) { $updated } else { 'never' }) },
    @{ type = 'custom'; format = "`e[90m└────────────────────────────────────────────────────┘" },
    'break'
)
$cfg = [ordered]@{
    '$schema' = 'https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json'
    logo = [ordered]@{ type = 'file'; source = $logo; color = @{ '1' = 'green' }; padding = @{ top = 2; right = 6; left = 2 } }
    display = @{ disableLinewrap = $true }
    modules = $modules
}
$file = Join-Path $Generated 'fastfetch.jsonc'
Write-Json $file $cfg 6
Clear-Host
& $ff -c $file
[Console]::Write("`e[?25l")
[void][Console]::ReadKey($true)
