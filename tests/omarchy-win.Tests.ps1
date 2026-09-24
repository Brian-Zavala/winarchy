# Pester tests for the machine-independent logic: run with  Invoke-Pester ./tests
BeforeAll {
    $Verb = 'test'
    $root = Split-Path -Parent $PSScriptRoot
    foreach ($f in 'common', 'detect', 'render', 'themes', 'targets', 'journal', 'apply') { . "$root\lib\$f.ps1" }
    $Code = $root
}

Describe 'Workspace split' {
    It 'puts all 10 on one monitor' {
        $l = Get-WorkspaceLayout 1 'auto'
        $l.Count | Should -Be 10
        ($l | Where-Object monitor -ne 0).Count | Should -Be 0
    }
    It 'splits 5/5 on two monitors' {
        (Get-WorkspaceLayout 2 'auto' | Group-Object monitor | ForEach-Object Count) -join ',' | Should -Be '5,5'
    }
    It 'splits 4/3/3 on three monitors' {
        (Get-WorkspaceLayout 3 'auto' | Group-Object monitor | ForEach-Object Count) -join ',' | Should -Be '4,3,3'
    }
    It 'follows an explicit map and clamps to real monitors' {
        $l = Get-WorkspaceLayout 1 @{ '1' = @('1', '2'); '2' = @('3') }
        ($l | ForEach-Object { "$($_.name)@$($_.monitor)" }) -join ' ' | Should -Be '1@0 2@0 3@0'
    }
    It 'renders workspace 10 as 0' {
        ConvertTo-WorkspacesYaml (Get-WorkspaceLayout 1 'auto') | Should -Match "name: '10'\s+display_name: '0'"
    }
}

Describe 'Templates' {
    BeforeAll { $c = @{ background = '#1a1b26'; foreground = '#a9b1d6'; accent = '#7aa2f7'; mode = 'dark'; theme_type = 'dark' } }
    It 'fills plain, _strip and _rgb placeholders' {
        Expand-Template '{{ accent }}|{{ accent_strip }}|{{ accent_rgb }}' $c | Should -Be '#7aa2f7|7aa2f7|122,162,247'
    }
    It 'mixes colors with a percentage or a fraction' {
        Expand-Template '{{ mix background foreground 6% }}' $c | Should -Be '#232431'
        Expand-Template '{{ mix_rgb accent foreground 0.35 }}' $c | Should -Be '138,167,235'
        Expand-Template '{{ mix_strip accent foreground 35 }}' $c | Should -Be '8aa7eb'
    }
    It 'leaves unknown placeholders alone' {
        Expand-Template '{{ nope }}' $c | Should -Be '{{ nope }}'
    }
    It 'Mix ends at both colors' {
        Mix '#000000' '#ffffff' 0 | Should -Be '#000000'
        Mix '#000000' '#ffffff' 1 | Should -Be '#ffffff'
    }
}

Describe 'Flow hotkey conversion' {
    It 'converts <flow> to <ahk>' -TestCases @(
        @{ flow = 'Alt + Space'; ahk = '!{Space}' }
        @{ flow = 'Ctrl + Shift + K'; ahk = '^+k' }
        @{ flow = 'Win + Alt + F1'; ahk = '#!{F1}' }
        @{ flow = $null; ahk = '!{Space}' }
    ) { ConvertTo-AhkHotkey $flow | Should -Be $ahk }
}

Describe 'JSONC edits (VS Code settings keep their comments)' {
    It 'replaces an existing value' {
        $f = Join-Path $TestDrive 'a.json'
        Set-Content $f "{`n  // comment`n  `"workbench.colorTheme`": `"Old`",`n  `"x`": 1`n}"
        Set-JsoncString $f 'workbench.colorTheme' 'New "One"'
        $t = Get-Content -Raw $f
        $t | Should -Match '// comment'
        Get-JsoncString $f 'workbench.colorTheme' | Should -Be 'New "One"'
    }
    It 'adds a missing key' {
        $f = Join-Path $TestDrive 'b.json'
        Set-Content $f "{`n  `"x`": 1`n}"
        Set-JsoncString $f 'workbench.colorTheme' 'Omarchy'
        Get-JsoncString $f 'workbench.colorTheme' | Should -Be 'Omarchy'
        (Get-Content -Raw $f | ConvertFrom-Json).x | Should -Be 1
    }
}

Describe 'Backup journal' {
    BeforeEach {
        $script:JournalDir = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory $script:JournalDir | Out-Null
        Set-Content (Join-Path $script:JournalDir 'journal.json') '{"entries":[]}'
        $script:JournalCache = $null
    }
    It 'records the first original only' {
        $f = Join-Path $TestDrive 'settings.json'
        Set-Content $f '{"a":1}'
        Save-File $f
        Set-Content $f '{"a":2}'
        Save-File $f
        (Read-Journal).entries.Count | Should -Be 1
    }
    It 'restores a JSON property and removes one that did not exist' {
        $f = Join-Path $TestDrive 'wt.json'
        Set-Content $f '{"profiles":{"defaults":{"padding":"8"}}}'
        Save-JsonProperty $f 'profiles.defaults.padding'
        Save-JsonProperty $f 'profiles.defaults.colorScheme'
        Set-Content $f '{"profiles":{"defaults":{"padding":"14","colorScheme":"Omarchy"}}}'
        foreach ($e in (Read-Journal).entries) { Restore-JournalEntry $e $script:JournalDir }
        $o = Get-Content -Raw $f | ConvertFrom-Json
        $o.profiles.defaults.padding | Should -Be '8'
        $o.profiles.defaults.PSObject.Properties.Name | Should -Not -Contain 'colorScheme'
    }
    It 'restores a file that did not exist by deleting it' {
        $f = Join-Path $TestDrive 'new.txt'
        Save-File $f
        Set-Content $f 'x'
        foreach ($e in (Read-Journal).entries) { Restore-JournalEntry $e $script:JournalDir }
        Test-Path $f | Should -BeFalse
    }
}
