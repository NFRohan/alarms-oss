param(
    [string]$Repo
)

$ErrorActionPreference = 'Stop'

function Read-KeyProperties {
    param([string]$Path)

    $values = @{}
    foreach ($line in Get-Content $Path) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
            continue
        }

        $parts = $line.Split('=', 2)
        if ($parts.Count -eq 2) {
            $values[$parts[0].Trim()] = $parts[1].Trim()
        }
    }

    return $values
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$keyPropertiesPath = Join-Path $repoRoot 'android\key.properties'
$keystorePath = Join-Path $repoRoot 'android\app\release-keystore.jks'

if (-not (Test-Path $keyPropertiesPath)) {
    throw "Missing signing config at $keyPropertiesPath"
}

if (-not (Test-Path $keystorePath)) {
    throw "Missing release keystore at $keystorePath"
}

$properties = Read-KeyProperties -Path $keyPropertiesPath

foreach ($requiredKey in 'storePassword', 'keyAlias', 'keyPassword') {
    if (-not $properties.ContainsKey($requiredKey) -or [string]::IsNullOrWhiteSpace($properties[$requiredKey])) {
        throw "Missing required key.properties value: $requiredKey"
    }
}

if ([string]::IsNullOrWhiteSpace($Repo)) {
    $Repo = & 'C:\Program Files\GitHub CLI\gh.exe' repo view --json nameWithOwner --jq .nameWithOwner
}

if ([string]::IsNullOrWhiteSpace($Repo)) {
    throw 'Unable to resolve GitHub repository name.'
}

$keystoreBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystorePath))

$keystoreBase64 | & 'C:\Program Files\GitHub CLI\gh.exe' secret set ANDROID_SIGNING_KEYSTORE_BASE64 --repo $Repo
$properties['keyAlias'] | & 'C:\Program Files\GitHub CLI\gh.exe' secret set ANDROID_KEY_ALIAS --repo $Repo
$properties['storePassword'] | & 'C:\Program Files\GitHub CLI\gh.exe' secret set ANDROID_KEYSTORE_PASSWORD --repo $Repo
$properties['keyPassword'] | & 'C:\Program Files\GitHub CLI\gh.exe' secret set ANDROID_KEY_PASSWORD --repo $Repo

Write-Host "Updated Android signing secrets for $Repo"
Write-Host 'Secrets set: ANDROID_SIGNING_KEYSTORE_BASE64, ANDROID_KEY_ALIAS, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD'
