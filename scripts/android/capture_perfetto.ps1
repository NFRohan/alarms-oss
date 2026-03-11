param(
    [string]$Serial,
    [string]$ConfigPath = "scripts/android/perfetto/startup_trace.pbtxt",
    [string]$TraceName = "neoalarm-startup",
    [string]$OutputDir = ".artifacts/android-performance",
    [switch]$LaunchNeoAlarm
)

$ErrorActionPreference = "Stop"

function Resolve-AdbPath {
    $adbCommand = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCommand) {
        return $adbCommand.Source
    }

    $sdkAdb = "C:\Android\SDK\platform-tools\adb.exe"
    if (Test-Path $sdkAdb) {
        return $sdkAdb
    }

    throw "adb was not found on PATH and C:\Android\SDK\platform-tools\adb.exe does not exist."
}

$adb = Resolve-AdbPath
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$resolvedConfigPath = Resolve-Path (Join-Path $repoRoot $ConfigPath)
$resolvedOutputDir = Join-Path $repoRoot $OutputDir
$remoteTracePath = "/data/misc/perfetto-traces/$TraceName.perfetto-trace"
$localTracePath = Join-Path $resolvedOutputDir "$TraceName.perfetto-trace"

New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null

$adbArgs = @()
if ($Serial) {
    $adbArgs += @("-s", $Serial)
}

$perfettoArgs = @()
$perfettoArgs += $adbArgs
$perfettoArgs += @(
    "shell"
    "perfetto"
    "--txt"
    "-c"
    "-"
    "-o"
    $remoteTracePath
)

$perfettoProcess = Start-Process `
    -FilePath $adb `
    -ArgumentList $perfettoArgs `
    -RedirectStandardInput $resolvedConfigPath `
    -PassThru `
    -NoNewWindow
Start-Sleep -Seconds 2

if ($LaunchNeoAlarm) {
    & $adb @adbArgs shell am start -W -n dev.neoalarm.app/.MainActivity | Out-Null
}

$perfettoProcess.WaitForExit()
if ($null -ne $perfettoProcess.ExitCode -and $perfettoProcess.ExitCode -ne 0) {
    throw "Perfetto capture failed with exit code $($perfettoProcess.ExitCode)."
}

& $adb @adbArgs pull $remoteTracePath $localTracePath | Out-Null
& $adb @adbArgs shell rm -f $remoteTracePath | Out-Null

Write-Host "Perfetto trace saved to $localTracePath"
