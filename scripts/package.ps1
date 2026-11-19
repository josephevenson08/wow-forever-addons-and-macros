<#
.SYNOPSIS
    Zip addons for upload to CurseForge / Wago / GitHub releases.

.DESCRIPTION
    Writes dist\<Name>-<Version>.zip with the addon folder at the root of the
    zip, which is the layout addon managers expect. The version comes from the
    "## Version:" line in the TOC.

.EXAMPLE
    .\scripts\package.ps1
.EXAMPLE
    .\scripts\package.ps1 -Name XPRate
#>
[CmdletBinding()]
param(
    [string[]] $Name
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo = Split-Path -Parent $PSScriptRoot
$repoAddons = Join-Path $repo 'addons'
$dist = Join-Path $repo 'dist'

$sources = @()
if (Test-Path $repoAddons) {
    $sources = Get-ChildItem -Path $repoAddons -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "$($_.Name).toc") }
}
if ($Name) { $sources = $sources | Where-Object { $_.Name -in $Name } }

if (-not $sources) {
    Write-Output 'No addons to package.'
    return
}

New-Item -ItemType Directory -Path $dist -Force | Out-Null

foreach ($src in $sources) {
    $toc = Join-Path $src.FullName "$($src.Name).toc"
    $match = Select-String -Path $toc -Pattern '^##\s*Version:\s*(.+?)\s*$' | Select-Object -First 1
    $version = if ($match) { $match.Matches[0].Groups[1].Value } else { 'dev' }

    $zip = Join-Path $dist "$($src.Name)-$version.zip"
    if (Test-Path $zip) { Remove-Item -Path $zip }

    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $src.FullName, $zip,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $true)  # include the addon folder itself at the zip root

    Write-Output "packaged dist\$($src.Name)-$version.zip"
}
