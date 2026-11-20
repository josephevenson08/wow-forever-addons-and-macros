# WoW Forever Addons

Addons for World of Warcraft: Forever (interface 16001).

## Addons

| Addon | What it does | Slash |
| ----- | ------------ | ----- |
| [Wyvern Wits](addons/WyvernWits) | Reverse-trivia minigame on flight paths: rarer valid answers send an 8-bit Thrall diving deeper. | `/wits` |
| [Ore Atlas](addons/OreAtlas) | Scrollable mining reference: every ore's skill colors, the zones to find it in, and your Mining progress. | `/ore` |

## Install (players)

Copy an addon folder from `addons/` into
`World of Warcraft\_forever_\Interface\AddOns\`, then restart the game.

## Development

Requirements: Windows with PowerShell 7, and WoW Forever installed. VS Code
with the recommended extensions (Lua + WoW API) gives autocomplete for the
game API.

```powershell
git clone https://github.com/josephevenson08/wowforeveraddons.git
cd wowforeveraddons

# Create a new addon from the template and link it into the game
.\scripts\new-addon.ps1 -Name MyAddon -Title "My Addon" -Slash myaddon -Notes "What it does." -Link

# Link every addon in addons\ into the game (directory junctions)
.\scripts\link-addons.ps1

# Build release zips in dist\
.\scripts\package.ps1
```

The scripts assume the game is at `D:\World of Warcraft\_forever_`. For a
different path, pass `-WowPath` or write the path into
`scripts\wow-path.local.txt`.

After editing Lua, type `/reload` in game. New files or TOC changes need a
full restart. Turn on error popups with `/console scriptErrors 1`.

See [docs/forever-api-notes.md](docs/forever-api-notes.md) for what the
Forever API allows and blocks.
