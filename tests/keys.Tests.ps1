# Pester tests: the keys your own Startup scripts bind (lib/keys.ps1), which winarchy's
# scripts leave to you (BindUnlessUser in ahk/lib/env.ahk). Fixtures only: the real
# Startup folder is never read here.
BeforeDiscovery {
    $Verb = 'test'
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\common.ps1')
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\detect.ps1')
    $hasAhk = [bool](Find-AutoHotkey)
}

BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'keys', 'render', 'themes', 'journal', 'apply') { . "$root\lib\$f.ps1" }
    $Code = $root
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    # The journal too: the real one in ~/.winarchy/backup is what uninstall replays.
    $BackupRoot = Join-Path $TestDrive 'backup'
    # Not $Generated here: the key-name helper's compiled type is cached under it, and a
    # loaded DLL in TestDrive can't be deleted when the run ends.
}

Describe 'Key ids' {
    It 'puts modifiers in one order and drops the prefix symbols' {
        ConvertTo-KeyId '#+!a' | Should -Be '#!+a'
        ConvertTo-KeyId '+#b' | Should -Be '#+b'
        ConvertTo-KeyId '~$*<#>^Enter' | Should -Be '#^enter'
        ConvertTo-KeyId '#Return' | Should -Be '#enter'
        ConvertTo-KeyId '#+B' | Should -Be '#+b'
        ConvertTo-KeyId '#a up' | Should -Be '#a'
    }
    It 'makes a punctuation character and its scan code the same key' {
        ConvertTo-KeyId '#+SC035' | Should -Be '#+sc035'
        ConvertTo-KeyId '#+sc35' | Should -Be '#+sc035'
        # "/" is SC035 on US-style layouts; on others it is whatever key types it.
        ConvertTo-KeyId '#+/' | Should -Match '^#\+(sc[0-9a-f]{3}|vk[0-9a-f]{2}|/)$'
        if ((ConvertTo-KeyId '#+/') -like '#+sc*') { ConvertTo-KeyId '#+vkBF' | Should -Be (ConvertTo-KeyId '#+/') }
    }
    It 'reads custom combinations' {
        ConvertTo-KeyId 'LWin & x' | Should -Be '#x'
        ConvertTo-KeyId 'CapsLock & j' | Should -Be 'combo:capslock&j'
    }
    It 'reads the keybindings list''s names back' {
        ConvertFrom-KeyText 'Super + Shift + O' | Should -Be '#+o'
        ConvertFrom-KeyText 'Super + Return' | Should -Be '#enter'
        ConvertFrom-KeyText 'Super + Shift + Return / B' | Should -Not -Be '#+b'
        ConvertTo-KeyText '#!+a' | Should -Be 'Super + Alt + Shift + A'
    }
}

Describe 'Reading a script' {
    It 'finds the key forms a launcher script uses' {
        $text = @'
#Requires AutoHotkey v2.0
; Super + Return: Windows Terminal
#Enter::Run("wt.exe")
#+b::
{
    try Run("chrome.exe")
}
#+/::
{
    try Run("1password.exe")
}
#+!a::Run("wt.exe -e gemini -y")
Hotkey "#^k", (*) => MsgBox()
Hotkey("#+SC033", Fn)
Hotkey(name, Fn)
'@
        $r = Get-AhkHotkeys $text
        $r.keys | Should -Contain '#enter'
        $r.keys | Should -Contain '#+b'
        $r.keys | Should -Contain (ConvertTo-KeyId '#+/')
        $r.keys | Should -Contain '#!+a'
        $r.keys | Should -Contain '#^k'
        $r.keys | Should -Contain '#+sc033'
        $r.dynamic | Should -Be 1
    }
    It 'skips comments, hotstrings and code that only mentions "::"' {
        $text = @'
; #+x::Run("nope")
/*
#+z::Run("in a block comment")
*/
::btw::by the way
:*:@@::me@example.com
x := "#+q::"
MsgBox "a::b"
'@
        (Get-AhkHotkeys $text).keys | Should -BeNullOrEmpty
    }
    It 'leaves keys under a #HotIf with a condition to winarchy everywhere else' {
        $text = @'
#HotIf WinActive("ahk_exe code.exe")
#+c::Run("x")
#HotIf
#+e::Run("y")
#IfWinActive ahk_class Notepad
#+f::Run("z")
#IfWinActive
HotIf (*) => WinActive("ahk_exe x.exe")
Hotkey "#+g", Fn
HotIf()
Hotkey "#+h", Fn
'@
        $r = Get-AhkHotkeys $text
        $r.keys | Should -Not -Contain '#+c'
        $r.keys | Should -Not -Contain '#+f'
        $r.keys | Should -Not -Contain '#+g'
        $r.keys | Should -Contain '#+e'
        $r.keys | Should -Contain '#+h'
    }
    It 'reads the Startup folder''s scripts and shortcuts, never winarchy''s own' {
        $dir = Join-Path $TestDrive 'Startup'
        New-Item -ItemType Directory -Force $dir | Out-Null
        Set-Content (Join-Path $dir 'mine.ahk') "#+y::Run(`"https://youtube.com`")"
        $elsewhere = Join-Path $TestDrive 'scripts\other.ahk'
        New-Item -ItemType Directory -Force (Split-Path $elsewhere) | Out-Null
        Set-Content $elsewhere '#+p::Run("x")'
        $sh = New-Object -ComObject WScript.Shell
        $l = $sh.CreateShortcut((Join-Path $dir 'other.lnk')); $l.TargetPath = 'C:\Windows\notepad.exe'; $l.Arguments = "`"$elsewhere`""; $l.Save()
        $l = $sh.CreateShortcut((Join-Path $dir 'winarchy.lnk')); $l.TargetPath = 'C:\Windows\notepad.exe'; $l.Arguments = "`"$Code\ahk\winarchy.ahk`""; $l.Save()
        $r = Get-UserHotkeys $dir
        $r.keys | Should -Be @('#+p', '#+y')
        $r.files.Count | Should -Be 2
    }
    It 'finds nothing, without failing, when there is no Startup folder' {
        (Get-UserHotkeys (Join-Path $TestDrive 'nowhere')).keys | Should -BeNullOrEmpty
    }
}

Describe 'Settings and the keybindings list' {
    It 'writes the keys for AutoHotkey' {
        $Generated = Join-Path $TestDrive 'generated'
        $cfg = @{ apps = @{ editor = 'notepad.exe'; terminal = 'auto'; browser = 'auto'; files = 'explorer.exe' }; screensaver = @{}; agentUsage = @{}; autoTiling = @{} }
        Write-AhkIni @{ userHotkeys = @{ keys = @('#+a', '#+sc035') } } $cfg
        Get-Content -Raw (Join-Path $Generated 'winarchy.ini') | Should -Match 'userKeys=#\+a\|#\+sc035'
    }
    It 'marks the keys your script has, and only those' {
        $text = "APPS`n  Super + Shift + O             Obsidian`n  Super + Shift + G             Signal`n"
        $out = Add-YieldMarks $text @('#+o')
        $out | Should -Match 'Obsidian \(your script\)'
        $out | Should -Not -Match 'Signal \(your script\)'
        # The viewer splits key and action on 2+ spaces: the mark must not add a column.
        ($out -split "`n")[1] -split '\s{2,}' | Should -HaveCount 3
    }
}

Describe 'Repo scripts' {
    It 'bind every launcher key through BindUnlessUser' {
        $src = Get-Content -Raw (Join-Path $root 'ahk\launchers.ahk')
        $src | Should -Match 'BindUnlessUser\(hk, fn\)'
        $src | Should -Not -Match '(?m)^#[^:\r\n]+::'
    }
}

Describe 'AutoHotkey agrees on key ids' -Skip:(-not $hasAhk) {
    It 'KeyId in env.ahk gives the same ids as ConvertTo-KeyId' {
        $cases = '#+!a', '~$*<#Enter', '#+SC035', '#+/', '#^SC033', 'LWin & x', 'CapsLock & j', '#Return', '#+B', '#a up', '#vkBF', '#Esc'
        $out = Join-Path $TestDrive 'ids.txt'
        $harness = Join-Path $TestDrive 'ids.ahk'
        $list = ($cases | ForEach-Object { '"' + ($_ -replace '"', '""') + '"' }) -join ', '
        Set-Content $harness @"
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((*) => ExitApp(2))
#Include "$root\ahk\lib\env.ahk"
out := ""
for hk in [$list]
    out .= KeyId(hk) "``n"
FileAppend out, "$out", "UTF-8"
ExitApp 0
"@
        $p = Start-Process (Find-AutoHotkey) -ArgumentList "`"$harness`"" -Wait -PassThru
        $p.ExitCode | Should -Be 0
        $ahk = @(Get-Content $out | Where-Object { $_ -ne '' })
        $ahk | Should -Be @($cases | ForEach-Object { ConvertTo-KeyId $_ })
    }
}
