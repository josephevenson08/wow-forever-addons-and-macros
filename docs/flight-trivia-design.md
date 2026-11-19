# Flight path trivia minigame: design draft

Working title: **Wyvern Wits** (wind riders are wyverns in WoW lore). Rename
freely.

## The pitch

You click a flight master and take off. A small 8-bit window pops up: Thrall
on his wind rider. Each prompt asks for any valid answer ("Name a zone in
Kalimdor"), but **rarer valid answers score more**. Every point sends Thrall
10 yards deeper, through clouds, over Durotar, down the canyons, into
Ragefire, and on to the molten core. You see how deep you got by the time you
land.

The scoring idea, where obscure-but-correct beats obvious, is borrowed from
reverse-trivia games like Krillion. Everything else is our own: the WoW
prompts, the tier names, the Thrall dive, and the visuals. We don't reuse
Krillion's name, tier names, art, or layout.

## Why it fits WoW Forever

- It runs only while you're on a taxi: no combat, no protected actions, no
  combat log. Nothing in it touches secret values.
- Everything is local Lua data. No network, no addon messages, so the
  "no comms in instances" rule never comes up.
- Nobody else does trivia on flights. Existing flight-path games are a
  falling-block puzzle (SkyStack), an arcade pack (Darkmoon Arcade, Flight
  Games), a retro shooter (Flight Doom), a bomber (A-Bomb!), and typing tests
  (Typing Life).

## Game flow

1. **Take off.** We hook `TakeTaxiNode` (via `hooksecurefunc`), remember the
   destination name and the time, and wait for `PLAYER_CONTROL_LOST`. If
   `UnitOnTaxi("player")` is true within a second or two, the flight has
   started. A short poll covers the race where `UnitOnTaxi` lags the event.
   After a `/reload` mid-flight, `PLAYER_ENTERING_WORLD` plus `UnitOnTaxi`
   brings the window back.
2. **Popup.** The window slides in with the route ("Orgrimmar to
   Crossroads") and a Start button. It also has "not now" and "never on
   this route" options, and a setting to auto-start.
3. **Rounds.** Each round is one prompt with a 20 second timer and an input
   box. Wrong guesses don't end the round: you get "Not on the list" and keep
   typing. A valid answer locks in its tier and points. Speed gives no bonus.
4. **Reveal.** After each prompt we show your tier, your points, and the
   deepest answer you could have given (for example "Warchief: GM Island").
   You learn something every round.
5. **Landing.** Landing is `UnitOnTaxi` turning false or
   `PLAYER_CONTROL_GAINED`. If the game isn't over, it keeps going on the
   ground and the window doesn't vanish mid-prompt. The summary shows final
   depth, the tier of each answer, and your personal best for that route.

**Game length:** we record each route's flight time in SavedVariables. The
first time we fly a route we use 5 prompts. After that, we fit the number of
prompts to the flight (about 25 seconds each), between 3 and 10.

## Rarity tiers

| Tier         | Points | Meaning                                 |
| ------------ | ------ | --------------------------------------- |
| Peon         | 10     | The answer everyone says first          |
| Grunt        | 25     | Common, but not the first thing said    |
| Blademaster  | 45     | Solid, a bit less obvious               |
| Far Seer     | 70     | Niche knowledge                         |
| Warchief     | 100    | Almost nobody thinks of it              |

Colors follow the item-quality feel WoW players already read: gray, green,
blue, purple, orange.

## Prompt bank

- Lua tables, one entry per prompt. Each answer has a display name, a
  tier, and aliases (`Stonetalon` for Stonetalon Mountains, `Domo` for
  Majordomo, `Grommash` for Grom). Matching ignores case, punctuation, and
  a leading "the". It also allows 1 typo for answers of 5+ characters and
  2 typos for 9+.
- **Grading:** we grade by hand by how likely a typical player is to think
  of the answer, which is the WoW version of "how often it shows up in
  print". It's tuned over time. Players can report "my answer should count"
  with a slash command; it's stored locally so we can collect it later.
- **Live game data where it helps:** for some categories we can also accept
  answers the client itself knows about. Zones come from `C_Map`, flight
  points from `C_TaxiMap`, and classes and races from the game. An answer
  that's valid in game but missing from our list counts at a fixed tier
  ("Far Seer: not in our book yet") and gets saved, so the grade stays the
  same the next time you give it. That covers Forever-only content we don't
  know about yet.
- Faction-aware: Horde prompts lean Kalimdor/Horde lore, and Alliance
  players get the matching set plus a gryphon rider in place of Thrall
  (later).
- Starting categories: zones by continent, capital cities, classic
  dungeons, raid bosses (Molten Core, Onyxia, Blackwing Lair), herbs, ores,
  professions, beast families, orc lore characters, factions you can earn
  reputation with, flight points on your continent, and world bosses. We
  aim for 40+ prompts at launch so repeats are rare.
- No repeats within a flight, and recently seen prompts sit out for a while.

## Visuals

- **One 8-bit scene**, about 160x100 "pixels" drawn at 3x, inside a pixel
  border.
- **Sprites:** the art lives as text pixel grids in `art/flight-trivia/`.
  `scripts/build-art.js` turns them into 32-bit TGA sprite sheets (power of
  two sizes) plus a generated `Sprites.lua` with frame sizes. The game uses
  `SetTexture(path, nil, nil, "NEAREST")` so pixels stay crisp at any UI
  scale. Thrall on a wind rider has 2 wing frames and a 1 pixel bob.
- **Background:** stacked bands of solid color that step (not blend) as the
  depth changes, drawn with plain color textures. The layers going down
  are open sky, cloud bank, over Durotar, canyon walls, deep caverns,
  Ragefire, and the molten core. Each layer adds its own props: drifting
  clouds, red rock walls, glowing crystals, rising embers.
- **Climb variant:** the same engine runs upward instead (Durotar, open
  sky, clouds, high winds, storm front, starfield, Twisting Nether). The
  concept mockup has a toggle so we can pick one, or offer both as a
  setting.
- **Text:** a pixel font with a license that lets us ship it (for example
  Press Start 2P or Silkscreen, both OFL), drawn with the `MONOCHROME`
  flag. Until then we use the game font.
- **Juice:** speed lines while diving, a tier banner that pops in the tier
  color, a screen shake on Warchief answers, and a sound cue per tier using
  built-in game sounds (`PlaySound` with existing sound kit IDs).

## Saved data

`WyvernWitsDB`:

- Settings: auto-start, sound, dive or climb, window position and scale.
- Flight time and personal best per route.
- Answer history: which answers you've given, for "new answer" badges and
  stats.
- Locked grades for live-data answers that aren't in our book.
- Lifetime stats: deepest dive and Warchief count.

## Later ideas

- Guild leaderboard and "rarest answer in your guild" using guild addon
  messages, which are allowed in the open world.
- A daily prompt set that's the same for everyone, seeded by date.
- Alliance theme: a gryphon rider diving into Ironforge's Deeprun depths.

## Decisions

- Thrall **dives down** (chosen 2026-11-19). The climb variant is dropped.
- A Start button shows on takeoff by default; `/wits auto on` skips it.
- Tier names and the starting categories are as listed above. Retune them
  after real games.

## Build order

1. Taxi detection, popup window, and a prompt engine with a 10-prompt bank.
   Test it in game on a real flight.
2. The sprite pipeline in game: Thrall TGA, color bands, depth movement.
3. The full prompt bank, flight-time fitting, and personal bests.
4. Polish: font, sounds, juice, and settings.
