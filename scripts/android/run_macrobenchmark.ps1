param(
    [string]$Serial
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$androidDir = Join-Path $repoRoot "android"

if ($Serial) {
    $env:ANDROID_SERIAL = $Serial
}

Push-Location $androidDir
try {
    & .\gradlew :benchmark:connectedBenchmarkAndroidTest --rerun-tasks
} finally {
    Pop-Location
}

Write-Host "Macrobenchmark outputs are under android\\benchmark\\build\\outputs."
