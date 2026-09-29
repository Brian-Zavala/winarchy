<#
  Writes the Bluetooth radio state for the bar icon and the Bluetooth panel: bluetooth.json in
  the Zebar pack, {"present": bool, "on": bool} and, with -Devices, the paired devices:
    {"present":true,"on":true,"devices":[{"id":"...","name":"WH-1000XM5","connected":true}]}
  -Action on|off switches the radio first. Needs Windows PowerShell 5.1 for the WinRT projection:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File bluetooth.ps1 [-Action on|off] [-Devices]
#>
param(
    [string]$Out = (Join-Path $env:USERPROFILE '.glzr\zebar\omarchy\bluetooth.json'),
    [ValidateSet('', 'on', 'off')][string]$Action = '',
    [switch]$Devices
)

$present = $false; $on = $false; $list = @()
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTaskOp = [System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } |
        Select-Object -First 1
    function Await($op, [Type]$type) {
        $task = $asTaskOp.MakeGenericMethod($type).Invoke($null, @($op))
        [void]$task.Wait(10000)
        $task.Result
    }
    [void][Windows.Devices.Radios.Radio, Windows.System.Devices, ContentType = WindowsRuntime]
    $radios = Await ([Windows.Devices.Radios.Radio]::GetRadiosAsync()) ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]])
    $bt = @($radios) | Where-Object { $_.Kind -eq 'Bluetooth' } | Select-Object -First 1
    if ($bt) {
        $present = $true
        if ($Action) {
            $state = if ($Action -eq 'on') { [Windows.Devices.Radios.RadioState]::On } else { [Windows.Devices.Radios.RadioState]::Off }
            [void](Await ($bt.SetStateAsync($state)) ([Windows.Devices.Radios.RadioAccessStatus]))
        }
        $on = ($bt.State -eq 'On')
    }
    if ($Devices -and $present) {
        [void][Windows.Devices.Enumeration.DeviceInformation, Windows.Devices.Enumeration, ContentType = WindowsRuntime]
        [void][Windows.Devices.Bluetooth.BluetoothDevice, Windows.Devices.Bluetooth, ContentType = WindowsRuntime]
        $selector = [Windows.Devices.Bluetooth.BluetoothDevice]::GetDeviceSelectorFromPairingState($true)
        $infos = Await ([Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($selector)) ([Windows.Devices.Enumeration.DeviceInformationCollection])
        foreach ($info in @($infos)) {
            $dev = Await ([Windows.Devices.Bluetooth.BluetoothDevice]::FromIdAsync($info.Id)) ([Windows.Devices.Bluetooth.BluetoothDevice])
            $list += [ordered]@{
                id = $info.Id; name = $info.Name
                connected = [bool]($dev -and $dev.ConnectionStatus -eq 'Connected')
            }
        }
    }
} catch {}

$obj = [ordered]@{ present = $present; on = $on }
if ($Devices) { $obj.devices = @($list | Sort-Object { -[int]$_.connected }, name) }
$json = $obj | ConvertTo-Json -Depth 4 -Compress
$tmp = "$Out.tmp"
[IO.File]::WriteAllText($tmp, $json, (New-Object Text.UTF8Encoding $false))
Move-Item -Force $tmp $Out
