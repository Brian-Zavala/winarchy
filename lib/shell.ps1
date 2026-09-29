# winarchy shell on|off|status: Omarchy's shell setup (default/bash/aliases, init) for
# PowerShell 7: the starship prompt, zoxide, eza and bat under names of their own, fzf with
# a preview, and Omarchy's short aliases. A delimited block in your profile, like the Herdr
# shortcuts: on replaces it in place, off and uninstall take out just that block.
#
# PowerShell's own ls, cat and cd are left alone (scripts pass their objects along
# pipelines), and so is any name that is already a command, alias or function: gcm, h and r
# are PowerShell's own aliases. What a tool needs is checked when the shell starts, so
# installing one later (Install > Shell Tools) is enough.
$ShellProfileBegin = '# >>> winarchy shell >>>'
$ShellProfileEnd = '# <<< winarchy shell <<<'

function Get-ShellProfileBlock {
    @(
        $ShellProfileBegin
        "# Omarchy's shell setup (default/bash/aliases). Written by winarchy shell on; winarchy shell off"
        '# takes it out. Names that are already commands keep their meaning.'
        '& {'
        '    $free = { param($n) -not (Get-Command $n -ErrorAction SilentlyContinue) }'
        '    $has = { param($n) [bool](Get-Command $n -CommandType Application -ErrorAction SilentlyContinue) }'
        '    if (& $has starship) { Invoke-Expression (& starship init powershell --print-full-init | Out-String) }'
        '    if (& $has zoxide) {'
        '        Invoke-Expression (zoxide init powershell | Out-String)'
        "        # Omarchy's cd: a folder that exists, else zoxide's best match."
        '        if (& $free zd) { function global:zd { if (-not $args) { Set-Location ~ } elseif (Test-Path -LiteralPath $args[0] -PathType Container) { Set-Location -LiteralPath $args[0] } else { z @args; if ($?) { Write-Host "$([char]::ConvertFromUtf32(0xF17A9)) $PWD" } } } }'
        '    }'
        '    if (& $has eza) {'
        '        if (& $free l) { function global:l { eza -lh --group-directories-first --icons=auto @args } }'
        '        if (& $free lsa) { function global:lsa { eza -lha --group-directories-first --icons=auto @args } }'
        '        if (& $free lt) { function global:lt { eza --tree --level=2 --long --icons --git @args } }'
        '        if (& $free lta) { function global:lta { eza --tree --level=2 --long --icons --git -a @args } }'
        '    }'
        '    if ((& $has fzf) -and (& $free ff)) {'
        "        function global:ff { if (Get-Command bat -ErrorAction SilentlyContinue) { fzf --preview 'bat --style=numbers --color=always {}' @args } else { fzf @args } }"
        '    }'
        '    if (& $free ..) { function global:.. { Set-Location .. } }'
        '    if (& $free ...) { function global:... { Set-Location ..\.. } }'
        '    if (& $free ....) { function global:.... { Set-Location ..\..\.. } }'
        '    if ((& $has git) -and (& $free g)) { function global:g { git @args } }'
        '    if ((& $has git) -and (& $free gcam)) { function global:gcam { git commit -a -m @args } }'
        '    if ((& $has git) -and (& $free gcad)) { function global:gcad { git commit -a --amend @args } }'
        '    if ((& $has docker) -and (& $free d)) { function global:d { docker @args } }'
        '    if ((& $has nvim) -and (& $free n)) { function global:n { if ($args) { nvim @args } else { nvim . } } }'
        '    if (& $free a) { function global:a { winarchy agent -Inline @args } }'
        '    if ((& $has opencode) -and (& $free c)) { function global:c { opencode --auto @args } }'
        '    if ((& $has claude) -and (& $free cx)) { function global:cx { Clear-Host; claude --permission-mode auto @args } }'
        '    if ((& $has codex) -and (& $free cy)) { function global:cy { codex --approve-for-me @args } }'
        '    if (& $free open) { function global:open { foreach ($f in $args) { Invoke-Item $f } } }'
        '}'
        $ShellProfileEnd
    ) -join "`r`n"
}

$ShellProfilePattern = "(?s)\r?\n?" + [regex]::Escape($ShellProfileBegin) + ".*?" + [regex]::Escape($ShellProfileEnd) + "\r?\n?"

# The file is a parameter only so tests never touch the real profile.
function Set-ShellProfile([string]$file = $PROFILE.CurrentUserAllHosts) {
    $block = Get-ShellProfileBlock
    $old = if (Test-Path -LiteralPath $file) { Get-Content -Raw -LiteralPath $file } else { '' }
    $new = if ($old -match $ShellProfilePattern) { [regex]::Replace($old, $ShellProfilePattern, "`r`n$block`r`n") }
           else { ($old.TrimEnd() + "`r`n`r`n$block`r`n").TrimStart() }
    if ($new -eq $old) { return 'unchanged' }
    Save-File $file
    Write-Utf8 $file $new
    'written'
}

function Remove-ShellProfile([string]$file = $PROFILE.CurrentUserAllHosts) {
    if (-not $file -or -not (Test-Path -LiteralPath $file)) { return }
    $old = Get-Content -Raw -LiteralPath $file
    if ($old -notmatch $ShellProfilePattern) { return }
    Write-Utf8 $file ([regex]::Replace($old, $ShellProfilePattern, "`r`n"))
}

function Test-ShellProfile([string]$file = $PROFILE.CurrentUserAllHosts) {
    (Test-Path -LiteralPath $file) -and ((Get-Content -Raw -LiteralPath $file) -match [regex]::Escape($ShellProfileBegin))
}

function Invoke-Shell([string]$what) {
    $file = $PROFILE.CurrentUserAllHosts
    switch ($what) {
        'on' {
            [void](Set-ShellProfile $file)
            $tools = 'starship', 'zoxide', 'eza', 'fzf', 'bat'
            $missing = @($tools | Where-Object { -not (Get-Command $_ -CommandType Application -ErrorAction SilentlyContinue) })
            Write-Host "Omarchy's shell setup is in $file; it takes effect in a new PowerShell window."
            if ($missing) { Write-Host "Not installed yet: $($missing -join ', ') (Install > Shell Tools, or winarchy install-app <name>)." }
        }
        'off' { Remove-ShellProfile $file; Write-Host "Taken out of $file (open a new window)." }
        { $_ -in '', 'status' } { if (Test-ShellProfile $file) { "on ($file)" } else { 'off (winarchy shell on)' } }
        default { throw 'usage: winarchy shell [on|off|status]' }
    }
}
