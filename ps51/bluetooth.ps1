<#
  Writes the Bluetooth radio state for the bar icon: bluetooth.json in the Zebar pack,
  {"present": bool, "on": bool}. Needs Windows PowerShell 5.1 for the WinRT projection:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File bluetooth.ps1
#>
param([string]$Out = (Join-Path $env:USERPROFILE '.glzr\zebar\omarchy\bluetooth.json'))

$present = $false; $on = $false
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTaskOp = [System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } |
        Select-Object -First 1
    [void][Windows.Devices.Radios.Radio, Windows.System.Devices, ContentType = WindowsRuntime]
    $listType = [System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]]
    $task = $asTaskOp.MakeGenericMethod($listType).Invoke($null, @([Windows.Devices.Radios.Radio]::GetRadiosAsync()))
    [void]$task.Wait(10000)
    $bt = @($task.Result) | Where-Object { $_.Kind -eq 'Bluetooth' } | Select-Object -First 1
    if ($bt) { $present = $true; $on = ($bt.State -eq 'On') }
} catch {}

$json = '{"present":' + "$present".ToLower() + ',"on":' + "$on".ToLower() + '}'
$tmp = "$Out.tmp"
[IO.File]::WriteAllText($tmp, $json, (New-Object Text.UTF8Encoding $false))
Move-Item -Force $tmp $Out
