<#
  Sets (or clears) the Chromium BrowserThemeColor policy for this user.
  Browser policies are admin-only, so this runs from the elevated scheduled task
  \omarchy-win\browser-color, created once by `omarchy-win browser-setup` - the same idea
  as Omarchy's omarchy-theme-set-browser-policy sudo rule.

  Security: the task runs an admin-owned copy of this file (C:\ProgramData\omarchy-win),
  it accepts nothing but "#rrggbb" or "none" from ~/.omarchy-win/generated/browser-color.txt,
  writes nothing but that one policy value, and uses only .NET APIs (no cmdlets, so no
  module can be picked up from a user-writable module path).
#>
$colorFile = [IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), '.omarchy-win', 'generated', 'browser-color.txt')
$color = 'none'
if ([IO.File]::Exists($colorFile)) { $color = [IO.File]::ReadAllText($colorFile).Trim().ToLowerInvariant() }
if ($color -ne 'none' -and $color -notmatch '^#[0-9a-f]{6}$') { exit 2 }

$pf = [Environment]::GetFolderPath('ProgramFiles')
$la = [Environment]::GetFolderPath('LocalApplicationData')
$browsers = @(
    @{ key = 'Software\Policies\Google\Chrome'; exe = @("$pf\Google\Chrome\Application\chrome.exe", "$la\Google\Chrome\Application\chrome.exe") },
    @{ key = 'Software\Policies\BraveSoftware\Brave'; exe = @("$pf\BraveSoftware\Brave-Browser\Application\brave.exe", "$la\BraveSoftware\Brave-Browser\Application\brave.exe") }
)
foreach ($b in $browsers) {
    $installed = $false
    foreach ($e in $b.exe) { if ([IO.File]::Exists($e)) { $installed = $true } }
    if (-not $installed) { continue }
    $hkcu = [Microsoft.Win32.Registry]::CurrentUser
    if ($color -eq 'none') {
        $k = $hkcu.OpenSubKey($b.key, $true)
        if ($k) {
            $k.DeleteValue('BrowserThemeColor', $false)
            $empty = ($k.ValueCount -eq 0 -and $k.SubKeyCount -eq 0)
            $k.Close()
            if ($empty) { $hkcu.DeleteSubKey($b.key, $false) }
        }
    } else {
        $k = $hkcu.CreateSubKey($b.key)
        $k.SetValue('BrowserThemeColor', $color, [Microsoft.Win32.RegistryValueKind]::String)
        $k.Close()
    }
}
