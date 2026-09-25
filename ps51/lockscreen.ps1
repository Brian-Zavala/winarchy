<#
  Sets the Windows lock screen image (Omarchy's lock screen shows the current background).
  Needs Windows PowerShell 5.1 for the WinRT projection:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File lockscreen.ps1 -Path <image> [-StateFile <state.json>]
  With -StateFile it does nothing if a newer background was picked meanwhile (latest pick wins).
#>
param([Parameter(Mandatory)][string]$Path, [string]$StateFile)

$log = Join-Path $env:USERPROFILE '.winarchy\logs\winarchy.log'
function Write-OwLog([string]$msg) { try { Add-Content $log "$(Get-Date -Format 'HH:mm:ss') [lockscreen] $msg" } catch {} }

if ($StateFile -and (Test-Path $StateFile)) {
    Start-Sleep -Milliseconds 700   # let a burst of picks settle
    try {
        $current = (Get-Content -Raw $StateFile | ConvertFrom-Json).background
        if ($current -and $current -ne $Path) { exit 0 }
    } catch {}
}

try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $methods = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 }
    $asTaskOp = $methods | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1
    $asTaskAction = $methods | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } | Select-Object -First 1

    [void][Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
    [void][Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime]

    $op = [Windows.Storage.StorageFile]::GetFileFromPathAsync($Path)
    $task = $asTaskOp.MakeGenericMethod([Windows.Storage.StorageFile]).Invoke($null, @($op))
    [void]$task.Wait(15000)
    $file = $task.Result

    $set = $asTaskAction.Invoke($null, @([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($file)))
    [void]$set.Wait(15000)
    Write-OwLog "-> $Path"
} catch {
    Write-OwLog "FAILED for ${Path}: $($_.Exception.Message)"
    exit 1
}
