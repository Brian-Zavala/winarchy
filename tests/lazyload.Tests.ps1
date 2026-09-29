# Pester tests: the CLI verbs that load only some libraries ($VerbLibs in bin\winarchy.ps1).
# A function or script variable from a library that isn't loaded fails quietly at best
# (Write-Status's Get-Command fallbacks, a $null setting), so this walks the code instead of
# running it: from the verb's own lines, through every library function they reach.
BeforeDiscovery {
    $root = Split-Path -Parent $PSScriptRoot
    $entry = [Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'bin' 'winarchy.ps1'), [ref]$null, [ref]$null)
    $assigned = { param($name) $entry.Find({ param($a) $a -is [Management.Automation.Language.AssignmentStatementAst] -and "$($a.Left)" -eq "`$$name" }, $true) }
    $table = (& $assigned 'VerbLibs').Right.Expression.SafeGetValue()
    # (PSBase: 'keys' is one of the verbs, and $table.Keys would be its value.)
    $cases = foreach ($k in $table.PSBase.Keys | Sort-Object) { @{ Name = $k; Libs = [string[]]$table[$k] } }
}

BeforeAll {
    $root = Split-Path -Parent $PSScriptRoot
    $parse = { param($path) [Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null) }
    $entry = & $parse (Join-Path $root 'bin' 'winarchy.ps1')
    $allLibs = @((& { $entry.Find({ param($a) $a -is [Management.Automation.Language.AssignmentStatementAst] -and "$($a.Left)" -eq '$AllLibs' }, $true) }).Right.Expression.SafeGetValue())

    # Every library's functions and script-level variables: name -> library. (The libraries
    # the CLI loads, and the two setup.ps1 brings along; lib\ also holds standalone scripts.)
    $funcs = @{}; $vars = @{}; $loadTime = @{}
    foreach ($f in Get-ChildItem (Join-Path $root 'lib') -Filter '*.ps1' | Where-Object BaseName -in ($allLibs + 'fonts', 'ui')) {
        $ast = & $parse $f.FullName
        foreach ($fn in $ast.FindAll({ param($a) $a -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)) { $funcs[$fn.Name] = @{ lib = $f.BaseName; ast = $fn } }
        $loadTime[$f.BaseName] = @($ast.EndBlock.Statements | Where-Object { $_ -isnot [Management.Automation.Language.FunctionDefinitionAst] })
        foreach ($s in $loadTime[$f.BaseName]) {
            if ($s -is [Management.Automation.Language.AssignmentStatementAst] -and $s.Left -is [Management.Automation.Language.VariableExpressionAst]) {
                $vars[$s.Left.VariablePath.UserPath -replace '^script:', ''] = $f.BaseName
            }
        }
    }
    # Log's pretty output for install and update: read as $null (off) without ui.ps1, and
    # Write-UiLog is only called when it is on.
    $optional = 'UiPretty', 'UiClock', 'Write-UiLog'

    # The switch ($Verb) clause for each verb name.
    $switch = $entry.Find({ param($a) $a -is [Management.Automation.Language.SwitchStatementAst] -and "$($a.Condition)" -eq '$Verb' }, $true)
    $clauses = @{}
    foreach ($c in $switch.Clauses) {
        foreach ($s in $c.Item1.FindAll({ param($a) $a -is [Management.Automation.Language.StringConstantExpressionAst] }, $true)) { $clauses[$s.Value] = $c.Item2 }
    }
    $inClause = { param($ast) foreach ($c in $switch.Clauses) { if ($ast.Extent.StartOffset -ge $c.Item2.Extent.StartOffset -and $ast.Extent.EndOffset -le $c.Item2.Extent.EndOffset) { return $true } }; $false }

    # What a verb reaches that its libraries don't have: missing functions, script variables,
    # and calls through a variable that can't be followed.
    function Get-Unreached([string]$verb, [string[]]$libs) {
        $bad = [Collections.Generic.List[string]]::new()
        $todo = [Collections.Generic.Queue[object]]::new()
        # The script outside the switch (the version line, the catch's Log), the verb's clause,
        # and what the loaded libraries run as they load.
        $todo.Enqueue(@('bin\winarchy.ps1', $entry, $true))
        $todo.Enqueue(@("the '$verb' clause", $clauses[$verb], $false))
        foreach ($l in $libs) { foreach ($s in $loadTime[$l]) { $todo.Enqueue(@("$l.ps1 (load)", $s, $false)) } }
        $walked = @{}
        while ($todo.Count) {
            $where, $ast, $skipClauses = $todo.Dequeue()
            $all = @($ast.FindAll({ $true }, $true) | Where-Object { -not $skipClauses -or -not (& $inClause $_) })
            $local = @{}
            foreach ($x in $all) {
                $v = if ($x -is [Management.Automation.Language.ParameterAst]) { $x.Name }
                    elseif ($x -is [Management.Automation.Language.ForEachStatementAst]) { $x.Variable }
                    elseif ($x -is [Management.Automation.Language.AssignmentStatementAst]) { $x.Left }
                if ($v -is [Management.Automation.Language.VariableExpressionAst]) { $local[$v.VariablePath.UserPath -replace '^script:', ''] = $true }
                if ($v -is [Management.Automation.Language.ArrayLiteralAst]) { foreach ($e in $v.Elements) { if ($e -is [Management.Automation.Language.VariableExpressionAst]) { $local[$e.VariablePath.UserPath] = $true } } }
            }
            foreach ($x in $all) {
                if ($x -is [Management.Automation.Language.VariableExpressionAst]) {
                    $n = $x.VariablePath.UserPath -replace '^script:', ''
                    if ($vars.ContainsKey($n) -and $vars[$n] -notin $libs -and -not $local[$n] -and $n -notin $optional) { $bad.Add("`$$n ($($vars[$n]).ps1) in $where") }
                }
                if ($x -isnot [Management.Automation.Language.CommandAst]) { continue }
                $names = @($x.GetCommandName())
                # Get-Command '<name>' is a call that fails quietly when the library is missing.
                if ($names[0] -eq 'Get-Command' -and $x.CommandElements.Count -gt 1 -and $x.CommandElements[1] -is [Management.Automation.Language.StringConstantExpressionAst]) { $names += $x.CommandElements[1].Value }
                $head = $x.CommandElements[0]
                if (-not $names[0] -and $x.InvocationOperator -ne 'Dot' -and $head -is [Management.Automation.Language.VariableExpressionAst] -and -not $local[$head.VariablePath.UserPath]) {
                    $bad.Add("call through $head in $where")
                }
                foreach ($n in $names) {
                    if (-not $n -or -not $funcs.ContainsKey($n) -or $n -in $optional) { continue }   # cmdlets, programs
                    if ($funcs[$n].lib -notin $libs) { $bad.Add("$n ($($funcs[$n].lib).ps1) in $where"); continue }
                    if (-not $walked[$n]) { $walked[$n] = $true; $todo.Enqueue(@($n, $funcs[$n].ast, $false)) }
                }
            }
        }
        @($bad | Sort-Object -Unique)
    }
}

Describe 'bin\winarchy.ps1 verbs with their own libraries' {
    It '<Name> reaches nothing outside <Libs>' -ForEach $cases {
        $clauses.ContainsKey($Name) | Should -BeTrue -Because "'$Name' needs a clause in the switch"
        Get-Unreached $Name $Libs | Should -BeNullOrEmpty
    }
    It '<Name> loads its libraries in the full order, common first' -ForEach $cases {
        $Libs[0] | Should -Be 'common'
        $at = @($Libs | ForEach-Object { [array]::IndexOf($allLibs, $_) })
        $at | Should -Not -Contain -1
        ($at -join ',') | Should -Be (($at | Sort-Object) -join ',')
    }
    It 'catches a verb that reaches past its libraries' {
        Get-Unreached 'audio' @('common', 'audio') | Should -Contain 'Write-JsonAtomic (netpanel.ps1) in Update-AudioState'
        Get-Unreached 'dns-set' @('common') | Should -Contain "Set-WinarchyDns (system.ps1) in the 'dns-set' clause"
    }
}
