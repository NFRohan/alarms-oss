param(
    [string]$OutputPath = ".artifacts/android-performance/datatransport-audit.txt"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$androidDir = Join-Path $repoRoot "android"
$resolvedOutputPath = Join-Path $repoRoot $OutputPath

New-Item -ItemType Directory -Force -Path (Split-Path $resolvedOutputPath) | Out-Null

Push-Location $androidDir
try {
    $barcodeInsight = & .\gradlew :app:dependencyInsight --configuration releaseRuntimeClasspath --dependency com.google.mlkit:barcode-scanning
    $transportInsight = & .\gradlew :app:dependencyInsight --configuration releaseRuntimeClasspath --dependency com.google.android.datatransport:transport-runtime
} finally {
    Pop-Location
}

@(
    "NeoAlarm DataTransport dependency audit"
    "Generated: $(Get-Date -Format o)"
    ""
    "Barcode dependency insight"
    "========================="
    $barcodeInsight
    ""
    "Transport runtime dependency insight"
    "==================================="
    $transportInsight
) | Set-Content $resolvedOutputPath

Write-Host "Dependency audit written to $resolvedOutputPath"
