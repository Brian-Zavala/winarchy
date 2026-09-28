# Pester tests: uninstall gives windows back what winarchy.ahk and GlazeWM took (minimize
# buttons, title bars, rounded corners), and really stops the admin game helper.
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'apply', 'journal', 'targets', 'setup', 'uninstall') { . "$root\lib\$f.ps1" }
    $Code = $root
    $LogFile = Join-Path $TestDrive 'winarchy.log'
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -Namespace WinarchyTest -Name Prop -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern bool SetPropW(IntPtr hWnd, string name, IntPtr data);
'@
    Initialize-MinBox
    function Get-Style($h) { [Winarchy.MinBox]::GetWindowLongPtrW($h, -16).ToInt64() }
    function Set-Style($h, [long]$style) { [void][Winarchy.MinBox]::SetWindowLongPtrW($h, -16, [IntPtr]$style) }
}

# The forms are never shown: the handle exists, nothing appears on screen.
Describe 'Restore-MinimizeBoxes' {
    It 'puts the button back on a window winarchy.ahk tagged, and drops the tag' {
        $form = [Windows.Forms.Form]::new()
        try {
            $h = $form.Handle
            Set-Style $h ((Get-Style $h) -band -bnot 0x20000)
            [void][WinarchyTest.Prop]::SetPropW($h, 'winarchy.nomin', [IntPtr]1)
            (Get-MinimizeBoxStripped) | Should -Contain $h

            Restore-MinimizeBoxes | Should -BeGreaterOrEqual 1

            (Get-Style $h) -band 0x20000 | Should -Be 0x20000
            [Winarchy.MinBox]::GetPropW($h, 'winarchy.nomin') | Should -Be ([IntPtr]::Zero)
        } finally { $form.Dispose() }
    }
}

Describe 'Restore-WindowFrames' {
    It 'gives a window GlazeWM stripped its title bar and default corners back' {
        $form = [Windows.Forms.Form]::new()
        try {
            $h = $form.Handle
            Set-Style $h ((Get-Style $h) -band -bnot 0x400000)       # hide_title_bar
            $square = 1
            [void][Winarchy.MinBox]::DwmSetWindowAttribute($h, 33, [ref]$square, 4)

            Restore-WindowFrames | Should -BeGreaterOrEqual 1

            (Get-Style $h) -band 0x400000 | Should -Be 0x400000
            $corner = -1
            [void][Winarchy.MinBox]::DwmGetWindowAttribute($h, 33, [ref]$corner, 4)
            $corner | Should -Be 0
        } finally { $form.Dispose() }
    }
    It 'leaves a window that draws its own title bar alone (no square corners)' {
        $form = [Windows.Forms.Form]::new()
        try {
            $h = $form.Handle
            Set-Style $h ((Get-Style $h) -band -bnot 0x400000)
            [void](Restore-WindowFrames)
            (Get-Style $h) -band 0x400000 | Should -Be 0
        } finally { $form.Dispose() }
    }
}

Describe 'Stopping winarchy on uninstall' {
    BeforeAll {
        Mock Write-Host {}
        Mock Get-JournalDir { 'C:\nowhere' }
        Mock Read-Journal { @{ entries = @() } }
        Mock Get-Paths { @{} }
        Mock Get-Process {}
        Mock Stop-Process {}
        # The keep-apps/keep-settings prompts, where this version of uninstall has them.
        foreach ($n in 'Get-UserApps', 'Read-YesNo', 'Read-State', 'Write-Json') {
            if (-not (Get-Command $n -ErrorAction SilentlyContinue)) { Set-Item "function:global:$n" {} }
        }
        Mock Get-UserApps {}
        Mock Read-YesNo { $true }
        Mock Write-Json {}
        Mock Read-State { @{} }
        Mock Restore-WindowFrames { 0 }
        Mock Stop-ScreenshotWatcher {}
    }
    It 'closes winarchy.ahk gracefully, then restores what a force-stop left behind' {
        Mock Get-OmarchyAhk { [pscustomobject]@{ ProcessId = 4242 } }
        Mock Close-AhkGracefully { 1 }
        Mock Restore-MinimizeBoxes { 2 }
        Invoke-Uninstall
        Should -Invoke Close-AhkGracefully -Times 1 -ParameterFilter { $processIds -contains 4242 }
        Should -Invoke Restore-MinimizeBoxes -Times 1
        Should -Invoke Restore-WindowFrames -Times 1
    }
    It 'restores them even when winarchy.ahk is not running' {
        Mock Get-OmarchyAhk {}
        Mock Close-AhkGracefully { 0 }
        Mock Restore-MinimizeBoxes { 0 }
        Invoke-Uninstall
        Should -Invoke Close-AhkGracefully -Times 0
        Should -Invoke Restore-MinimizeBoxes -Times 1
    }
}

Describe 'Removing the admin game helper' {
    It 'survives -EncodedCommand intact and matches the helper by its exe' {
        $gh = @{ dir = 'C:\ProgramData\winarchy-games'; path = '\winarchy\'; name = 'game-helper' }
        $script = Get-GameHelperRemoveScript $gh
        $decoded = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String((ConvertTo-EncodedCommand $script)))
        $decoded | Should -Be $script
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseInput($script, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
        $script | Should -Match ([regex]::Escape("ExecutablePath -like 'C:\ProgramData\winarchy-games\*'"))
    }
}
