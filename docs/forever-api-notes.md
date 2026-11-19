# WoW Forever addon API notes

Research notes gathered 2026-11-19. Almost everything here comes from fan
guide sites written against beta builds (1.60.1.69913 to 70450), not from
Blizzard documentation. **Treat every item as "check in game" until one of our
addons has confirmed it**, and update this file when we confirm or disprove
something.

## What WoW Forever is

- A Blizzard game mode that launched 2026-11-04: original Azeroth, level cap
  60, running on the modern Mainline client (the same UI code as Midnight).
- Internal game type name: **Camelot**. Mainline has two game types,
  Standard (Midnight) and Camelot (Forever).
- Blizzard said (WoW UI Discord, 2026-09-15) that Forever has "the vast
  majority of APIs available in 12.1.5".
- Not Classic Era. Classic Era addons do not load.
- Rulesets: Normal, PvP, RP, RP-PvP, with Hardcore promised after launch.
- First raid tier opens 2026-12-09.

## TOC

```
## Interface: 16001
```

- Install folder: `World of Warcraft\_forever_\Interface\AddOns\<Addon>\`.
  On this machine: `D:\World of Warcraft\_forever_\Interface\AddOns`.
- Flavor-specific TOC suffix: `<Addon>_Camelot.toc`. One guide says
  `_Forever.toc` became an alias on 2026-10-08. We use a single
  `<Addon>.toc` with interface 16001 until we need per-flavor files.
- To support Midnight as well, a comma list works:
  `## Interface: 16001, 120105` (Midnight's number is reported as 120100 or
  120105; check before using).
- An addon with the wrong interface number shows as out of date and only loads
  with "Load out of date AddOns" ticked.
- `WOW_PROJECT_ID` was 1 on one beta build and 18 (`WOW_PROJECT_CAMELOT`) on
  a later one. Don't branch on the number alone.

## Lua

Lua 5.1 as in every WoW client: no `goto`, no `//`, no bitwise operators (use
the `bit` library), no `_ENV`, no `require`/`dofile`/`io`/`os`.

## Missing legacy globals → use these instead

| Gone or deprecated        | Use                                       |
| ------------------------- | ----------------------------------------- |
| `GetSpellInfo`            | `C_Spell.GetSpellInfo` (returns a table)  |
| `GetItemInfo`             | `C_Item.GetItemInfo`                      |
| `GetAddOnMetadata`        | `C_AddOns.GetAddOnMetadata`               |
| `GetSpellBookItemName`    | `C_SpellBook` equivalents                 |
| `GetNumTalentTabs`, `GetTalentInfo` | check in game                   |
| `GetNumSkillLines`        | check in game                             |

Spell and item data return nil until cached: call
`C_Spell.RequestLoadSpellData` / `C_Item.RequestLoadItemDataByID`, then wait
for `SPELL_DATA_LOAD_RESULT` / `ITEM_DATA_LOAD_RESULT`. `Item:CreateFromItemID(id):ContinueOnItemLoad(fn)`
also works on Mainline.

## Restrictions (Midnight-era rules apply)

Blizzard's stated rule: addons must not give a competitive advantage in
combat. Concretely:

- **No combat log.** `COMBAT_LOG_EVENT_UNFILTERED` errors and
  `CombatLogGetCurrentEventInfo` is unavailable. Damage numbers come from the
  built-in meter (`C_DamageMeter`).
- **Secret values.** Some unit API results are "secret": `type()` says
  `number`/`string`/`boolean` but you can't do arithmetic, compare, or
  concatenate them. Reported: `UnitHealth` (even for the player),
  unit names, `UnitCanAttack`, `UnitExists`. Check with `issecretvalue(x)`.
  You can still pass secret health straight into
  `StatusBar:SetMinMaxValues` / `SetValue` to draw a bar.
- Reportedly readable in combat: unit name, class, level, cast bars and the
  spell being cast, aggro state, your own max health/power. Reportedly hidden:
  current health/power, exact threat, other units' max health/power, auras and
  cooldowns in combat.
- Restriction contexts: Combat, Encounter, ChallengeMode, PvPMatch, Map, Chat.
- **GUIDs are obfuscated** (since 2026-10-16), so no layer detection.
- **No addon messages to other players inside instances.** Addon comms work
  in the open world, guild, and so on.
- Protected functions: `pcall` does not get around a block. A blocked call can
  leave "Interface action failed because of an AddOn" until a full client
  restart. Reported blocked: `ChatFrame_OpenChat`, `ChatEdit_ActivateChat`,
  `C_SuperTrack.SetSuperTrackedUserWaypoint`. Use `HandleModifiedItemClick`
  for shift-links and `C_Map.SetUserWaypoint` for map pins.
- Don't write secure attributes on Blizzard unit frames. Secure snippets
  failed to compile on one beta build (click-casting addons broke); maybe a
  beta bug.
- Combat lockdown: queue protected frame changes until
  `PLAYER_REGEN_ENABLED` (`InCombatLockdown()` to check).

## Built into the default UI (don't rebuild these)

- Edit Mode with Modern and Classic presets, shareable layout strings.
- Cooldown Manager (Options → Gameplay Enhancement, `/cdm`).
- Damage Meter (Options → Advanced).
- Swing Timer (two guides say built in, one says "coming soon").
- Combined bags.

Not built in: boss timers (DBM/BigWigs cover it), arena frames.

## Existing Forever addons (so we don't duplicate them)

Bartender4, BetterBlizzFrames/Plates, EllesmereUI, ForeverUI, Plater,
Questie, Leatrix Maps/Plus, TomTom, DBM, BigWigs, GTFO, Details!, Auctionator,
Baganator, Bagnon, TSM, BlizzMove, Talents Forever, GearQuest Forever,
Guidelime, RestedXP, Hardcore, AllTheThings, RareScanner, several hunter-pet
addons.

## Gaps people mention

- Deathlog-style hardcore death feed (no verified Forever build).
- Raid click-casting frames (broken by secret health / secure snippets).
- WeakAuras replacements (only unofficial forks, combat triggers broken).
- Official ElvUI Forever release.

## Sources

- https://wowforeverguides.com/addons/developers (updated 2026-11-11)
- https://forevermeta.me/en/guides/wow-forever-addons-interface (2026-10-23, pre-launch)
- https://mmonster.co/wow-forever/guides/addons (updated 2026-11-19)
- https://mmonster.co/wow-forever/guides/addons/restrictions
- https://mmonster.co/wow-forever/guides/addons/install
