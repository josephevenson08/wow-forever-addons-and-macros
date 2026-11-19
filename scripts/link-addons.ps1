<#
.SYNOPSIS
    Link the addons in addons\ into the WoW Forever AddOns folder with directory
    junctions, so edits in the repo show up in game after /reload.

.DESCRIPTION
    The game folder defaults to D:\World of Warcraft\_forever_. To use another
    path, pass -WowPath or put the path on the first line of
    scripts\wow-path.local.txt (git-ignored).

    Real folders that already exist in AddOns are never touched; the script only
    creates and removes its own junctions. Junctions need no admin rights.

.EXAMPLE
    .\scripts\link-addons.ps1
.EXAMPLE
    .\scripts\link-addons.ps1 -Name XPRate
.EXAMPLE
    .\scripts\link-addons.ps1 -Unlink
#>
[CmdletBinding()]
param(
    [string] $WowPath,

    # Only link these addons (folder names). Default: every addon in addons\.
    [string[]] $Name,

    # Remove the junctions instead of creating them.
    [switch] $Unlink
)

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$localPathFile = Join-Path $PSScriptRoot 'wow-path.local.txt'

if (-not $WowPath) {
    if (Test-Path $localPathFile) {
        $WowPath = (Get-Content -Path $localPathFile -TotalCount 1).Trim()
    } else {
        $WowPath = 'D:\World of Warcraft\_forever_'
    }
}

if (-not (Test-Path $WowPath)) {
    throw "WoW Forever folder not found: $WowPath. Pass -WowPath or put the path in scripts\wow-path.local.txt."
}

$gameAddons = Join-Path $WowPath 'Interface\AddOns'
if (-not (Test-Path $gameAddons)) {
    New-Item -ItemType Directory -Path $gameAddons | Out-Null
    Write-Output "created $gameAddons"
}

$repoAddons = Join-Path $repo 'addons'
$sources = @()
if (Test-Path $repoAddons) {
    $sources = Get-ChildItem -Path $repoAddons -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "$($_.Name).toc") }
}
if ($Name) { $sources = $sources | Where-Object { $_.Name -in $Name } }

if (-not $sources) {
    Write-Output 'No addons to link (each addon needs addons\<Name>\<Name>.toc).'
    return
}

function Get-LinkTarget($item) {
    $target = @($item.Target)[0]
    if ($target) { return $target.TrimEnd('\') }
}

foreach ($src in $sources) {
    $linkPath = Join-Path $gameAddons $src.Name
    $existing = Get-Item -Path $linkPath -Force -ErrorAction SilentlyContinue
    $isJunction = $existing -and $existing.LinkType -eq 'Junction'
    $pointsHere = $isJunction -and ((Get-LinkTarget $existing) -ieq $src.FullName.TrimEnd('\'))

    if ($Unlink) {
        if ($pointsHere) {
            # Deletes the junction only, never the folder it points to.
            [System.IO.Directory]::Delete($linkPath)
            Write-Output "unlinked $($src.Name)"
        } elseif ($existing) {
            Write-Warning "$linkPath is not a link to this repo; left alone."
        }
        continue
    }

    if ($pointsHere) {
        Write-Output "ok       $($src.Name)"
    } elseif ($existing) {
        Write-Warning "$linkPath already exists and is not a link to this repo; skipped. Move it out of the way to use the repo copy."
    } else {
        New-Item -ItemType Junction -Path $linkPath -Target $src.FullName | Out-Null
        Write-Output "linked   $($src.Name) -> $linkPath"
    }
}
