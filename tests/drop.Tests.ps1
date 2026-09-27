# Pester tests: where a window lands when it is dropped (Super+drag) or just opened
# (openOnHoveredMonitor). The GlazeWM CLI is stubbed - it answers the queries from a
# canned two-monitor state and logs every `command` it is asked to run.
BeforeAll {
    $root = Split-Path -Parent $PSScriptRoot
    $Drop = "$root\lib\drop.ps1"

    # Window W1 is tiled on workspace 1 (monitor 0, 3840x2160 at 0,0). W2 sits under the
    # drop point on monitor 1 (2560x1440 at 3840,0), whose displayed workspace is 6.
    $win1 = '{"type":"window","id":"W1","state":{"type":"tiling"},"displayState":"shown","x":17,"y":63,"width":1895,"height":2080}'
    $win2 = '{"type":"window","id":"W2","state":{"type":"tiling"},"displayState":"shown","x":3857,"y":63,"width":2526,"height":1360}'
    $ws1 = '{"type":"workspace","id":"WS1","name":"1","isDisplayed":true,"children":[' + $win1 + ']}'
    $ws6 = '{"type":"workspace","id":"WS6","name":"6","isDisplayed":true,"children":[' + $win2 + ']}'
    $State = @{
        windows    = '{"data":{"windows":[' + $win1 + ',' + $win2 + ']}}'
        workspaces = '{"data":{"workspaces":[' + $ws1 + ',' + $ws6 + ']}}'
        monitors   = '{"data":{"monitors":[' +
            '{"type":"monitor","id":"M0","x":0,"y":0,"width":3840,"height":2160,"children":[' + $ws1 + ']},' +
            '{"type":"monitor","id":"M1","x":3840,"y":0,"width":2560,"height":1440,"children":[' + $ws6 + ']}' +
        ']}}'
    }

    # Runs drop.ps1 against a stub CLI and returns the `command` lines it asked for.
    function Invoke-Drop($x, $y, [switch]$WorkspaceOnly) {
        $dir = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Force $dir | Out-Null
        foreach ($k in $State.Keys) { Set-Content -LiteralPath "$dir\$k.json" -Value $State[$k] }
        $log = "$dir\commands.txt"
        $cli = "$dir\glazewm.ps1"
        Set-Content -LiteralPath $cli -Value @"
param([Parameter(ValueFromRemainingArguments)]`$a)
if (`$a[0] -eq 'query') { Get-Content -Raw "$dir\`$(`$a[1]).json"; exit }
Add-Content -LiteralPath "$log" -Value ((`$a | Select-Object -Skip 1) -join ' ')
"@
        & $Drop -Id 'W1' -X $x -Y $y -Cli $cli -WorkspaceOnly:$WorkspaceOnly | Out-Null
        if (Test-Path $log) { Get-Content -LiteralPath $log } else { @() }
    }
}

Describe 'drop.ps1' {
    It 're-homes the window to the workspace displayed on the monitor at the point' {
        Invoke-Drop 5000 700 | Should -Contain '--id W1 move --workspace 6'
    }
    It 'leaves the layout alone with -WorkspaceOnly (a window that was just opened)' {
        $cmds = (Invoke-Drop 5000 700 -WorkspaceOnly) -join "`n"
        $cmds | Should -Match 'move --workspace 6'
        $cmds | Should -Not -Match 'move --direction'
    }
    It 'steps a dropped window toward the point without -WorkspaceOnly' {
        ((Invoke-Drop 5000 700) -join "`n") | Should -Match 'move --direction right'
    }
    It 'does not change workspace when the point is on the monitor it is already on' {
        ((Invoke-Drop 900 700 -WorkspaceOnly) -join "`n") | Should -Not -Match 'move --workspace'
    }
}
