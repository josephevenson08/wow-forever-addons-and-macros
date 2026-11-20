# Wyvern Wits

A reverse-trivia minigame for WoW Forever flight paths. Any valid answer
counts, but **rarer answers score more**. Every point sends an 8-bit Thrall
on his wind rider 10 yards deeper: through the clouds, over Durotar, down
the canyons, through Ragefire and the molten core, all the way to the
Elemental Plane.

Interface 16001 (WoW Forever). Version 0.1.0.

## Install

Copy the `WyvernWits` folder into
`World of Warcraft\_forever_\Interface\AddOns\`, then restart the game.

## How it plays

1. Take a flight path. When you lift off, the window opens with your route
   (for example "Orgrimmar to Crossroads") and a Start button.
2. Each round is one prompt, like "Name a boss in Molten Core", with a
   20 second timer.
3. Type an answer and press Enter. Wrong guesses just say "Not on the
   list". Keep trying until the timer runs out. Speed earns nothing extra.
4. A valid answer locks in its tier. The reveal also shows the rarest
   answer you could have given.
5. After the last prompt you get your final depth, your points per prompt,
   and any new records.

Landing doesn't end a game in progress. If you land without pressing
Start, the window closes itself.

### Tiers

| Tier        | Points | Meaning                              |
| ----------- | ------ | ------------------------------------ |
| Peon        | 10     | The answer everyone says first       |
| Grunt       | 25     | Common, but not the first thing said |
| Blademaster | 45     | Solid and a bit less obvious         |
| Far Seer    | 70     | Niche knowledge                      |
| Warchief    | 100    | Almost nobody thinks of it           |

### Game length

The addon times each route. A route it hasn't seen gets 5 prompts. After
that, it fits the game to the flight at about 24 seconds per prompt,
between 3 and 10 prompts.

### Answers

- Case, spaces, punctuation and a leading "the" don't matter, so
  "un'goro" and "The Un'Goro Crater" both work.
- Common short names work: STV, BRD, UBRS, Domo, Grommash and so on.
  Short names under 5 letters must match exactly.
- One typo is forgiven for answers of 5+ letters, two for 9+.

### Prompts

20 prompts so far: zones in Kalimdor and the Eastern Kingdoms, classic
dungeons, bosses in Molten Core, Blackwing Lair and Zul'Gurub, herbs, ores,
professions, classes, playable races, hunter pet families, orc lore
characters, orc clans, troll tribes, dragons, reputation factions, Kalimdor
flight points, famous lore weapons, and Warchiefs of the Horde. Prompts
from your last few games sit out so you don't see them again right away.

The tiers are graded by hand in [Prompts.lua](Prompts.lua). Edit them
freely.

## Commands

| Command                    | What it does                                      |
| -------------------------- | ------------------------------------------------- |
| `/wits`                    | List the commands                                 |
| `/wits play`               | Practice game, no flight needed                   |
| `/wits show`               | Reopen the window                                 |
| `/wits popup [on\|off]`    | Open the window on takeoff (default on)           |
| `/wits auto [on\|off]`     | Skip the Start button (default off)               |
| `/wits sound [on\|off]`    | Sounds (default on)                               |
| `/wits scale 0.8`          | Window size, 0.5 to 2                             |
| `/wits stats`              | Games played, deepest dive, Warchief answers      |
| `/wits version`            | Addon version                                     |
| `/wits reset`              | Reset settings and window position (keeps stats)  |

`/wyvernwits` works too. Clicking Wyvern Wits in the minimap addon menu
opens the window.

Drag the window to move it. Escape closes it, which also pauses the timer.

## Saved data

`WyvernWitsDB` (account-wide) holds:

- Your settings and window position.
- Each route's flight time and your best depth on it.
- The prompts from your recent games.
- Every answer you've given, which powers the "(new)" tag.
- Lifetime stats.

## Status

Not tested in game yet. Things to check on a first run:

- The window opens when a flight starts, and the route names look right.
- The Thrall sprite is sharp, not blurry.
- No Lua errors. Turn on `/console scriptErrors 1` to see them.

## Files

| File          | Purpose                                                  |
| ------------- | -------------------------------------------------------- |
| `Core.lua`    | Saved settings, events, slash commands                   |
| `Flight.lua`  | Detects takeoff and landing, times routes                |
| `Game.lua`    | Game flow: rounds, timer, scoring, summary               |
| `Matcher.lua` | Tiers and answer matching                                |
| `Prompts.lua` | The prompt bank                                          |
| `Scene.lua`   | The 8-bit dive scene                                     |
| `UI.lua`      | The window, prompt panel and answer box                  |
| `media/`      | The Thrall sprite sheet, generated from `art/flight-trivia` |

To change the sprite, edit `art/flight-trivia/thrall_windrider.txt` at the
repo root, then run:

```powershell
node scripts/build-art.js art/flight-trivia addons/WyvernWits/media
```

Design notes are in
[docs/flight-trivia-design.md](../../docs/flight-trivia-design.md).
