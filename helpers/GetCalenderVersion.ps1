[CmdletBinding()]
param(
    [Parameter()][string]$VersionOverride
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Function Get-CalVerBase {
    [OutputType([string])]
    param()

    $now = [datetime]::UtcNow
    return $now.ToString('yyyy.MM.dd')
}

Function Get-BuildDateString {
    [OutputType([string])]
    param()

    return [datetime]::UtcNow.ToString('yyyy-MM-dd')
}

Function Get-NextPatchNumber {
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [string]$Prefix
    )

    git fetch --tags --quiet 2>$null

    $existingTags = git tag --list "$Prefix*" --sort=version:refname
    if (-not $existingTags) {
        return 0
    }

    # Count non-empty lines
    return ($existingTags -split '\n' | Where-Object { $_ }).Count
}

Function Resolve-FinalVersion {
    [OutputType([string])]
    param(
        [string]$Override,
        [string]$Base
    )

   if ($Override -and $Override.Trim()) {
        $cleanOverride = $Override.Trim()
        Write-Host "Using version override: $cleanOverride"
        return $cleanOverride
    }

    $prefix = $Base

    $patch = Get-NextPatchNumber -Prefix $prefix

    if ($patch -eq 0) {
        return $prefix
    }

    return "$prefix.$patch"
}

Function ConvertTo-GalleryVersion {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$SemverVersion
    )

    # No -beta anymore → no replacement needed, but kept for future-proofing
    return $SemverVersion -replace '-', '.'
}

Function Get-ImageAgeInDays {
    [OutputType([int])]
    param(
        [string]$Version
    )

    if (-not ($Version -match '^(\d{4})\.(\d{2})\.(\d{2})')) {
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
# Main logic
# ────────────────────────────────────────────────

$baseVersion   = Get-CalVerBase
$buildDate     = Get-BuildDateString

$version       = Resolve-FinalVersion -Override $VersionOverride -Base $baseVersion
$galleryVer    = ConvertTo-GalleryVersion $version
$imageAgeDays  = Get-ImageAgeInDays $version

$stepSummary = @"
## Runner Image Version (CalVer)

- **Version**         : ``$version``
- **Gallery version** : ``$galleryVer``
- **Build date**      : ``$buildDate``
- **Type**            : stable
- **Age**             : ≈ $imageAgeDays days
"@

# GitHub Actions output
$githubOutput = [ordered]@{
    version         = $version
    version_tag     = "v$version"
    gallery_version = $galleryVer
    build_date      = $buildDate
    image_age_days  = $imageAgeDays
    is_beta         = 'false'
}

foreach ($key in $githubOutput.Keys) {
    $value = $githubOutput[$key]
    "$key=$value" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}

# Summary (visible in GitHub UI)
$stepSummary | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8

Write-Host "Generated CalVer: $version  (gallery: $galleryVer)"
