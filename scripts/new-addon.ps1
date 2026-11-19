<#
.SYNOPSIS
    Create a new addon in addons\<Name> from templates\AddonTemplate.

.EXAMPLE
    .\scripts\new-addon.ps1 -Name XPRate -Title "XP Rate" -Slash xpr -Notes "XP per hour and time to level." -Link
#>
[CmdletBinding()]
param(
    # Folder and TOC name. Letters, digits and underscores; must start with a letter.
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]*$')]
    [string] $Name,

    # Name shown in the in-game AddOns list.
    [string] $Title,

    # One-line description shown in the AddOns list tooltip.
    [string] $Notes = '',

    # Slash command without the leading "/". Defaults to the name in lower case.
    [string] $Slash,

    [string] $Author,

    # Also link the new addon into the game's AddOns folder.
    [switch] $Link
)

$ErrorActionPreference = 'Stop'

if (-not $Title) { $Title = $Name }
if (-not $Slash) { $Slash = $Name.ToLower() }
if (-not $Author) { $Author = (git config user.name 2>$null) }
if (-not $Author) { $Author = 'Unknown' }

$repo = Split-Path -Parent $PSScriptRoot
$template = Join-Path $repo 'templates\AddonTemplate'
$addonsRoot = Join-Path $repo 'addons'
$dest = Join-Path $addonsRoot $Name

if (Test-Path $dest) { throw "addons\$Name already exists." }
if (-not (Test-Path $addonsRoot)) { New-Item -ItemType Directory -Path $addonsRoot | Out-Null }

# Order matters: replace the longer token first.
$tokens = [ordered]@{
    '__ADDON_UPPER__' = $Name.ToUpper()
    '__ADDON__'       = $Name
    '__TITLE__'       = $Title
    '__NOTES__'       = $Notes
    '__SLASH__'       = $Slash.TrimStart('/').ToLower()
    '__AUTHOR__'      = $Author
}

function Expand-Tokens([string] $text) {
    foreach ($key in $tokens.Keys) { $text = $text.Replace($key, $tokens[$key]) }
    return $text
}

Copy-Item -Path $template -Destination $dest -Recurse

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
Get-ChildItem -Path $dest -Recurse -File | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName)
    [System.IO.File]::WriteAllText($_.FullName, (Expand-Tokens $content), $utf8NoBom)

    $newName = Expand-Tokens $_.Name
    if ($newName -ne $_.Name) { Rename-Item -Path $_.FullName -NewName $newName }
}

Write-Output "created addons\$Name  (/$($tokens['__SLASH__']))"

if ($Link) {
    & (Join-Path $PSScriptRoot 'link-addons.ps1') -Name $Name
}
