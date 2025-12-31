[CmdletBinding()]
param(
    [Parameter()]
    [string]$VersionOverride
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CalVerBase {
    [OutputType([string])]
    param()
    return [datetime]::UtcNow.ToString('yyyy.MM.dd')
}

function Get-BuildDateString {
    [OutputType([string])]
    param()
    return [datetime]::UtcNow.ToString('yyyy-MM-dd')
}

function Get-NextPatchNumber {
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [string]$Prefix
    )

    git fetch --tags --quiet 2>$null

    $tags = git tag --list "$Prefix*" --sort=version:refname
    if (-not $tags) { return 0 }

    return ($tags -split '\n' | Where-Object { $_ }).Count
}

function Resolve-FinalVersion {
    [OutputType([string])]
    param(
        [string]$Override,
        [string]$Base
    )

    if ($Override -and $Override.Trim()) {
        $clean = $Override.Trim()
        Write-Host "Using version override: $clean"
        return $clean
    }

    $patch = Get-NextPatchNumber -Prefix $Base

    if ($patch -eq 0) {
        return "$Base.0"
    }

    return "$Base.$patch"
}

function Get-ImageAgeInDays {
    [OutputType([int])]
    param(
        [string]$Version
    )

    if ($Version -notmatch '^(\d{4})\.(\d{2})\.(\d{2})') {
        Write-Host "::warning::Cannot parse date from version '$Version'"
        return 1
    }

    $dateStr = "$($Matches[1])-$($Matches[2])-$($Matches[3])"

    try {
        $buildDate = [datetime]::ParseExact($dateStr, 'yyyy-MM-dd', [cultureinfo]::InvariantCulture)
        $days = [math]::Round(((Get-Date).Date - $buildDate.Date).TotalDays) + 1
        return [math]::Max(1, $days)
    }
    catch {
        Write-Host "::warning::Invalid date format: $dateStr"
        return 1
    }
}

# ────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────

$base     = Get-CalVerBase
$buildDate = Get-BuildDateString
$version  = Resolve-FinalVersion -Override $VersionOverride -Base $base
$ageDays  = Get-ImageAgeInDays $version

$summary = @"
## Runner Image Version (CalVer)

- **Version**     : ``$version``
- **Build date**  : ``$buildDate``
- **Type**        : stable
- **Age**         : ≈ $ageDays days
"@

# GitHub Actions outputs
$outputs = [ordered]@{
    version         = $version
    version_tag     = "v$version"
    build_date      = $buildDate
    image_age_days  = $ageDays
}

foreach ($key in $outputs.Keys) {
    "$key=$($outputs[$key])" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}

$summary | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8

Write-Host "Generated CalVer: $version"
