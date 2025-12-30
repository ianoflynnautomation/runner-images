$ErrorActionPreference = 'Stop'

$buildTimestamp = (Get-Date -AsUTC).ToString("yyyy-MM-ddTHH:mm:ssZ")

$gitShortSha = if ($env:GITHUB_SHA) {
    $env:GITHUB_SHA.Substring(0, [Math]::Min(8, $env:GITHUB_SHA.Length))
} else {
    "unknown"
}

$imageTier = "stable"
if ($env:GITHUB_REF -eq 'refs/heads/develop') {
    $imageTier = "beta"
}

$imageName = "${{ matrix.image_definition }}-${{ env.IMAGE_VERSION }}"

@{
    build_timestamp = $buildTimestamp
    git_short_sha   = $gitShortSha
    image_tier      = $imageTier
    image_name      = $imageName
} | ConvertTo-Json -Compress | Out-File -FilePath env:GITHUB_OUTPUT -Append -Encoding utf8

$summaryTable = @"
### Build Configuration

| Property       | Value                                      |
|----------------|--------------------------------------------|
| **Image**      | ${{ matrix.name }}                         |
| **CalVer**     | ``${{ env.IMAGE_VERSION }}``               |
| **Build Date** | ``${{ env.BUILD_DATE }}``                  |
| **Tier**       | ``$imageTier``                             |
| **Commit**     | ``$gitShortSha``                           |
| **Age**        | ≈ ${{ needs.version.outputs.image_age_days }} days old |
"@

$summaryTable | Out-File -FilePath env:GITHUB_STEP_SUMMARY -Append -Encoding utf8

Write-Host "Metadata generated:"
Write-Host "  Timestamp : $buildTimestamp"
Write-Host "  Short SHA : $gitShortSha"
Write-Host "  Tier      : $imageTier"
Write-Host "  Image name: $imageName"
