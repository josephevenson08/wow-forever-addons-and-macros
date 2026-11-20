# WoW Forever addons

Addons for **WoW Forever**: Blizzard's level-60 original-Azeroth mode that
runs on the modern Mainline (Midnight) client. Not Classic Era, not a private
server.

## Target

- `## Interface: 16001` in every TOC.
- Mainline APIs: use `C_*` namespaces (`C_AddOns`, `C_Spell`, `C_Item`,
  `C_Map`, `C_Timer`). Many legacy globals (`GetSpellInfo`, `GetItemInfo`,
  `GetAddOnMetadata`, ...) are gone.
- Lua 5.1: no `goto`, `//`, bitwise operators, `require`, `io`, `os`.
- Game folder on this machine: `C:\Blizzard main\World of Warcraft\_forever_`
  (saved in the git-ignored `scripts\wow-path.local.txt`, which the scripts
  read). `D:\World of Warcraft\_forever_` is a stub install that isn't played.
  SavedVariables are under `WTF\Account\<account>\SavedVariables\`; read them
  to see what an addon actually recorded in game.
- Forever uses classic-era uiMapIDs (Durotar 1411 ... Winterspring 1452,
  Tanaris 1446), plus new IDs for Forever zones (e.g. 2482, 2521, 2548, 2652).

## Hard limits (read docs/forever-api-notes.md before designing a feature)

- No combat log. No reading live combat numbers. Addons must not give a
  combat advantage; don't build rotation helpers, threat calculators, or
  enemy-cooldown trackers.
- Secret values: `UnitHealth` and some unit names/booleans can't be used in
  math, comparisons, or string building. Guard with `issecretvalue`.
- No addon messages to other players inside instances. GUIDs are obfuscated.
- Protected actions only out of combat; defer with `PLAYER_REGEN_ENABLED`.
- The default UI already has Edit Mode, a cooldown manager, a damage meter,
  and combined bags. Don't rebuild those.

Good fits: out-of-combat quality of life, leveling and economy tools, alt
tracking, professions, map/quest helpers, cosmetic UI.

## Layout

```
addons/<Name>/          one folder per addon; folder name == TOC name
  <Name>.toc
  Core.lua
templates/AddonTemplate source for new addons (tokens like __ADDON__)
art/<set>/              text pixel-art sources (built into addon media)
scripts/                new-addon.ps1, link-addons.ps1, package.ps1, build-art.js
docs/                   API notes, research, design drafts
```

## Conventions

- File-level `local ADDON_NAME, ns = ...`; share code through `ns`, not
  globals. The only globals an addon defines are its SavedVariables
  (`<Name>DB`), `SLASH_*`/`SlashCmdList` entries, and the
  `<Name>Compartment_OnClick` function named in the TOC.
- Events go through the `handlers` table in Core.lua
  (`function handlers.EVENT_NAME(...)` + `ns.RegisterEvent`).
- Settings live in SavedVariables with a `defaults` table merged on load.
- Bump `## Version:` in the TOC when a change is user-visible.

## Workflow

- New addon: `.\scripts\new-addon.ps1 -Name Foo -Title "Foo" -Slash foo -Notes "..." -Link`
- Link everything into the game: `.\scripts\link-addons.ps1` (junctions, no
  admin needed). Then `/reload` in game picks up Lua edits. New files or TOC
  changes need a full client restart.
- Package: `.\scripts\package.ps1` → `dist\<Name>-<Version>.zip`.
- Pixel art: text grids in `art/<set>/*.txt` are the source. Build with
  `node scripts/build-art.js art/<set> addons/<Name>/media` → TGA sprite
  sheets (power-of-two) + `Sprites.lua`, and 8x PNG previews in
  `art/<set>/preview/` (git-ignored) to eyeball the result. Draw textures
  with `SetTexture(path, nil, nil, "NEAREST")` so pixels stay crisp.
- There is no Lua interpreter or game in this environment. Testing happens in
  game: ask the user to `/reload` and report what they see. Turn on Lua errors
  with `/console scriptErrors 1`.
- API facts in docs/forever-api-notes.md come from beta-era fan guides. When
  in-game testing confirms or disproves one, update that file.
