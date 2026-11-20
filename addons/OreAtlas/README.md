# Ore Atlas

Your Mining leveling guide for WoW Forever. One scrollable pane lists every
ore you can mine. For each one it shows which color the ore is for you right
now, the skill where it turns yellow, green and gray, and the zones to find
it in. It also tracks your Mining skill and tells you what to mine next.

Ore Atlas is built to pair with **GatherMate2**: GatherMate2 shows every
node on the map, and Ore Atlas tells you which ore to chase and which zone to
go to. Click a zone in Ore Atlas, the world map opens there, and GatherMate2's
icons show every node of that ore.

Interface 16001 (WoW Forever). Version 0.3.0.

<img src="../../docs/screenshots/ore-atlas.png" width="420" alt="Ore Atlas pane at Mining 142: Iron is orange, Indurium and Gold are still too high">

_The pane at Mining 142. This is a preview rendered from the addon's own layout and data. Real in-game screenshots will replace it once it's been tested._

## Install

Copy the `OreAtlas` folder into
`World of Warcraft\_forever_\Interface\AddOns\`, then restart the game.

Recommended: also install **GatherMate2** and **GatherMate2_Data (Retail &
Forever)** from CurseForge (their WoW Forever files), and import the Mining
data in GatherMate2 (`/gathermate`, then **Import**). Ore Atlas works without
them, but then its zone lists come only from research.

## The pane

Open it with `/ore` or from the minimap addon menu.

- **Header:** your Mining skill and cap as a progress bar, your rank
  (Apprentice to Artisan), and any skill bonus from gear. Below that is a
  training hint, such as "Capped at 150. Train Expert at a Mining trainer
  to keep going.", plus your skill-ups this session.
- **Best now:** the ore to mine at your skill and its top three zones.
  Click it to scroll to that ore. It picks the highest common ore that's
  orange for you, then yellow, then green. Rare spawns and quest ores are
  never picked.
- **Other miners:** your other characters' Mining levels, saved whenever
  you log in on them.
- **Ore cards**, every ore in order of required skill:
  - The ore's icon, and its color for you, or "need 155" if your skill is
    too low.
  - A bar from 0 to 300 showing the orange, yellow, green and gray ranges,
    with a white marker at your skill.
  - The exact thresholds, for example "125 orange, 150 yellow, 175 green,
    225 gray".
  - Notes on special cases, like Ooze Covered versions or the Black Forge
    for Dark Iron.
  - Zone buttons. Click one to open the world map there (not in combat).
    Hover for details.

## Zone lists and GatherMate2

With GatherMate2 installed, Ore Atlas counts the Mining nodes GatherMate2
knows. Each card then lists the zones where that ore really spawns, busiest
first, with node counts like "The Hinterlands 89". Ore Atlas only reads that
data from your own install while you play; it never copies or ships it. If
GatherMate2_Data is installed but not imported yet, Ore Atlas reads its
Forever table directly.

Until an ore has at least 20 known nodes, its card also keeps the researched
zones after the counted ones. Those come from Forever mining guides (gold)
and classic spawn data, with a `*` on the densest classic zones.

## Ores

Colors follow the classic rule: orange at the required skill, yellow at
+25, green at +50, gray at +100.

| Node                      | Needs | Yellow | Green | Gray | Notes                              |
| ------------------------- | ----- | ------ | ----- | ---- | ---------------------------------- |
| Copper Vein               | 1     | 25     | 50    | 100  | Forever adds Poor Copper and Amber |
| Tin Vein                  | 65    | 90     | 115   | 165  |                                    |
| Incendicite Mineral Vein  | 65    | 90     | 115   | 165  | Quest ore, Wetlands                |
| Silver Vein               | 75    | 100    | 125   | 175  | Rare spawn                         |
| Lesser Bloodstone Deposit | 75    | 100    | 125   | 175  | Quest ore, Arathi                  |
| Iron Deposit              | 125   | 150    | 175   | 225  |                                    |
| Indurium Mineral Vein     | 150   | 175    | 200   | 250  | Quest ore, inside Uldaman          |
| Gold Vein                 | 155   | 180    | 205   | 255  | Rare spawn                         |
| Mithril Deposit           | 175   | 200    | 225   | 275  |                                    |
| Truesilver Deposit        | 230   | 255    | 280   | 330  | Rare spawn                         |
| Dark Iron Deposit         | 230   | 255    | 280   | 330  | Blackrock Mountain                 |
| Small Thorium Vein        | 245   | 270    | 295   | 345  |                                    |
| Rich Thorium Vein         | 275   | 300    | 325   | 375  |                                    |
| Heavy Thorium Vein        | 300   | -      | -     | -    | New in Forever, Mount Hyjal        |
| Obsidian Chunk            | 305   | -      | -     | -    | Ahn'Qiraj, needs +Mining gear      |

Trainer ranks: Apprentice to 75, Journeyman to 150 (train at 50), Expert to
225 (train at 125), Artisan to 300 (train at 200). Junior trainers in the
starting zones only teach up to 75.

## Commands

| Command                  | What it does                                          |
| ------------------------ | ----------------------------------------------------- |
| `/ore`                   | Open or close the pane                                |
| `/ore alerts [on\|off]`  | Chat alerts when your best ore changes (default on)   |
| `/ore scale 0.9`         | Pane size, 0.5 to 2                                   |
| `/ore debug`             | Print Mining, map and GatherMate2 data the addon sees |
| `/ore reset`             | Reset settings and pane position                      |
| `/ore help`              | List the commands                                     |

`/oreatlas` works too. Drag the pane to move it, and press Escape to close
it.

**Alerts:** when a skill-up changes your best ore, you get a chat message
like "Tin Vein is your best ore now (orange): Redridge Mountains, The
Barrens, Ashenvale." You also get one when you hit a trainer cap.

## How it works

- **Skill:** read with `GetProfessions` and `GetProfessionInfo`. The older
  skill functions are gone on Forever. No event fires for a single skill
  point, so the addon re-reads your skill whenever the "Your skill in
  Mining has increased" message appears, and when you learn a rank.
- **Maps:** zones are looked up by name in the game's live map data.
  Forever uses classic map IDs (Tanaris is 1446), which are the fallback,
  used only when the name matches.
- **Ore data:** all of it is in [Data.lua](Data.lua), with sources listed
  at the top. If you find an ore somewhere the atlas doesn't list, or never
  find it where it says, fix `Data.lua`.

## Saved data

`OreAtlasDB` (account-wide) holds your alert and scale settings, the pane
position, and each character's Mining skill. Settings from 0.2.x (map
shading, the ore filter, recorded mining spots) are removed on load.

## Status

Not fully tested in game yet. On a first run:

- Run `/ore debug`. It shows the raw profession data Forever returns, any
  zones the map lookup couldn't find, whether GatherMate2 was found, and
  how many nodes it knows per ore.
- If the header says "not learned" on a character that has Mining, the
  debug output shows why.
- Turn on `/console scriptErrors 1` to see any Lua errors.

## Files

| File        | Purpose                                                    |
| ----------- | ---------------------------------------------------------- |
| `Core.lua`  | Saved settings, events, alerts, slash commands             |
| `Data.lua`  | Ores, zones, trainer ranks, skill colors                   |
| `Skill.lua` | Reads and saves your Mining skill                          |
| `Maps.lua`  | Finds a zone's map and opens the world map to it           |
| `Nodes.lua` | Counts GatherMate2's Mining nodes per zone                 |
| `UI.lua`    | The pane: header, ore cards, zone buttons                  |
