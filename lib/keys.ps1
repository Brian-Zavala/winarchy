# The hotkeys your own AutoHotkey scripts in the Startup folder bind, so winarchy's
# scripts can leave those keys to you instead of fighting over them (whichever script
# started last would win). The files are only read, never changed.
#
# A key is compared in one form, the same one ahk/lib/env.ahk (KeyId) produces: its
# modifiers in the order # ^ ! +, then the key. Letters and digits stay as they are;
# punctuation becomes its scan code on this keyboard layout, the way winarchy's own
# scripts write those keys (#+/ and #+SC035 are then the same key).

function Initialize-KeysNative {
    Add-NativeType Keys @'
[DllImport("user32.dll")] public static extern short VkKeyScanW(char ch);
[DllImport("user32.dll")] public static extern uint MapVirtualKeyW(uint code, uint mapType);
'@
}

$KeyAliases = @{ return = 'enter'; esc = 'escape'; bs = 'backspace'; del = 'delete'; ins = 'insert' }
$ModifierNames = @{
    lwin = '#'; rwin = '#'
    ctrl = '^'; control = '^'; lctrl = '^'; rctrl = '^'; lcontrol = '^'; rcontrol = '^'
    alt = '!'; lalt = '!'; ralt = '!'
    shift = '+'; lshift = '+'; rshift = '+'
}

function Get-SortedMods([string]$mods) {
    -join ('#', '^', '!', '+' | Where-Object { $mods.Contains($_) })
}

function ConvertTo-KeyName([string]$key) {
    Initialize-KeysNative
    if ($key.Length -eq 1) {
        if ($key -match '^[A-Za-z0-9]$') { return $key.ToLower() }
        $vk = [Winarchy.Keys]::VkKeyScanW($key[0]) -band 0xFF
        if ($vk -eq 0xFF) { return $key }
        $sc = [Winarchy.Keys]::MapVirtualKeyW($vk, 0)
        return $(if ($sc) { 'sc{0:x3}' -f $sc } else { 'vk{0:x2}' -f $vk })
    }
    if ($key -match '^sc([0-9a-f]+)$') { return 'sc{0:x3}' -f [Convert]::ToInt32($Matches[1], 16) }
    if ($key -match '^vk([0-9a-f]{2})(?:sc[0-9a-f]+)?$') {
        $vk = [Convert]::ToInt32($Matches[1], 16)
        $sc = [Winarchy.Keys]::MapVirtualKeyW($vk, 0)
        return $(if ($sc) { 'sc{0:x3}' -f $sc } else { 'vk{0:x2}' -f $vk })
    }
    $k = $key.ToLower()
    if ($KeyAliases[$k]) { $KeyAliases[$k] } else { $k }
}

# "#+/" -> "#+sc035"; "~$*<#Enter" -> "#enter"; "LWin & x" -> "#x"; "CapsLock & j" -> "combo:capslock&j".
function ConvertTo-KeyId([string]$hotkey) {
    $hk = ($hotkey.Trim() -replace '(?i)\s+up$', '')
    if ($hk -match '^(.+?)\s+&\s+(.+)$') {
        $prefix = $Matches[1].Trim().TrimStart('~', '*', '$'); $suffix = $Matches[2].Trim()
        $mod = $ModifierNames[$prefix.ToLower()]
        if (-not $mod) { return "combo:$(ConvertTo-KeyName $prefix)&$(ConvertTo-KeyName $suffix)" }
        return "$mod$(ConvertTo-KeyName $suffix)"
    }
    $mods = ''
    while ($hk.Length -gt 1 -and '#^!+<>*~$'.Contains($hk[0])) {
        if ('#^!+'.Contains($hk[0])) { $mods += $hk[0] }
        $hk = $hk.Substring(1)
    }
    "$(Get-SortedMods $mods)$(ConvertTo-KeyName $hk)"
}

# One script's keys. Only keys that work everywhere count: one under a #HotIf with a
# condition (only in some app) still lets winarchy's work in every other one.
# Hotkey() with a variable instead of a literal can't be known without running it: counted
# in "dynamic" for doctor to mention.
function Get-AhkHotkeys([string]$text) {
    $keys = [Collections.Generic.List[string]]::new()
    $dynamic = 0
    $conditional = $false
    $inComment = $false
    $spec = '[#^!+<>*~$]*(?:[A-Za-z0-9_]{2,}|\S)'
    foreach ($raw in $text -split "`r?`n") {
        $line = $raw.Trim()
        if ($inComment) { if ($line -match '^\*/|\*/\s*$') { $inComment = $false }; continue }
        if ($line.StartsWith('/*')) { if ($line -notmatch '\*/\s*$') { $inComment = $true }; continue }
        if (-not $line -or $line.StartsWith(';')) { continue }
        # #HotIf / v1's #If, #IfWinActive ...: with a condition, the keys after it are
        # conditional; bare, it ends the section.
        if ($line -match '^#(?:HotIf|If\w*)\b(.*)$') {
            $conditional = [bool](($Matches[1] -replace '(^|\s);.*$', '').Trim())
            continue
        }
        if ($line -match '^HotIf\s*\(\s*\)') { $conditional = $false; continue }
        if ($line -match '^HotIf\s*\(.+\)') { $conditional = $true; continue }
        if ($line.StartsWith(':')) { continue }   # a hotstring
        if ($line -match "^($spec(?:\s+&\s+$spec)?(?:\s+up)?)::") {
            if (-not $conditional) { $keys.Add((ConvertTo-KeyId $Matches[1])) }
            continue
        }
        foreach ($m in [regex]::Matches($line, '(?<![\w.])Hotkey\s*\(?\s*(?:"([^"]+)"|''([^'']+)''|([A-Za-z_]\w*))')) {
            if ($m.Groups[3].Success) { $dynamic++; continue }
            $name = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
            if (-not $conditional) { $keys.Add((ConvertTo-KeyId $name)) }
        }
    }
    @{ keys = @($keys | Select-Object -Unique); dynamic = $dynamic }
}

# The .ahk scripts the Startup folder starts: the scripts themselves, and shortcuts that
# run one. Winarchy's own (its code or data folder) are not yours.
function Get-StartupAhkFiles([string]$dir = [Environment]::GetFolderPath('Startup')) {
    if (-not $dir -or -not (Test-Path -LiteralPath $dir)) { return @() }
    $ours = @($Code, $Data) | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') + '\' }
    $found = foreach ($f in Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue) {
        if ($f.Extension -eq '.ahk') { $f.FullName; continue }
        if ($f.Extension -ne '.lnk') { continue }
        try {
            $s = (New-Object -ComObject WScript.Shell).CreateShortcut($f.FullName)
            if ($s.TargetPath -like '*.ahk') { $s.TargetPath }
            elseif ($s.Arguments -match '"([^"]+\.ahk)"|(\S+\.ahk)\b') { $Matches[1] ?? $Matches[2] }
        } catch {}
    }
    @($found | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Where-Object {
        $p = $_; -not ($ours | Where-Object { $p -like "$_*" })
    } | Select-Object -Unique)
}

function Get-UserHotkeys([string]$dir = [Environment]::GetFolderPath('Startup')) {
    $keys = [Collections.Generic.List[string]]::new()
    $files = [Collections.Generic.List[string]]::new()
    $dynamic = 0
    foreach ($f in Get-StartupAhkFiles $dir) {
        try {
            $r = Get-AhkHotkeys (Get-Content -Raw -LiteralPath $f)
            foreach ($k in $r.keys) { $keys.Add($k) }
            $dynamic += $r.dynamic
            $files.Add($f)
        } catch { Log "keys: could not read ${f}: $($_.Exception.Message)" }
    }
    [ordered]@{ keys = @($keys | Sort-Object -Unique); files = @($files); dynamic = $dynamic }
}

# winarchy keys-refresh: winarchy.ahk runs it when a script in the Startup folder is saved,
# added or removed. When the keys it binds changed, the settings are rewritten and
# winarchy's scripts restarted (they bind at start), so a key you take or give back
# changes hands at once.
function Invoke-KeysRefresh {
    $before = @((Get-Paths).userHotkeys.keys) -join '|'
    $p = Update-Paths
    $after = @($p.userHotkeys.keys) -join '|'
    if ($before -eq $after) { Log 'keys: your scripts bind the same keys as before'; return }
    $cfg = Get-Config
    Write-AhkIni $p $cfg
    Write-Utf8 (Join-Path $Pack 'keybindings.txt') (Get-KeybindingsText $cfg $p)
    Log "keys: your scripts bind $(@($p.userHotkeys.keys).Count) key(s); winarchy leaves those to them"
    Restart-OmarchyAhk $p
}

# "#+sc035" -> "Super + Shift + /" (this layout's character for the scan code), for doctor.
function ConvertTo-KeyText([string]$id) {
    if ($id.StartsWith('combo:')) { return ($id.Substring(6) -replace '&', ' & ') }
    $names = [ordered]@{ '#' = 'Super'; '^' = 'Ctrl'; '!' = 'Alt'; '+' = 'Shift' }
    $parts = [Collections.Generic.List[string]]::new()
    $i = 0
    while ($i -lt $id.Length - 1 -and $names.Contains([string]$id[$i])) { $parts.Add($names[[string]$id[$i]]); $i++ }
    $key = $id.Substring($i)
    if ($key -match '^sc([0-9a-f]{3})$') {
        Initialize-KeysNative
        $vk = [Winarchy.Keys]::MapVirtualKeyW([Convert]::ToUInt32($Matches[1], 16), 1)
        $ch = if ($vk) { [Winarchy.Keys]::MapVirtualKeyW($vk, 2) -band 0xFFFF } else { 0 }
        $key = if ($ch -ge 0x21) { [string][char]$ch } else { $key.ToUpper() }
    } elseif ($key.Length -eq 1) { $key = $key.ToUpper() }
    else { $key = $key.Substring(0, 1).ToUpper() + $key.Substring(1) }
    $parts.Add($key)
    $parts -join ' + '
}

# "Super + Shift + /" (the keybindings list) -> the same form, for marking what yields.
function ConvertFrom-KeyText([string]$text) {
    $parts = @($text -split '\s*\+\s*' | Where-Object { $_ })
    if ($parts.Count -lt 1) { return $null }
    $names = @{ super = '#'; ctrl = '^'; alt = '!'; shift = '+' }
    $mods = ''
    foreach ($p in $parts | Select-Object -SkipLast 1) {
        $m = $names[$p.ToLower()]
        if (-not $m) { return $null }
        $mods += $m
    }
    "$(Get-SortedMods $mods)$(ConvertTo-KeyName $parts[-1])"
}

# The keybindings list with "(your script)" on the lines whose key your own script has.
function Add-YieldMarks([string]$text, [string[]]$userKeys) {
    if (-not $userKeys) { return $text }
    $set = @{}; foreach ($k in $userKeys) { $set[$k] = $true }
    $lines = foreach ($line in $text -split "`n") {
        # "  Super + Shift + O             Obsidian": the key, 2+ spaces, what it does.
        if ($line -match '^(\s+)(\S(?:.*?\S)?)(\s{2,})(\S.*?)\r?$' -and -not $line.Contains('(your script)')) {
            $id = ConvertFrom-KeyText $Matches[2]
            if ($id -and $set[$id]) { $line = "$($Matches[1])$($Matches[2])$($Matches[3])$($Matches[4]) (your script)" }
        }
        $line
    }
    $lines -join "`n"
}
