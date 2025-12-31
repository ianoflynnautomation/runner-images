[CmdletBinding()]
param (
    [Parameter()]
    [string]$VersionOverride
)

$ErrorActionPreference = 'Stop'

$date = Get-Date
$year   = $date.ToString("yyyy")
$month  = $date.ToString("MM")
$day    = $date.ToString("dd")
$buildDate = $date.ToString("yyyy-MM-dd")

$base = "$year.$month.$day"
$suffix = ""

if ($env:GITHUB_REF -eq 'refs/heads/develop') {
    $suffix = "-beta"
}

$version = $null

if ($VersionOverride) {
    $version = $VersionOverride
    Write-Host "Using override: $version"
}
else {
    git fetch --tags --quiet 2>$null

    $prefix = "$base$suffix"
    $existing = git tag --list "$prefix*" --sort=version:refname
    $count = if ($existing) { ($existing -split '\n').Count } else { 0 }

    if ($count -gt 0) {
        $patch = $count + 1
        $version = "$base$suffix.$patch"
    }
    else {
        $version = "$base$suffix"
    }
}

$galleryVersion = $version -replace '-', '.'

$datePartMatch = [regex]::Match($version, '^\d{4}\.\d{2}\.\d{2}')
$datePart = if ($datePartMatch.Success) { $datePartMatch.Value } else { $base }
$imageDateStr = $datePart -replace '\.', '-'

try {
    $imageDate = [datetime]::ParseExact($imageDateStr, 'yyyy-MM-dd', [cultureinfo]::InvariantCulture)
    $ageDays = [math]::Round(((Get-Date) - $imageDate).TotalDays) + 1
}
catch {
    Write-Host "::warning::Date parsing failed for age: $imageDateStr"
    $ageDays = 1
}

$outputs = @(
    "version=$version"
    "version_tag=v$version"
    "gallery_version=$galleryVersion"
    "build_date=$buildDate"
    "image_age_days=$ageDays"
    "is_beta=$($suffix -eq '-beta')".ToLower()
)

$outputs | ForEach-Object {
    $_ | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}

@"
## Runner Image Version (CalVer)

- **Version**         : ``$version``
- **Gallery version** : ``$galleryVersion``
- **Build date**      : ``$buildDate``
- **Type**            : $(if ($suffix) { 'preview/beta' } else { 'stable' })
- **Age**             : ≈ $ageDays days
"@ | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8

Write-Host "Generated CalVer: $version (gallery: $galleryVersion)"
