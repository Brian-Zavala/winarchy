# apps.json for the menu's Apps route. Omarchy's Apps opens walker on the system's
# .desktop files; the nearest thing Windows has is its own Start list, which covers both
# desktop programs and Store apps. Every entry comes back with an AppID that
# shell:AppsFolder launches, so the menu needs only one action for both kinds.

# Start lists more than things you would launch from a launcher: the shell's own folders,
# uninstallers, web links, and the help/licence files that ship beside a program. The
# file-extension rules do most of the work (a "7-Zip Help" entry points at a .chm), so the
# name rules stay narrow and only catch uninstallers, whose target is often a plain .exe.
$AppSkipName = '(?i)^uninstall(\s|$)|\buninstall(er)?$'
$AppSkipExe = '(?i)\\(unins\d*|uninstall(er)?|uninst|remove[^\\]*)\.exe$'
$AppSkipDoc = '(?i)\.(chm|hlp|txt|pdf|rtf|html?|md|url|website|ini|log|xml)$'
# A Store AppID is "<package family name>!<app id>", and a family name ends in _<13 chars>.
$AppStoreId = '^[^\\/:]+_[a-z0-9]{13}!'

function Get-InstalledApps {
    # Get-StartApps (the StartLayout module, shipped with Windows) is the supported reading
    # of the Start list. The AppsFolder shell namespace is the same data underneath, so it
    # stands in if the module ever isn't there.
    $raw = try {
        @(Get-StartApps)
    } catch {
        @((New-Object -ComObject Shell.Application).NameSpace('shell:AppsFolder').Items() |
            ForEach-Object { [pscustomobject]@{ Name = $_.Name; AppID = $_.Path } })
    }
    $out = [Collections.Generic.List[object]]::new()
    $seen = @{}
    foreach ($a in $raw) {
        $name = ([string]$a.Name).Trim()
        $id = ([string]$a.AppID).Trim()
        if (-not $name -or -not $id) { continue }
        if ($id.StartsWith('::')) { continue }                  # This PC, Recycle Bin, ...
        if ($id -match '^[a-z][a-z0-9+.-]*://') { continue }     # a bookmark, not an app
        if ($id -match $AppSkipDoc -or $id -match $AppSkipExe) { continue }
        if ($name -match $AppSkipName) { continue }
        # Start lists pinned folders too, and those are a real path on disk.
        if ($id -notmatch '!' -and (Test-Path -LiteralPath $id -PathType Container -ErrorAction SilentlyContinue)) { continue }
        $key = "$name|$id".ToLowerInvariant()
        if ($seen[$key]) { continue }
        $seen[$key] = $true
        $out.Add([ordered]@{ name = $name; id = $id; store = [bool]($id -match $AppStoreId) })
    }
    @($out | Sort-Object @{ e = { $_.name } })
}

# Written by `winarchy apply`, and refreshed in the background every time the menu opens
# the Apps route, so installing something shows up without re-applying.
function Update-AppList {
    $apps = Get-InstalledApps
    Write-Json (Join-Path $Pack 'apps.json') ([ordered]@{ generated = (Get-Date).ToString('s'); apps = $apps })
    $apps
}
